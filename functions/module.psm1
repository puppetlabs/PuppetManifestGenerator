# Import this modules functions etc.
Get-ChildItem -Path $PSScriptRoot | Unblock-File | Out-Null
Get-ChildItem -Path $PSScriptRoot\*.ps1 -Recurse | ForEach-Object {
  Write-Verbose "Importing $($_.Name)..."
  . ($_.Fullname)
}