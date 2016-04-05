Function Invoke-PuppetGenerator
{
  [CmdletBinding()]
  param(
    [string[]]$Computers = 'localhost',
    [PSCredential]$Credentials,
    [string]$ModulePath,
    [string]$Path
  )
  
  $ConnectionInfo = $PsBoundParameters
  $ConnectionInfo.Remove('Path') | Out-Null
  $ConnectionInfo['ErrorAction'] = 'SilentlyContinue'
  $ConnectionInfo['ErrorVariable'] = 'connectionErrors'
  
  $ManifestInfo = $PsBoundParameters
  $ManifestInfo.Remove('Computers') | Out-Null
  $ManifestInfo.Remove('Credentials') | Out-Null
  $ManifestInfo.Remove('ModulePath') | Out-Null
  $ManifestInfo.Remove('Path') | Out-Null
  
  # slurp modules
  Write-Verbose "Installed path: $($PSScriptRoot)"
  $ModulePath = $PSScriptRoot

  [IO.FileInfo]$module = Join-Path $ModulePath "resources\users\users.psm1"
  [string]$content = Get-Content -Path $module -Encoding UTF8
  $code = @"
  New-Module -ScriptBlock {$($content)} -Name $($module.BaseName) | Import-Module;
  Get-$($module.BaseName);
"@
   $sb =[ScriptBlock]::Create($code)
  
  # create pssession
  $sessions = New-PSSession @ConnectionInfo
  
  # invoke command
  $CommandInfo = @{
    Session       = $sessions
    ThrottleLimit = 10
    ScriptBlock   = $sb
  }
  Invoke-Command @CommandInfo
  
  # format manifest
}

Export-ModuleMember -Function *
