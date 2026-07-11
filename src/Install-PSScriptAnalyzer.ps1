<#
    .SYNOPSIS
    Ensures the requested PSScriptAnalyzer version is the only one installed and loaded.

    .DESCRIPTION
    Runs as the Invoke-Pester prescript, in the same process as the analyzer test run. It installs the
    PSScriptAnalyzer version selected through the action's Version/Prerelease inputs (retrying transient
    PSGallery failures), removes any other PSScriptAnalyzer version from the session, and imports the chosen
    version into the global session state. This guarantees the tests use the selected version instead of
    PowerShell auto-loading whatever copy happens to be preinstalled on the runner.
#>

[CmdletBinding()]
param()

$moduleName = 'PSScriptAnalyzer'
$version = $env:PSMODULE_INVOKE_SCRIPTANALYZER_INPUT_Version
$prerelease = $env:PSMODULE_INVOKE_SCRIPTANALYZER_INPUT_Prerelease -eq 'true'

$installParams = @{
    Name            = $moduleName
    Repository      = 'PSGallery'
    TrustRepository = $true
    PassThru        = $true
    WarningAction   = 'SilentlyContinue'
}
if (-not [string]::IsNullOrWhiteSpace($version)) {
    $installParams['Version'] = $version
}
if ($prerelease) {
    $installParams['Prerelease'] = $true
}

$label = [string]::IsNullOrWhiteSpace($version) ? $moduleName : "$moduleName $version"
Write-Host "Installing module: $label"

$installed = $null
$retryCount = 5
$retryDelay = 10
for ($i = 0; $i -lt $retryCount; $i++) {
    try {
        $installed = Install-PSResource @installParams
        break
    } catch {
        Write-Warning "Installation of $moduleName failed with error: $_"
        if ($i -eq $retryCount - 1) {
            throw
        }
        Write-Warning "Retrying in $retryDelay seconds..."
        Start-Sleep -Seconds $retryDelay
    }
}

# Resolve the exact version to load. Prefer what was just installed; if the resource was already
# present, Install-PSResource returns nothing, so fall back to the newest installed version that
# satisfies the requested constraint.
$resolved = $installed | Where-Object { $_.Name -eq $moduleName } | Sort-Object Version -Descending | Select-Object -First 1
if (-not $resolved) {
    $getParams = @{ Name = $moduleName; Verbose = $false; ErrorAction = 'SilentlyContinue' }
    if (-not [string]::IsNullOrWhiteSpace($version)) {
        $getParams['Version'] = $version
    }
    $resolved = Get-InstalledPSResource @getParams | Sort-Object Version -Descending | Select-Object -First 1
}
if (-not $resolved) {
    throw "No installed '$moduleName' version satisfies constraint '$version'."
}

# Remove any already-loaded versions so only the chosen one remains, then import that exact version
# into the global session state used by the Pester run.
Write-Host "Removing any loaded '$moduleName' module from the session"
Remove-Module -Name $moduleName -Force -ErrorAction SilentlyContinue

Write-Host "Importing module: $moduleName $($resolved.Version)"
Import-Module -Name $moduleName -RequiredVersion $resolved.Version -Force -Global
