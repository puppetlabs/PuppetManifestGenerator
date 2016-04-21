@ECHO OFF

SETLOCAL

SET RootDir=%~dp0..
SET WorkDir=%~dp0working
SET ThisDir=%~dp0.
SET OutputDir=%~dp0output


ECHO Cleaning working directory...
IF EXIST "%WorkDir%" (
  RD "%WorkDir%" /s /q > NUL
)
MD "%WorkDir%" > NUL
IF EXIST "%OutputDir%" (
  RD "%OutputDir%" /s /q > NUL
)
MD "%OutputDir%" > NUL


ECHO Creating working files
MD "%WorkDir%\tools\module"

REM Package spec
COPY "%ThisDir%\Package.nuspec" "%WorkDir%" > NUL

REM Chocolatey install and uninstall files
Copy "%ThisDir%\chocolatey*.ps1" "%WorkDir%\tools" > NUL

REM Powershell module
COPY "%RootDir%\PuppetManifestGenerator*.*" "%WorkDir%\tools\module" > NUL
XCOPY "%RootDir%\resources" "%WorkDir%\tools\module\resources" /s /e /c /i /v /y > NUL


ECHO Creating chocolatey package....
PUSHD "%OutputDir%"
choco pack "%WorkDir%\Package.nuspec" %*
POPD