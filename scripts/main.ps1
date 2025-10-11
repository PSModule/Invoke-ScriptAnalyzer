# Resolve paths for testing
$testPath = Resolve-Path -Path "$PSScriptRoot/tests/PSScriptAnalyzer" | Select-Object -ExpandProperty Path
$path = [string]::IsNullOrEmpty($env:PSMODULE_INVOKE_SCRIPTANALYZER_INPUT_Path) ? '.' : $env:PSMODULE_INVOKE_SCRIPTANALYZER_INPUT_Path
$codePath = Resolve-Path -Path $path | Select-Object -ExpandProperty Path
$settingsFilePath = Resolve-Path -Path $env:PSMODULE_INVOKE_SCRIPTANALYZER_INPUT_SettingsFilePath | Select-Object -ExpandProperty Path

[pscustomobject]@{
    CodePath         = $codePath
    TestPath         = $testPath
    SettingsFilePath = $settingsFilePath
} | Format-List | Out-String

if (!(Test-Path -Path $settingsFilePath)) {
    Write-Error "Settings file not found at path: $settingsFilePath"
    exit 1
}

Set-GitHubOutput -Name CodePath -Value $codePath
Set-GitHubOutput -Name TestPath -Value $testPath
Set-GitHubOutput -Name SettingsFilePath -Value $settingsFilePath
