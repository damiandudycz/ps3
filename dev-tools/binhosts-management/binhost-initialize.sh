#!/bin/bash

# This script builds clean installation in directory, used for Binhosts rebuild.
# First it builds a clean PS3 configuration install.
# Then it configures distcc host, and rebuilds all packages, to generate all binpkgs.
# Finally it should send new packages to the git repository.

# TODO: Automatically remove unused variables from config - networking, rc, user, etc

prepare_chroot() {
	local path="$1"
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
	local path="$1"
	umount -l "$path/dev"{"/shm","/pts"}
	umount -R "$path/proc"
	umount -R "$path/run"
	umount -R "$path/dev"
	umount -R "$path/sys"
	rm "$path/etc/resolv.conf"
}

# -----------------------------------------------------------------------------------

distcc="192.168.86.53"

name_base="PS3"
path_local_base="../../local/binhost-maintainers/${name_base}"
path_binhost_base="../../binhosts/ps3-gentoo-binhosts/${name_base}"

name_desktop="PS3-desktop"
path_local_desktop="../../local/binhost-maintainers/${name_desktop}"
path_binhost_desktop="../../binhosts/ps3-gentoo-binhosts/${name_desktop}"
profile_desktop="default/linux/ppc64/17.0/desktop"

# Initialize Base binrepo installation.
../../installer/installer.sh --directory "${path_local_base}" --config ${name_base} --edit-config --distcc ${distcc}
# Mount chroot.
prepare_chroot "${path_local_base}"
# Reset distcc host to localhost.
chroot "${path_local_base}" /bin/bash -c "distcc-config --set-hosts 127.0.0.1"
# Rebuild packages in base binrepo.
mount -o bind "$path_binhost_base" "$path_local_base/var/cache/binpkgs"
rm -rf "$path_local_base/var/cache/binpkgs"/* # Delete previous database of binpkgs to get a fresh start
chroot "$path_local_base" /bin/bash -c "FEATURES=\"buildpkg\" emerge @world --deep --emptytree --with-bdeps=y --binpkg-respect-use=y --quiet"
umount "$path_local_base/var/cache/binpkgs"
# Umount chroot.
unprepare_chroot "${path_local_base}"

# Initialize PS3 Desktop binrepo installation.
cp -a "${path_local_base}" "${path_local_desktop}"
# Mount chroot.
prepare_chroot "${path_local_desktop}"
# Change profile
chroot "${path_local_desktop}" /bin/bash -c "eselect profile set ${profile_desktop}"
# Rebuild packages in desktop binrepo.
mount -o bind "$path_binhost_desktop" "$path_local_desktop/var/cache/binpkgs"
rm -rf "$path_local_desktop/var/cache/binpkgs"/* # Delete previous database of binpkgs to get a fresh start
chroot "$path_local_desktop" /bin/bash -c "FEATURES=\"buildpkg\" emerge @world --deep --emptytree --with-bdeps=y --binpkg-respect-use=y --quiet"
umount "$path_local_desktop/var/cache/binpkgs"
# Umount chroot.
unprepare_chroot "${path_local_desktop}"

# Cleanup caches and not needed files.
# Remove duplicated entries from desktop which are already available in base.
