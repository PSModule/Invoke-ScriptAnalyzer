# Resolve paths for testing
$testPath = Resolve-Path -Path "$PSScriptRoot/tests/PSScriptAnalyzer" | Select-Object -ExpandProperty Path
$path = [string]::IsNullOrEmpty($env:PSMODULE_INVOKE_SCRIPTANALYZER_INPUT_Path) ? '.' : $env:PSMODULE_INVOKE_SCRIPTANALYZER_INPUT_Path
$codePath = Resolve-Path -Path $path | Select-Object -ExpandProperty Path

[pscustomobject]@{
    CodePath         = $codePath
    TestPath         = $testPath
    SettingsFilePath = $env:PSMODULE_INVOKE_SCRIPTANALYZER_INPUT_SettingsFilePath
} | Format-List | Out-String

if (!(Test-Path -Path $env:PSMODULE_INVOKE_SCRIPTANALYZER_INPUT_SettingsFilePath)) {
    Write-Error "Settings file not found at path: $env:PSMODULE_INVOKE_SCRIPTANALYZER_INPUT_SettingsFilePath"
    exit 1
}

Set-GitHubOutput -Name CodePath -Value $codePath
Set-GitHubOutput -Name TestPath -Value $testPath
Set-GitHubOutput -Name SettingsFilePath -Value $env:PSMODULE_INVOKE_SCRIPTANALYZER_INPUT_SettingsFilePath
