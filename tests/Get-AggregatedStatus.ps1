'Markdown' | ForEach-Object {
    $name = $_
    Write-Output "Installing module: $name"
    $retryCount = 5
    $retryDelay = 10
    for ($i = 0; $i -lt $retryCount; $i++) {
        try {
            Install-PSResource -Name $name -WarningAction SilentlyContinue -TrustRepository -Repository PSGallery
            break
        } catch {
            Write-Warning "Installation of $name failed with error: $_"
            if ($i -eq $retryCount - 1) {
                throw
            }
            Write-Warning "Retrying in $retryDelay seconds..."
            Start-Sleep -Seconds $retryDelay
        }
    }
    Import-Module -Name $name
}

# Build an array of objects for each job
$SourceCodeExpectedOutcome = 'success'
$SourceCodeOutcomeResult = $env:SourceCodeOutcome -eq $SourceCodeExpectedOutcome
$SourceCodeExpectedConclusion = 'success'
$SourceCodeConclusionResult = $env:SourceCodeConclusion -eq $SourceCodeExpectedConclusion

$CustomExpectedOutcome = 'success'
$CustomOutcomeResult = $env:CustomOutcome -eq $CustomExpectedOutcome
$CustomExpectedConclusion = 'success'
$CustomConclusionResult = $env:CustomConclusion -eq $CustomExpectedConclusion

$WithManifestExpectedOutcome = 'failure'
$WithManifestOutcomeResult = $env:WithManifestOutcome -eq $WithManifestExpectedOutcome
$WithManifestExpectedConclusion = 'success'
$WithManifestConclusionResult = $env:WithManifestConclusion -eq $WithManifestExpectedConclusion

$WithManifestDefaultExpectedOutcome = 'failure'
$WithManifestDefaultOutcomeResult = $env:WithManifestDefaultOutcome -eq $WithManifestDefaultExpectedOutcome
$WithManifestDefaultExpectedConclusion = 'success'
$WithManifestDefaultConclusionResult = $env:WithManifestDefaultConclusion -eq $WithManifestDefaultExpectedConclusion

$OutputsExpectedOutcome = 'success'
$OutputsOutcomeResult = $env:OutputsOutcome -eq $OutputsExpectedOutcome
$OutputsExpectedConclusion = 'success'
$OutputsConclusionResult = $env:OutputsConclusion -eq $OutputsExpectedConclusion

$jobs = @(
    [PSCustomObject]@{
        Name               = 'Action-Test - [Src-SourceCode]'
        Outcome            = $env:SourceCodeOutcome
        ExpectedOutcome    = $SourceCodeExpectedOutcome
        PassedOutcome      = $SourceCodeOutcomeResult
        Conclusion         = $env:SourceCodeConclusion
        ExpectedConclusion = $SourceCodeExpectedConclusion
        PassedConclusion   = $SourceCodeConclusionResult
    },
    [PSCustomObject]@{
        Name               = 'Action-Test - [Src-Custom]'
        Outcome            = $env:CustomOutcome
        ExpectedOutcome    = $CustomExpectedOutcome
        PassedOutcome      = $CustomOutcomeResult
        Conclusion         = $env:CustomConclusion
        ExpectedConclusion = $CustomExpectedConclusion
        PassedConclusion   = $CustomConclusionResult
    },
    [PSCustomObject]@{
        Name               = 'Action-Test - [Src-WithManifest]'
        Outcome            = $env:WithManifestOutcome
        ExpectedOutcome    = $WithManifestExpectedOutcome
        PassedOutcome      = $WithManifestOutcomeResult
        Conclusion         = $env:WithManifestConclusion
        ExpectedConclusion = $WithManifestExpectedConclusion
        PassedConclusion   = $WithManifestConclusionResult
    },
    [PSCustomObject]@{
        Name               = 'Action-Test - [Src-WithManifest-Default]'
        Outcome            = $env:WithManifestDefaultOutcome
        ExpectedOutcome    = $WithManifestDefaultExpectedOutcome
        PassedOutcome      = $WithManifestDefaultOutcomeResult
        Conclusion         = $env:WithManifestDefaultConclusion
        ExpectedConclusion = $WithManifestDefaultExpectedConclusion
        PassedConclusion   = $WithManifestDefaultConclusionResult
    },
    [PSCustomObject]@{
        Name               = 'Action-Test - [outputs]'
        Outcome            = $env:OutputsOutcome
        ExpectedOutcome    = $OutputsExpectedOutcome
        PassedOutcome      = $OutputsOutcomeResult
        Conclusion         = $env:OutputsConclusion
        ExpectedConclusion = $OutputsExpectedConclusion
        PassedConclusion   = $OutputsConclusionResult
    }
)

# Display the table in the workflow logs
$jobs | Format-List

$passed = $true
$jobs | ForEach-Object {
    if (-not $_.PassedOutcome) {
        Write-Warning "Job $($_.Name) failed with Outcome $($_.Outcome) and Expected Outcome $($_.ExpectedOutcome)"
        $passed = $false
        Write-Warning "Passed: $passed"
    }

    if (-not $_.PassedConclusion) {
        Write-Warning "Job $($_.Name) failed with Conclusion $($_.Conclusion) and Expected Conclusion $($_.ExpectedConclusion)"
        $passed = $false
        Write-Warning "Passed: $passed"
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
