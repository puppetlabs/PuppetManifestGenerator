Function Invoke-PuppetGenerator
{
  [CmdletBinding()]
  param(
    [string[]]$ComputerName = 'localhost',
    [AllowNull()]
    [PSCredential]$Credential = $null,
    [string]$ModulePath = (Join-Path $PSScriptRoot "resources"),
    [string]$OutPutPath = (Join-Path $PSScriptRoot "output")
  )

  $jsonFilePath = Join-Path $OutPutPath "json"
  $manifestFilePath = Join-Path $OutPutPath "manifest"

  if(-not(Test-path $OutPutPath)){ mkdir $OutPutPath }
  if(-not(Test-path $jsonFilePath)){ mkdir $jsonFilePath }
  if(-not(Test-path $manifestFilePath)){ mkdir $manifestFilePath }

  Write-Verbose "Creating connections to target nodes"
  $connectionInfo = $PSBoundParameters
  $connectionInfo.Remove('ModulePath') | Out-Null
  $connectionInfo.Remove('OutPutPath') | Out-Null

  $sessions = New-PSSession @connectionInfo

  Write-Verbose "Adding modules to discover"
  Get-ChildItem -Path $ModulePath -Directory | % {

    [IO.FileInfo]$moduleFile     = Join-Path $_.FullName "$($_.Name).ps1"
    [IO.FileInfo]$moduleManifest = Join-Path $_.FullName "ConvertTo-Manifest$($_.Name).ps1"

    $sb = New-ScriptCommand -Name $moduleFile.BaseName -Content $content

    $CommandInfo = @{
      Session       = $sessions
      ThrottleLimit = 10
      ScriptBlock   = $sb
    }

    Write-Verbose "Executing $($moduleFile.BaseName) on target nodes"
    $info = Invoke-Command @CommandInfo

    $info | Group-Object PSComputerName | % {
      $computername = $_.Name
      $groupInfo = $_.Group
      $jsonParams = @{
        info         = $groupInfo
        computername = $computername
        moduleName   = $moduleFile.BaseName
        OutPutPath   = $jsonFilePath
      }
      Write-Verbose "Exporting $($moduleFile.BaseName) info from $($computername) to json"
      $outputFile = New-JSONOutputFile @jsonParams
      $jsonString = [string]([IO.File]::ReadAllText($outputFile))

      if($jsonString){
        $manifestParams = @{
          ModuleName = $moduleFile.BaseName
          Module     = $moduleManifest
          jsonString = $jsonString
          OutPutPath = $manifestFilePath
        }
        Write-Verbose "Parsing $($moduleFile.BaseName) info from $($computername) to Puppet manifest"
        New-PuppetManifestFile @manifestParams
      }
    }
  }

  $sessions | Remove-PSSession
}

function New-PuppetManifestFile
{
  param($ModuleName, [IO.FileInfo]$Module, $jsonString, $OutPutPath)

  . $Module.FullName

  $manifestText = &"$($Module.BaseName)" -jsonString $jsonString

  if ($manifestText -eq $null -or $manifestText -eq '') {
    Write-Warning "Content for $($Module.BaseName) was empty"
    return
  }

  $outputFile = (Join-Path $OutputPath "$computername.$($moduleName).pp")

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
