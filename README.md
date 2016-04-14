# Puppet Manifest Generator for Windows

A Blueprint style powershell module for Puppet - Windows Hackday 2016

![Image of Puppet Manifest Generator](https://github.com/puppetlabs/PuppetManifestGenerator/blob/master/img/enterprise.png)

## Overview

The goal of the project is to show proof of concept for discovering what can be managed on a user's Windows machine. We will demonstrate the following workflow:

1. User installs Powershell module
2. User invokes Invoke-PuppetGenerator
3. User converts returned PSObject to Puppet manifests

The plan of record is to discover and model the following types of resources:

- Groups
- Windows Features
- Environment variables
- Services
- Chocolatey Packages
- Local Group Policy
- Users
- IIS Configuration
- Message of the Day (MOTD)

## Background

Windows users face a steep learning curve in understanding how to use Puppet. Using familiar Windows tools to discover the resources that can be managed and showing the user how to represent these resources with Puppet makes this on-ramp less daunting.

For more details on the project:
https://docs.google.com/document/d/1ix4fwg3yi2z4BUV5EQ2wPhVyeiyZMm2VoCJIxwRZpC0/edit

## Assumptions

- Client machine runs Powershell v3+
- Target server machine runs Powershell v2+
- Generates both JSON and PP

## Constraints

- No Puppet software needed
- Only generate Puppet manifests for which we have modules in the Forge or core Puppet types
- Single system (e.g. no modeling of Windows clustering)
- No de-duping of resources (e.g. may have two or more services with the same name)

## Installation Instructions

This will execute the generator on your local computer and output the results to `output\json` and `output\manifest`

~~~
[PS] > git clone https://github.com/puppetlabs/PuppetManifestGenerator
[PS] > cd PuppetManifestGenerator
[PS] > Import-Module ./PuppetManifestGenerator.psm1 -Force -Verbose
[PS] > Invoke-PuppetGenerator -Verbose
~~~

You can use `Get-Help` for detailed information

### Common Parameters

#### ComputerName

Array of computer names to query e.g.
~~~
Invoke-PuppetGenerator -ComputerName 'host-01','host-02','host-03'-Verbose
~~~
~~~
'host-01','host-02','host-03' | Invoke-PuppetGenerator  -Verbose
~~~

#### OutputPath

Folder where to output the results to.  The default is the `<module root>\output`
~~~
Invoke-PuppetGenerator -Output "$($ENV:UserProfile)\PMG\Output" -Verbose
~~~


## Packaging Instructions

Note - Requires chocolatey (choco.exe) be in the search path

From a command prompt or Powershell console window run `packaging\build.bat`

This will create a chocolatey package in `packaging\output`
