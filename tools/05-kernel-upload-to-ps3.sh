#!/bin/bash

. .config

title="KERNEL UPLOAD TO PS3"
welcome

# Configuration
ssh_addr=root@$ps3_host

#try quiet ssh $ssh_addr "mount /boot"
try quiet scp $path_linux/vmlinux $ssh_addr:/boot/vmlinux-$kernel_version
try quiet scp $path_linux/initramfs.img $ssh_addr:/boot/initramfs-$kernel_version.img
try quiet scp -r $path_linux/modules/$kernel_version-gentoo-ppc64 $ssh_addr:$path_modules
try quiet ssh $ssh_addr "reboot"

summary
