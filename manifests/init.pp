# Define mounts

define mounts (
  $source = undef,
  $dest   = undef,
  $type   = undef,
  $opts   = 'defaults',
  $dump   = 0,
  $passno = 0,
  $ensure = 'present'){

  # mounting like this only makes sense in unixoid operating systems. Stop all other
  case $::osfamily {
    'RedHat', 'Debian', 'SuSE', 'Solaris': {}
    default: { fail("Your operating system family '${::osfamily}' is not supported by this module") }
  }

  if $source == undef {
    fail('The source parameter is required.')
  }

  if $dest == undef {
    fail('The dest parameter is required.')
  }

  if $type == undef {
    fail('The type parameter is required.')
  }

  fstab { "fstab entry for ${source} to ${dest} as ${type}":
        ensure => $ensure,
        source => $source,
        dest   => $dest,
        type   => $type,
        opts   => $opts,
        dump   => $dump,
        passno => $passno,
  }

  if $type == 'nfs' {

     # set up packages and services
     case $::operatingsystem {
       redhat, centos, amazon: {

         ensure_resource('package', 'nfs-utils', {'ensure' => 'present'})
         case $::operatingsystemmajrelease {
           '6': {
             ensure_resource('package', 'rpcbind', {'ensure' => 'present'})
             ensure_resource('service', 'rpcbind', {'ensure' => 'running'})
             Package['rpcbind'] -> Service['rpcbind']
           }
           '5': {
             ensure_resource('package', 'portmap', {'ensure' => 'present'})
             ensure_resource('service', 'portmap', {'ensure' => 'running'})
             Package['portmap'] -> Service['portmap']
           }
           default: {
             alert('Unsupported version of OS')
           }
         }
       }
       'Ubuntu', 'Debian': {
         ensure_resource('package', 'nfs-common', {'ensure' => 'present'})
         ensure_resource('package', 'rpcbind', {'ensure' => 'present'})
         ensure_resource('service', 'rpcbind', {'ensure' => 'running'})
         Package['rpcbind'] -> Service['rpcbind']
       }
       default: { fail("Your OS '${::operatingsystem}' isn\'t supported by the mounts module yet.") }
     }
  }


  case $ensure {
     'present': {
       # Ensure the entire tree of the destination has been created.
       $dirtree = dirtree($dest)
       ensure_resource('file', $dirtree, {'ensure' => 'directory'})

       exec { "/bin/mount '${dest}'":
         unless  => "/bin/mount -l | /bin/grep 'on ${dest} type'",
         require => [File[$dirtree], Fstab["fstab entry for ${source} to ${dest} as ${type}"]],
       }
     }
     'absent': {
       exec { "/bin/umount '${dest}'":
         onlyif => "/bin/mount -l | /bin/grep 'on ${dest} type'",
         before => Fstab["fstab entry for ${source} to ${dest} as ${type}"],
       }

       # Note: we won't remove the directory since we don't know if it'll destroy data
       notify { "${dest} wasn't removed after being unmounted.  Please remove it manually.": }
     }
     default: { }
  }

}
