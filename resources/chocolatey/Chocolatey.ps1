Function Get-Chocolatey {
  [CmdletBinding(SupportsShouldProcess=$false, ConfirmImpact='Low')]
  param()

  Process {
    $chocoInstall = $Env:ChocolateyInstall
    # Chocolatey isn't installed
    if ($chocoInstall -eq $null) { Write-Verbose "Chocolatey isn't installed"; return $null }

    $pkgList = (& Choco.exe list -lo | 
      ? { $_ -and $_ -notmatch "packages installed" }
    )
    
    $props = @{
      'ChocolateyInstall' = $chocoInstall
      'Packages' = $pkgList
    }

    Write-Output (New-Object -Type PSCustomObject -ArgumentList $props)
  }
}
