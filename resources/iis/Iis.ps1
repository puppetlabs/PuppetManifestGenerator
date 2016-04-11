Function Convert-ToHashTable($inputObject) {
  $thisObject = @{}

  Get-Member -InputObject $inputObject  -MemberType NoteProperty | ? { -not $_.Name.StartsWith('PS') } | % {
    $name = $_.Name
    $value = $inputObject."$name"
    
    switch ($value.GetType().ToString()) {
      # String-able types
      #   Note - This bit isn't really necessary but it helps with the debug statement in 'default'
      "System.String" { $thisObject.Add($name,$value) }
      "System.Boolean" { $thisObject.Add($name,$value.ToString()) }
      "System.Int64" { $thisObject.Add($name,$value.ToString()) }
      "System.Int32" { $thisObject.Add($name,$value.ToString()) }
      "System.TimeSpan" { $thisObject.Add($name,$value.ToString()) }
      # Recursive object types
      "Microsoft.IIs.PowerShell.Framework.ConfigurationElement" {
        $thatValue = Convert-ToHashTable($value)
        $thisObject.Add($name,$thatValue)
      }
      "System.Management.Automation.PSObject[]" {        
        $thatValue = @()
        $value | % {
          $thatValue += Convert-ToHashTable($_)
        }        
        $thisObject.Add($name,$thatValue)
      }
      default {
        # Useful for debugging
        Write-Verbose "Unknown object type '$($value.GetType().ToString())' with value '$($value.ToString())' for property called '$name'"
        
        # Default to just casting as a string
        $thisObject.Add($name,$value.ToString())
      }
    }
  }

  $thisObject
}


Function Get-Iis {
  [CmdletBinding(SupportsShouldProcess=$false, ConfirmImpact='Low')]
  param()

  Process {
    # Check if IIS Windows Features are installed
    $webServer = (Get-WindowsFeature -Name  'Web-WebServer' -ErrorAction 'SilentlyContinue'  -Verbose:$false)
    if ($webServer -eq $null) {
      Write-Verbose "IIS is not installed"
      return $null
    }
    
    try
    {
      Import-Module 'WebAdministration'  -ErrorAction 'Stop' -Verbose:$false
    }
    catch {
      Write-Verbose "IIS Powershell Cmdlets are not available"
      return $null
    }
    
    $iisConfig = @{
      'Sites' = @()
      'AppPools' = @()
    }
    
    # Websites
    Get-ChildItem -Path 'IIS:\Sites' | % {
      $thisValue = Convert-ToHashTable -InputObject $_
            
      $iisConfig.Sites += $thisValue
    } 
    
    # App Pools
    Get-ChildItem -Path 'IIS:\AppPools' | % {
      $thisValue = Convert-ToHashTable -InputObject $_
            
      $iisConfig.AppPools += $thisValue
    } 

    # TODO Parse Site object model
    #  - Figure out physical paths for all VDIRS
    #  - Foreach VDIR get the ACLs
    
    Write-Output $iisConfig    
  }
}
