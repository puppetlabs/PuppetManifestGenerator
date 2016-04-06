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
    
    if (-not (Test-path $moduleFile)){
    }else{
    
    if(-not(Test-path $Path)){
      mkdir $path
    }

    #[string]$content = Get-Content -Path $moduleFile.fullname -Encoding UTF8
    [string]$content = [IO.File]::ReadAllText($moduleFile.fullname)
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
      
      $info | Group-Object PSComputerName | % {
        $group = $_.Group | %{
          $computername = $_.PSComputerName
        
          # format manifest
          $outputFile = (Join-Path $Path "$computername.$($moduleFile.BaseName).json")
          $info | ConvertTo-JSON -Depth 10 | Out-File -Force -FilePath $outputFile
          
          . $moduleManifest.fullname
          $jsonString = [string]( [IO.File]::ReadAllText( $outputFile))
          if($jsonString){
            $manifestText = &"$($moduleManifest.BaseName)" -jsonString $jsonString
            $outputFile = (Join-Path $Path "$computername.$($moduleFile.BaseName).pp")
            Out-File -Force -FilePath $outputFile -InputObject $manifestText
          }
        }
        
      }
    }
  }
}

Export-ModuleMember -Function Invoke-PuppetGenerator
