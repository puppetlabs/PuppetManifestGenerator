Function Convert-ObjTreeToHash($objTree, $ignore = @(), $prefix = '') {
  $kv = @{}
  
  if (!$prefix.EndsWith('_') -and ($prefix -ne '')) { $prefix += '_' }

  $objTree | Get-Member -MemberType NoteProperty | ? { -not($ignore -contains $_.Name) } | % {
    $name = $_.Name
    $value = $objTree."$($_.Name)"
    
    switch ($value.GetType().ToString()) {
      'System.String' {
        $kv.Add($prefix + $name.ToLower(),$value)
      }
      'System.Management.Automation.PSCustomObject' {
        $thatHash = Convert-ObjTreeToHash -ObjTree $value -Ignore $ignore -Prefix ($prefix + $name.ToLower())
        $thatHash.GetEnumerator() | % {
          $kv.Add($_.Name,$_.Value)
        }      
      }
      default {
        throw "THROW YOUR HANDS UP IN THE AIR. AND WAVE THEM LIKE YOU JUST DON'T CARE! Prefix=$prefix Name=$name $($value.GetType().ToString()) "
      }
    }    
  }
  Write-Output $kv
}

Function ConvertTo-ManifestIis {
  [cmdletBinding(SupportsShouldProcess=$false,ConfirmImpact='Low')]
  param(
    [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [string]$JSONString
  )

  Process {
    $manifest = @"
# This manifest requires the simondean-iis module
# https://forge.puppet.com/simondean/iis


"@
    $objTree = ConvertFrom-Json -InputObject $JSONString
    
    
    # App Pools   
    $width = 40
    $objTree.AppPools | % {
      $appPool = $_

      $thisManifest = @"
iis_apppool { '$($appPool.Name)':
  ensure                                   => 'present',

"@

      $objTreeKV = Convert-ObjTreeToHash -objTree $appPool -Ignore 'ItemXPath','Name','Collection'
      'autostart',
      'clrconfigfile',
      'cpu_action',
      'cpu_limit',
      'cpu_resetinterval',
      'cpu_smpaffinitized',
      'cpu_smpprocessoraffinitymask',
      'cpu_smpprocessoraffinitymask2',
      'enable32bitapponwin64',
      'enableconfigurationoverride',
      'failure_autoshutdownexe',
      'failure_autoshutdownparams',
      'failure_loadbalancercapabilities',
      'failure_orphanactionexe',
      'failure_orphanactionparams',
      'failure_orphanworkerprocess',
      'failure_rapidfailprotection',
      'failure_rapidfailprotectioninterval',
      'failure_rapidfailprotectionmaxcrashes',
      'managedpipelinemode',
      'managedruntimeloader',
      'managedruntimeversion',
      'passanonymoustoken',
      'processmodel_identitytype',
      'processmodel_idletimeout',
      'processmodel_loaduserprofile',
      'processmodel_logontype',
      'processmodel_manualgroupmembership',
      'processmodel_maxprocesses',
      'processmodel_password',
      'processmodel_pingingenabled',
      'processmodel_pinginterval',
      'processmodel_pingresponsetime',
      'processmodel_setprofileenvironment',
      'processmodel_shutdowntimelimit',
      'processmodel_startuptimelimit',
      'processmodel_username',
      'queuelength',
      'recycling_disallowoverlappingrotation',
      'recycling_disallowrotationonconfigchange',
      'recycling_logeventonrecycle',
      'recycling_periodicrestart_memory',
      'recycling_periodicrestart_privatememory',
      'recycling_periodicrestart_requests',
      'recycling_periodicrestart_time',
      'startmode' |  % {
        [string]$value = $objTreeKV."$_"
        if ($value -ne '') {
          $thisManifest += "  " + ("{0,-$width}" -f $_) + " => '$value'`n"
        }
      }
      $thisManifest += "# recycling_periodicrestart_memory            # TODO`n"
      $thisManifest += "# recycling_periodicrestart_privatememory     # TODO`n"
      $thisManifest += "# recycling_periodicrestart_requests          # TODO`n"
      $thisManifest += "# recycling_periodicrestart_time              # TODO`n"
      
      $thisManifest += "}`n"
      
      $manifest += "`n$($thisManifest)`n"
    }
    # IIS Site   
    $width = 76
    $objTree.Sites | % {
      $thisSite = $_

      $thisManifest = @"
iis_site { '$($thisSite.Name)':
  ensure                                                                       => 'present',

"@

      $objTreeKV = Convert-ObjTreeToHash -objTree $thisSite -Ignore 'ItemXPath','Name','Collection'
      'applicationdefaults_applicationpool',
      'applicationdefaults_enabledprotocols',
      'applicationdefaults_path',
      'applicationdefaults_serviceautostartenabled',
      'applicationdefaults_serviceautostartprovider',
      'ftpserver_allowutf8',
      'ftpserver_connections_controlchanneltimeout',
      'ftpserver_connections_datachanneltimeout',
      'ftpserver_connections_disablesocketpooling',
      'ftpserver_connections_maxbandwidth',
      'ftpserver_connections_maxconnections',
      'ftpserver_connections_minbytespersecond',
      'ftpserver_connections_resetonmaxconnections',
      'ftpserver_connections_serverlistenbacklog',
      'ftpserver_connections_unauthenticatedtimeout',
      'ftpserver_directorybrowse_showflags',
      'ftpserver_directorybrowse_virtualdirectorytimeout',
      'ftpserver_filehandling_allowreaduploadsinprogress',
      'ftpserver_filehandling_allowreplaceonrename',
      'ftpserver_filehandling_keeppartialuploads',
      'ftpserver_firewallsupport_externalip4address',
      'ftpserver_logfile_directory',
      'ftpserver_logfile_enabled',
      'ftpserver_logfile_localtimerollover',
      'ftpserver_logfile_logextfileflags',
      'ftpserver_logfile_period',
      'ftpserver_logfile_selectivelogging',
      'ftpserver_logfile_truncatesize',
      'ftpserver_messages_allowlocaldetailederrors',
      'ftpserver_messages_bannermessage',
      'ftpserver_messages_exitmessage',
      'ftpserver_messages_expandvariables',
      'ftpserver_messages_greetingmessage',
      'ftpserver_messages_maxclientsmessage',
      'ftpserver_messages_suppressdefaultbanner',
      'ftpserver_security_authentication_anonymousauthentication_defaultlogondomain',
      'ftpserver_security_authentication_anonymousauthentication_enabled',
      'ftpserver_security_authentication_anonymousauthentication_logonmethod',
      'ftpserver_security_authentication_anonymousauthentication_password',
      'ftpserver_security_authentication_anonymousauthentication_username',
      'ftpserver_security_authentication_basicauthentication_defaultlogondomain',
      'ftpserver_security_authentication_basicauthentication_enabled',
      'ftpserver_security_authentication_basicauthentication_logonmethod',
      'ftpserver_security_authentication_clientcertauthentication_enabled',
      'ftpserver_security_commandfiltering_allowunlisted',
      'ftpserver_security_commandfiltering_maxcommandline',
      'ftpserver_security_datachannelsecurity_matchclientaddressforpasv',
      'ftpserver_security_datachannelsecurity_matchclientaddressforport',
      'ftpserver_security_ssl_controlchannelpolicy',
      'ftpserver_security_ssl_datachannelpolicy',
      'ftpserver_security_ssl_servercerthash',
      'ftpserver_security_ssl_servercertstorename',
      'ftpserver_security_ssl_ssl128',
      'ftpserver_security_sslclientcertificates_clientcertificatepolicy',
      'ftpserver_security_sslclientcertificates_revocationfreshnesstime',
      'ftpserver_security_sslclientcertificates_revocationurlretrievaltimeout',
      'ftpserver_security_sslclientcertificates_useactivedirectorymapping',
      'ftpserver_security_sslclientcertificates_validationflags',
      'ftpserver_serverautostart',
      'ftpserver_userisolation_activedirectory_adcacherefresh',
      'ftpserver_userisolation_activedirectory_adpassword',
      'ftpserver_userisolation_activedirectory_adusername',
      'ftpserver_userisolation_mode',
      'id',
      'limits_connectiontimeout',
      'limits_maxbandwidth',
      'limits_maxconnections',
      'logfile_customlogpluginclsid',
      'logfile_directory',
      'logfile_enabled',
      'logfile_localtimerollover',
      'logfile_logextfileflags',
      'logfile_logformat',
      'logfile_period',
      'logfile_truncatesize',
      'serverautostart',
      'tracefailedrequestslogging_customactionsenabled',
      'tracefailedrequestslogging_directory',
      'tracefailedrequestslogging_enabled',
      'tracefailedrequestslogging_maxlogfiles',
      'tracefailedrequestslogging_maxlogfilesizekb',
      'virtualdirectorydefaults_allowsubdirconfig',
      'virtualdirectorydefaults_logonmethod',
      'virtualdirectorydefaults_password',
      'virtualdirectorydefaults_path',
      'virtualdirectorydefaults_physicalpath',
      'virtualdirectorydefaults_username' | % {
        [string]$value = $objTreeKV."$_"
        if ($value -ne '') {
          if ($_ -eq 'id') {
            $thisManifest += "# This shouldn't be managed by Puppet`n# " + ("{0,-$width}" -f $_) + " => '$value'`n"            
          } else {
            $thisManifest += "  " + ("{0,-$width}" -f $_) + " => '$value'`n"            
          }                   
        }
      }
      
      $bindings = ($thisSite.bindings.Collection | % { "'$($_.protocol)/$($_.bindingInformation)'" }) -join ', '
      $thisManifest += "  " + ("{0,-$width}" -f 'bindings') + " => [$bindings]`n"
      
      # Comment out FTP settings if it's not FTP
      if ($bindings -notlike '*ftp*') {
        $thisManifest = "# This site does not have FTP enabled`n" + $thisManifest.Replace("  ftpserver_", "# ftpserver_")        
      }

      # Add Require
      $thisManifest += "  " + ("{0,-$width}" -f 'require') + " => Iis_apppool['$($thisSite.Collection[0].applicationPool)']`n"
      
      $thisManifest += "}`n"

      $manifest += "`n$($thisManifest)`n" 
    }


    # IIS App   
    $width = 42
    $objTree.Sites | % {
      $thisSite = $_
      
      $thisSite.Collection | % {
        $thisApp = $_

        $thisManifest = @"
iis_app { '$($thisSite.Name)$($thisApp.path)':
  ensure                                     => 'present',

"@

        $objTreeKV = Convert-ObjTreeToHash -objTree $_ -Ignore 'ItemXPath','Name','Collection'
        'applicationpool',
        'enabledprotocols',
        'serviceautostartenabled',
        'serviceautostartprovider',
        'virtualdirectorydefaults_allowsubdirconfig',
        'virtualdirectorydefaults_logonmethod',
        'virtualdirectorydefaults_password',
        'virtualdirectorydefaults_path',
        'virtualdirectorydefaults_physicalpath',
        'virtualdirectorydefaults_username' | % {
          [string]$value = $objTreeKV."$_"
          if ($value -ne '') {
            if ($_ -eq 'id') {
              $thisManifest += "# This shouldn't be managed by Puppet`n# " + ("{0,-$width}" -f $_) + " => '$value'`n"            
            } else {
              $thisManifest += "  " + ("{0,-$width}" -f $_) + " => '$value'`n"            
            }                   
          }        
        }

        # Add Require
        $thisManifest += "  " + ("{0,-$width}" -f 'require') + " => [ Iis_apppool['$($thisApp.applicationPool)'], Iis_site['$($thisSite.Name)'] ]`n"

        $thisManifest += "}`n"

        $manifest += "`n$($thisManifest)`n" 
      }
    }

    # IIS Virtual Directories 
    $width = 17
    $objTree.Sites | % {
      $thisSite = $_
      
      $thisSite.Collection | % {
        $thisApp = $_
        
        $appName = $thisSite.Name + $thisApp.path
        
        $thisApp.Collection | % {
          $thisVdir = $_
        
          $vdirname = $thisSite.Name + $thisApp.path
          if ($vdirname.EndsWith('/')) { $vdirname = $vdirname.SubString(0,$vdirname.Length - 1) }
          $vdirname += $thisVdir.Path
          if (-not $vdirname.EndsWith('/')) { $vdirname += '/' }
        
          $thisManifest = @"
# Physical path must be a Windows style path
iis_vdir { '$($vdirname)':
  ensure            => present,

"@

          $objTreeKV = Convert-ObjTreeToHash -objTree $_ -Ignore 'ItemXPath','Name','Collection'
          'allowsubdirconfig',
          'logonmethod',
          'password',
          'physicalpath',
          'username' | % {
            [string]$value = $objTreeKV."$_"
            if ($value -ne '') {
              if ($_ -eq 'physicalpath') {
                $thisManifest += "  " + ("{0,-$width}" -f $_) + " => '$($value.Replace('\','\\'))'`n"            
              } else {
                $thisManifest += "  " + ("{0,-$width}" -f $_) + " => '$value'`n"            
              }                   
            }        
          }

          # Add Require
          $thisManifest += "  " + ("{0,-$width}" -f 'require') + " => [ Iis_app['$($appName)'], File['$($thisVdir.physicalpath.Replace('\','/'))'] ]`n"

          $thisManifest += "}`n"

          $manifest += "`n$($thisManifest)`n" 
        }
      }
    }


    # File system 
    $width = 17
    $objTree.Sites | % {
      $thisSite = $_
      
      $thisSite.Collection | % {
        $thisApp = $_
        
        $thisApp.Collection | % {
          $thisVdir = $_

          $thisManifest = @"
File { '$($thisVdir.physicalpath.Replace('\','/'))':
  ensure => directory,
}

# TODO ACLs
# acl { '$($thisVdir.physicalpath.Replace('\','/'))':
#  
#}
"@

          $manifest += "`n$($thisManifest)`n" 
        }
      }
    }


    Write-Output $manifest
  }
}
