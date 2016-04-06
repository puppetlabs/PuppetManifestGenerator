Function Get-Groups {
  [cmdletBinding(SupportsShouldProcess=$false,ConfirmImpact='Low')]
  param()

  Process {
    Get-WMIObject -Class "Win32_Group" -Filter "LocalAccount=True" | ForEach-Object -Process {
      $props = @{
        'SID' = $_.SID.ToString()
        'Name' = $_.Name
        'Description' = $_.Description
      }
      
      # TODO Get members of group and append to object
      $members = (NET LOCALGROUP "$($_.Name)" | 
        where {$_ -AND $_ -notmatch "command completed successfully"} | 
        select -skip 4)
      if ($members -ne $null) {
        $props.Members = $members
      } else {
        $props.Members = @()
      }
      
      Write-Output (New-Object -Type PSCustomObject -ArgumentList $props)
    }
  }
}
