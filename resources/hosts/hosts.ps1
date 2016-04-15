Function Get-Hosts {
  [cmdletBinding(SupportsShouldProcess=$false,ConfirmImpact='Low')]
  param()
  
 Process {
    Get-content "$env:windir\System32\drivers\etc\hosts" | where {$_ -ne $null -AND $_.Length -gt 0 -AND $_ -notmatch '^#'} | Foreach-Object {
        $parts = $_.Split() | where {$_ -ne ''}
        $props = @{
            'IP' = $parts[0]
        }
        
        $lastIndex = $parts.Length - 1
        $host_aliases = @()
        $comment = ''
        
        $commentDetected = 0
        foreach ($part in $parts[1..$lastIndex]){
            if($part -notmatch '^#' -AND !$commentDetected){
                $host_aliases += $part
            }
            else{
                $commentDetected = 1
                $comment += $part + ' '
            }
        }
        
        if ($host_aliases -ne $null) {
            $props.Host_Aliases = $host_aliases
        } else {
            $props.Host_Aliases = @()
        }
        
        if ($comment -ne $null) {
            $props.Comment = $comment
        } else {
            $props.Comment = ''
        }
        
        Write-Output (New-Object -Type PSCustomObject -ArgumentList $props)
        }
    }   
}
