$packageName = 'puppetmanifestgenerator' # arbitrary name for the package, used in messages

try { 
  $installDir = Join-Path (Join-Path $PSHome "Modules") "PuppetManifestGenerator"

  # Remove the folder from the powershell modules directory
  if (Test-Path $installDir) {
    Remove-Item $installDir -Recurse -Confirm:$false -Force -ErrorAction 'Stop' | Out-NUll
  }
  else
  {
    Write-Debug "Installation directory doesn't exist"
  }

  Write-ChocolateySuccess "$packageName"
} catch {
  Write-ChocolateyFailure "$packageName" "$($_.Exception.Message)"
  throw 
}
