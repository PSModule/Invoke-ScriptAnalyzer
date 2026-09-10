[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $WorkingDirectory,

    [Parameter(Mandatory)]
    [string] $TestResultPath,

    [Parameter(Mandatory)]
    [string] $CodeCoveragePath
)

function Assert-ReportPath {
    <#
        .SYNOPSIS
        Confirms that an action report is generated in the fixture artifact directory.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Path,

        [Parameter(Mandatory)]
        [string] $ReportName,

        [Parameter(Mandatory)]
        [string] $ArtifactDirectory
    )

    $resolvedPath = [System.IO.Path]::GetFullPath($Path)
    $resolvedArtifactDirectory = [System.IO.Path]::GetFullPath($ArtifactDirectory).TrimEnd(
        [System.IO.Path]::DirectorySeparatorChar,
        [System.IO.Path]::AltDirectorySeparatorChar
    ) + [System.IO.Path]::DirectorySeparatorChar

    if (-not $resolvedPath.StartsWith($resolvedArtifactDirectory, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Expected $ReportName report beneath [$resolvedArtifactDirectory], but found [$resolvedPath]."
    }

    foreach ($reportPath in @($resolvedPath, [System.IO.Path]::ChangeExtension($resolvedPath, '.json'))) {
        if (-not (Test-Path -Path $reportPath -PathType Leaf)) {
            throw "Expected $ReportName report at [$reportPath]."
        }
    }

    try {
        $null = [xml](Get-Content -Path $resolvedPath -Raw)
    } catch {
        throw "Expected an XML $ReportName report at [$resolvedPath]."
    }
}

$resolvedWorkingDirectory = [System.IO.Path]::GetFullPath($WorkingDirectory)
$artifactDirectory = Join-Path -Path $resolvedWorkingDirectory -ChildPath '.PSModule'

Assert-ReportPath -Path (Join-Path -Path $resolvedWorkingDirectory -ChildPath $TestResultPath) `
    -ReportName 'test result' `
    -ArtifactDirectory $artifactDirectory
Assert-ReportPath -Path (Join-Path -Path $resolvedWorkingDirectory -ChildPath $CodeCoveragePath) `
    -ReportName 'code coverage' `
    -ArtifactDirectory $artifactDirectory

foreach ($unexpectedDirectory in @('TestResult', 'CodeCoverage', '.temp')) {
    $unexpectedPath = Join-Path -Path $resolvedWorkingDirectory -ChildPath $unexpectedDirectory
    if (Test-Path -Path $unexpectedPath) {
        throw "Did not expect generated action state at [$unexpectedPath]."
    }
}
