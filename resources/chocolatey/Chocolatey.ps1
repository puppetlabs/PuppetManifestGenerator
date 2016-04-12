Function Get-Chocolatey {
  [CmdletBinding(SupportsShouldProcess=$false, ConfirmImpact='Low')]
  param()

  Process {
    $chocoInstall = $Env:ChocolateyInstall
    # Chocolatey isn't installed
    if ($chocoInstall -eq $null) { Write-Verbose "Chocolatey isn't installed"; return $null }

    $pkgList = (& choco.exe list -lo -r | %{
      @{
        Name = $_.Split('|')[0]
        Version= $_.Split('|')[1]
      }
    })

    $props = @{
      'ChocolateyInstall' = $chocoInstall
      'Packages' = $pkgList
    }

    Write-Output (New-Object -Type PSCustomObject -ArgumentList $props)
  }
}
