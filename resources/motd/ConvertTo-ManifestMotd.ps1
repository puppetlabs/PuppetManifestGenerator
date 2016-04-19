Function ConvertTo-ManifestMotd {
  [cmdletBinding(SupportsShouldProcess=$false,ConfirmImpact='Low')]
  param(
    [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [string]$JSONString
  )
  
 

  Process {
    $manifest = @"
# This manifest requires the puppetlabs/motd forge module
# https://forge.puppet.com/puppetlabs/motd
 
"@
    $objTree = ConvertFrom-Json -InputObject $JSONString
    
    $objTree | % {
      if ($_.Type -eq "ExpandString") {
        $EnvType = 'REG_EXPAND_SZ'  
      } else {
        $EnvType = 'REG_SZ'
      }
      $thisManifest = @"
class { 'motd':
  content     => '$($_.Value)',
} 
"@
      
      $manifest += "`n$thisManifest`n"
    }
    
    Write-Output $manifest
  }
}
