# Resolve paths for testing
$testPath = Resolve-Path -Path "$PSScriptRoot/tests/PSScriptAnalyzer" | Select-Object -ExpandProperty Path
$path = [string]::IsNullOrEmpty($env:PSMODULE_INVOKE_SCRIPTANALYZER_INPUT_Path) ? '.' : $env:PSMODULE_INVOKE_SCRIPTANALYZER_INPUT_Path
$codePath = Resolve-Path -Path $path | Select-Object -ExpandProperty Path

Write-Host "Looking for settings file under $($pwd.Path)"
$tmpSettingsFilePath = Join-Path -Path $pwd.Path -ChildPath $env:PSMODULE_INVOKE_SCRIPTANALYZER_INPUT_SettingsFilePath
$settingsFileExists = Test-Path -Path $tmpSettingsFilePath
if ($settingsFileExists) {
    $settingsFilePath = $tmpSettingsFilePath
} else {
    $settingsFilePath = ''
}
Write-Warning "Settings file not found at path: $($env:PSMODULE_INVOKE_SCRIPTANALYZER_INPUT_SettingsFilePath). Using default settings."

[pscustomobject]@{
    CodePath         = $codePath
    TestPath         = $testPath
    SettingsFilePath = $settingsFilePath
} | Format-List | Out-String

Set-GitHubOutput -Name CodePath -Value $codePath
Set-GitHubOutput -Name TestPath -Value $testPath
Set-GitHubOutput -Name SettingsFilePath -Value $settingsFilePath
