Function ConvertTo-ManifestLocalGroupPolicy {
  [cmdletBinding(SupportsShouldProcess=$false,ConfirmImpact='Low')]
  param(
    [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [string]$JSONString
  )
  
# Name
# DisplayName
# Description

  Process {
    $manifest = @"
# This manifest is *** EXPERIMENTAL ***
# Module code is at https://github.com/glennsarti/spike-puppet-packer-windows/tree/master/puppet/modules/windows_group_policy

# Search Group Policies and find their registry information
# http://gpsearch.azurewebsites.net/

# GPUpdate is called whenever local group policy is updated
# windows_group_policy::gpupdate { 'GPUpdate':
# }
  
"@
    $objTree = ConvertFrom-Json -InputObject $JSONString
    
    $numPolicy = 1
    $objTree | % {
      # TODO Should change the data if it's a binary or number instead of always being a string.  Not sure if necessary
      $thisManifest = @"

# windows_group_policy::local::$($_.PolicyContext.ToLower()) { 'LocalGPO-$($numPolicy)':
#     key   => '$($_.Keyname)',
#     value => '$($_.ValueName)',
#     data  => '$($_.value)',
#     type  => '$($_.value)',
#     notify => Windows_group_policy::Gpupdate['GPUpdate'],
# }
"@
      $manifest += "$thisManifest`n"
      $numPolicy++
    }
    
    Write-Output $manifest
  }
}