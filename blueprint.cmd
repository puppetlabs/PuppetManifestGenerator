@ECHO OFF

SETLOCAL

RD "%~dp0blueprints" /s/q > NUL
MD "%~dp0blueprints" > NUL
Powershell -NoProfile -NonInteractive -NoLogo -ExecutionPolicy Bypass -Command "Import-Module '%~dp0functions\module.psm1' -ErrorAction Stop; New-Blueprint -Output '%~dp0blueprints' -ErrorAction Stop;"