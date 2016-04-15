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
