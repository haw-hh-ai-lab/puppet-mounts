# Define mounts

define mounts (
  $source = undef,
  $dest   = undef,
  $type   = undef,
  $opts   = 'defaults',
  $dump   = 0,
  $passno = 0,
  $ensure = 'present',
  $mkdir  = true,
  $force_mount = []){

  if $source == undef {
    err('The source parameter is required.')
  }

  if $dest == undef {
    err('The dest parameter is required.')
  }

  if $type == undef {
    err('The type parameter is required.')
  }

  $dest2 = "${dest}"

  fstab { "fstab entry for ${source} to ${dest} as ${type}":
    ensure => $ensure,
    source => $source,
    dest   => "${dest}",
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
      $dirtree = dirtree("$dest2")
      $dirtree_parents = dirtree(dirname("$dest2"))
      if $mkdir {
        ensure_resource('file', $dirtree, {'ensure' => 'directory'})

        # The root folder is not part of $dirtree (for whatever reason),
        # but we may need it later.
        # This doesn't work: ensure_resource('file', ['/'], {'ensure' => 'directory', 'path' => '/'})
        if "$dest2" == "/" {
          file { '/':
            ensure => 'directory',
            path => '//'
          }
        }

        # We need two directory resources:
        # 1. A directory for the mount point. It must exist
        #    before we mount the file system.
        # 2. A directory resource for the mounted directory to
        #    set its attributes and make sure that all tasks
        #    that depend on the directory will be executed
        #    after it is mounted.
        # The first one is declared here (with a different name) and
        # the second one has been declared above as part of the dirtree.
        # Unfortunately, we cannot really make this a file resource
        # because it would conflict with the other file resource
        # (even if we use a different name).
        exec { "$dest2?mountpoint":
          command => "/bin/mkdir -p '$dest2'",
          creates => $dest2,
          require => File[$dirtree_parents]
        }
      }
      
      $auto = $opts ? { /(^|,)noauto($|,)/ => false, default => true }
      $chroot = !member($force_mount, 'chroot') and $::is_chroot
      if $auto and !$chroot {
        exec { "/bin/mount '${dest2}'":
          unless  => "/bin/mount -l | /bin/grep '${dest2}'",
          require => [File[$dirtree_parents], $fstab],
        }

        if $mkdir {
          Exec["$dest2?mountpoint"] -> Exec["/bin/mount '${dest2}'"] -> File[$dest2]
        }
      }
    }
    'absent': {
      exec { "/bin/umount '${dest2}'":
        onlyif => "/bin/mount -l | /bin/grep '${dest2}'",
        before => Fstab["fstab entry for ${source} to ${dest2} as ${type}"],
      }

      # Note: we won't remove the directory since we don't know if it'll destroy data
      notify { "${dest2} wasn't removed after being unmounted.  Please remove it manually.": }
    }
    default: { }
  }

}
