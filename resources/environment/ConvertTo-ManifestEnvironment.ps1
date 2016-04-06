Function ConvertTo-ManifestEnvironment {
  [cmdletBinding(SupportsShouldProcess=$false,ConfirmImpact='Low')]
  param(
    [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [string]$JSONString
  )
  
  #  {
  #       "Name":  "TEMP",
  #       "Type":  "ExpandString",
  #       "Value":  "%SystemRoot%\\TEMP"
  #   }

  Process {
    $manifest = @"
# This manifest requires the badgerious/windows_env forge module
# https://forge.puppetlabs.com/badgerious/windows_env
# Some variables listed here may be managed by other means e.g. Software Installation
 
"@
    $objTree = ConvertFrom-Json -InputObject $JSONString
    
    $objTree | % {
      if ($_.Type -eq "ExpandString") {
        $EnvType = 'REG_EXPAND_SZ'  
      } else {
        $EnvType = 'REG_SZ'
      }
      $thisManifest = @"
windows_env { '$($_.Name)':
  ensure    => present,
  variable  => '$($_.Name)',
  value     => '$($_.Value)',
  mergemode => clobber,
  type      => '$EnvType',
} 
"@
      $CommentOut = $true
      switch ($_.Name.ToUpper()) {
        "PATH" {}
        "COMSPEC" {}
        "TMP" {}
        "TEMP" {}
        "PATHEXT" {}
        "PSMODULEPATH" {}
        default { $CommentOut = $false }
      }
      
      if ($CommentOut) {
        $thisManifest = "# The $($_.Name) environment variable probably shouldn't be managed by Puppet.`n# " + $thisManifest.Replace("`n","`n# ")
      }
      # If the SID ends in -500 or -501 it's the Admin and Guest User.
      # Comment these out as they shouldn't be enforced by Puppet
      # if ($_.SID.EndsWith('-500')) {
      #   $userManifest = "# This is the local Administrator Account. This should not be managed by puppet`n# " + $userManifest.Replace("`n","`n# ")
      # }
      # if ($_.SID.EndsWith('-501')) {
      #   $userManifest = "# This is the local Guest Account. This should not be managed by puppet`n# " + $userManifest.Replace("`n","`n# ")
      # }

      $manifest += "`n$thisManifest`n"
    }
    
    Write-Output $manifest
  }
}
