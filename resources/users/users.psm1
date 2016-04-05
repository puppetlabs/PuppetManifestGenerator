Function Get-Users {
  [cmdletBinding(SupportsShouldProcess=$false,ConfirmImpact='Low')]
  param()
  
  Begin { }

  Process {
    Get-WMIObject -Class "Win32_UserAccount" -Filter "LocalAccount=True" | `
      Select AccountType,Caption,Domain,SID,FullName,Name
  }

  End { }
}

Function ConvertTo-ManifestsUsers {
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
  
  
  Begin {
    
  }
  Process {
    $manifest = ""
    $objTree = ConvertFrom-Json -InputObject $JSONString
    
    $objTree | % {
      $userManifest = "" + `
        "user { '$($_.Name)':" + `
        "  ensure => 'present'," + `
        "  comment => '$($_.Fullname)'," + `
        "}"
      # If the SID ends in -500 or -501 it's the Admin and Guest User.
      # Comment these out as they shouldn't be enforced by Puppet
      if ($_.SID.EndsWith('-500')) {
        $userManifest = "# This is the local Administrator Account`n# " + $userManifest.Replace("`n","`n# ")
      }
      if ($_.SID.EndsWith('-501')) {
        $userManifest = "# This is the local Guest Account`n# " + $userManifest.Replace("`n","`n# ")
      }

      $manifest += "`n$userManifest`n"
    }
    
    Write-Output $manifest
  }
  End {
    
  }
}