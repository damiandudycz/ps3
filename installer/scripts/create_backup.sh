# Creates backup copy of entire system as a tar file after installation is completed
# Run after unprepare_chroot

try tar cvpJf "$path_chroot/gentoo-ps3.tar.bz" --exclude="$path_chroot/gentoo-ps3.tar.bz" -C "$path_chroot"
