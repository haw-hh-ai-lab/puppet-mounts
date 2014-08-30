define mounts::bind($source, $dest, $opts = undef, $mkdir = true, $ensure = 'present') {
	mounts { $title:
		source => $source,
		dest   => $dest,
		type   => 'none',
		opts   => $opts ? { undef => "bind", default => "bind,${opts}" },
		mkdir  => $mkdir,
		ensure => $ensure
	}
}
