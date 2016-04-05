Function Get-Users {
  [cmdletBinding(SupportsShouldProcess=$false,ConfirmImpact='Low')]
  param()

  Process {
    $props = @("AccountType","Caption","Domain","SID","FullName","Name","Description")
    Get-WMIObject -Class "Win32_UserAccount" -Filter "LocalAccount=True" | Select $props
  }
}
