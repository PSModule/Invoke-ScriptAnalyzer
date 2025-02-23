Install-PSResource -Name Markdown -Repository PSGallery -TrustRepository

# Build an array of objects for each job
$ActionTestSrcSourceCodeExpectedOutcome = 'success'
$ActionTestSrcSourceCodeOutcomeResult = $env:ActionTestSrcSourceCodeOutcome -eq $ActionTestSrcSourceCodeExpectedOutcome
$ActionTestSrcSourceCodeExpectedConclusion = 'success'
$ActionTestSrcSourceCodeConclusionResult = $env:ActionTestSrcSourceCodeConclusion -eq $ActionTestSrcSourceCodeExpectedConclusion

$ActionTestSrcCustomExpectedOutcome = 'success'
$ActionTestSrcCustomOutcomeResult = $env:ActionTestSrcCustomOutcome -eq $ActionTestSrcCustomExpectedOutcome
$ActionTestSrcCustomExpectedConclusion = 'success'
$ActionTestSrcCustomConclusionResult = $env:ActionTestSrcCustomConclusion -eq $ActionTestSrcCustomExpectedConclusion

$ActionTestSrcWithManifestExpectedOutcome = 'failure'
$ActionTestSrcWithManifestOutcomeResult = $env:ActionTestSrcWithManifestOutcome -eq $ActionTestSrcWithManifestExpectedOutcome
$ActionTestSrcWithManifestExpectedConclusion = 'success'
$ActionTestSrcWithManifestConclusionResult = $env:ActionTestSrcWithManifestConclusion -eq $ActionTestSrcWithManifestExpectedConclusion

$ActionTestOutputsExpectedOutcome = 'success'
$ActionTestOutputsOutcomeResult = $env:ActionTestOutputsOutcome -eq $ActionTestOutputsExpectedOutcome
$ActionTestOutputsExpectedConclusion = 'success'
$ActionTestOutputsConclusionResult = $env:ActionTestOutputsConclusion -eq $ActionTestOutputsExpectedConclusion

$jobs = @(
    [PSCustomObject]@{
        Name               = 'Action-Test - [Src-SourceCode]'
        Outcome            = $env:ActionTestSrcSourceCodeOutcome
        ExpectedOutcome    = $ActionTestSrcSourceCodeExpectedOutcome
        PassedOutcome      = $ActionTestSrcSourceCodeOutcomeResult
        Conclusion         = $env:ActionTestSrcSourceCodeConclusion
        ExpectedConclusion = $ActionTestSrcSourceCodeExpectedConclusion
        PassedConclusion   = $ActionTestSrcSourceCodeConclusionResult
    },
    [PSCustomObject]@{
        Name               = 'Action-Test - [Src-Custom]'
        Outcome            = $env:ActionTestSrcCustomOutcome
        ExpectedOutcome    = $ActionTestSrcCustomExpectedOutcome
        PassedOutcome      = $ActionTestSrcCustomOutcomeResult
        Conclusion         = $env:ActionTestSrcCustomConclusion
        ExpectedConclusion = $ActionTestSrcCustomExpectedConclusion
        PassedConclusion   = $ActionTestSrcCustomConclusionResult
    },
    [PSCustomObject]@{
        Name               = 'Action-Test - [Src-WithManifest]'
        Outcome            = $env:ActionTestSrcWithManifestOutcome
        ExpectedOutcome    = $ActionTestSrcWithManifestExpectedOutcome
        PassedOutcome      = $ActionTestSrcWithManifestOutcomeResult
        Conclusion         = $env:ActionTestSrcWithManifestConclusion
        ExpectedConclusion = $ActionTestSrcWithManifestExpectedConclusion
        PassedConclusion   = $ActionTestSrcWithManifestConclusionResult
    },
    [PSCustomObject]@{
        Name               = 'Action-Test - [outputs]'
        Outcome            = $env:ActionTestOutputsOutcome
        ExpectedOutcome    = $ActionTestOutputsExpectedOutcome
        PassedOutcome      = $ActionTestOutputsOutcomeResult
        Conclusion         = $env:ActionTestOutputsConclusion
        ExpectedConclusion = $ActionTestOutputsExpectedConclusion
        PassedConclusion   = $ActionTestOutputsConclusionResult
    }
)

# Display the table in the workflow logs
$jobs | Format-List

$passed = $true
$jobs | ForEach-Object {
    if (-not $_.PassedOutcome) {
        Write-Error "Job $($_.Name) failed with Outcome $($_.Outcome) and Expected Outcome $($_.ExpectedOutcome)"
        $passed = $false
    }

    if (-not $_.PassedConclusion) {
        Write-Error "Job $($_.Name) failed with Conclusion $($_.Conclusion) and Expected Conclusion $($_.ExpectedConclusion)"
        $passed = $false
    }
}

$icon = if ($passed) { '✅' } else { '❌' }
$status = Heading 1 "$icon - GitHub Actions Status" {
    Table {
        $jobs
    }
}

Set-GitHubStepSummary -Summary $status

if (-not $passed) {
    Write-GitHubError 'One or more jobs failed'
    exit 1
}
