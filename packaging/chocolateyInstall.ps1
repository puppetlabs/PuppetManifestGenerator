$packageName = 'puppetmanifestgenerator' # arbitrary name for the package, used in messages

try { 
  $installDir = Join-Path (Join-Path $PSHome "Modules") "PuppetManifestGenerator"

  $sourceDir = Join-Path (Split-Path -parent $MyInvocation.MyCommand.Definition) "module"

  # Copy the folder to the powershell modules directory
  Copy-Item -Path $sourceDir -Destination $installDir -Recurse -Confirm:$false -Force -ErrorAction 'Stop' | Out-Null
  
} catch {
  throw $_ 
}
