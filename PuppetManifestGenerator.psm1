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
  $Path = (Join-Path $PSScriptRoot "output")

  [IO.FileInfo]$module = Join-Path $ModulePath "resources\users\users.ps1"
  [IO.FileInfo]$manifestModule = Join-Path $ModulePath "resources\users\ConvertTo-ManifestsUsers.ps1"
  
  [string]$content = Get-Content -Path $module -Encoding UTF8
  $code = @"
  New-Module -ScriptBlock {$($content)} -Name $($module.BaseName) | Import-Module;
  $($module.BaseName);
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
  $info = Invoke-Command @CommandInfo
  
  # format manifest
  if(-not(Test-path $Path)){ mkdir $path }
  
  $outputFile = (Join-Path $Path "$($module.BaseName).json")
  $info | ConvertTo-JSON -Depth 10 | Out-File -Force -FilePath $outputFile
  
  . $manifestModule
  [string](Get-Content $outputFile) | ConvertTo-ManifestsUsers
}

Export-ModuleMember -Function *
