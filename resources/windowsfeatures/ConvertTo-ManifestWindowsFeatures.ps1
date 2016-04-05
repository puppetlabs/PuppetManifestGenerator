Function ConvertTo-ManifestWindowsFeatures {
  [cmdletBinding(SupportsShouldProcess=$false,ConfirmImpact='Low')]
  param(
    [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [string]$JSONString
  )
  
# Name
# DisplayName
# Description

  Process {
    $manifest = "# This manifest requires the Windows Feature module`n" + `
                "# Available at https://forge.puppetlabs.com/puppet/windowsfeature`n"
    $objTree = ConvertFrom-Json -InputObject $JSONString
    
    $objTree | % {
      $thisManifest = @"
# $($_.DisplayName)
windowsfeature { '$($_.Name)':
  ensure       => 'present',
  feature_name => '$($_.Name)',
}
"@
      $manifest += "`n$thisManifest`n"
    }
    
    Write-Output $manifest
  }
}