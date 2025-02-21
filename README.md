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

| Input               | Description                                                    | Required | Default                                                                     |
|---------------------|----------------------------------------------------------------|----------|-----------------------------------------------------------------------------|
| **Path**            | The path to the code to test.                                  | Yes      | `${{ github.workspace }}`                                                   |
| **Settings**        | The type of tests to run: `Module`, `SourceCode`, or `Custom`. | No       | `Custom`                                                                    |
| **SettingsFilePath**| If `Custom` is selected, the path to the settings file.        | No       | `${{ github.workspace }}/.github/linters/.powershell-psscriptanalyzer.psd1` |

## Outputs

| Output   | Description                    | Value                              |
|----------|--------------------------------|------------------------------------|
| `passed` | Indicates if the tests passed. | `${{ steps.test.outputs.Passed }}` |

## How It Works

1. **Set a Path**
   Choose a path for your code to test into the `Path` input. This can be a
   directory or a file.

2. **Choose settings**
   Choose the type of tests to run by setting the `Settings` input. The options
   are `Module`, `SourceCode`, or `Custom`. The default is `Custom`.

   The predefined settings:
    - [`Module`](./scripts/tests/PSScriptAnalyzer/Module.Settings.psd1): Analyzes a module following PSModule standards.
    - [`SourceCode`](./scripts/tests/PSScriptAnalyzer/SourceCode.Settings.psd1): Analyzes the source code following PSModule standards.

    You can also create a custom settings file to customize the analysis. The
    settings file is a hashtable that defines the rules to include, exclude, or
    customize. The settings file is in the format of a `.psd1` file.

    For more info on how to create a settings file, see the [Settings Documentation](./Settings.md) file.

3. **Run the Action**
   The tests import the settings file and use `Invoke-ScriptAnalyzer` to analyze
   the code. Each rule is evaluated, and if a rule violation is found, the test
   will fail for that rule. Rules that are marked to be skipped (via exclusions
   in the settings file) are automatically skipped in the test.

   To be clear; the action follows the settings file to determine which rules to skip.

4. **View the Results**
    The action outputs the results of the tests. If the tests pass, the action
    will return a `passed` output with a value of `true`. If the tests fail, the
    action will return a `passed` output with a value of `false`.

    The action also outputs the results of the tests to the console.

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
        uses: PSModule/Invoke-ScriptAnalyzer@v1
        with:
          Path: ${{ github.workspace }}
          Settings: SourceCode
```

## References and Links

- [PSScriptAnalyzer Documentation](https://learn.microsoft.com/powershell/module/psscriptanalyzer/)
- [PSScriptAnalyzer Module Overview](https://learn.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/overview?view=ps-modules)
- [PSScriptAnalyzer Rules](https://learn.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/rules/readme?view=ps-modules)
- [PSScriptAnalyzer GitHub Repository](https://github.com/PowerShell/PSScriptAnalyzer)
- [Custom Rules in PSScriptAnalyzer](https://docs.microsoft.com/powershell/scripting/developer/hosting/psscriptanalyzer-extensibility)
- [GitHub Super-Linter](https://github.com/github/super-linter)
