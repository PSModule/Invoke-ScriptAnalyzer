# Using a Hashtable-Based Settings File for PSScriptAnalyzer in PowerShell 7

## Introduction

**PSScriptAnalyzer** is a static code checker for PowerShell modules and scripts. It evaluates your code against a set of built-in rules based on PowerShell best practices identified by the PowerShell team and community ([PSScriptAnalyzer/README.md at main · PowerShell/PSScriptAnalyzer · GitHub](https://github.com/PowerShell/PSScriptAnalyzer/blob/master/README.md#:~:text=PSScriptAnalyzer%20is%20a%20static%20code,suggests%20possible%20solutions%20for%20improvements)). When run (for example, via the `Invoke-ScriptAnalyzer` cmdlet), it produces diagnostics (errors, warnings, or informational messages) to highlight potential issues and suggest improvements. This helps maintain code quality by catching common mistakes, stylistic issues, or potential bugs early in the development process.

Using a **settings file** for PSScriptAnalyzer allows you to customize which rules are applied and how they're reported, without having to specify numerous parameters on each run. In effect, a settings file acts as a profile or configuration that PSScriptAnalyzer will follow, much like *splatting* parameters in a single hashtable ([Invoke-ScriptAnalyzer (PSScriptAnalyzer) - PowerShell | Microsoft Learn](https://learn.microsoft.com/en-us/powershell/module/psscriptanalyzer/invoke-scriptanalyzer?view=ps-modules#:~:text=The%20keys%20and%20values%20in,For%20more%20information%2C%20see%20about_Splatting)). This approach is beneficial for several reasons:

- **Consistency**: By sharing a common settings file across your project or team, you ensure that everyone’s code is analyzed with the same rules and standards. This avoids “it works on my machine” discrepancies in linting results.
- **Customization**: Not all projects are the same. A settings file allows you to **include or exclude specific rules** and even filter by severity levels to tailor the analysis to your project's needs ([Using PSScriptAnalyzer - PowerShell | Microsoft Learn](https://learn.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/using-scriptanalyzer?view=ps-modules#:~:text=The%20following%20example%20excludes%20two,other%20than%20Error%20and%20Warning)). For instance, you might choose to treat only errors and warnings as relevant, ignoring info-level suggestions in certain CI scenarios.
- **Maintainability**: It's easier to update one configuration file than to modify multiple build or script invocations. If you decide to enable a new rule or adjust severities, you can do it in one place. The settings file “does everything the different parameters on `Invoke-ScriptAnalyzer` [would do]” ([Creating custom PSScriptAnalyzer rules](https://blog.ironmansoftware.com/psscriptanalyzer-custom-rules/#:~:text=In%20order%20to%20customize%20,ScriptAnalyzer)), so it centralizes your static analysis configuration.
- **Integration**: Many tools (like VS Code, CI/CD pipelines, and GitHub actions) can automatically pick up your PSScriptAnalyzer settings file. This implicit usage means you often just drop the file in the right location and your rules preferences will be applied without extra scripting ([Using PSScriptAnalyzer - PowerShell | Microsoft Learn](https://learn.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/using-scriptanalyzer?view=ps-modules#:~:text=Implicit)).

In summary, a hashtable-based settings file gives you fine-grained control over PSScriptAnalyzer’s behavior. In the latest PowerShell (Core 7+) environment, PSScriptAnalyzer fully supports such configuration files, making it easier to enforce coding standards and best practices consistently across various contexts.

## Basic Setup

This section guides you through creating a PSScriptAnalyzer settings file (which is a PowerShell **.psd1 data file**) and getting it ready for use. We will assume a common scenario of using a GitHub repository, with the settings file stored at `.github/linters/.powershell-psscriptanalyzer.psd1` (a location conventionally used by some CI linters), but you can adapt the location to your needs. The file itself can be named anything, but by default PSScriptAnalyzer looks for **`PSScriptAnalyzerSettings.psd1`** if no explicit path is provided ([Using PSScriptAnalyzer - PowerShell | Microsoft Learn](https://learn.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/using-scriptanalyzer?view=ps-modules#:~:text=Implicit)).

**Steps to create the settings file:**

1. **Choose a Location:** Decide where to place the settings file. For automatic discovery, the recommended name is `PSScriptAnalyzerSettings.psd1` in the root of your project (so that if you run PSScriptAnalyzer on the project folder, it finds the file) ([Using PSScriptAnalyzer - PowerShell | Microsoft Learn](https://learn.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/using-scriptanalyzer?view=ps-modules#:~:text=Implicit)). If you are using GitHub's Super-Linter Action or similar, the convention is to put the file under a `.github/linters/` directory with a language-specific name. For example, GitHub Super-Linter will look for a PowerShell analyzer config at `.github/linters/.powershell-psscriptanalyzer.psd1` by default ([
        PowerShell Gallery
        | .github/linters/.powershell-psscriptanalyzer.psd1 0.0.2-Preview
    ](https://www.powershellgallery.com/packages/SecretManagement.Hashicorp.Vault.KV/0.0.2-Preview/Content/.github%5Clinters%5C.powershell-psscriptanalyzer.psd1#:~:text=Documentation%3A%20https%3A%2F%2Fgithub.com%2FPowerShell%2FPSScriptAnalyzer%2Fblob%2Fmaster%2Fdocs%2Fmarkdown%2FInvoke,RecurseCustomRulePath%3D%27path%5Cof%5Ccustomrules%27%20Severity%C2%A0%C2%A0%C2%A0%C2%A0%C2%A0%C2%A0%C2%A0%C2%A0%C2%A0%C2%A0%C2%A0%C2%A0%3D)). Create the directories if they don't exist:
   ```bash
   mkdir -p .github/linters
   ```
   Then create an empty file named `.powershell-psscriptanalyzer.psd1` in that folder.

2. **File Structure:** Open the file in a text editor. A PSScriptAnalyzer settings file is essentially a PowerShell hashtable literal enclosed in `@{ ... }`. Start with an empty hashtable:
   ```powershell
   @{}
   ```
   This empty config would mean "use all default rules with default severities." It’s a valid starting point, but typically you will add keys and values to customize the analysis. Each key in this hashtable corresponds to a PSScriptAnalyzer parameter or setting (like which rules to include/exclude). We will cover these keys in the next sections.

3. **Add Basic Configuration:** As a quick test, you might add a simple setting. For example, to only show errors (and hide warnings/information messages), you could set the **Severity** filter in the file:
   ```powershell
   @{
       Severity = @('Error')
   }
   ```
   This is a minimal configuration that tells PSScriptAnalyzer to report only rule violations of severity "Error" ([Where do I place the PSScriptAnalyzerSettings.psd1 file so the settings will be applied for all user accounts? : r/PowerShell](https://www.reddit.com/r/PowerShell/comments/lt5w8q/where_do_i_place_the_psscriptanalyzersettingspsd1/#:~:text=%40%7B%20,Error%27%29)). For now, you can save the file with just this content or another simple tweak. We will expand on the various settings in subsequent sections.

4. **Using the Settings File:** To verify that your settings file is recognized, run PSScriptAnalyzer with it. From a PowerShell prompt at the root of your project, execute:
   ```powershell
   Invoke-ScriptAnalyzer -Path . -Recurse -Settings .\.github\linters\.powershell-psscriptanalyzer.psd1
   ```
   Replace the `-Path` with the path to your scripts (here we use `.` for current directory, and `-Recurse` to analyze all subfolders). The `-Settings` parameter points to the file we created. PSScriptAnalyzer will load the hashtable from that file and apply those settings for the analysis run. You should see that the output now reflects your configuration (e.g., only errors if you set `Severity='Error'` earlier). If you placed a file named `PSScriptAnalyzerSettings.psd1` at the root of the path you're analyzing, you could even omit the `-Settings` parameter and PSScriptAnalyzer would **implicitly** find it ([Using PSScriptAnalyzer - PowerShell | Microsoft Learn](https://learn.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/using-scriptanalyzer?view=ps-modules#:~:text=Implicit)).

5. **Commit the File (if applicable):** If this is for a repository (especially with CI integration), be sure to add and commit the new `.psd1` file to version control. This allows the settings to travel with the code, so that other developers and automated pipelines use the same analyzer configuration.

At this point, you have a basic settings file set up. Next, we'll dive into how to configure specific rules and options within that file to fine-tune the analyzer to your needs.

## Configuring Rules

The power of a PSScriptAnalyzer settings file comes from the ability to **enable or disable specific rules** and **adjust filtering options like severity** in one place. The settings file uses certain predefined keys (entries in the hashtable) that PSScriptAnalyzer recognizes. These keys correspond to parameters you might otherwise pass to `Invoke-ScriptAnalyzer`. The most commonly used keys include:

- **`IncludeRules`** – A list of rule names to **include** (run) during analysis ([Using PSScriptAnalyzer - PowerShell | Microsoft Learn](https://learn.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/using-scriptanalyzer?view=ps-modules#:~:text=,)). Only rules in this list will be executed (all others will be skipped). Wildcards are supported (e.g., `'PSAvoid*'` to include all rules starting with "PSAvoid").
- **`ExcludeRules`** – A list of rule names to **exclude** from analysis ([Using PSScriptAnalyzer - PowerShell | Microsoft Learn](https://learn.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/using-scriptanalyzer?view=ps-modules#:~:text=,)). All rules except those listed will run. Use this when you want most rules enabled, but need to turn off a few that aren't relevant or cause noise. Wildcards can be used here as well.
- **`Severity`** – A list of severity levels to report. By default, PSScriptAnalyzer rules can output findings of severity **Error**, **Warning**, or **Information**. Using this setting filters out findings that are not in the list. For example, `Severity = @('Error','Warning')` means informational messages will be omitted from results ([Using PSScriptAnalyzer - PowerShell | Microsoft Learn](https://learn.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/using-scriptanalyzer?view=ps-modules#:~:text=Severity%3D%40%28%27Error%27%2C%27Warning%27%29%20ExcludeRules%3D%40%28%27PSAvoidUsingCmdletAliases%27%2C%20%27PSAvoidUsingWriteHost%27%29%20)). This does **not** change the inherent severity of rules; it just acts as a post-analysis filter for what gets reported ([Using PSScriptAnalyzer - PowerShell | Microsoft Learn](https://learn.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/using-scriptanalyzer?view=ps-modules#:~:text=The%20following%20example%20excludes%20two,other%20than%20Error%20and%20Warning)). (Note: Currently, you cannot directly change a rule's designated severity via the settings file – you can only filter what severities to see.)
- **`IncludeDefaultRules`** – A Boolean switch ( `$true` / `$false` ) that determines whether the built-in default rules should be included. This is typically used in combination with custom rules (discussed later). For instance, if you are using custom rules and want to **also** run the normal PSScriptAnalyzer rules, set `IncludeDefaultRules = $true` ([
        PowerShell Gallery
        | .github/linters/.powershell-psscriptanalyzer.psd1 0.0.2-Preview
    ](https://www.powershellgallery.com/packages/SecretManagement.Hashicorp.Vault.KV/0.0.2-Preview/Content/.github%5Clinters%5C.powershell-psscriptanalyzer.psd1#:~:text=Severity%C2%A0%C2%A0%C2%A0%C2%A0%C2%A0%C2%A0%C2%A0%C2%A0%C2%A0%C2%A0%C2%A0%C2%A0%3D%C2%A0%40%28%20%27Error%27%20%27Warning%27%20%29%20IncludeDefaultRules%C2%A0%3D%C2%A0%24,%27PSUseShouldProcessForStateChangingFunctions%27%2C%20%27PSAvoidUsingConvertToSecureStringWithPlainText)). If false (or not set, which defaults to false when custom rules are specified), you might be running only a custom rule set. In normal use (without custom rules), you don't need to set this – by default all built-in rules run unless you exclude or limit them.
- **`CustomRulePath`** – One or more filesystem paths to custom rule scripts or modules. Custom rules allow you to extend PSScriptAnalyzer with your own rules; by specifying their path here, PSSA will load and include them in analysis ([Using PSScriptAnalyzer - PowerShell | Microsoft Learn](https://learn.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/using-scriptanalyzer?view=ps-modules#:~:text=In%20this%20example%20the%20property,used%20for%20the%20property%20IncludeRules)). (More on custom rules in its own section below.)
- **`RecurseCustomRulePath`** – A Boolean indicating if PSScriptAnalyzer should search subdirectories of the provided custom rule path(s) for additional rule files ([
        PowerShell Gallery
        | .github/linters/.powershell-psscriptanalyzer.psd1 0.0.2-Preview
    ](https://www.powershellgallery.com/packages/SecretManagement.Hashicorp.Vault.KV/0.0.2-Preview/Content/.github%5Clinters%5C.powershell-psscriptanalyzer.psd1#:~:text=psscriptanalyzer.psd1%20%40%7B%20,true)). Set this to `$true` if you've organized custom rules in a folder hierarchy and want all of them picked up. If you enable this, and you *only* want custom rules, remember to disable default rules (or don't set IncludeDefaultRules) to avoid running everything.
- **`Rules`** – A nested hashtable for providing **per-rule specific settings**. This is used to pass **rule parameters** to particular rules, or to override certain rule behaviors. For example, some rules have optional parameters (like a whitelist of allowed terms or specific options). If you want to provide those, you do so under `Rules`. The key is the rule name, and the value is another hashtable of that rule's parameter names and values. For example:
  ```powershell
  Rules = @{
      PSAvoidUsingCmdletAliases = @{ Whitelist = @('cd') }
  }
  ```
  This would configure the rule **PSAvoidUsingCmdletAliases** to ignore the alias `cd` (so using `cd` won't trigger a warning in that rule) ([Where do I place the PSScriptAnalyzerSettings.psd1 file so the settings will be applied for all user accounts? : r/PowerShell](https://www.reddit.com/r/PowerShell/comments/lt5w8q/where_do_i_place_the_psscriptanalyzersettingspsd1/#:~:text=,Whitelist%20%3D%20%40%28%27cd)). Not all rules have configurable parameters, but for those that do (like specifying compatible PowerShell versions in compatibility rules, etc.), the `Rules` key is how you pass those in. We’ll see more examples of this in **Advanced Use Cases**.

**Enabling or Disabling Rules:** To selectively run rules, use **IncludeRules** or **ExcludeRules**. It’s generally recommended to use one of these approaches, not both, to avoid confusion – but if you do use both, note that any rule present in both lists will be *excluded* (ExcludeRules takes precedence) ([Where do I place the PSScriptAnalyzerSettings.psd1 file so the settings will be applied for all user accounts? : r/PowerShell](https://www.reddit.com/r/PowerShell/comments/lt5w8q/where_do_i_place_the_psscriptanalyzersettingspsd1/#:~:text=,ExcludeRules%20%3D%20%40%28%27PSAvoidUsingWriteHost%27%2C%27PSMissingModuleManifestField)). In practice:
- If you want to run a small *subset* of all rules (for example, only security-related rules), use **IncludeRules** to list them. Everything not listed is ignored.
- If you want to run most rules, but skip a few that don't apply, use **ExcludeRules** for those few, and let all others run.

For example, your settings file might include:
```powershell
@{
    ExcludeRules = @('PSAvoidUsingWriteHost', 'PSUseWriteOutput')
}
```
This would disable the **PSAvoidUsingWriteHost** and **PSUseWriteOutput** rules (perhaps you decide using Write-Host is acceptable in your project), and run all other default rules normally. Conversely, using IncludeRules:
```powershell
@{
    IncludeRules = @('PSAvoidHardcodingCredentials', 'PSUseApprovedVerbs')
}
```
would run *only* those two rules (one that checks for hardcoded credentials and one that checks cmdlet naming) and no others ([Using PSScriptAnalyzer - PowerShell | Microsoft Learn](https://learn.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/using-scriptanalyzer?view=ps-modules#:~:text=,)).

**Adjusting Rule Severity Reporting:** Every PSScriptAnalyzer rule is defined with a severity level (information, warning, or error). These indicate how critical a finding is (with "Error" being most severe). Out of the box, most PSScriptAnalyzer rules are classified as warnings or information; truly critical issues (like syntax errors) might appear as errors. In the settings file, you can’t change a rule’s intrinsic severity, but you *can* control what severities are considered worth reporting:
- To **limit output to certain severities**, list them under the **Severity** key. For example: `Severity = @('Error','Warning')` will suppress informational messages ([Using PSScriptAnalyzer - PowerShell | Microsoft Learn](https://learn.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/using-scriptanalyzer?view=ps-modules#:~:text=Severity%3D%40%28%27Error%27%2C%27Warning%27%29%20ExcludeRules%3D%40%28%27PSAvoidUsingCmdletAliases%27%2C%20%27PSAvoidUsingWriteHost%27%29%20)). This is useful in CI/CD when you want to reduce noise (e.g., treat the build as passed even if only informational/style issues are present). In a development environment, you might use the full set including Information to get more suggestions, but in automation, you might filter out low-severity items.
- If you want to be extra strict, you could even *narrow* to `'Error'` only (meaning the build will only fail or report if an actual error-level issue is found). Or conversely, include `'Information'` if you want absolutely everything reported.
- Keep in mind that filtering by Severity happens **after** rules run ([Invoke-ScriptAnalyzer (PSScriptAnalyzer) - PowerShell | Microsoft Learn](https://learn.microsoft.com/en-us/powershell/module/psscriptanalyzer/invoke-scriptanalyzer?view=ps-modules#:~:text=)) ([Invoke-ScriptAnalyzer (PSScriptAnalyzer) - PowerShell | Microsoft Learn](https://learn.microsoft.com/en-us/powershell/module/psscriptanalyzer/invoke-scriptanalyzer?view=ps-modules#:~:text=You%20can%20specify%20one%20ore,more%20severity%20values)). PSScriptAnalyzer will still execute the rules; it just won't output the ones that don’t match the filter. If performance or efficiency is a concern (to not even run some rules), you should instead use Include/ExcludeRules to prevent running those rules at all. For instance, if you only care about error-level rules, you might identify which rules can produce warnings and exclude them instead of relying solely on the Severity filter.

In summary, **configuring rules** via the settings file involves deciding which rules to run, which to skip, and what levels of findings to show. The table below summarizes the key configuration options and their effects:

| **Key**            | **Purpose**                                                | **Example**                                         |
|--------------------|------------------------------------------------------------|-----------------------------------------------------|
| `IncludeRules`     | Run *only* these specific rules (names or wildcards).      | `IncludeRules = @('PSUseApprovedVerbs', 'PSAvoid*')` |
| `ExcludeRules`     | Run all except these specific rules.                       | `ExcludeRules = @('PSAvoidUsingWriteHost')`         |
| `Severity`         | Only report findings of these severities.                  | `Severity = @('Error', 'Warning')`                  |
| `IncludeDefaultRules` | When using custom rules, whether to also include built-in rules. | `IncludeDefaultRules = $true` (include both custom + default) |
| `CustomRulePath`   | Path(s) to custom rule modules or scripts to load.         | `CustomRulePath = 'path\to\MyRules.psm1'`           |
| `RecurseCustomRulePath` | If true, search subfolders in CustomRulePath for rules. | `RecurseCustomRulePath = $true`                     |
| `Rules`            | Rule-specific settings (hashtable of rule names to settings). | `Rules = @{ PSWhateverRule = @{ Param = 'Value' } }` |

With these tools, you can fine-tune the analysis exactly as required. Next, we'll focus specifically on excluding rules and then on creating custom rules.

## Rule Exclusions

Sometimes you may want to **suppress certain rules** from running because they are not applicable to your scenario or perhaps yield too many false positives. Using the settings file to exclude rules is often preferable to peppering your code with suppression attributes, as it provides a single point of control. Here’s how to manage rule exclusions effectively:

- **ExcludeRules Key:** As mentioned, this key takes an array of rule names to disable. The rule names correspond to the PSScriptAnalyzer rules (for example: PSAvoidUsingCmdletAliases, PSUseDeclaredVarsMoreThanAssignments, etc.). You can find the list of rule names via the `Get-ScriptAnalyzerRule` cmdlet or in [PSScriptAnalyzer’s rule documentation](https://learn.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/overview#available-rules). In the settings file, list the rules to skip like so:
  ```powershell
  @{
      ExcludeRules = @('RuleName1', 'RuleName2', 'RuleName3')
  }
  ```
  For instance, to exclude the rules that discourage using Write-Host and ConvertTo-SecureString with plaintext, you could configure:
  ```powershell
  @{
      ExcludeRules = @('PSUseShouldProcessForStateChangingFunctions',
                       'PSAvoidUsingConvertToSecureStringWithPlainText')
  }
  ```
  This example matches the Super-Linter default, which excludes two specific rules from the analysis ([
        PowerShell Gallery
        | .github/linters/.powershell-psscriptanalyzer.psd1 0.0.2-Preview
    ](https://www.powershellgallery.com/packages/SecretManagement.Hashicorp.Vault.KV/0.0.2-Preview/Content/.github%5Clinters%5C.powershell-psscriptanalyzer.psd1#:~:text=IncludeDefaultRules%C2%A0%3D%C2%A0%24,%27MyCustomRuleName%27)). The rest of the rules would still run (unless further limited by includes or severities).

- **Wildcards:** You can use wildcard patterns to exclude groups of rules. For example, `ExcludeRules = @('PSAvoid*')` would exclude all rules whose names start with "PSAvoid". Use this with caution, as you might accidentally skip important rules.

- **Precedence with IncludeRules:** If you happen to use both IncludeRules and ExcludeRules, note that an exclude will override an include. *“If a rule is in both IncludeRules and ExcludeRules, the rule will be excluded.”* ([Where do I place the PSScriptAnalyzerSettings.psd1 file so the settings will be applied for all user accounts? : r/PowerShell](https://www.reddit.com/r/PowerShell/comments/lt5w8q/where_do_i_place_the_psscriptanalyzersettingspsd1/#:~:text=,ExcludeRules%20%3D%20%40%28%27PSAvoidUsingWriteHost%27%2C%27PSMissingModuleManifestField)). This is logical – you explicitly told the analyzer to exclude it, so it won’t run even if it was also on your include list. In practice, try to stick to one approach (include-only or exclude-only) to keep the configuration clear.

- **Temporary vs Permanent Exclusions:** If you find yourself excluding many rules, double-check if you truly need them all off. It's often better to exclude only what you must. Some teams use exclusions temporarily and aim to fix the underlying code issues so they can remove the exclusion later (for example, turning off a deprecated alias rule until they have time to refactor all uses of those aliases).

- **Suppressing in Code vs. Settings:** PSScriptAnalyzer also supports suppressing a rule for a specific portion of code using annotations (the `[Diagnostics.CodeAnalysis.SuppressMessage()]` attribute in your script). Use that approach when a rule is generally useful, but a *specific instance* in code should be exempt. However, if you find you are suppressing the same rule in many places, it's a sign that maybe that rule should be globally excluded via the settings file (or that the team has consciously decided to not follow that particular guideline).

In summary, **rule exclusions** in the settings file let you turn off unwanted rules globally for the analysis run. Keep the list of exclusions as short as possible to get maximum value from PSScriptAnalyzer, but do use it to disable rules that don’t make sense for your project. This ensures the output focuses only on relevant issues.

## Custom Rules

While PSScriptAnalyzer comes with a rich set of built-in rules, you may have organization-specific or project-specific guidelines that aren’t covered by the defaults. **Custom rules** allow you to extend PSScriptAnalyzer by writing your own rule logic. The settings file plays a crucial role in **registering these custom rules** so that PSScriptAnalyzer knows about them.

**Creating a Custom Rule:** Custom rules are implemented as functions in a PowerShell module (.psm1) or script file. Key points for writing a custom rule module:

- Each custom rule is a function that typically uses a verb like *Measure* or *Test* (for example, `Measure-MyCustomRule`). There's no strict naming requirement, but following a consistent verb-noun naming helps. In Microsoft’s examples, they use `Measure-` for custom rules ([Using PSScriptAnalyzer - PowerShell | Microsoft Learn](https://learn.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/using-scriptanalyzer?view=ps-modules#:~:text=In%20this%20example%20the%20property,used%20for%20the%20property%20IncludeRules)).
- The function must accept either a `[ScriptBlockAst]` (AST of the script) or `[Token[]]` (array of tokens) as a parameter. Most custom rules work with the AST, as it provides a structured representation of the code.
- The function should return one or more **DiagnosticRecord** objects (or nothing if no issues found). A DiagnosticRecord is what PSScriptAnalyzer uses to represent a rule violation (with properties like Severity, ScriptName, Line, Message, etc.).
- Include comment-based help in your function with at least a `.Synopsis` (this becomes the rule's description) and `.Description` if needed. Also use the `[OutputType()]` attribute to declare that it outputs `DiagnosticRecord` objects ([Creating custom PSScriptAnalyzer rules](https://blog.ironmansoftware.com/psscriptanalyzer-custom-rules/#:~:text=,function%20that%20should%20be%20noted)).
- After defining the function(s) in the .psm1, make sure to **export** them (e.g., using `Export-ModuleMember -Function MyFunctionName`) ([Creating custom PSScriptAnalyzer rules](https://blog.ironmansoftware.com/psscriptanalyzer-custom-rules/#:~:text=Finally%2C%20we%20make%20sure%20to,the%20function%20from%20our%20module)). If you have multiple rules in one module, export each function that implements a rule.

For example, imagine we want a custom rule to ensure no TODO comments are left in the code. We could create `MyCompany.AnalyzerRules.psm1` with a function `Measure-TodoComment` that scans the AST for comment tokens containing "TODO" and emits a DiagnosticRecord for each occurrence. Once that function is ready and exported from the module, we're set to wire it into PSScriptAnalyzer.

**Using Custom Rules via Settings File:** The settings file needs to tell PSScriptAnalyzer where to find your custom rules and which ones to run. This is done with two keys we mentioned: `CustomRulePath` and (optionally) `IncludeRules`/`IncludeDefaultRules`.

- **CustomRulePath:** Add this key with the path(s) to your custom rule module or script. For example:
  ```powershell
  @{
      CustomRulePath = @(
          '.\Modules\MyCompany.AnalyzerRules\MyCompany.AnalyzerRules.psm1'
      )
  }
  ```
  You can specify multiple paths (e.g., if you have several custom rule modules) by using an array as shown. Relative paths are typically resolved relative to where you run PSScriptAnalyzer (e.g., your project root). Ensure the path is correct; if pointing to a module folder, you can just give the folder path (and it will load the module manifest if present). If pointing to a .psm1 file, include the full filename ([Using PSScriptAnalyzer - PowerShell | Microsoft Learn](https://learn.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/using-scriptanalyzer?view=ps-modules#:~:text=In%20this%20example%20the%20property,used%20for%20the%20property%20IncludeRules)).

- **IncludeRules for custom rules:** By default, when you provide custom rules, PSScriptAnalyzer might run *only* those custom rules (depending on how you configure IncludeDefaultRules). If you want to run all your custom rules, one easy way is to name them with a common prefix or verb and use a wildcard include. For instance, if all your custom rule functions start with `Measure-`, you could do:
  ```powershell
  @{
      CustomRulePath = '.\AnalyzerRules\CustomRules.psm1'
      IncludeRules   = @('Measure-*')
  }
  ```
  This tells PSSA to include any rules whose names match "Measure-*", which should rope in all functions from your custom module (assuming they use that naming convention) ([Using PSScriptAnalyzer - PowerShell | Microsoft Learn](https://learn.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/using-scriptanalyzer?view=ps-modules#:~:text=In%20this%20example%20the%20property,used%20for%20the%20property%20IncludeRules)) ([Using PSScriptAnalyzer - PowerShell | Microsoft Learn](https://learn.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/using-scriptanalyzer?view=ps-modules#:~:text=IncludeRules%20%20%20%20,%29)).

- **Including default rules as well:** If you want to *add* custom rules on top of the standard ones (common case – you usually want both your rules and the built-ins), you should set `IncludeDefaultRules = $true` in the hashtable ([Using PSScriptAnalyzer - PowerShell | Microsoft Learn](https://learn.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/using-scriptanalyzer?view=ps-modules#:~:text=IncludeDefaultRules%20%3D%20%24true)). By doing so, you ensure that the default rule set remains active alongside your custom ones. Then you have two options:
  1. **Run all default rules + all custom rules:** In this case, you might not even need an IncludeRules list; simply adding a CustomRulePath and setting IncludeDefaultRules `$true` might load everything (all defaults and all functions found in custom path). However, to be explicit, you could list some or all rules in `IncludeRules`.
  2. **Run a selection of default rules + specific custom rules:** List exactly which rules to run in `IncludeRules` (both default and custom). For example:
     ```powershell
     @{
         CustomRulePath      = @('.\MyRules\MyRules.psm1')
         IncludeDefaultRules = $true
         IncludeRules        = @(
             # select some default rules
             'PSAvoidDefaultValueForMandatoryParameter',
             'PSUseApprovedVerbs',
             # select custom rules by name
             'Measure-TodoComment',
             'Measure-SecretInScript'
         )
     }
     ```
     In this snippet, we point to a custom rules module, allow default rules, and explicitly include two specific default rules and two custom rules by name. Only those four rules would run.

A real example from Microsoft’s documentation shows including both default and custom rules by mixing them in the IncludeRules list and enabling default rules:
```powershell
@{
    CustomRulePath      = @(
        '.\output\RequiredModules\DscResource.AnalyzerRules',
        '.\tests\QA\AnalyzerRules\SqlServerDsc.AnalyzerRules.psm1'
    )
    IncludeDefaultRules = $true
    IncludeRules        = @(
        # Default rules
        'PSAvoidDefaultValueForMandatoryParameter',
        'PSAvoidDefaultValueSwitchParameter',
        # Custom rules
        'Measure-*'
    )
}
```
In this case, any rule in the custom modules matching `Measure-*` will run, plus the two named default rules (and no other default rules) ([Using PSScriptAnalyzer - PowerShell | Microsoft Learn](https://learn.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/using-scriptanalyzer?view=ps-modules#:~:text=%40,SqlServerDsc.AnalyzerRules.psm1%27)) ([Using PSScriptAnalyzer - PowerShell | Microsoft Learn](https://learn.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/using-scriptanalyzer?view=ps-modules#:~:text=%27PSAvoidDefaultValueForMandatoryParameter%27%20%27PSAvoidDefaultValueSwitchParameter%27)).

**Using Custom Rules in VS Code:** If you're working in Visual Studio Code with the PowerShell extension, you can have it use your settings (and thus your custom rules) by pointing to the settings file in your workspace settings. In your `.vscode/settings.json`, set:
```json
{
    "powershell.scriptAnalysis.settingsPath": ".github/linters/.powershell-psscriptanalyzer.psd1",
    "powershell.scriptAnalysis.enable": true
}
```
This ensures that the editor, when providing real-time PSScriptAnalyzer feedback, uses your settings (including loading any custom rule modules) ([Using PSScriptAnalyzer - PowerShell | Microsoft Learn](https://learn.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/using-scriptanalyzer?view=ps-modules#:~:text=workspace%20settings%20file%20%28)). Without this, VS Code might only use default rules or its own default settings.

**Testing Custom Rules:** After configuring, run `Invoke-ScriptAnalyzer` on a sample script that should trigger your custom rule to verify it's working. If it doesn't appear to run:
- Check that the path in CustomRulePath is correct. Try an absolute path to be sure.
- Ensure the module is not throwing errors on import (e.g., try an `Import-Module` on it).
- Confirm the function name or pattern is correctly listed in IncludeRules (if you use that).
- Make sure `IncludeDefaultRules` is set appropriately. If your custom rule names don't match any default rules and you **only** want custom rules, you might set `IncludeDefaultRules = $false` (or omit it, as false is default when IncludeRules is specified) to avoid running built-ins.
- If still not working, run PSScriptAnalyzer in verbose mode or check for any warnings about loading rules. There's also a built-in rule "PSScriptAnalyzerSettingsSchema" (available in newer versions) that can validate your settings file structure to catch mistakes ([[Resolved] PSSCriptAnalyzer warnings in VSCode](https://forums.ironmansoftware.com/t/resolved-psscriptanalyzer-warnings-in-vscode/3602#:~:text=rule%20definitions%20can%20be%20read,com%20%C2%B7%20PowerShell)).

Custom rules empower you to enforce project-specific guidelines. Once set up in the settings file, they integrate seamlessly – from the command line, to editors, to CI pipelines – just like the built-in PSScriptAnalyzer rules.

## Advanced Use Cases

In this section, we explore advanced scenarios and fine-tuning techniques for PSScriptAnalyzer settings. These go beyond the basic include/exclude and custom rules to address project-specific needs and edge cases.

### Fine-Tuning for Specific Projects

Every project might have its own quirks. The settings file can be adjusted to handle those:

- **Different Settings per Project**: If you maintain multiple projects (or modules) in one repository that have distinct guidelines, you can create multiple settings files. For example, if you have a module in one folder that requires strict rules and a script in another that requires a looser rule set, you might use `Invoke-ScriptAnalyzer -Path ModuleA -Settings .\ModuleA\PSScriptAnalyzerSettings.psd1` for one and a different settings file for the other. You could even automate this via separate CI jobs or scripts for each sub-project. Keep each settings file alongside its project files for clarity.
- **Built-in Presets**: PSScriptAnalyzer offers some built-in presets which are essentially pre-configured rule sets (invoked by passing a special value to the `-Settings` parameter, like "PSGallery", "DSC", or "CodeFormatting") ([Using PSScriptAnalyzer - PowerShell | Microsoft Learn](https://learn.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/using-scriptanalyzer?view=ps-modules#:~:text=Built)). While these aren't hashtable files you edit, it's good to know about them. For instance, the "PSGallery" preset focuses on rules relevant to publishing modules to PowerShell Gallery (e.g., required metadata), and "DSC" preset focuses on Desired State Configuration script guidelines. Advanced users sometimes start with a preset and then modify further via a custom settings file if needed.
- **Rule Parameter Customization**: We introduced the `Rules` hashtable for passing rule-specific settings. This is particularly useful for **edge cases** like:
  - Whitelisting or blacklisting certain elements. e.g., *PSAvoidUsingCmdletAliases* rule normally warns on any alias usage. If your project is okay with a few specific aliases (like `ls` or `gc`), add them to a whitelist:
    ```powershell
    Rules = @{ PSAvoidUsingCmdletAliases = @{ Whitelist = @('ls','gc') } }
    ```
    Now those aliases won't trigger the rule ([Where do I place the PSScriptAnalyzerSettings.psd1 file so the settings will be applied for all user accounts? : r/PowerShell](https://www.reddit.com/r/PowerShell/comments/lt5w8q/where_do_i_place_the_psscriptanalyzersettingspsd1/#:~:text=,Whitelist%20%3D%20%40%28%27cd)).
  - Configuring compatibility checks. PSScriptAnalyzer has rules like **PSUseCompatibleCmdlets** which can check if your script's cmdlets exist in other PowerShell versions. That rule takes a `Compatibility` parameter (specifying target platforms/versions). You can set in the settings file:
    ```powershell
    Rules = @{ PSUseCompatibleCmdlets = @{ Compatibility = @('WindowsPowerShell_5.1', 'PowerShellCore_7.0') } }
    ```
    This would make the rule check compatibility against Windows PowerShell 5.1 and PowerShell 7.0. Without such specification, it might default to some baseline or require manual parameter each time.
  - Adjusting formatting rules. If you use the PSScriptAnalyzer formatting features (via `Invoke-Formatter` or the VSCode formatting), you might have formatting rules that accept settings (indentation style, etc.). Those too can often be configured via the settings file under the `Rules` key for the specific formatting rule.

- **Excluding Files or Paths**: Unlike some linters, PSScriptAnalyzer’s settings file does not have a direct way to exclude specific file paths from analysis. File scoping is usually handled when invoking the tool (e.g., you choose what `-Path` to analyze, or you could script to skip certain files). However, you can simulate per-path rule exclusions by combining with the ability to suppress in-code or running separate passes. One advanced approach is to run PSScriptAnalyzer multiple times on different sets of files with different settings (perhaps via a script). For example, you might run it on all files normally, but on a specific problematic script with a special settings file that excludes a rule that doesn't play well with that script.

- **Implicit vs Explicit Settings Usage**: Recall that if a file named `PSScriptAnalyzerSettings.psd1` is present in the directory you're analyzing, it will be automatically picked up ([Using PSScriptAnalyzer - PowerShell | Microsoft Learn](https://learn.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/using-scriptanalyzer?view=ps-modules#:~:text=Implicit)). In advanced scenarios, you may intentionally leverage this:
  - If you have a repository with many projects, each could have its own settings file in its folder. A top-level build script could just call `Invoke-ScriptAnalyzer -Recurse` on each folder and let each one pick up its own settings implicitly.
  - However, be cautious: if multiple settings files are present (say one in a parent folder and one in a subfolder), PSScriptAnalyzer will pick the one in the **exact path you specify**. It doesn't merge or traverse upward to find others. The *explicitly provided* `-Settings` always wins over implicit ([Using PSScriptAnalyzer - PowerShell | Microsoft Learn](https://learn.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/using-scriptanalyzer?view=ps-modules#:~:text=Invoke)). So if you want a single settings to apply to a whole repo, keep one at the root and call PSSA on the root. If you want different ones per sub-project, call PSSA on each sub-project folder separately.

### Handling Edge Cases and Gotchas

Even with a well-tuned configuration, you might encounter odd situations:

- **Settings File Not Detected**: If you run `Invoke-ScriptAnalyzer` and it seems to ignore your settings (e.g., you still see warnings you meant to exclude), double-check:
  - The `-Settings` parameter path is correct (if using explicitly).
  - If relying on implicit discovery, ensure the file is named exactly `PSScriptAnalyzerSettings.psd1` (capitalization doesn't matter) and that you ran PSSA on the directory that contains that file.
  - Make sure the .psd1 has valid PowerShell syntax. If there's a typo (like a missing `@` or a stray character), PSScriptAnalyzer may silently fall back to defaults. You can test by trying to manually dot-source the psd1 file in PowerShell (`. .\PSScriptAnalyzerSettings.psd1`) – it should import as a hashtable without error. If it errors out, fix the syntax.
  - Check if there is a rule named **PSScriptAnalyzerSettingsSchema** in your PSSA version. This is a rule under discussion/implementation ([[RULE] PSScriptAnalyzerSettingsSchema · Issue #1279 - GitHub](https://github.com/PowerShell/PSScriptAnalyzer/issues/1279#:~:text=%5BRULE%5D%20PSScriptAnalyzerSettingsSchema%20%C2%B7%20Issue%20,so%20that%20I%20can)) ([[Resolved] PSSCriptAnalyzer warnings in VSCode](https://forums.ironmansoftware.com/t/resolved-psscriptanalyzer-warnings-in-vscode/3602#:~:text=rule%20definitions%20can%20be%20read,com%20%C2%B7%20PowerShell)) that, when enabled, could validate the structure of your settings file. If available, try enabling it to get feedback on your configuration file itself.

- **Conflicting Settings**: Setting include and exclude rules that overlap, or severity filters that contradict included rules, can lead to confusion. For instance, if you set `Severity = @('Error')` but also `IncludeRules = @('PSAvoidUsingCmdletAliases')` (which is typically a Warning-level rule), you might wonder why you get no output – it's because the rule runs (due to IncludeRules) but its warning results are filtered out by the Severity setting (which allows only Errors). In such cases, PSScriptAnalyzer's logic is that the severity filter is applied after running all rules, effectively discarding any non-matching severities ([Invoke-ScriptAnalyzer (PSScriptAnalyzer) - PowerShell | Microsoft Learn](https://learn.microsoft.com/en-us/powershell/module/psscriptanalyzer/invoke-scriptanalyzer?view=ps-modules#:~:text=You%20can%20specify%20one%20ore,more%20severity%20values)). The takeaway: ensure your rule inclusion/exclusion and severity filters are aligned. Usually, if using Severity filtering, you don't need to list rules of a filtered-out severity in IncludeRules.

- **Performance Considerations**: In very large projects, running all rules can be slow. You might create a slim settings file for quick iterative checks (excluding some heavy rules or using severity filter to skip informational/style rules), and a full settings file for a thorough check before release. Similarly, if custom rules are slow, you could enable them conditionally. This is more of a pipeline optimization – for example, one could run a "fast lint" on each commit and a "full lint" nightly.

- **Rule Updates in New PSScriptAnalyzer Versions**: The PSScriptAnalyzer module is periodically updated with new rules or changes. If you update it, new rules (with their default severities) might start running on your code. If you have an **ExcludeRules** list, those new rules will run because you didn’t explicitly exclude them (since they were unknown before). If you use **IncludeRules**, those new rules will *not* run (since your list is explicit). There’s a trade-off:
  - Using *ExcludeRules* is future-proof in that you automatically get any new rules (which might be good, to catch new best practices) except ones you excluded. But you might need to update the exclude list if a new rule is noisy or not applicable.
  - Using *IncludeRules* gives you a fixed set until you manually update it, preventing surprises from new rules. But you might miss out on beneficial new analysis until you revise the settings.
  - **Best practice**: if your goal is to enforce all possible checks and only omit known problematic ones, favor ExcludeRules. If your goal is to enforce a very specific set of rules (compliance scenario, perhaps), use IncludeRules.

- **Combining with Other Analyzers**: In advanced cases, projects might use multiple linters (e.g., perhaps PSScriptAnalyzer plus a JSON linter for config files, etc.). If using a unified tool like Super-Linter or Mega-Linter, make sure the config file is in the correct location and named as expected for PSScriptAnalyzer. For instance, as noted earlier, Super-Linter expects `.github/linters/.powershell-psscriptanalyzer.psd1`. If you name it differently, you might need to configure the linter to know the custom path (Super-Linter allows some override variables if needed, but following convention is easiest).

With careful configuration, PSScriptAnalyzer can handle most project requirements. You can mix and match these strategies—just keep track of what you’ve configured so that the behavior remains predictable.

## Automation and CI/CD Integration

Integrating PSScriptAnalyzer into your automated build or deployment pipeline is an excellent way to prevent code with issues from being merged or released. Here’s how you can use the hashtable-based settings file in various CI/CD scenarios:

- **GitHub Actions (Super-Linter)**: GitHub offers a **Super-Linter** action that runs multiple linters, including PSScriptAnalyzer, in one go. If you use Super-Linter, simply placing your settings file at `.github/linters/.powershell-psscriptanalyzer.psd1` in your repo is all you need – the action will automatically detect and use it ([
        PowerShell Gallery
        | .github/linters/.powershell-psscriptanalyzer.psd1 0.0.2-Preview
    ](https://www.powershellgallery.com/packages/SecretManagement.Hashicorp.Vault.KV/0.0.2-Preview/Content/.github%5Clinters%5C.powershell-psscriptanalyzer.psd1#:~:text=Documentation%3A%20https%3A%2F%2Fgithub.com%2FPowerShell%2FPSScriptAnalyzer%2Fblob%2Fmaster%2Fdocs%2Fmarkdown%2FInvoke,RecurseCustomRulePath%3D%27path%5Cof%5Ccustomrules%27%20Severity%C2%A0%C2%A0%C2%A0%C2%A0%C2%A0%C2%A0%C2%A0%C2%A0%C2%A0%C2%A0%C2%A0%C2%A0%3D)). Super-Linter will run PSScriptAnalyzer against your `.ps1`, `.psm1`, etc., files using the rules defined in that file. Ensure that the file is named exactly as expected (note the leading dot and specific name). In your GitHub Actions workflow yaml, you might have:
  ```yaml
  - uses: github/super-linter@vX.Y.Z
    with:
      languages: 'POWERSHELL'  # (and others as needed)
  ```
  That’s it – the configuration is picked up by convention.

- **GitHub Actions (Dedicated PSSA Action)**: There is also a dedicated action, **microsoft/psscriptanalyzer-action**, which focuses on PSScriptAnalyzer and produces outputs like SARIF (for GitHub code scanning). With this action, you can specify the `settings` input to point to your settings file. For example:
  ```yaml
  - name: Run PSScriptAnalyzer
    uses: microsoft/psscriptanalyzer-action@v1
    with:
      path: './**/*.ps1'            # or path to your scripts directory
      settings: .github/linters/.powershell-psscriptanalyzer.psd1
      failOnError: true            # (if you want to fail the job on any errors)
  ```
  The `settings` parameter accepts a path to your psd1 file ([GitHub - microsoft/psscriptanalyzer-action: GitHub Action to run PSScriptAnalyzer to your repository and produce a SARIF file](https://github.com/microsoft/psscriptanalyzer-action#:~:text=settings)), so you can keep your config in the repo. This action also supports additional options like producing a SARIF report that integrates with GitHub’s code scanning alerts. Check the action’s documentation for details, such as the `enableExit` flag (which makes the action exit with a non-zero code equal to the number of errors, causing the pipeline to fail if any errors are found) ([GitHub - microsoft/psscriptanalyzer-action: GitHub Action to run PSScriptAnalyzer to your repository and produce a SARIF file](https://github.com/microsoft/psscriptanalyzer-action#:~:text=enableExit)).

- **Azure Pipelines**: In Azure DevOps or other CI systems, you might not have a pre-built PSScriptAnalyzer task by default, but it's easy to use via PowerShell scripts. For example, in an Azure Pipeline YAML:
  ```yaml
  - task: PowerShell@2
    inputs:
      targetType: inline
      script: |
        Install-Module PSScriptAnalyzer -Scope CurrentUser -Force
        Invoke-ScriptAnalyzer -Path "$(System.DefaultWorkingDirectory)\MyProject" -Recurse -Settings "$(System.DefaultWorkingDirectory)\MyProject\.github\linters\.powershell-psscriptanalyzer.psd1" -ErrorAction Continue
        if ($LASTEXITCODE -ne 0) {
            Write-Host "PSScriptAnalyzer found errors."
            Exit 1
        }
  ```
  This installs PSScriptAnalyzer (if not already available on the agent), runs it with the settings file, and uses the exit code or $LASTEXITCODE to decide if the pipeline should fail. You might also capture the results and publish them as artifacts or test results. (Note: By default, `Invoke-ScriptAnalyzer` does not set a distinct exit code for findings; one way to get an exit code is to use the `-ErrorAction` as shown combined with `failOnError`-like logic, or use the PSScriptAnalyzer `EnableExit` switch introduced in newer versions which directly exits with number of errors ([GitHub - microsoft/psscriptanalyzer-action: GitHub Action to run PSScriptAnalyzer to your repository and produce a SARIF file](https://github.com/microsoft/psscriptanalyzer-action#:~:text=enableExit)).)

- **Other CI Tools**: In Jenkins or other CI systems, the approach is similar: run a PowerShell step that calls PSScriptAnalyzer with the `-Settings` pointing to your file, then parse the output or exit code. PSScriptAnalyzer can output results to the console or to a file (it supports formatting output as plain text, JSON, or even SARIF using the `-OutPath` and `-Format` parameters). For instance, you could output SARIF and feed it into a code analysis tool or archive it for review.

- **Failing the Build on Violations**: Decide what level of violations should cause a build to fail. A common practice:
  - Fail on any "Error" severity issues (these often indicate likely bugs or serious problems).
  - Optionally, allow "Warnings" but still succeed the build (maybe just log them), or fail if you want to enforce a stricter standard.
  - Ignore "Information" in CI to reduce noise.

  Since your settings file can filter severities, one strategy is to maintain a separate CI-specific settings that sets `Severity = @('Error','Warning')` (if you want to treat warnings as needing attention) or just `'Error'` for very strict pipelines ([Where do I place the PSScriptAnalyzerSettings.psd1 file so the settings will be applied for all user accounts? : r/PowerShell](https://www.reddit.com/r/PowerShell/comments/lt5w8q/where_do_i_place_the_psscriptanalyzersettingspsd1/#:~:text=%40%7B%20,Error%27%29)). However, it's often sufficient to use one settings file and handle severity in the pipeline script: e.g., run PSSA with all severities but then post-process results – if any errors, fail; if only warnings, perhaps just warn. This depends on your build governance policy.

- **Continuous Integration Example**: Suppose we want to ensure no new PSScriptAnalyzer errors/warnings get introduced. We could have a step in CI that runs PSSA and outputs results. If output is not empty (or contains certain severities), mark the build unstable. In GitHub Actions, if using the PSScriptAnalyzer action with `failOnError: true` (or using `enableExit` internally), the action will handle failing on error-level findings automatically ([GitHub - microsoft/psscriptanalyzer-action: GitHub Action to run PSScriptAnalyzer to your repository and produce a SARIF file](https://github.com/microsoft/psscriptanalyzer-action#:~:text=enableExit)). For warnings, you might need a custom step or adjust the action's parameters (some might offer `failOnWarning`). Always consult the specific action/tool docs.

- **Automated Formatting**: While not exactly analysis, PSScriptAnalyzer includes an `Invoke-Formatter` cmdlet that can auto-format code according to rules. This can be integrated into pre-commit hooks or CI (for example, to fail if code is not formatted). The formatting rules can also be controlled via a settings file (using the `Rules` key for the formatting settings). An advanced CI integration could run the formatter in a PR workflow, and either auto-commit the changes or advise the user to run formatting. This goes hand-in-hand with analysis: analyze to catch issues, format to fix style issues automatically.

- **SARIF and Security Scanning**: PSScriptAnalyzer isn't a security scanner per se, but it can detect some security relevant patterns (like potential credential leaks, use of dangerous commands, etc.). By outputting to SARIF (Static Analysis Results Interchange Format) and uploading that to platforms like GitHub or Azure, you can integrate PSSA results into code scanning dashboards. The GitHub action we discussed can output SARIF by default, and GitHub Advanced Security can pick it up to show alerts in the Security tab of the repo.

**Tip:** When integrating into CI, run PSScriptAnalyzer on the **same PowerShell version** that your team uses for development, or the environment you target. The set of rules and their behavior is the same across PS versions for a given PSSA version, but if you use the compatibility rules, the runtime matters (e.g., running on PowerShell 7 analyzing for Windows PowerShell compatibility is fine, but just be aware of what environment the analysis is running in for path references and such).

By automating PSScriptAnalyzer in CI/CD, you create a quality gate that helps maintain your PowerShell code standard. The settings file ensures this is done consistently every time. As developers push code, they get immediate feedback if something doesn't meet the team's standards, and they can fix it before merging – resulting in cleaner, more reliable code in your main branches.

## Best Practices

To wrap up, here are some best practices and tips for using a hashtable-based PSScriptAnalyzer settings file effectively:

- **Start with Defaults, Then Tweak**: Begin by running PSScriptAnalyzer with the default rules on your codebase to see what it flags. Use that to inform your settings. Disable rules only if you have a good reason. It's better to be informed of an issue and decide to ignore it than to never know it at all. That said, if a rule consistently flags things that are acceptable in your context, exclude it in the settings to reduce noise.

- **Use Exclusions Sparingly**: Each excluded rule is a class of issues you won't hear about. Keep the **ExcludeRules** list as short as possible. For instance, you might exclude style preferences you don't agree with, but think twice before excluding rules related to security or correctness. If a rule is noisy but important, consider fixing the underlying code instead of excluding the rule.

- **Leverage Severity for Focus**: Especially in CI, consider filtering out informational messages. Many teams configure `Severity = @('Error','Warning')` in the settings (or only errors) ([
        PowerShell Gallery
        | .github/linters/.powershell-psscriptanalyzer.psd1 0.0.2-Preview
    ](https://www.powershellgallery.com/packages/SecretManagement.Hashicorp.Vault.KV/0.0.2-Preview/Content/.github%5Clinters%5C.powershell-psscriptanalyzer.psd1#:~:text=Severity%C2%A0%C2%A0%C2%A0%C2%A0%C2%A0%C2%A0%C2%A0%C2%A0%C2%A0%C2%A0%C2%A0%C2%A0%3D%C2%A0%40%28%20%27Error%27%20%27Warning%27%20%29%20IncludeDefaultRules%C2%A0%3D%C2%A0%24,%27PSUseShouldProcessForStateChangingFunctions%27%2C%20%27PSAvoidUsingConvertToSecureStringWithPlainText)) to focus on the more significant issues. You can still run a full analysis locally with all severities if you want the additional info. Another approach is to use severity filtering only in CI (with a separate settings or `-Severity` param) while keeping the dev-time analysis fully verbose.

- **Keep the Settings File with the Code**: Store the `.psd1` in your repository (as we did under `.github/linters/` or at the project root). This way, changes to it are versioned. When updating PSScriptAnalyzer or altering rules, any adjustments you make to the configuration travel along with those changes in source control. New developers pulling the repo will get the config and their VSCode can pick it up, etc.

- **Document Your Choices**: Within the settings file, use comments to note why certain rules are excluded or certain settings are in place. This helps future maintainers understand the rationale. The psd1 supports comments (as it's just text), as shown in the VSCode example settings file with lots of commented explanations ([Where do I place the PSScriptAnalyzerSettings.psd1 file so the settings will be applied for all user accounts? : r/PowerShell](https://www.reddit.com/r/PowerShell/comments/lt5w8q/where_do_i_place_the_psscriptanalyzersettingspsd1/#:~:text=%40%7B%20,Severity%20%3D%20%40%28%27Error%27%2C%27Warning)) ([Where do I place the PSScriptAnalyzerSettings.psd1 file so the settings will be applied for all user accounts? : r/PowerShell](https://www.reddit.com/r/PowerShell/comments/lt5w8q/where_do_i_place_the_psscriptanalyzersettingspsd1/#:~:text=,ExcludeRules%20%3D%20%40%28%27PSAvoidUsingWriteHost%27%2C%27PSMissingModuleManifestField)). Don’t hesitate to annotate it.

- **Validate Custom Rules**: If you wrote custom rules, include unit tests for them if possible (for example, using Pester to run the rule function on sample ASTs). This ensures your custom rules work as expected and continue to work when you update PSScriptAnalyzer (or PowerShell itself). Also, if sharing custom rules with others, provide documentation for those rules.

- **Regularly Update PSScriptAnalyzer**: New versions may bring improvements and new rules. Keep an eye on the PSScriptAnalyzer release notes. When updating, run it on your code with the new version in a non-blocking way to see if new warnings/errors appear. Adjust your code or settings accordingly. For example, if a new rule flags something you intentionally do, you might add that rule to ExcludeRules after upgrading.

- **Use CI to Enforce Standards**: Make the CI builds fail on PSScriptAnalyzer errors (and optionally on warnings). This creates an incentive to keep code clean. However, avoid making it so strict that it impedes progress – find a balance. Often teams treat warnings as "should fix" but not blockers, while errors are "must fix". If so, set up your pipeline accordingly (fail on errors, and maybe allow warnings but still report them).

- **Troubleshooting Tips**:
  - If you think the settings file isn't working, run `Invoke-ScriptAnalyzer` with the `-Verbose` flag. It will often print information about which settings file is loaded (or if none) and what rules it's executing. This can reveal, for example, that it's not finding your file, or a rule name was not recognized.
  - Ensure no duplicate keys or conflicting keys in the hashtable. Each key should appear at most once. If you accidentally have two `Severity` entries, for example, the latter might overwrite the former or the file might fail to parse.
  - Remember that the settings file is essentially a PowerShell script that returns a hashtable. This means you could even have logic in it (though not recommended for simplicity and security). For instance, technically you could do something like:
    ```powershell
    @{
       Severity = $([Environment]::GetEnvironmentVariable('PSSASeverity') -split ',')
    }
    ```
    This is advanced usage and generally discouraged, but it's worth noting the file is evaluated by PowerShell. Most will keep it static.

  - On rare occasions, a rule might throw an unexpected error when running on certain code (an edge case bug in PSScriptAnalyzer). If you encounter this, you can exclude that rule as a workaround and report the issue to the PSScriptAnalyzer project. Use `-ExcludeRule` on the command as a quick test to identify which rule is problematic, then permanently exclude in settings until a fix is available.

- **Security of the Settings File**: Treat the settings file as part of your codebase. It doesn't typically contain secrets or anything sensitive (unless you, say, whitelist some secret in it which you shouldn't). However, because it can theoretically execute code (like any .psd1), ensure only trusted persons can modify it, especially in environments where it might run automatically (CI). In practice, keep it in source control and use code reviews for changes.

By following these best practices, you can harness PSScriptAnalyzer to its fullest, maintaining high quality PowerShell code with a configuration that suits your team's needs. A well-tuned settings file becomes a powerful ally in your development process – catching issues early, enforcing standards, and even educating team members about best practices (since each rule often comes with guidance on how to improve the code).

**References:** The information in this guide was compiled from official PSScriptAnalyzer documentation and community sources. Key references include the Microsoft Learn docs for PSScriptAnalyzer ([Using PSScriptAnalyzer - PowerShell | Microsoft Learn](https://learn.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/using-scriptanalyzer?view=ps-modules#:~:text=The%20following%20example%20excludes%20two,other%20than%20Error%20and%20Warning)) ([Using PSScriptAnalyzer - PowerShell | Microsoft Learn](https://learn.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/using-scriptanalyzer?view=ps-modules#:~:text=Implicit)), the PSScriptAnalyzer GitHub README ([PSScriptAnalyzer/README.md at main · PowerShell/PSScriptAnalyzer · GitHub](https://github.com/PowerShell/PSScriptAnalyzer/blob/master/README.md#:~:text=PSScriptAnalyzer%20is%20a%20static%20code,suggests%20possible%20solutions%20for%20improvements)), example settings files provided by the PowerShell extension ([Where do I place the PSScriptAnalyzerSettings.psd1 file so the settings will be applied for all user accounts? : r/PowerShell](https://www.reddit.com/r/PowerShell/comments/lt5w8q/where_do_i_place_the_psscriptanalyzersettingspsd1/#:~:text=%40%7B%20,Severity%20%3D%20%40%28%27Error%27%2C%27Warning)) ([Where do I place the PSScriptAnalyzerSettings.psd1 file so the settings will be applied for all user accounts? : r/PowerShell](https://www.reddit.com/r/PowerShell/comments/lt5w8q/where_do_i_place_the_psscriptanalyzersettingspsd1/#:~:text=,ExcludeRules%20%3D%20%40%28%27PSAvoidUsingWriteHost%27%2C%27PSMissingModuleManifestField)), and community blog posts about custom rules ([Using PSScriptAnalyzer - PowerShell | Microsoft Learn](https://learn.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/using-scriptanalyzer?view=ps-modules#:~:text=%40,SqlServerDsc.AnalyzerRules.psm1%27)) and CI integration. These resources offer deeper insights and examples for those looking to further explore PSScriptAnalyzer's capabilities. Enjoy clean, robust PowerShell scripting with PSScriptAnalyzer!
