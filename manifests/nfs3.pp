define mounts::nfs3($server, $share, $dest = undef, $nfs_opts = "vers=3", $opts = undef, $mkdir = true, $ensure = 'present', $force_mount = []) {
	$real_dest = $dest ? { undef => $title, default => $dest }
	mounts { $title:
		source => "${server}:${share}",
		dest   => $real_dest,
		type   => 'nfs',
		opts   => $opts ? { undef => $nfs_opts, default => "${nfs_opts},${opts}" },
		mkdir  => $mkdir,
		ensure => $ensure,
		force_mount => $force_mount
	}
}
