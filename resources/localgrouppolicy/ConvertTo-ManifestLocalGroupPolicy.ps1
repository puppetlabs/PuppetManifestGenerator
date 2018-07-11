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
# Module code is at https://github.com/puppetlabs/puppetlabs-registry
# Requires RegUser.rb and UserSids.rb to do user code portion (and turn it into a loop)

# Search Group Policies and find their registry information
# http://gpsearch.azurewebsites.net/
# }

"@
    $objTree = ConvertFrom-Json -InputObject $JSONString

    $numPolicy = 1
        $objTree | % {
            If($($_.ValueType) -match "REG_SZ"){$type='string'}Else{$type='dword'}
            If ($($_.PolicyContext.ToLower()) -match "machine") {
                $thisManifest = @"

# registry::value { 'LocalGPO-$($numPolicy)':
#     key   => 'HKLM\$($_.Keyname)',
#     value => '$($_.ValueName)',
#     data  => '$($_.value)',
#     type  => '$($type)',
# }
"@
            }
            Else {
                $userkey = ('HKU\${sids}\' + $($_.Keyname)).Replace('\', '\\')
                $thisManifest = @"

# registry::value { 'LocalGPO-$($numPolicy)':
#     key   => '$userkey',
#     value => '$($_.ValueName)',
#     data  => '$($_.value)',
#     type  => '$($type)',
# }
"@
            }
            $manifest += "$thisManifest`n"
            $numPolicy++
        }

    Write-Output $manifest
  }
}
