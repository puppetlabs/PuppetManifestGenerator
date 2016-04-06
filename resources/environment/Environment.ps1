Function Get-Environment {
  [cmdletBinding(SupportsShouldProcess=$false,ConfirmImpact='Low')]
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
          $rv = 1 | Select-Object -Property Name, Type, Value
          $rv.Name = $name
          $rv.Type = $key.GetValueKind($name).ToString()
          $rv.Value = $key.GetValue($name,$null,'DoNotExpandEnvironmentNames')
          $rv
        }
      }
    }
  }
}
