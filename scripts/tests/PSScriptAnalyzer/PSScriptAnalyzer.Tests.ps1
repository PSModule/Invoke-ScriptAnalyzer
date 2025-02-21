﻿[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSReviewUnusedParameter', '',
    Justification = 'Pester blocks line of sight during analysis.'
)]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSUseDeclaredVarsMoreThanAssignments', '',
    Justification = 'Pester blocks line of sight during analysis.'
)]
[CmdLetBinding()]
Param(
    [Parameter(Mandatory)]
    [string] $Path,

    [Parameter(Mandatory)]
    [string] $SettingsFilePath
)

BeforeDiscovery {
    $settings = Import-PowerShellDataFile -Path $SettingsFilePath
    $rules = [Collections.Generic.List[System.Collections.Specialized.OrderedDictionary]]::new()
    $ruleObjects = Get-ScriptAnalyzerRule -Verbose:$false | Sort-Object -Property Severity, CommonName
    $Severeties = $ruleObjects | Select-Object -ExpandProperty Severity -Unique
    foreach ($ruleObject in $ruleObjects) {
        $skip = if ($ruleObject.RuleName -in $settings.ExcludeRules) {
            $true
        } elseif ($settings.IncludeRules -and $ruleObject.RuleName -notin $settings.IncludeRules) {
            $skip = $true
        } elseif ($settings.Severity -and $ruleObject.Severity -notin $settings.Severity) {
            $skip = $true
        } elseif ($settings.Rules -and $settings.Rules.ContainsKey($ruleObject.RuleName) -and -not $settings.Rules[$ruleObject.RuleName].Enabled) {
            $skip = $true
        } else {
            $skip = $false
        }

        $rules.Add(
            [ordered]@{
                RuleName    = $ruleObject.RuleName
                CommonName  = $ruleObject.CommonName
                Severity    = $ruleObject.Severity
                Description = $ruleObject.Description
                Skip        = $skip
                <#
                    RuleName          : PSDSCUseVerboseMessageInDSCResource
                    CommonName        : Use verbose message in DSC resource
                    Description       : It is a best practice to emit informative, verbose messages in DSC resource functions.
                                        This helps in debugging issues when a DSC configuration is executed.
                    SourceType        : Builtin
                    SourceName        : PSDSC
                    Severity          : Information
                    ImplementingType  : Microsoft.Windows.PowerShell.ScriptAnalyzer.BuiltinRules.UseVerboseMessageInDSCResource
                #>
            }
        )
    }
    Write-Warning "Discovered [$($rules.Count)] rules"
    $relativeSettingsFilePath = $SettingsFilePath.Replace($PSScriptRoot, '').Trim('\').Trim('/')
}

Describe "PSScriptAnalyzer tests using settings file [$relativeSettingsFilePath]" {
    BeforeAll {
        $testResults = Invoke-ScriptAnalyzer -Path $Path -Settings $SettingsFilePath -Recurse -Verbose:$false
        Write-Warning "Found [$($testResults.Count)] issues"
    }

    foreach ($Severety in $Severeties) {
        Context "Severity: $Severety" {
            foreach ($rule in $rules | Where-Object -Property Severity -EQ $Severety) {
                It "$($rule.CommonName) ($($rule.RuleName))" -Skip:$rule.Skip {
                    $issues = [Collections.Generic.List[string]]::new()
                    $testResults | Where-Object -Property RuleName -EQ $rule.RuleName | ForEach-Object {
                        $relativePath = $_.ScriptPath.Replace($Path, '').Trim('\').Trim('/')
                        $issues.Add(([Environment]::NewLine + " - $relativePath`:L$($_.Line):C$($_.Column)"))
                    }
                    $issues -join '' | Should -BeNullOrEmpty -Because $rule.Description
                }
            }
        }
    }
}
