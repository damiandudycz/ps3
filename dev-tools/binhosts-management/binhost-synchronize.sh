#!/bin/bash

config="PS3"
path="../../local/binhost-maintainers/$config"
path_repo="../../binhosts/ps3-gentoo-binhosts/$config"

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

# Sync and build all packages.
prepare_chroot
mount -o bind "$path_repo" "$path/var/cache/binpkgs"

chroot "$path" /bin/bash -c "emerge --sync"
chroot "$path" /bin/bash -c "FEATURES=\"buildpkg -getbinpkg\" emerge @world --update --newuse --deep --quiet"
#chroot "$path" /bin/bash -c "FEATURES=\"buildpkg distcc -getbinpkg\" emerge --update --newuse --deep --quiet @world"

if [[ -n $(git status --porcelain -- "$path_repo") ]]; then
	git add "$path_repo"/*
	git commit --path="$path_repo" -m "PS3 Binhost packages update"
 	git push
fi

umount "$path/var/cache/binpkgs"
unprepare_chroot

# TODO: Add a check if there is no other binhost-synchronize.sh running already
