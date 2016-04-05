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

  ls $ModulePath -file -rec | % {
    
    $module = $_

    if($Module.Name -match "Convert"){
      . $module
      $jsonString = [string](Get-Content $outputFile)
      &"ConvertTo-Manifest$($module.BaseName) -jsonString $($jsonString)"
    }else{
      [string]$content = Get-Content -Path $module.fullname -Encoding UTF8
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
      if(-not(Test-path $Path)){
        mkdir $path
      }

      $outputFile = (Join-Path $Path "$($module.BaseName).json")
      $info | ConvertTo-JSON -Depth 10 | Out-File -Force -FilePath $outputFile
    }
  }

}

Export-ModuleMember -Function Invoke-PuppetGenerator
