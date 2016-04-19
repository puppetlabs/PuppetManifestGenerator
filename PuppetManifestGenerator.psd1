#
# Module manifest for module 'PuppetManifestGenerator'
#
# Generated by: James Pogran
#
# Generated on: 4/15/2016
#

@{
  RootModule             = 'PuppetManifestGenerator.psm1'
  ModuleVersion          = '0.1.0'
  GUID                   = '7fa3386a-ccc2-47d8-bfac-9bcd8f036dc7'
  Author                 = 'James Pogran, Glenn Sarti, Roby Reynolds, Eric Banks'
  CompanyName            = 'Puppet'
  Copyright              = '(c) 2016 Puppet. All rights reserved.'
  Description            = 'Generate Puppet manifests from existing infrastructure without installing any software'
  PowerShellVersion      = '2.0'
  # DotNetFrameworkVersion = ''
  # CLRVersion             = ''
  # RequiredModules        = @()
  # RequiredAssemblies     = @()
  # ScriptsToProcess       = @()
  # TypesToProcess         = @()
  # FormatsToProcess       = @()
  NestedModules          = @('PuppetManifestGeneratorGUI')
  FunctionsToExport      = '*'
  CmdletsToExport        = '*'
  VariablesToExport      = '*'
  AliasesToExport        = '*'
}
