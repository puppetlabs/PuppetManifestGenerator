Function New-Blueprint {
  [cmdletBinding(SupportsShouldProcess=$false,ConfirmImpact='Low')]
  param(
    [Parameter(Mandatory=$true,ValueFromPipeline=$false)]
    # Default to working directory
    [string]$Output = (Convert-Path -Path '.')
  )
  
  Begin {
  }
  
  Process {
  } 
  
  End {
  }
}