Function Get-Motd {
  [CmdletBinding(SupportsShouldProcess=$false, ConfirmImpact='Low')]
  param()

  Process {
    $regKey = "HKLM\Software\Microsoft\Windows\CurrentVersion\policies\system"

    $key = Get-Item -Path "Registry::$regKey"
    if($key.GetValue('legalnoticetext').ToString()){
            $props = @{
                'Value' = $key.GetValue('legalnoticetext').ToString()
                }
             Write-Output (New-Object -Type PSCustomObject -ArgumentList $props)
        }
    }
  }

