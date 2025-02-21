[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSReviewUnusedParameter', 'Path',
    Justification = 'Path is being used.'
)]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSReviewUnusedParameter', 'SettingsFilePath',
    Justification = 'SettingsFilePath is being used.'
)]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSUseDeclaredVarsMoreThanAssignments', 'relativeSettingsFilePath',
    Justification = 'relativeSettingsFilePath is being used.'
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
        $rules.Add(
            [ordered]@{
                RuleName    = $ruleObject.RuleName
                CommonName  = $ruleObject.CommonName
                Severity    = $ruleObject.Severity
                Description = $ruleObject.Description
                Skip        = $ruleObject.RuleName -in $settings.ExcludeRules
                <#
                RuleName         : PSDSCUseVerboseMessageInDSCResource
                CommonName       : Use verbose message in DSC resource
                Description      : It is a best practice to emit informative, verbose messages in DSC resource functions. This helps in debugging issues when a DSC configuration is executed.
                SourceType       : Builtin
                SourceName       : PSDSC
                Severity         : Information
                ImplementingType : Microsoft.Windows.PowerShell.ScriptAnalyzer.BuiltinRules.UseVerboseMessageInDSCResource
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
