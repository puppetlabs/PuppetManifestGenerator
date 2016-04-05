Function Get-Users {
  [cmdletBinding(SupportsShouldProcess=$false,ConfirmImpact='Low')]
  param()

  Process {
    Get-WMIObject -Class "Win32_UserAccount" -Filter "LocalAccount=True" | `
      Select AccountType,Caption,Domain,SID,FullName,Name
  }
}