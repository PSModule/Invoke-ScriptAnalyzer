﻿@{
    Path = Get-ChildItem -Path $PSScriptRoot -Filter *.Tests.ps1 | Select-Object -ExpandProperty FullName
    Data = @{
        Path             = $env:PSMODULE_INVOKE_PESTER_INPUT_Run_Path
        SettingsFilePath = $env:SettingsFilePath
        Debug            = $false
        Verbose          = $false
    }
}
