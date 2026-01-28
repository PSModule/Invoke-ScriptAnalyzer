<#
    .DESCRIPTION
    Aggregates and validates test results from all Action-Test workflow jobs.
    Compares actual outcomes against expected values and generates a summary report.
#>

[CmdletBinding()]
param()

# Install and import the Markdown module for generating summary tables
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

# Build test job objects with expected vs actual values
$jobs = @(
    @{
        Name       = 'Action-Test - [Src-SourceCode]'
        Outcome    = @{ Actual = $env:SourceCodeOutcome; Expected = 'success' }
        Conclusion = @{ Actual = $env:SourceCodeConclusion; Expected = 'success' }
    }
    @{
        Name       = 'Action-Test - [Src-Custom]'
        Outcome    = @{ Actual = $env:CustomOutcome; Expected = 'success' }
        Conclusion = @{ Actual = $env:CustomConclusion; Expected = 'success' }
    }
    @{
        Name       = 'Action-Test - [Src-WithManifest]'
        Outcome    = @{ Actual = $env:WithManifestOutcome; Expected = 'failure' }
        Conclusion = @{ Actual = $env:WithManifestConclusion; Expected = 'success' }
    }
    @{
        Name       = 'Action-Test - [Src-WithManifest-Default]'
        Outcome    = @{ Actual = $env:WithManifestDefaultOutcome; Expected = 'failure' }
        Conclusion = @{ Actual = $env:WithManifestDefaultConclusion; Expected = 'success' }
    }
    @{
        Name       = 'Action-Test - [outputs]'
        Outcome    = @{ Actual = $env:OutputsOutcome; Expected = 'success' }
        Conclusion = @{ Actual = $env:OutputsConclusion; Expected = 'success' }
    }
)

# Add Pass property to each check and convert to PSCustomObject for table output
$results = $jobs | ForEach-Object {
    [PSCustomObject]@{
        Name               = $_.Name
        Outcome            = $_.Outcome.Actual
        OutcomeExpected    = $_.Outcome.Expected
        OutcomePass        = $_.Outcome.Actual -eq $_.Outcome.Expected
        Conclusion         = $_.Conclusion.Actual
        ConclusionExpected = $_.Conclusion.Expected
        ConclusionPass     = $_.Conclusion.Actual -eq $_.Conclusion.Expected
    }
}

# Display the table in the workflow logs
$results | Format-List | Out-String

$passed = $true
foreach ($job in $results) {
    if (-not $job.OutcomePass) {
        Write-Error "Job $($job.Name) failed with Outcome $($job.Outcome) and Expected Outcome $($job.OutcomeExpected)"
        $passed = $false
    }

    if (-not $job.ConclusionPass) {
        Write-Error "Job $($job.Name) failed with Conclusion $($job.Conclusion) and Expected Conclusion $($job.ConclusionExpected)"
        $passed = $false
    }
}

$icon = if ($passed) { '✅' } else { '❌' }
$status = Heading 1 "$icon - GitHub Actions Status" {
    Table {
        $results
    }
}

Set-GitHubStepSummary -Summary $status

if (-not $passed) {
    Write-GitHubError 'One or more jobs failed'
    exit 1
}
