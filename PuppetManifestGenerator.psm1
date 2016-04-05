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
  $content = Get-Content -Path $module
  $code = [ScriptBlock]::create("New-Module -ScriptBlock {$($content); Get-$($module.BaseName)} -ReturnResult;")
  
  # create pssession
  $sessions = New-PSSession @ConnectionInfo
  
  # invoke command
  $CommandInfo = @{
    Session       = $sessions
    ThrottleLimit = 10
    ScriptBlock   = $code
  }
  Invoke-Command @CommandInfo
  
  # format manifest
}

Export-ModuleMember -Function *
