Function ConvertTo-ManifestUsers {
  [cmdletBinding(SupportsShouldProcess=$false,ConfirmImpact='Low')]
  param(
    [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [string]$JSONString
  )
  
# AccountType : 512
# Caption     : WIN-EDSON23CGLF\Administrator
# Domain      : WIN-EDSON23CGLF
# SID         : S-1-5-21-2403692303-2757309524-139230436-500
# FullName    :
# Name        : Administrator  

  Process {
    $manifest = ""
    $objTree = ConvertFrom-Json -InputObject $JSONString
    
    $objTree | % {
      $userManifest = "" + `
        "user { '$($_.Name)':`n" + `
        "  ensure => 'present',`n" + `
        "  comment => '$($_.Description)',`n" + `
        "}"
      # If the SID ends in -500 or -501 it's the Admin and Guest User.
      # Comment these out as they shouldn't be enforced by Puppet
      if ($_.SID.EndsWith('-500')) {
        $userManifest = "# This is the local Administrator Account. This should not be managed by puppet`n# " + $userManifest.Replace("`n","`n# ")
      }
      if ($_.SID.EndsWith('-501')) {
        $userManifest = "# This is the local Guest Account. This should not be managed by puppet`n# " + $userManifest.Replace("`n","`n# ")
      }

      $manifest += "`n$userManifest`n"
    }
    
    Write-Output $manifest
  }
}
