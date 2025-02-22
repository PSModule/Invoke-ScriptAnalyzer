# PSScriptAnalyzer Settings File Format Documentation

This document describes the format and usage of the hashtable-based settings file
for PSScriptAnalyzer. The file is used by the GitHub action to customize analysis.

## Basic Setup

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
  Filters output by severity. Allowed values include `Error`, `Warning`, and `Information`.

- **IncludeDefaultRules**
  A Boolean switch to include default rules when using custom rules.

- **CustomRulePath**
  One or more paths to custom rule modules or scripts. These extend PSScriptAnalyzer.

- **RecurseCustomRulePath**
  Boolean to search subdirectories of the custom rule path(s) for more rule files.

- **Rules**
  A nested hashtable for rule-specific settings. Use it to pass parameters to rules.

```powershell
Rules = @{
    PSAvoidUsingCmdletAliases = @{
        Enabled   = $true
        Whitelist = @('ls','gc')
    }
}
```

## Configuring Custom Rules

Custom rules are implemented in modules (.psm1) or scripts. They must export
functions that return DiagnosticRecord objects. Specify their location using
`CustomRulePath`. Use `IncludeDefaultRules = $true` if you want to run both
default and custom rules.

For example:
```powershell
@{
    CustomRulePath      = @('.\Modules\MyCustomRules.psm1')
    IncludeDefaultRules = $true
    IncludeRules        = @('PSUseApprovedVerbs', 'Measure-*')
}
```

## Rule Execution and Skip Logic

The action evaluates each rule using several configurable settings to determine whether it should be executed or skipped.
The evaluation is performed in the following order:

1. **Exclude Rules**
   - If the rule's name is present in the **`ExcludeRules`** list, the rule is skipped immediately, regardless of other settings.

2. **Include Rules**
   - If an **`IncludeRules`** list is provided, the rule must be part of this list. If the rule's name is *not* in the list, it is skipped.

3. **Severity Filtering**
   - If a **`Severity`** list is specified, the rule's severity must be included in that list. If the rule's severity is not part of the allowed
     values, the rule is skipped.

4. **Rule-Specific Configuration**
   - If a specific configuration exists for the rule under the **Rules** key, and its `Enable` property is set to false, the rule is skipped.

To see what rules are skipped and why, check the logs for the action. There is a log group inside the test that contains the rules that were skipped.
