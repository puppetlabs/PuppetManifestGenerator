Function Get-WindowsFeatures {
  [cmdletBinding(SupportsShouldProcess=$false,ConfirmImpact='Low')]
  param()

  Process {
    $props = @('Name','DisplayName','Description')
    Get-WindowsFeature | ? { $_.Installed } | Select $props
  }
}