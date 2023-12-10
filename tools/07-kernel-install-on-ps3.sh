#!/bin/bash

. .config

title="KERNEL INSTALL PS3"
welcome

# TODO: Validate architecture

try cd $path_main
try git pull

cd $path_linux_promoted
cp vmlinux /boot/vmlinux-$kernel_version
cp initramfs.img /boot/initramfs-$kernel_version.img
rm -rf $path_modules
if [ -d modules/$kernel_version-gentoo-ppc64 ]
then
	cp -r modules/$kernel_version-gentoo-ppc64 $path_modules
fi

summary
