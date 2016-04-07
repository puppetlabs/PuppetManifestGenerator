Function ConvertTo-ManifestServices {
  [cmdletBinding(SupportsShouldProcess=$false,ConfirmImpact='Low')]
  param(
    [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [string]$JSONString
  )
  
    # {
    #     "PathName":  "C:\\Windows\\system32\\svchost.exe -k LocalSystemNetworkRestricted",
    #     "ImageInfo":  {
    #                       "Comments":  "",
    #                       "CompanyName":  "Microsoft Corporation",
    #                       "FileBuildPart":  9600,
    #                       "FileDescription":  "Host Process for Windows Services",
    #                       "FileMajorPart":  6,
    #                       "FileMinorPart":  3,
    #                       "FileName":  "C:\\Windows\\system32\\svchost.exe",
    #                       "FilePrivatePart":  17415,
    #                       "FileVersion":  "6.3.9600.16384 (winblue_rtm.130821-1623)",
    #                       "InternalName":  "svchost.exe",
    #                       "IsDebug":  false,
    #                       "IsPatched":  false,
    #                       "IsPrivateBuild":  false,
    #                       "IsPreRelease":  false,
    #                       "IsSpecialBuild":  false,
    #                       "Language":  "English (United States)",
    #                       "LegalCopyright":  "© Microsoft Corporation. All rights reserved.",
    #                       "LegalTrademarks":  "",
    #                       "OriginalFilename":  "svchost.exe.mui",
    #                       "PrivateBuild":  "",
    #                       "ProductBuildPart":  9600,
    #                       "ProductMajorPart":  6,
    #                       "ProductMinorPart":  3,
    #                       "ProductName":  "Microsoft® Windows® Operating System",
    #                       "ProductPrivatePart":  17415,
    #                       "ProductVersion":  "6.3.9600.16384",
    #                       "SpecialBuild":  ""
    #                   },
    #     "StartMode":  "Manual",
    #     "State":  "Stopped",
    #     "ImageBinary":  "C:\\Windows\\system32\\svchost.exe",
    #     "DisplayName":  "Windows Driver Foundation - User-mode Driver Framework",
    #     "Name":  "wudfsvc",
    #     "Description":  "Creates and manages user-mode driver processes. This service cannot be stopped.",

    #     "ServiceType":  "Share Process"
    # }

  Process {
    $manifest = @"
# The native Puppet service resource is not able to set Delayed Start or Trigger Start services
# For more advanced support try forge modules for windows services https://forge.puppetlabs.com/modules?q=windows+service

"@
    $objTree = ConvertFrom-Json -InputObject $JSONString

    $objTree | % {
      if ($_.State -eq 'Running') {
        $ensure = 'running'
      } else {
        $ensure = 'stopped'
      }
      $manifestEnable = 'false'
      switch ($_.StartMode) {
        "Manual" { $manifestEnable = 'manual' }
        "Auto"   { $manifestEnable = 'true' }
      } 
      
      $thisManifest = @"
# $($_.DisplayName)
# Service Executable $($_.ImageBinary)
service { '$($_.Name)':
  ensure => '$($ensure)',
  enable => '$($manifestEnable)',
}
"@
      # Try and determin if the this resource should be commented out
      if ($_.ImageInfo -ne $null) {
        if ( ($_.ImageInfo.CompanyName -eq 'Microsoft Corporation') -and ($_.ImageInfo.FileName -like '*\Windows*') ) {
          $thisManifest = "# This is a system service and probably shouldn't be managed by puppet`n# " + $thisManifest.Replace("`n","`n# ")
        }
      }

      $manifest += "`n$thisManifest`n"
    }
    
    Write-Output $manifest
  }
}