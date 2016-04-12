Function Get-Environment {
  [CmdletBinding(SupportsShouldProcess=$false, ConfirmImpact='Low')]
  param()

  Process {
    $regKey = "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment"

    $key = Get-Item -Path "Registry::$regKey"
    $key.GetValueNames() | % {
      $name = $_
      switch ($_.ToUpper()) {
        # Ignore these
        "FP_NO_HOST_CHECK" {}
        "NUMBER_OF_PROCESSORS" {}
        "OS" {}
        "PROCESSOR_ARCHITECTURE" {}
        "PROCESSOR_LEVEL" {}
        "PROCESSOR_REVISION" {}
        "PROCESSOR_IDENTIFIER" {}
        "WINDIR" {}
        # Export these
        default {
          $props = @{
            'Name' = $name
            'Type' = $key.GetValueKind($name).ToString()
            'Value' = $key.GetValue($name, $null, 'DoNotExpandEnvironmentNames').ToString()
          }

          Write-Output (New-Object -Type PSCustomObject -ArgumentList $props)
        }
      }
    }
  }
}
