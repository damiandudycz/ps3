#!/bin/bash

# This script builds clean installation in directory, used for Binhosts rebuild.
# First it builds a clean PS3 configuration install.
# Then it configures distcc host, and rebuilds all packages, to generate all binpkgs.
# Finally it should send new packages to the git repository.

# TODO: Get user input values for things like distcc host, cofiguration, etc

config="PS3"
#distcc_host="192.168.86.67"
path="../../local/binhost-maintainers/$config"
path_repo = "../../binhosts/$config"

../../installer/installer.sh --directory "$path" --config $config --verbose
# --distcc "$distcc_host"

prepare_chroot() {
	mount --type proc /proc "$path/proc"
	mount --rbind /sys "$path/sys"
	mount --make-rslave "$path/sys"
	mount --rbind /dev "$path/dev"
	mount --make-rslave "$path/dev"
	mount --bind /run "$path/run"
	mount --make-slave "$path/run"
	cp --dereference '/etc/resolv.conf' "$path/etc/resolv.conf"
}

unprepare_chroot() {
	umount -l "$path/dev"{"/shm","/pts"}
	umount -R "$path/proc"
	umount -R "$path/run"
	umount -R "$path/dev"
	umount -R "$path/sys"
	rm "$path/etc/resolv.conf"
}

# Rebuild all packages and create binpkgs. Add distcc config before that.
prepare_chroot
mount -o bind "$path_repo" "$path/var/cache/binpkgs"
rm -rf "$path/var/cache/binpkgs"/* # Delete previous database of binpkgs to get a fresh start
chroot "$path" /bin/bash -c "FEATURES=\"buildpkg distcc -getbinpkg\" emerge @system @world --deep --emptytree --with-bdeps=y --quiet"
umount "$path/var/cache/binpkgs"
unprepare_chroot
