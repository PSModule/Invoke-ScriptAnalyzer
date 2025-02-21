# Invoke-ScriptAnalyzer (by PSModule)

This repository contains a GitHub Action that runs PSScriptAnalyzer on your code.
The action analyzes PowerShell scripts using a hashtable-based settings file to
customize rule selection, severity filtering, and custom rule inclusion.

> **Note:** This repository includes automated tests that run via Pester to ensure
> your settings file is working as expected.

## Action Details

- **Name:** Invoke-ScriptAnalyzer (by PSModule)
- **Description:** Runs PSScriptAnalyzer on the code.
- **Author:** PSModule
- **Branding:**
  Icon: `check-square`
  Color: `gray-dark`

## Inputs

| Input               | Description                                                       | Required | Default                                                                     |
|---------------------|-------------------------------------------------------------------|----------|-----------------------------------------------------------------------------|
| **Path**            | The path to the code to test.                                     | Yes      | `${{ github.workspace }}`                                                   |
| **Settings**        | The type of tests to run: `Module`, `SourceCode`, or `Custom`.    | No       | `Custom`                                                                    |
| **SettingsFilePath**| If `Custom` is selected, the path to the settings file.           | No       | `${{ github.workspace }}/.github/linters/.powershell-psscriptanalyzer.psd1` |

## Outputs

| Output  | Description                           | Value                                      |
|---------|---------------------------------------|--------------------------------------------|
| passed  | Indicates if the tests passed.      | `${{ steps.test.outputs.Passed }}`         |

## Files Overview

- **action.yml**
  Describes the action inputs, outputs, and run steps. The action uses a
  composite run steps approach with two main steps:
  1. **Get test paths:** Uses a script to resolve paths and settings.
  2. **Invoke-Pester:** Runs Pester tests against PSScriptAnalyzer.

- **scripts/main.ps1**
  Determines the correct settings file path based on the test type. It
  supports testing a module, source code, or using a custom settings file.

- **scripts/tests/PSScriptAnalyzer/**
  Contains Pester tests that run PSScriptAnalyzer using the provided settings
  file. The tests check for issues reported by PSScriptAnalyzer based on rule
  configuration.

## How It Works

1. **Path Resolution:**
   The action reads inputs and determines the code path, test path, and the
   settings file path. For custom settings, it uses the file at:
   ```
   .github/linters/.powershell-psscriptanalyzer.psd1
   ```
   Otherwise, it uses a default settings file from the test folder.

2. **Pester Testing:**
   The tests import the settings file and use `Invoke-ScriptAnalyzer` to scan
   the code. Each rule is evaluated, and if a rule violation is found, the test
   will fail for that rule. Rules that are marked to be skipped (via exclusions
   in the settings file) are automatically skipped in the test.

3. **Automation:**
   Designed for CI/CD, this action integrates with GitHub Actions, Azure Pipelines,
   and other systems. The settings file customizes analysis, letting you control
   rule inclusion, severity filtering, and custom rule paths.

## Example Workflow

Below is an example workflow configuration using this action:

```yaml
name: Analyze PowerShell Code

on: [push, pull_request]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Invoke PSScriptAnalyzer
        uses: PSModule/Invoke-ScriptAnalyzer@v1
        with:
          Path: ${{ github.workspace }}
          Settings: Custom
          SettingsFilePath: ${{ github.workspace }}/.github/linters/.powershell-psscriptanalyzer.psd1
```

## Appendix: Settings File Documentation

For detailed documentation on the format of the settings file, see the
[Settings File Documentation](./SettingsFileDocumentation.md) file.

## References and Links

- [PSScriptAnalyzer Documentation](https://learn.microsoft.com/powershell/module/psscriptanalyzer/)
- [GitHub Super-Linter](https://github.com/github/super-linter)
- [PSScriptAnalyzer GitHub Repository](https://github.com/PowerShell/PSScriptAnalyzer)
- [Custom Rules in PSScriptAnalyzer](https://docs.microsoft.com/powershell/scripting/developer/hosting/psscriptanalyzer-extensibility)
