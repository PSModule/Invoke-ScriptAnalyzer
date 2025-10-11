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
param(
    [Parameter(Mandatory)]
    [string] $Path,

    [Parameter()]
    [string] $SettingsFilePath
)

BeforeDiscovery {
    $hasSettingsFile = -not [string]::IsNullOrEmpty($SettingsFilePath)
    $settingsDescription = $hasSettingsFile ? "settings file [$SettingsFilePath]" : 'default settings'

    LogGroup "PSScriptAnalyzer tests using $settingsDescription" {
        if ($hasSettingsFile) {
            $settings = Import-PowerShellDataFile -Path $SettingsFilePath
        } else {
            $settings = @{}
        }

        $rules = [Collections.Generic.List[System.Collections.Specialized.OrderedDictionary]]::new()
        $ruleObjects = Get-ScriptAnalyzerRule -Verbose:$false | Sort-Object -Property Severity, CommonName
        $Severeties = $ruleObjects | Select-Object -ExpandProperty Severity -Unique

        $PSStyle.OutputRendering = 'Ansi'
        $darkGrey = $PSStyle.Foreground.FromRgb(85, 85, 85)
        $green = $PSStyle.Foreground.Green
        $reset = $PSStyle.Reset

        foreach ($ruleObject in $ruleObjects) {
            if ($settings.ContainsKey('ExcludeRules') -and $ruleObject.RuleName -in $settings.ExcludeRules) {
                Write-Host "$darkGrey - $($ruleObject.RuleName) - Skipping rule - Exclude list$reset"
                $skip = $true
            } elseif ($settings.ContainsKey('IncludeRules') -and $ruleObject.RuleName -notin $settings.IncludeRules) {
                Write-Host "$darkGrey - $($ruleObject.RuleName) - Skipping rule - Include list$reset"
                $skip = $true
            } elseif ($settings.ContainsKey('Severity') -and $ruleObject.Severity -notin $settings.Severity) {
                Write-Host "$darkGrey - $($ruleObject.RuleName) - Skipping rule - Severity list$reset"
                $skip = $true
            } elseif ($settings.ContainsKey('Rules') -and $settings.Rules.ContainsKey($ruleObject.RuleName) -and
                -not $settings.Rules[$ruleObject.RuleName].Enable) {
                Write-Host "$darkGrey - $($ruleObject.RuleName) - Skipping rule  - Disabled$reset"
                $skip = $true
            } else {
                Write-Host "$green + $($ruleObject.RuleName) - Including rule$reset"
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
    }
}

Describe 'PSScriptAnalyzer' {
    BeforeAll {
        $hasSettingsFile = -not [string]::IsNullOrEmpty($SettingsFilePath)

        if ($hasSettingsFile) {
            $relativeSettingsFilePath = if ($SettingsFilePath.StartsWith($PSScriptRoot)) {
                $SettingsFilePath.Replace($PSScriptRoot, 'Action:').Trim('\').Trim('/')
            } elseif ($SettingsFilePath.StartsWith($env:GITHUB_WORKSPACE)) {
                $SettingsFilePath.Replace($env:GITHUB_WORKSPACE, 'Workspace:').Trim('\').Trim('/')
            } else {
                $SettingsFilePath
            }
        }

        $Path = Resolve-Path -Path $Path | Select-Object -ExpandProperty Path
        $relativePath = if ($Path.StartsWith($PSScriptRoot)) {
            $Path.Replace($PSScriptRoot, 'Action:').Trim('\').Trim('/').Replace('\', '/')
        } elseif ($Path.StartsWith($env:GITHUB_WORKSPACE)) {
            $Path.Replace($env:GITHUB_WORKSPACE, 'Workspace:').Trim('\').Trim('/').Replace('\', '/')
        } else {
            $Path
        }

        [pscustomobject]@{
            relativeSettingsFilePath = $relativeSettingsFilePath
            SettingsFilePath         = $SettingsFilePath
            PSScriptRoot             = $PSScriptRoot
            GITHUB_WORKSPACE         = $env:GITHUB_WORKSPACE
        }

        $invokeParams = @{
            Path    = $Path
            Recurse = $true
        }

        if ($hasSettingsFile) {
            $invokeParams['Settings'] = $SettingsFilePath
        }

        $logMessage = if ($hasSettingsFile) {
            "Invoke-ScriptAnalyzer -Path [$relativePath] -Recurse -Settings [$relativeSettingsFilePath]"
        } else {
            "Invoke-ScriptAnalyzer -Path [$relativePath] -Recurse (using default settings)"
        }

        LogGroup $logMessage {
            $testResults = Invoke-ScriptAnalyzer @invokeParams
        }

        LogGroup "TestResults [$($testResults.Count)]" {
            $testResults | Select-Object -Property * | Format-List | Out-String -Stream | ForEach-Object {
                Write-Verbose $_ -Verbose
            }
        }
    }

    foreach ($Severety in $Severeties) {
        Context "Severity: $Severety" {
            foreach ($rule in $rules | Where-Object -Property Severity -EQ $Severety) {
                It "$($rule.CommonName) ($($rule.RuleName))" -Skip:$rule.Skip -ForEach @{ Rule = $rule } {
                    $issues = [Collections.Generic.List[string]]::new()
                    $testResults | Where-Object { $_.RuleName -eq $Rule.RuleName } | ForEach-Object {
                        $relativeScriptPath = if ($_.ScriptPath.StartsWith($PSScriptRoot)) {
                            $_.ScriptPath.Replace($PSScriptRoot, 'Action:').Trim('\').Trim('/')
                        } elseif ($_.ScriptPath.StartsWith($env:GITHUB_WORKSPACE)) {
                            $_.ScriptPath.Replace($env:GITHUB_WORKSPACE, 'Workspace:').Trim('\').Trim('/')
                        } else {
                            $_.ScriptPath
                        }
                        $issues.Add(([Environment]::NewLine + " - $relativeScriptPath`:L$($_.Line):C$($_.Column)"))
                    }
                    $issues -join '' | Should -BeNullOrEmpty -Because $rule.Description
                }
            }
        }
    }
}

AfterAll {
    $PSStyle.OutputRendering = 'Host'
}
