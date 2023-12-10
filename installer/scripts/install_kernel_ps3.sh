#!/bin/bash

# Installs special pre-built version of kernel for the PS3.
# This script should later be replaced with installation from custom portage repository.

# TODO: Install with custom repository.
if [ ! -n "$kernel_version" ]; then
    return
fi
linux_filename="linux-$kernel_version.tar.xz"
url_linux_download="https://github.com/damiandudycz/ps3/raw/main/$linux_filename"
path_linux_download="$path_tmp/$linux_filename"
path_linux_extract="$path_tmp/linux-$kernel_version"

path_chroot_boot="$path_chroot/boot"
path_kernel_vmlinux="$path_linux_extract/vmlinux"
path_kernel_initramfs="$path_linux_extract/initramfs.img"
path_kernel_modules="$path_linux_extract/modules/$kernel_version-gentoo-ppc64"
path_chroot_modules="$path_chroot/lib/modules/$kernel_version-gentoo-ppc64"

if [ ! -d "$path_tmp" ]; then
    try mkdir -p "$path_tmp"
fi
if [ ! -d "$path_linux_extract" ]; then
    try mkdir -p "$path_linux_extract"
fi

try wget "$url_linux_download" -O "$path_linux_download" --no-http-keep-alive --no-cache --no-cookies $quiet_flag
try tar -xvpf "$path_linux_download" --directory "$path_linux_extract"

if [ ! -d "$path_chroot_modules" ]; then
    try mkdir -p "$path_chroot_modules"
fi

try cp "$path_kernel_vmlinux" "$path_chroot_boot/vmlinux-$kernel_version"
try cp "$path_kernel_initramfs" "$path_chroot_boot/initramfs-$kernel_version.img"
try cp -r "$path_kernel_modules"/* "$path_chroot_modules"

update_distcc_host