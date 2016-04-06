Function Get-Services {
  [cmdletBinding(SupportsShouldProcess=$false,ConfirmImpact='Low')]
  param()

  Process {

# PSComputerName          : WIN-EDSON23CGLF
# Name                    : wudfsvc
# Status                  : OK
# ExitCode                : 1077
# DesktopInteract         : False
# ErrorControl            : Normal
# PathName                : C:\Windows\system32\svchost.exe -k LocalSystemNetworkRestricted
# ServiceType             : Share Process
# StartMode               : Manual
# __GENUS                 : 2
# __CLASS                 : Win32_Service
# __SUPERCLASS            : Win32_BaseService
# __DYNASTY               : CIM_ManagedSystemElement
# __RELPATH               : Win32_Service.Name="wudfsvc"
# __PROPERTY_COUNT        : 25
# __DERIVATION            : {Win32_BaseService, CIM_Service, CIM_LogicalElement, CIM_ManagedSystemElement}
# __SERVER                : WIN-EDSON23CGLF
# __NAMESPACE             : root\cimv2
# __PATH                  : \\WIN-EDSON23CGLF\root\cimv2:Win32_Service.Name="wudfsvc"
# AcceptPause             : False
# AcceptStop              : False
# Caption                 : Windows Driver Foundation - User-mode Driver Framework
# CheckPoint              : 0
# CreationClassName       : Win32_Service
# Description             : Creates and manages user-mode driver processes. This service cannot be stopped. DisplayName             : Windows Driver Foundation - User-mode Driver Framework
# InstallDate             :
# ProcessId               : 0
# ServiceSpecificExitCode : 0
# Started                 : False
# StartName               : LocalSystem
# State                   : Stopped
# SystemCreationClassName : Win32_ComputerSystem
# SystemName              : WIN-EDSON23CGLF
# TagId                   : 0
# WaitHint                : 0
# Scope                   : System.Management.ManagementScope
# Path                    : \\WIN-EDSON23CGLF\root\cimv2:Win32_Service.Name="wudfsvc"
# Options                 : System.Management.ObjectGetOptions
# ClassPath               : \\WIN-EDSON23CGLF\root\cimv2:Win32_Service
# Properties              : {AcceptPause, AcceptStop, Caption, CheckPoint...}
# SystemProperties        : {__GENUS, __CLASS, __SUPERCLASS, __DYNASTY...}
# Qualifiers              : {dynamic, Locale, provider, UUID}
# Site                    :
# Container               :

    Get-WMIObject -Class "Win32_Service" | % {
      $props = @{
        'Name' = $_.Name
        'Description' = $_.Description
        'DisplayName' = $_.DisplayName
        'ServiceType' = $_.ServiceType
        'StartMode' = $_.StartMode
        'PathName' = $_.PathName
        'State' = $_.State
      }
      
      # Try and find the executable that it's using
      $imageBinary = $_.PathName
      if ($matches -ne $null) { $matches.Clear() }
      $regex = '^"([^"]+)|^([^\s]+)'
      if ($imageBinary -match $regex) {
        if ($matches[2] -eq $null) { $binPath = $matches[1] } else { $binPath = $matches[2] }
        $props.ImageBinary = $binPath
        if (Test-Path -Path $binPath -ErrorAction SilentlyContinue) {
          $fileInfo = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($binPath)
          
          $props.ImageInfo = $fileInfo
        } else {
          # Couldn't find the image binary :sadpanda:
          $props.ImageInfo = @{}
        }
      } else {
        # Couldn't extract the binary path :sadpanda:
        $props.ImageBinary = ''
        $props.ImageInfo = @{}
      }
            
      Write-Output (New-Object -Type PSCustomObject -ArgumentList $props)
    }
  }
}
