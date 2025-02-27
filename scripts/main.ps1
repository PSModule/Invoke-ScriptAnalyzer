# If test type is module, the code we ought to test is in the path/name folder, otherwise it's in the path folder.
$settings = $env:PSMODULE_INVOKE_SCRIPTANALYZER_INPUT_Settings
$testPath = Resolve-Path -Path "$PSScriptRoot/tests/PSScriptAnalyzer" | Select-Object -ExpandProperty Path
$codePath = Resolve-Path -Path $env:PSMODULE_INVOKE_SCRIPTANALYZER_INPUT_Path | Select-Object -ExpandProperty Path
$settingsFilePath = switch -Regex ($settings) {
    'Module|SourceCode' {
        "$testPath/$settings.Settings.psd1"
    }
    'Custom' {
        Resolve-Path -Path "$env:PSMODULE_INVOKE_SCRIPTANALYZER_INPUT_SettingsFilePath" | Select-Object -ExpandProperty Path
    }
    default {
        throw "Invalid test type: [$settings]"
    }
}

[pscustomobject]@{
    Settings         = $settings
    CodePath         = $codePath
    TestPath         = $testPath
    SettingsFilePath = $settingsFilePath
} | Format-List

Set-GitHubOutput -Name Settings -Value $settings
Set-GitHubOutput -Name CodePath -Value $codePath
Set-GitHubOutput -Name TestPath -Value $testPath
Set-GitHubOutput -Name SettingsFilePath -Value $settingsFilePath
