function wreckPSSociety {
    # This function is a purposeful exercise in breaking every PowerShell best practice.
    # No Verb-Noun naming, no param block, no proper help documentation,
    # inconsistent variable naming, and reliance on Write-Host for output.

    if ($args.Count -lt 2) {
        Write-Host 'Error: Please supply two arguments.' -ForegroundColor Red
        return
    }

    # Inconsistent variable names: one lowercase, one uppercase.
    $firstVal = $args[0]
    $SECONDVAL = $args[1]

    # Arbitrary logic: if both arguments can be cast to integers, add them;
    # otherwise, simply concatenate them as strings.
                                                                                                    if (($firstVal -as [int]) -and ($SECONDVAL -as [int])) {
        Write-Host "Adding numbers, even if it's not best practice..." -ForegroundColor Yellow
        $result = [int]$firstVal + [int]$SECONDVAL } else { Write-Host 'Concatenating values without type checking or clear intent...' -ForegroundColor Yellow
        $result = $firstVal + $SECONDVAL
    }

    Write-Host "Result: $result" -ForegroundColor Blue
}
