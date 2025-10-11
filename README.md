# Invoke-ScriptAnalyzer

This repository contains a GitHub Action that runs [`PSScriptAnalyzer`](https://github.com/PowerShell/PSScriptAnalyzer) on your code.
The action analyzes PowerShell scripts using a hashtable-based settings file to
customize rule selection, severity filtering, and custom rule inclusion.

## Dependencies

- This action.
- [`PSScriptAnalyzer` module](https://github.com/PowerShell/PSScriptAnalyzer).
- [`Invoke-Pester` action](https://github.com/PSModule/Invoke-Pester)
- [`Pester` module](https://github.com/Pester/Pester)
- [`GitHub-Script` action](https://github.com/PSModule/GitHub-Script)
- [`GitHub` module](https://github.com/PSModule/GitHub)

## Inputs

| Input                                | Description                                                                    | Required | Default                                                                     |
|--------------------------------------|--------------------------------------------------------------------------------|----------|-----------------------------------------------------------------------------|
| `Path`                               | The path to the code to test.                                                  | false    | `'.'`                                                                       |
| `SettingsFilePath`                   | The path to the settings file.                                                 | false    | `${{ github.workspace }}/.github/linters/.powershell-psscriptanalyzer.psd1` |
| `Debug`                              | Enable debug output.                                                           | false    | `'false'`                                                                   |
| `Verbose`                            | Enable verbose output.                                                         | false    | `'false'`                                                                   |
| `Version`                            | Specifies the exact version of the GitHub module to install.                   | false    |                                                                             |
| `Prerelease`                         | Allow prerelease versions if available.                                        | false    | `'false'`                                                                   |
| `WorkingDirectory`                   | The working directory where the script runs.                                   | false    | `'.'`                                                                       |
| `ReportAsJson`                       | Output generated reports in JSON format in addition to the configured format.  | false    | `'true'`                                                                    |
| `StepSummary_Enabled`                | Controls if a GitHub step summary should be shown.                             | false    | `'true'`                                                                    |
| `StepSummary_ShowTestOverview`       | Controls whether to show the test overview table in the GitHub step summary.   | false    | `'true'`                                                                    |
| `StepSummary_ShowTests`              | Controls which tests to show in the GitHub step summary (Full/Failed/None).    | false    | `'Failed'`                                                                  |
| `StepSummary_ShowConfiguration`      | Controls whether to show the configuration details in the GitHub step summary. | false    | `'false'`                                                                   |
| `Run_ExcludePath`                    | Directories or files to be excluded from the run.                              | false    |                                                                             |
| `Run_Exit`                           | Exit with non-zero exit code when the test run fails.                          | false    |                                                                             |
| `Run_Throw`                          | Throw an exception when test run fails.                                        | false    |                                                                             |
| `Run_SkipRun`                        | Runs the discovery phase but skips run.                                        | false    |                                                                             |
| `Run_SkipRemainingOnFailure`         | Skips remaining tests after failure (None/Run/Container/Block).                | false    |                                                                             |
| `CodeCoverage_Enabled`               | Enable CodeCoverage.                                                           | false    |                                                                             |
| `CodeCoverage_OutputFormat`          | Format to use for code coverage report (JaCoCo/CoverageGutters/Cobertura).     | false    |                                                                             |
| `CodeCoverage_OutputPath`            | Path relative to the current directory where code coverage report is saved.    | false    |                                                                             |
| `CodeCoverage_OutputEncoding`        | Encoding of the output file.                                                   | false    |                                                                             |
| `CodeCoverage_Path`                  | Directories or files to be used for code coverage.                             | false    |                                                                             |
| `CodeCoverage_ExcludeTests`          | Exclude tests from code coverage.                                              | false    |                                                                             |
| `CodeCoverage_RecursePaths`          | Will recurse through directories in the Path option.                           | false    |                                                                             |
| `CodeCoverage_CoveragePercentTarget` | Target percent of code coverage that you want to achieve.                      | false    |                                                                             |
| `CodeCoverage_UseBreakpoints`        | EXPERIMENTAL: Use Profiler based tracer instead of breakpoints when false.     | false    |                                                                             |
| `CodeCoverage_SingleHitBreakpoints`  | Remove breakpoint when it is hit.                                              | false    |                                                                             |
| `TestResult_Enabled`                 | Enable TestResult.                                                             | false    |                                                                             |
| `TestResult_OutputFormat`            | Format to use for test result report (NUnitXml/NUnit2.5/NUnit3/JUnitXml).      | false    |                                                                             |
| `TestResult_OutputPath`              | Path relative to the current directory where test result report is saved.      | false    |                                                                             |
| `TestResult_OutputEncoding`          | Encoding of the output file.                                                   | false    |                                                                             |
| `TestResult_TestSuiteName`           | Set the name assigned to the root 'test-suite' element.                        | false    | `PSScriptAnalyzer`                                                          |
| `Should_ErrorAction`                 | Controls if Should throws on error. Use 'Stop' or 'Continue'.                  | false    |                                                                             |
| `Debug_ShowFullErrors`               | Show full errors including Pester internal stack.                              | false    |                                                                             |
| `Debug_WriteDebugMessages`           | Write Debug messages to screen.                                                | false    |                                                                             |
| `Debug_WriteDebugMessagesFrom`       | Write Debug messages from a given source.                                      | false    |                                                                             |
| `Debug_ShowNavigationMarkers`        | Write paths after every block and test, for easy navigation.                   | false    |                                                                             |
| `Debug_ReturnRawResultObject`        | Returns unfiltered result object, for development only.                        | false    |                                                                             |
| `Output_Verbosity`                   | The verbosity of output (None/Normal/Detailed/Diagnostic).                     | false    |                                                                             |
| `Output_StackTraceVerbosity`         | The verbosity of stacktrace output (None/FirstLine/Filtered/Full).             | false    |                                                                             |
| `Output_CIFormat`                    | The CI format of error output (None/Auto/AzureDevops/GithubActions).           | false    |                                                                             |
| `Output_CILogLevel`                  | The CI log level in build logs (Error/Warning).                                | false    |                                                                             |
| `Output_RenderMode`                  | The mode used to render console output (Auto/Ansi/ConsoleColor/Plaintext).     | false    |                                                                             |
| `TestDrive_Enabled`                  | Enable TestDrive.                                                              | false    |                                                                             |
| `TestRegistry_Enabled`               | Enable TestRegistry.                                                           | false    |                                                                             |

## Outputs

The action provides the following outputs:

| Output                  | Description                                      |
|-------------------------|--------------------------------------------------|
| `Outcome`               | The outcome of the test run (success/failure)    |
| `Conclusion`            | The conclusion of the test run (success/failure) |
| `Executed`              | Whether tests were executed (True/False)         |
| `Result`                | Overall result of the test run (Passed/Failed)   |
| `FailedCount`           | Number of failed tests                           |
| `FailedBlocksCount`     | Number of failed blocks                          |
| `FailedContainersCount` | Number of failed containers                      |
| `PassedCount`           | Number of passed tests                           |
| `SkippedCount`          | Number of skipped tests                          |
| `InconclusiveCount`     | Number of inconclusive tests                     |
| `NotRunCount`           | Number of tests not run                          |
| `TotalCount`            | Total count of tests                             |

## How It Works

1. **Set a Path**
   Choose a path for your code to test into the `Path` input. This can be a
   directory or a file.

2. **Configure settings file**
   Create a custom settings file to customize the analysis. The settings file is
   a hashtable that defines the rules to include, exclude, or customize. The
   settings file is in the format of a `.psd1` file.

   By default, the action looks for a settings file at:
   `.github/linters/.powershell-psscriptanalyzer.psd1`

   You can override this by setting the `SettingsFilePath` input to point to your
   custom settings file.

   For more info on how to create a settings file, see the [Settings Documentation](./Settings.md) file.

3. **Run the Action**
   The tests import the settings file and use `Invoke-ScriptAnalyzer` to analyze
   the code. Each rule is evaluated, and if a rule violation is found, the test
   will fail for that rule. Rules that are marked to be skipped (via exclusions
   in the settings file) are automatically skipped in the test.

   To be clear; the action follows the settings file to determine which rules to skip.

4. **View the Results**
    The action outputs the results of the tests to goth logs and step summary. If the tests pass, the actions `outcome` will be `success`.
    If the tests fail, the actions outcome will be `failure`. To make the workflow continue even if the tests fail, you can set the
    `continue-on-error` option to `true`. Use this built-in feature to stop the workflow from failing so that you can aggregate the status of tests
    across multiple jobs.

    An example of how this is done can be seen in the [Action-Test workflow](.github/workflows/Action-Test.yml) file.

## Example Workflow

Below is an example workflow configuration using this action:

```yaml
name: Analyze PowerShell Code

on: [push, pull_request]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v2

      - name: Invoke PSScriptAnalyzer
        uses: PSModule/Invoke-ScriptAnalyzer@v2
        with:
          Path: src
          SettingsFilePath: .github/linters/.powershell-psscriptanalyzer.psd1
```

## References and Links

- [PSScriptAnalyzer Documentation](https://learn.microsoft.com/powershell/module/psscriptanalyzer/)
- [PSScriptAnalyzer Module Overview](https://learn.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/overview?view=ps-modules)
- [PSScriptAnalyzer Rules](https://learn.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/rules/readme?view=ps-modules)
- [PSScriptAnalyzer GitHub Repository](https://github.com/PowerShell/PSScriptAnalyzer)
- [Custom Rules in PSScriptAnalyzer](https://docs.microsoft.com/powershell/scripting/developer/hosting/psscriptanalyzer-extensibility)
- [GitHub Super-Linter](https://github.com/github/super-linter)
