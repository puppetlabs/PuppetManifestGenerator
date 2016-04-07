Function ConvertTo-ManifestChocolatey {
  [cmdletBinding(SupportsShouldProcess=$false,ConfirmImpact='Low')]
  param(
    [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [string]$JSONString
  )
  
# {
#     "ChocolateyInstall":  "C:\\ProgramData\\chocolatey",
#     "Packages":  [
#                      "7zip 15.14",
#                      "7zip.commandline 15.14",
#                      "7zip.install 15.14",

  Process {
    $objTree = ConvertFrom-Json -InputObject $JSONString

    $manifest = @"
# This manifest requires the Chocolatey module from the forge https://forge.puppet.com/chocolatey/chocolatey
# Note - These installations are version pinned and do not have any optional parameters

# Install Chocolatey
class {'chocolatey':
  choco_install_location => '$($objTree.ChocolateyInstall)',
}

"@
    if ($objTree.Packages -ne $null) {
      $objTree.Packages | % {
        $thisManifest = @"
package { '$($_)':
  ensure   => 'installed',
  provider => 'chocolatey',
}
"@
        $manifest += "`n$thisManifest`n"      
      }
    }
        
    Write-Output $manifest
  }
}