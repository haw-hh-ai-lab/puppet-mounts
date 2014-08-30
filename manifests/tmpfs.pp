define mounts::tmpfs($source = 'tmpfs', $dest = undef, $opts = undef) {
	$real_dest = $dest ? { undef => $title, default => $dest }
	mounts { $title:
		source => $source,
		dest   => $real_dest,
		type   => 'tmpfs',
		opts   => $opts
	}
}
