@ECHO OFF

SETLOCAL

RD "%~dp0blueprints" /s/q > NUL
MD "%~dp0blueprints" > NUL
Powershell -NoProfile -NonInteractive -NoLogo -ExecutionPolicy Bypass -Command "Import-Module '%~dp0PuppetManifestGenerator.psm1' -ErrorAction Stop; Invoke-Generator -ErrorAction Stop;"
