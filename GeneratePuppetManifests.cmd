@ECHO OFF

SETLOCAL

Powershell -NoProfile -NonInteractive -NoLogo -ExecutionPolicy Bypass -Command "Import-Module '%~dp0PuppetManifestGenerator.psm1' -ErrorAction Stop; Invoke-Generator -ErrorAction Stop;"
