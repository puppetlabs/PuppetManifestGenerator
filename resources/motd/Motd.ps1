Function Get-Motd {
  [CmdletBinding(SupportsShouldProcess=$false, ConfirmImpact='Low')]
  param()

  Process {
    $regKey = "HKLM\Software\Microsoft\Windows\CurrentVersion\policies\system"

    $value = $null
    try {
      $key = Get-Item -Path "Registry::$regKey" -ErrorAction Stop
      $value = $key.GetValue('legalnoticetext').Trim()
      # Ignore strings that are just null char
      if ($value -eq "`0") { $value = $null }
    } catch {
      $value = $null
    }
        
    if ($value -and $value.ToString()) {
      $props = @{
        'Value' = $key.GetValue('legalnoticetext').ToString()
      }
      Write-Output (New-Object -Type PSCustomObject -ArgumentList $props)
    }
  }
}
