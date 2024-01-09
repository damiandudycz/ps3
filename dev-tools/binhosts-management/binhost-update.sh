#!/bin/bash

# Updates packages in binhosts.

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

name_base="base"
path_local_base="../../local/binhost-maintainers/${name_base}"
path_binhost_base="../../binhosts/ps3-gentoo-binhosts/${name_base}"

name_desktop="desktop"
path_local_desktop="../../local/binhost-maintainers/${name_desktop}"
path_binhost_desktop="../../binhosts/ps3-gentoo-binhosts/${name_desktop}"

# Mount chroot.
prepare_chroot "${path_local_base}"
# Rebuild packages in base binrepo.
mount -o bind "$path_binhost_base" "$path_local_base/var/cache/binpkgs"
chroot "$path_local_base" /bin/bash -c "FEATURES=\"buildpkg\" emerge --sync --quiet"
chroot "$path_local_base" /bin/bash -c "FEATURES=\"buildpkg\" emerge @world --deep --update --newuse --with-bdeps=y --binpkg-respect-use=y --quiet"
if [[ -n $(git status --porcelain -- "$path_binhost_base") ]]; then
	git add "$path_binhost_base"/*
	git commit --path="$path_binhost_base" -m "PS3 Binhost packages update"
 	git push
fi
umount "$path_local_base/var/cache/binpkgs"
# Umount chroot.
unprepare_chroot "${path_local_base}"

# Mount chroot.
prepare_chroot "${path_local_desktop}"
# Change profile
chroot "${path_local_desktop}" /bin/bash -c "eselect profile set ${profile_desktop}"
# Rebuild packages in desktop binrepo.
mount -o bind "$path_binhost_desktop" "$path_local_desktop/var/cache/binpkgs"
chroot "$path_local_base" /bin/bash -c "FEATURES=\"buildpkg\" emerge --sync --quiet"
chroot "$path_local_desktop" /bin/bash -c "FEATURES=\"buildpkg\" emerge @world --deep --update --newuse --with-bdeps=y --binpkg-respect-use=y --quiet"
if [[ -n $(git status --porcelain -- "$path_binhost_desktop") ]]; then
	git add "$path_binhost_desktop"/*
	git commit --path="$path_binhost_desktop" -m "PS3 Binhost packages update"
 	git push
fi
umount "$path_local_desktop/var/cache/binpkgs"
# Umount chroot.
unprepare_chroot "${path_local_desktop}"

# Cleanup caches and not needed files.
# Remove duplicated entries from desktop which are already available in base.
