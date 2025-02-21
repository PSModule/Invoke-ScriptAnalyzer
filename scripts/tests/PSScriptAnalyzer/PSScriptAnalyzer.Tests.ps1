[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSReviewUnusedParameter', '',
    Justification = 'Pester blocks line of sight during analysis.'
)]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSUseDeclaredVarsMoreThanAssignments', '',
    Justification = 'Pester blocks line of sight during analysis.'
)]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSAvoidUsingWriteHost', '',
    Justification = 'Write-Host is used for log output.'
)]
[CmdLetBinding()]
Param(
    [Parameter(Mandatory)]
    [string] $Path,

    [Parameter(Mandatory)]
    [string] $SettingsFilePath
)

BeforeDiscovery {
    LogGroup "PSScriptAnalyzer tests using settings file [$SettingsFilePath]" {
        $settings = Import-PowerShellDataFile -Path $SettingsFilePath
        $rules = [Collections.Generic.List[System.Collections.Specialized.OrderedDictionary]]::new()
        $ruleObjects = Get-ScriptAnalyzerRule -Verbose:$false | Sort-Object -Property Severity, CommonName
        $Severeties = $ruleObjects | Select-Object -ExpandProperty Severity -Unique

        Write-GitHubNotice -Message "`e]8;;https://example.com`e\Click here`e]8;;`e\"

        foreach ($ruleObject in $ruleObjects) {
            if ($ruleObject.RuleName -in $settings.ExcludeRules) {
                Write-Host " - $($ruleObject.RuleName)"
                Write-Host '   Skipping rule - Exclude list'
                $skip = $true
            } elseif ($settings.IncludeRules -and $ruleObject.RuleName -notin $settings.IncludeRules) {
                Write-Host " - $($ruleObject.RuleName)"
                Write-Host '   Skipping rule - Include list'
                $skip = $true
            } elseif ($settings.Severity -and $ruleObject.Severity -notin $settings.Severity) {
                Write-Host " - $($ruleObject.RuleName)"
                Write-Host '   Skipping rule - Severity list'
                $skip = $true
            } elseif ($settings.Rules -and $settings.Rules.ContainsKey($ruleObject.RuleName) -and -not $settings.Rules[$ruleObject.RuleName].Enable) {
                Write-Host " - $($ruleObject.RuleName)"
                Write-Host '   Skipping rule  - Disabled'
                $skip = $true
            } else {
                Write-Host " - $($ruleObject.RuleName)"
                $skip = $false
            }

            $rules.Add(
                [ordered]@{
                    RuleName    = $ruleObject.RuleName
                    CommonName  = $ruleObject.CommonName
                    Severity    = $ruleObject.Severity
                    Description = $ruleObject.Description
                    Skip        = $skip
                }
            )
        }
        Write-Warning "Discovered [$($rules.Count)] rules"
        $relativeSettingsFilePath = $SettingsFilePath.Replace($PSScriptRoot, '').Trim('\').Trim('/')
    }
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
