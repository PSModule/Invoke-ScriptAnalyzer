# PSScriptAnalyzer Settings File Format Documentation

This document describes the format and usage of the hashtable-based settings file
for PSScriptAnalyzer. The file is used by the GitHub action to customize analysis.

## File Location and Basic Setup

Place the file at:
```
.github/linters/.powershell-psscriptanalyzer.psd1
```
The file is a PowerShell data file (.psd1) that returns a hashtable. For example:
```powershell
@{
    Severity     = @('Error','Warning')
    ExcludeRules = @('PSAvoidUsingWriteHost')
}
```
This example sets the severity filter and excludes a specific rule.

## Key Configuration Options

- **IncludeRules**
  A list of rules to run. Wildcards (e.g. `PSAvoid*`) are supported.

- **ExcludeRules**
  A list of rules to skip. Excludes take precedence over include lists.

- **Severity**
  Filters output by severity. Allowed values include `Error`, `Warning`, and
  `Information`.

- **IncludeDefaultRules**
  A Boolean switch to include default rules when using custom rules.

- **CustomRulePath**
  One or more paths to custom rule modules or scripts. These extend PSScriptAnalyzer.

- **RecurseCustomRulePath**
  Boolean to search subdirectories of the custom rule path(s) for more rule files.

- **Rules**
  A nested hashtable for rule-specific settings. Use it to pass parameters to rules.
  For example:
  ```powershell
  Rules = @{
      PSAvoidUsingCmdletAliases = @{ Whitelist = @('ls','gc') }
  }
  ```

## Configuring Custom Rules

Custom rules are implemented in modules (.psm1) or scripts. They must export
functions that return DiagnosticRecord objects. Specify their location using
**CustomRulePath**. Use **IncludeDefaultRules = $true** if you want to run both
default and custom rules.

For example:
```powershell
@{
    CustomRulePath      = @('.\Modules\MyCustomRules.psm1')
    IncludeDefaultRules = $true
    IncludeRules        = @('PSUseApprovedVerbs', 'Measure-*')
}
```

## Advanced Use Cases

- **Selective Rule Execution**
  Use either **IncludeRules** or **ExcludeRules** to control which rules run.
  They help reduce noise in the analysis output.

- **Rule-Specific Parameters**
  Configure individual rules via the **Rules** key. Pass any required
  parameters to fine-tune rule behavior.

- **Multiple Settings Files**
  In a multi-project repo, use separate settings files for each project and
  run PSScriptAnalyzer with the appropriate file.

- **Dynamic Settings**
  Although not recommended, you can include minimal logic in the .psd1 file.
  For example, using environment variables to adjust settings dynamically.

## Automation and CI/CD Integration

This settings file is designed to be used with automated pipelines.

- **GitHub Actions**
  The Super-Linter action automatically picks up the file from the above path.
  Alternatively, use a dedicated PSScriptAnalyzer action with the settings input.

- **Azure Pipelines**
  Run a PowerShell task that installs PSScriptAnalyzer and points to the settings file.
  Exit codes can be used to fail the build on errors.

- **Other CI Tools**
  Any CI system can invoke `Invoke-ScriptAnalyzer` with the `-Settings` parameter
  to use this configuration.

## Best Practices

- **Version Control**: Store the settings file in your repository to keep configuration
  consistent across environments.
- **Minimal Exclusions**: Exclude only rules that are not applicable to your project.
- **Documentation**: Use comments in the settings file to explain why certain rules are
  included or excluded.
- **Regular Updates**: Update your settings when you upgrade PSScriptAnalyzer or change your
  project requirements.

## Links and References

- [PSScriptAnalyzer Documentation](https://learn.microsoft.com/powershell/module/psscriptanalyzer/)
- [GitHub Super-Linter](https://github.com/github/super-linter)
- [PSScriptAnalyzer GitHub Repository](https://github.com/PowerShell/PSScriptAnalyzer)
- [Custom Rules in PSScriptAnalyzer](https://docs.microsoft.com/powershell/scripting/developer/hosting/psscriptanalyzer-extensibility)
