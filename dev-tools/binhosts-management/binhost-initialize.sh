#!/bin/bash

# Creates clean installations for managing binhost repository.

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

name_base="base"
path_local_base="../../local/binhost-maintainers/${name_base}"
path_binhost_base="../../binhosts/ps3-gentoo-binhosts/${name_base}"
profile_base="default/linux/ppc64/17.0"
packages_base=( # Additional packages for base binhost
	"sys-process/htop"
)

name_desktop="desktop"
path_local_desktop="../../local/binhost-maintainers/${name_desktop}"
path_binhost_desktop="../../binhosts/ps3-gentoo-binhosts/${name_desktop}"
profile_desktop="default/linux/ppc64/17.0/desktop"
packages_desktop=( # Additional packages for desktop binhost
	"x11-base/xorg-server"
 	"x11-misc/lightdm"
)

# Clean old installations.
rm -rf "${path_local_base}"
rm -rf "${path_local_desktop}"

# Initialize Base binrepo installation.
../../installer/installer.sh --directory "${path_local_base}" --edit-config --distcc ${distcc}
# Mount chroot.
prepare_chroot "${path_local_base}"
# Change profile
chroot "${path_local_base}" /bin/bash -c "eselect profile set ${profile_base}"
# Reset distcc host to localhost.
chroot "${path_local_base}" /bin/bash -c "distcc-config --set-hosts 127.0.0.1"
# Rebuild packages in base binrepo.
mount -o bind "$path_binhost_base" "$path_local_base/var/cache/binpkgs"
rm -rf "$path_local_base/var/cache/binpkgs"/* # Delete previous database of binpkgs to get a fresh start
chroot "$path_local_base" /bin/bash -c "FEATURES=\"buildpkg\" emerge @world --deep --emptytree --with-bdeps=y --binpkg-respect-use=y --quiet"
for package in "${packages_base[@]}"; do
	chroot "$path_local_base" /bin/bash -c "FEATURES=\"buildpkg\" emerge ${package} --with-bdeps=y --binpkg-respect-use=y --quiet"
done
umount "$path_local_base/var/cache/binpkgs"
# Umount chroot.
unprepare_chroot "${path_local_base}"

# Initialize PS3 Desktop binrepo installation.
cp -a "${path_local_base}" "${path_local_desktop}"
# Mount chroot.
prepare_chroot "${path_local_desktop}"
# Change profile
chroot "${path_local_desktop}" /bin/bash -c "eselect profile set ${profile_desktop}"
# TODO: ADD use flags and ENV overwrites
# Rebuild packages in desktop binrepo.
mount -o bind "$path_binhost_desktop" "$path_local_desktop/var/cache/binpkgs"
rm -rf "$path_local_desktop/var/cache/binpkgs"/* # Delete previous database of binpkgs to get a fresh start
chroot "$path_local_desktop" /bin/bash -c "FEATURES=\"buildpkg\" emerge @world --deep --update --newuse --with-bdeps=y --binpkg-respect-use=y --quiet"
for package in "${packages_desktop[@]}"; do
	chroot "$path_local_desktop" /bin/bash -c "FEATURES=\"buildpkg\" emerge ${package} --with-bdeps=y --binpkg-respect-use=y --quiet"
done
umount "$path_local_desktop/var/cache/binpkgs"
# Umount chroot.
unprepare_chroot "${path_local_desktop}"

# Cleanup caches and not needed files.
# Remove duplicated entries from desktop which are already available in base.
