define mounts::tmpfs($source = 'tmpfs', $dest = undef, $opts = undef, $mkdir = true, $ensure = 'present', $force_mount = []) {
	$real_dest = $dest ? { undef => $title, default => $dest }
	mounts { $title:
		source => $source,
		dest   => $real_dest,
		type   => 'tmpfs',
		opts   => $opts,
		mkdir  => $mkdir,
		ensure => $ensure,
		force_mount => $force_mount
	}
}
