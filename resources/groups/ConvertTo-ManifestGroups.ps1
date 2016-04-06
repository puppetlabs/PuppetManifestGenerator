Function ConvertTo-ManifestGroups {
  [cmdletBinding(SupportsShouldProcess=$false,ConfirmImpact='Low')]
  param(
    [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [string]$JSONString
  )
  
      # "SID":  "S-1-5-32-545",
      #   "Description":  "Users are prevented from making accidental or intentional system-wide changes and can run most applications",
      #   "Name":  "Users",
      #   "Members":  [
      #                   "nonadmin",
      #                   "NT AUTHORITY\\Authenticated Users",
      #                   "NT AUTHORITY\\INTERACTIVE"
      #               ]
      
  Process {
    $manifest = ""
    $objTree = ConvertFrom-Json -InputObject $JSONString
    
    $objTree | % {
      $memberList = ($_.Members | % {
        Write-Output "'$($_)'"
      }) -join ', '
      
      $descriptionText = ''
      if ($_.Description -ne '') {
        $descriptionText = "# $($_.Description)`n"
      }
      
      $thisManifest = "" + `
        $descriptionText + `
        "group { '$($_.Name)':`n" + `
        "  ensure  => 'present',`n" + `
        "  members => [$($memberList)],`n" + `
        "}"
        
      if ($_.SID.StartsWith('S-1-5-32-')) {
        $thisManifest = "# This is a system group and probably shouldn't be managed by puppet`n# " + $thisManifest.Replace("`n","`n# ")        
      }

      $manifest += "`n$thisManifest`n"
    }
    
    Write-Output $manifest
  }
}








