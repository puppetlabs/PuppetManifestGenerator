Function Invoke-PuppetGenerator
{
  [CmdletBinding()]
  param(
    [string[]]$Computers = 'localhost',
    [PSCredential]$Credentials,
    [string]$ModulePath = (Join-Path $PSScriptRoot "resources"),
    [string]$OutPutPath = (Join-Path $PSScriptRoot "output")
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
  if(-not(Test-path $OutPutPath)){
    mkdir $OutPutPath
  }
  
  # slurp modules
  Get-ChildItem -Path $ModulePath -Directory | % {
    
    [IO.FileInfo]$moduleFile     = Join-Path $_.FullName "$($_.Name).ps1"
    [IO.FileInfo]$moduleManifest = Join-Path $_.FullName "ConvertTo-Manifest$($_.Name).ps1"
    
    if(Test-path $moduleFile){

      $sb = New-ScriptCommand -Name $moduleFile.BaseName -Content $content

      # create pssession
      $sessions = New-PSSession @ConnectionInfo

      $CommandInfo = @{
        Session       = $sessions
        ThrottleLimit = 10
        ScriptBlock   = $sb
      }
      $info = Invoke-Command @CommandInfo
      
      $info | Group-Object PSComputerName | % {
        $group = $_.Group | %{
          $computername = $_.PSComputerName
          
          $jsonFilePath = Join-Path $OutPutPath "json"
          if(-not(Test-path $jsonFilePath)){
            mkdir $jsonFilePath
          }
          $outputFile = New-JSONOutputFile -info $info -computername $computername -moduleName $moduleFile.BaseName -OutPutPath $jsonFilePath
          $jsonString = [string]([IO.File]::ReadAllText($outputFile))
          
          if($jsonString){
            $manifestFilePath = Join-Path $OutPutPath "manifest"
            if(-not(Test-path $manifestFilePath)){
              mkdir $manifestFilePath
            }
            New-PuppetManifestFile -ModuleName $moduleFile.BaseName -Module $moduleManifest -jsonString $jsonString -OutPutPath $manifestFilePath
          }
        }
      }
      
    }
  }
}

function New-PuppetManifestFile
{
  param($ModuleName, [IO.FileInfo]$Module, $jsonString, $OutPutPath)
  
  . $Module.FullName
  
  $manifestText = &"$($Module.BaseName)" -jsonString $jsonString
  
  $outputFile = (Join-Path $OutPutPath "$computername.$($moduleName).pp")
  
  Out-File -Force -FilePath $outputFile -InputObject $manifestText
}

function New-JSONOutputFile
{
  param($info, $computername, $moduleName, $OutPutPath)
  
  $outputFile = (Join-Path $OutPutPath "$computername.$($moduleName).json")
  
  $info | ConvertTo-JSON -Depth 10 | Out-File -Force -FilePath $outputFile
  
  $outputFile
}

function New-ScriptCommand
{
  param($Name,$content)
  [string]$content = [IO.File]::ReadAllText($moduleFile.fullname)
  $code = @"
New-Module -ScriptBlock {$($content)} -Name $($Name) | Import-Module;
$($Name);
"@
  $sb = [ScriptBlock]::Create($code)
  $sb
}

Export-ModuleMember -Function Invoke-PuppetGenerator
