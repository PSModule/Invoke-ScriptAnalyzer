# Resolve paths for testing
$testPath = Resolve-Path -Path "$PSScriptRoot/tests/PSScriptAnalyzer" | Select-Object -ExpandProperty Path
$path = [string]::IsNullOrEmpty($env:PSMODULE_INVOKE_SCRIPTANALYZER_INPUT_Path) ? '.' : $env:PSMODULE_INVOKE_SCRIPTANALYZER_INPUT_Path
$codePath = Resolve-Path -Path $path | Select-Object -ExpandProperty Path

# Try to resolve the settings file path, but allow it to be null if not found
$settingsFilePath = $null
if (-not [string]::IsNullOrEmpty($env:PSMODULE_INVOKE_SCRIPTANALYZER_INPUT_SettingsFilePath)) {
    try {
        $settingsFilePath = Resolve-Path -Path $env:PSMODULE_INVOKE_SCRIPTANALYZER_INPUT_SettingsFilePath -ErrorAction Stop | Select-Object -ExpandProperty Path
        Write-Information "Using settings file: $settingsFilePath"
    } catch {
        Write-Warning "Settings file not found at path: $($env:PSMODULE_INVOKE_SCRIPTANALYZER_INPUT_SettingsFilePath). Using default settings."
    }
} else {
    $settingsFilePath = ''
}

if ([string]::IsNullOrEmpty($settingsFilePath)) {
    Write-Information 'No settings file specified or found. Using default PSScriptAnalyzer settings.'
}

[pscustomobject]@{
    CodePath         = $codePath
    TestPath         = $testPath
    SettingsFilePath = $settingsFilePath
} | Format-List | Out-String

Set-GitHubOutput -Name CodePath -Value $codePath
Set-GitHubOutput -Name TestPath -Value $testPath
Set-GitHubOutput -Name SettingsFilePath -Value $settingsFilePath
