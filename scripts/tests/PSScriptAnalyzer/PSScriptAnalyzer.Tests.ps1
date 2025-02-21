[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
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
            Write-Verbose "Skipping rule [$($ruleObject.RuleName)] - Because it is in the exclude list" -Verbose
            Write-Verbose "  Exclude: $($settings.ExcludeRules)" -Verbose
            Write-Verbose "  Rule is excluded: $($ruleObject.RuleName -in $($settings.ExcludeRules))" -Verbose
            $true
        } elseif ($settings.IncludeRules -and $ruleObject.RuleName -notin $settings.IncludeRules) {
            Write-Verbose "Skipping rule [$($ruleObject.RuleName)] - Because it is not in the include list" -Verbose
            Write-Verbose "  Include: $($settings.IncludeRules)" -Verbose
            Write-Verbose "  Rule is not included: $($ruleObject.RuleName -notin $($settings.IncludeRules))" -Verbose
            $true
        } elseif ($settings.Severity -and $ruleObject.Severity -notin $settings.Severity) {
            Write-Verbose "Skipping rule [$($ruleObject.RuleName)] - Because it is not in the severity list" -Verbose
            Write-Verbose "  Severity: $($settings.Severity)" -Verbose
            Write-Verbose "  Severity not included: $($ruleObject.Severity -notin $($settings.Severity))" -Verbose
            $true
        } elseif ($settings.Rules -and $settings.Rules.ContainsKey($ruleObject.RuleName) -and -not $settings.Rules[$ruleObject.RuleName].Enable) {
            Write-Verbose "Skipping rule [$($ruleObject.RuleName)] - Because it is disabled" -Verbose
            Write-Verbose "  Rules:    $($settings.Rules)" -Verbose
            Write-Verbose "  Contains: $($settings.Rules.ContainsKey($ruleObject.RuleName))" -Verbose
            Write-Verbose "  Enable:   $($settings.Rules[$ruleObject.RuleName].Enable)" -Verbose
            $true
        } else {
            $false
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
