define mounts::bind($source, $dest, $opts = undef) {
	mounts { $title:
		source => $source,
		dest   => $dest,
		type   => 'none',
		opts   => $opts ? { undef => "bind", default => "bind,${opts}" }
	}
}
