Function Invoke-PuppetGenerator
{
<#
.EXAMPLE
PS> Invoke-PuppetGenerator -Verbose
VERBOSE: Creating connections to target nodes
VERBOSE: Adding modules to discover
VERBOSE: Executing chocolatey on target nodes
VERBOSE: Executing environment on target nodes
VERBOSE: [localhost] Exporting environment info to json
WARNING: [localhost] Failed to convert data in environment to JSON
VERBOSE: Executing groups on target nodes
VERBOSE: [localhost] Exporting groups info to json
VERBOSE: [localhost] Parsing groups info to Puppet manifest
VERBOSE: Executing iis on target nodes
VERBOSE: Executing localgrouppolicy on target nodes
VERBOSE: [localhost] Exporting localgrouppolicy info to json
VERBOSE: [localhost] Parsing localgrouppolicy info to Puppet manifest
VERBOSE: Executing services on target nodes
VERBOSE: [localhost] Exporting services info to json
VERBOSE: [localhost] Parsing services info to Puppet manifest
VERBOSE: Executing users on target nodes
VERBOSE: [localhost] Exporting users info to json
VERBOSE: [localhost] Parsing users info to Puppet manifest
VERBOSE: Executing windowsfeatures on target nodes
VERBOSE: [localhost] Exporting windowsfeatures info to json
VERBOSE: [localhost] Parsing windowsfeatures info to Puppet manifest
#>
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$false, ValueFromPipeline=$true)]
    [string[]]$ComputerName = 'localhost',

    [AllowNull()]
    [PSCredential]$Credential = $null,

    [string]$ModulePath = (Join-Path $PSScriptRoot "resources"),

    [Alias('Output','Out')]
    [string]$OutPutPath = (Join-Path $PSScriptRoot "output")
  )

  $jsonFilePath = Join-Path $OutPutPath "json"
  $manifestFilePath = Join-Path $OutPutPath "manifest"

  if(-not(Test-path $OutPutPath)){ mkdir $OutPutPath }
  if (Test-Path($jsonFilePath)) { Remove-Item $jsonFilePath -Force -Recurse -EA SilentlyContinue }
  if(-not(Test-path $jsonFilePath)){ mkdir $jsonFilePath | Out-Null }
  if (Test-Path($manifestFilePath)) { Remove-Item $manifestFilePath -Force -Recurse -EA SilentlyContinue }
  if(-not(Test-path $manifestFilePath)){ mkdir $manifestFilePath | Out-Null }

  Write-Verbose "Creating connections to target nodes"
  $connectionInfo = $PSBoundParameters
  $connectionInfo.Remove('ModulePath') | Out-Null
  $connectionInfo.Remove('OutPutPath') | Out-Null
  $connectionInfo.ErrorAction = 'SilentlyContinue'
  $connectionInfo.ErrorVariable = '+connectionErrors'

  # TODO: Write our computers not connected to
  $sessions = New-PSSession @connectionInfo

  Write-Verbose "Adding modules to discover"
  Get-ChildItem -Path $ModulePath -Directory | % {

    [IO.FileInfo]$moduleFile     = Join-Path $_.FullName "$($_.Name).ps1"
    [IO.FileInfo]$moduleManifest = Join-Path $_.FullName "ConvertTo-Manifest$($_.Name).ps1"

    $sb = New-ScriptCommand -Name $moduleFile.BaseName -Content $content

    $CommandInfo = @{
      Session       = $sessions
      ThrottleLimit = 100
      ScriptBlock   = $sb
      ErrorAction   = 'SilentlyContinue'
      ErrorVariable = '+commandErrors'
    }

    Write-Verbose "Executing $($moduleFile.BaseName) on target nodes"
    $info = Invoke-Command @CommandInfo

    $info | Group-Object PSComputerName | % {
      $computername = $_.Name
      $groupInfo    = $_.Group
      $jsonParams   = @{
        info         = $groupInfo
        computername = $computername
        moduleName   = $moduleFile.BaseName
        OutPutPath   = $jsonFilePath
      }

      Write-Verbose "[$computername] Exporting $($moduleFile.BaseName) info to json"
      $outputFile = New-JSONOutputFile @jsonParams
      if($outputFile){
        $jsonString = [string]([IO.File]::ReadAllText($outputFile))
      }

      if($jsonString){
        $manifestParams = @{
          ModuleName   = $moduleFile.BaseName
          Module       = $moduleManifest
          jsonString   = $jsonString
          OutPutPath   = $manifestFilePath
          ComputerName = $computername
        }

        Write-Verbose "[$computername] Parsing $($moduleFile.BaseName) info to Puppet manifest"
        New-PuppetManifestFile @manifestParams
      }
    }
  }

  $sessions | Remove-PSSession

  Write-Output "Manifests are located at '$manifestFilePath'"
}

function New-PuppetManifestFile
{
  param(
    $ModuleName,
    [IO.FileInfo]$Module,
    $JsonString,
    $OutputPath,
    $computername
  )

  . $Module.FullName

  $manifestText = &"$($Module.BaseName)" -jsonString $JsonString

  if ($manifestText -eq $null -or $manifestText -eq '') {
    Write-Warning "[$computername] Content for $($Module.BaseName) was empty"
    return
  }

  $outputFile = (Join-Path $OutputPath "$computername.$($moduleName).pp")

  $utf8EncodingWithoutBom = New-Object System.Text.UTF8Encoding($false)
  if (Test-Path($outputFile)) { Remove-Item $outputFile -Force }
  [System.IO.File]::WriteAllLines($outputFile, $manifestText, $utf8EncodingWithoutBom)
}

function New-JSONOutputFile
{
  param(
    $info,
    $computername,
    $moduleName,
    $outputPath
  )

  try{
    $outputFile = (Join-Path $outputPath "$computername.$($moduleName).json")
    if (Test-Path($outputFile)) { Remove-Item $outputFile -Force }

    $info = $info | ConvertTo-JSON -Depth 10

    $info | Out-File -Force -FilePath $outputFile

    $outputFile
  }catch{
    Write-Warning "[$computername] Failed to convert data in $ModuleName to JSON"
  }
}

function New-ScriptCommand
{
  param(
    $Name,
    $content
  )

  [string]$content = [IO.File]::ReadAllText($moduleFile.fullname)
  $code = @"
New-Module -ScriptBlock {$($content)} -Name $($Name) | Import-Module;
Get-$($Name);
"@
  $sb = [ScriptBlock]::Create($code)
  $sb
}

Export-ModuleMember -Function Invoke-PuppetGenerator
