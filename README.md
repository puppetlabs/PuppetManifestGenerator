# Windows-Blueprinter
A Blueprint style powershell module for Puppet - Windows Hackday 2016

![Image of Puppet Blueprint](http://www.cygnus-x1.net/links/lcars/blueprints/star-trek-blueprint-collection/star-trek-blueprint-collection-1-s.jpg)

## Overview
The goal of the project is to show proof of concept for discovering what can be managed on a user's Windows machine. We will demonstrate the following workflow:

1. User installs Powershell module
2. User invokes Get-PuppetResources
3. User converts returned PSObject to Puppet manifests

The plan of record is to discover and model the following 4 types of resources:
- Groups
- Windows Features
- Environment variables 
- (Services) 
- (Chocolatey)

## Background
Windows users face a steep learning curve in understanding how to use Puppet. Using familiar Windows tools to discover the resources that can be managed and showing the user how to represent these resources with Puppet makes this on-ramp less daunting.

## Assumptions
- Client machine runs Powershell v3+
- Target server machine runs Powershell v2+ 
- Generates both JSON and PP

## Constraints 
- Only generate Puppet manifests for which we have modules in the Forge or core Puppet types
- Single system (e.g. no modeling of Windows clustering)
- No de-duping of resources (e.g. may have two or more services with the same name) 

## Installation Instructions
TBD



