Function ConvertTo-ManifestIis {
  [cmdletBinding(SupportsShouldProcess=$false,ConfirmImpact='Low')]
  param(
    [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [string]$JSONString
  )

  Process {
    $manifest = @"
# This manifest requires the puppetlabs-is module
# https://forge.puppet.com/puppet/iis

# NOT IMPLEMENTED YET 
"@
    $objTree = ConvertFrom-Json -InputObject $JSONString

    Write-Output $manifest
  }
}
