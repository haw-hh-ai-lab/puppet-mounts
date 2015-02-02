define mounts::bind($source, $dest, $opts = undef, $mkdir = true, $ensure = 'present', $force_mount = []) {
	mounts { $title:
		source => $source,
		dest   => $dest,
		type   => 'none',
		opts   => $opts ? { undef => "bind", default => "bind,${opts}" },
		mkdir  => $mkdir,
		ensure => $ensure,
		force_mount => $force_mount
	}
}
