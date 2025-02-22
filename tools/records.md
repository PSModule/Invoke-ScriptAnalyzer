# Schemas for records used in PSScriptAnalyzer

## Schema: Get-ScriptAnalyzerRule

```plaintext
                    RuleName              : PSDSCUseVerboseMessageInDSCResource
                    CommonName            : Use verbose message in DSC resource
                    Description           : It is a best practice to emit informative, verbose messages in DSC resource functions.
                                            This helps in debugging issues when a DSC configuration is executed.
                    SourceType            : Builtin
                    SourceName            : PSDSC
                    Severity              : Information
                    ImplementingType      : Microsoft.Windows.PowerShell.ScriptAnalyzer.BuiltinRules.UseVerboseMessageInDSCResource
```

## Schema: Invoke-ScriptAnalyzer ERROR record

```plaintext
Line                  : 1
Column                : 1
Message               : The member 'ModuleVersion' is not present in the module manifest. This member must exist and be assigned a
                        version number of the form 'n.n.n.n'. Add the missing member to the file
                        ' C:\Repos\GitHub\PSModule\Action\Test-PSModule\tests\srcWithManifestTestRepo\src\manifest.psd1'.
Extent                : @{
                            Author = 'Author'
                        }
RuleName              : PSMissingModuleManifestField
Severity              : Warning
ScriptName            : manifest.psd1
ScriptPath            : C:\Repos\GitHub\PSModule\Action\Test-PSModule\tests\srcWithManifestTestRepo\src\manifest.psd1
RuleSuppressionID     :
SuggestedCorrections  : {
                    # Version number of this module.
                    ModuleVersion = '1.0.0.0'
                    }
IsSuppressed         : False
```
