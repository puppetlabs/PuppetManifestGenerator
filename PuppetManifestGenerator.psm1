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

##### BEGIN UI Functions
#Load Required Assemblies
Write-Verbose 'Loading WPF assemblies'
Add-Type -assemblyName PresentationFramework
Add-Type -assemblyName PresentationCore
Add-Type -assemblyName WindowsBase
Write-Verbose 'Loading Windows Forms assemblies'
Add-Type -AssemblyName System.Windows.Forms

function Get-WPFControl {
  [cmdletBinding(SupportsShouldProcess=$false,ConfirmImpact='Low')]
  param(
    [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [string]$ControlName

    ,[Parameter(Mandatory=$true,ValueFromPipeline=$false)]
    [System.Windows.Window]$Window
  )
  Process {
    Write-Output $Window.FindName($ControlName)
  }
}

function Invoke-PuppetGeneratorGUI {
  [cmdletBinding(SupportsShouldProcess=$false,ConfirmImpact='Low')]
  param (
    [String]$CSVFile = ''
  )

  Begin {
  }

  Process {
    # Load XAML from the external file
    Write-Verbose "Loading the window XAML..."
    [xml]$xaml = (Get-Content (Join-Path -Path $PSScriptRoot -ChildPath 'PuppetManifestGenerator.xaml'))

    # Build the GUI
    Write-Verbose "Parsing the window XAML..."
    $reader = (New-Object System.Xml.XmlNodeReader $xaml)
    $thisWindow = [Windows.Markup.XamlReader]::Load($reader)

    # Wire up the XAML
    Write-Verbose "Adding XAML event handlers..."
    (Get-WPFControl 'btnShowIt' -Window $thisWindow).Add_Click({
      $outputPath = (Get-WPFControl 'txtOutputPath' -Window $thisWindow).Text

      & explorer.exe $outputPath
    })
    (Get-WPFControl 'btnDoIt' -Window $thisWindow).Add_Click({
      $outputPath = (Get-WPFControl 'txtOutputPath' -Window $thisWindow).Text

      # Convert the dataset back into XML DOM Document
      $sw = New-Object -Type System.IO.StringWriter
      $dataSet.Tables[0].WriteXml($sw);
      $result = $sw.ToString()
      [xml]$targets = $result

      # Disable the window UI..
      (Get-WPFControl 'gridMain' -Window $thisWindow).IsEnabled = $false
      (Get-WPFControl 'windowMain' -Window $thisWindow).Cursor = "Wait"

      Write-Verbose "Starting the generation..."
      $targets.SelectNodes("/targets/target") | % {
        if ( ($_.username.Trim() -ne '') -and ($_.password.Trim() -ne '') ) {
          $secpasswd = ConvertTo-SecureString ($_.password) -AsPlainText -Force
          $cred = New-Object System.Management.Automation.PSCredential ($_.username, $secpasswd)
        } else {
          $cred = $null
        }

        Invoke-PuppetGenerator -ComputerName ($_.computer) -Credential $cred -OutputPath $outputPath
      }

      # Enable the window UI..
      (Get-WPFControl 'gridMain' -Window $thisWindow).IsEnabled = $true
      (Get-WPFControl 'windowMain' -Window $thisWindow).Cursor = $null
      Write-Verbose "Generation completed"
    })

    # Create XML file information
    if ($CSVFile -ne '') {
      [xml]$xmlTargets = ('<targets xmlns="" />')
      Import-CSV -Path $CSVFile | % {
        $node = $xmlTargets.CreateElement('target')
        $node.SetAttribute('computer',$_.computer)
        $node.SetAttribute('username',$_.username)
        $node.SetAttribute('password',$_.password)
        $xmlTargets.DocumentElement.AppendChild($node) | Out-Null
      }
    } else {
      [xml]$xmlTargets = ('<targets xmlns=""><target computer="localhost" username=""  password="" /></targets>')
    }

    # Convert XML into a two-way DataSet -> Table and databind it to the DataGrid
    $reader = (New-Object System.Xml.XmlNodeReader $xmlTargets)
    $dataSet = New-Object -TypeName System.Data.DataSet
    $dataSet.ReadXml($reader) | Out-Null
    (Get-WPFControl 'dataGrid' -Window $thisWindow).DataContext = $dataSet.Tables[0].DefaultView

    # Set the default output dir
    (Get-WPFControl 'txtOutputPath' -Window $thisWindow).Text = [Environment]::GetFolderPath('MyDocuments') + '\Puppet Manifest Generator'

    # Show the GUI
    Write-Verbose "Showing the window..."
    [void]($thisWindow.ShowDialog())
    Write-Verbose "Cleanup..."
    $thisWindow.Close()
    $thisWindow = $null
  }

  End {
  }
}
##### END UI Functions

Export-ModuleMember -Function "Invoke-*"
