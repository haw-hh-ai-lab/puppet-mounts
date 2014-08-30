# Define mounts

define mounts (
  $source = undef,
  $dest   = undef,
  $type   = undef,
  $opts   = 'defaults',
  $dump   = 0,
  $passno = 0,
  $ensure = 'present',
  $mkdir  = true){

  if $source == undef {
    err('The source parameter is required.')
  }

  if $dest == undef {
    err('The dest parameter is required.')
  }

  if $type == undef {
    err('The type parameter is required.')
  }

  fstab { "fstab entry for ${source} to ${dest} as ${type}":
    ensure => $ensure,
    source => $source,
    dest   => "$dest",
    type   => $type,
    opts   => $opts,
    dump   => $dump,
    passno => $passno,
  }
  $fstab = Fstab["fstab entry for ${source} to ${dest} as ${type}"]

  case $::operatingsystem {
    redhat, centos, amazon: {
      if $type == 'nfs' {
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
    }
    debian, ubuntu: {
      if $type == 'nfs' {
        ensure_resource('package', 'nfs-common', {'ensure' => 'present'})
      }
    }
    default: { err('Your OS isn\'t supported by the mounts module yet.') }
  }

  case $ensure {
    'present': {
      # Ensure the entire tree of the destination has been created.
      $dirtree = dirtree($dest)
      if $mkdir {
        ensure_resource('file', $dirtree, {'ensure' => 'directory'})
      }
      
      $auto = $opts ? { /(^|,)noauto($|,)/ => false, default => true }
      if $auto {
        exec { "/bin/mount '${dest}'":
          unless  => "/bin/mount -l | /bin/grep '${dest}'",
          require => [File[$dirtree], $fstab],
        }
      }
    }
    'absent': {
      exec { "/bin/umount '${dest}'":
        onlyif => "/bin/mount -l | /bin/grep '${dest}'",
        before => Fstab["fstab entry for ${source} to ${dest} as ${type}"],
      }

      # Note: we won't remove the directory since we don't know if it'll destroy data
      notify { "${dest} wasn't removed after being unmounted.  Please remove it manually.": }
    }
    default: { }
  }

}
