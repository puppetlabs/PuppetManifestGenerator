Function ConvertTo-ManifestHosts {
  [cmdletBinding(SupportsShouldProcess=$false,ConfirmImpact='Low')]
  param(
    [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [string]$JSONString
  )

  Process {
    $manifest = ""
    $objTree = ConvertFrom-Json -InputObject $JSONString
    
    $objTree | % {    
        $commentText = ''
        $hostText = ''
        $ip = ''
        if ($_.Comment -ne '') {
            $commentText = "$($_.Comment)"
        }
        
        if ($_.Host_Aliases[0] -ne '') {
            $hostText = "$($_.host_aliases[0])"
        }
        
        if ($_.IP -ne '') {
            $ip = "$($_.IP)"
        }
        
        $hostManifest = "" + `
            "host { '$($hostText)':`n" + `
            "  ensure => 'present',`n" + `
            "  comment => '$($commentText)',`n" + `
            "  host_aliases => '$($_.Host_Aliases)',`n" + `
            "  ip => '$($ip)',`n" + `
            "}"

        $manifest += "`n$hostManifest`n"
    }
    
    Write-Output $manifest
  }
}
