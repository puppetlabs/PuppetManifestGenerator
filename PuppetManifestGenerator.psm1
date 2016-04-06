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
  $ModulePath = (Join-Path $PSScriptRoot "resources")
  $Path = (Join-Path $PSScriptRoot "output")
  Write-Verbose "Installed path: $($PSScriptRoot)"
  Write-Verbose "Installed path: $($ModulePath)"
  Write-Verbose "Installed path: $($path)"

  ls $ModulePath -Directory | % {
    
    [IO.FileInfo]$moduleFile = Join-Path $_.FullName "$($_.Name).ps1"
    [IO.FileInfo]$moduleManifest = Join-Path $_.FullName "ConvertTo-Manifest$($_.Name).ps1"
    
    $outputFile = (Join-Path $Path "$($moduleFile.BaseName).json")
    if(-not(Test-path $Path)){
      mkdir $path
    }

    [string]$content = Get-Content -Path $moduleFile.fullname -Encoding UTF8
    $code = @"
New-Module -ScriptBlock {$($content)} -Name $($moduleFile.BaseName) | Import-Module;
$($moduleFile.BaseName);
"@
    $sb =[ScriptBlock]::Create($code)

    # create pssession
    $sessions = New-PSSession @ConnectionInfo

    $CommandInfo = @{
      Session       = $sessions
      ThrottleLimit = 10
      ScriptBlock = $sb
    }
    # invoke command
    $info = Invoke-Command @CommandInfo

    # format manifest
    $info | ConvertTo-JSON -Depth 10 | Out-File -Force -FilePath $outputFile
    
    . $moduleManifest.fullname
    $jsonString = [string](Get-Content $outputFile)
    &"$($moduleManifest.BaseName) -jsonString $($jsonString)"
    
  }

}

Export-ModuleMember -Function Invoke-PuppetGenerator
