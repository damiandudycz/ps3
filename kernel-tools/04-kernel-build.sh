#!/bin/bash

. .config

title="KERNEL BUILD"
welcome

# Configuration
path_genkernel_tmp=/var/tmp/genkernel
export CFLAGS="-O2 -pipe -mcpu=cell -mtune=cell -mabi=altivec"
export CXXFLAGS="${CFLAGS}"
export LDFLAGS="${CFLAGS}"

# Compile kernel
try cd $path_kernel
try quiet genkernel --cross-compile=powerpc64-unknown-linux-gnu --oldconfig --no-save-config --kernel-config=.config --kerneldir=$path_kernel --no-install --no-microcode all

# Temporarly install modules
try rm -rf $path_modules
ARCH=powerpc CROSS_COMPILE=powerpc64-unknown-linux-gnu- try quiet make --silent modules_install

# Cleanup linux directory
if [ ! -d $path_linux ]
then
	try mkdir $path_linux
fi
try cd $path_linux

try rm -rf modules
try rm -rf patches
try mkdir modules
try mkdir patches

# Copy used patches
try cp $path_patches/* $path_linux/patches/

# Copy kernel files
try cp $path_genkernel_tmp/kernel-ppc64-$kernel_version-gentoo-ppc64 vmlinux
try cp $path_genkernel_tmp/initramfs-ppc64-$kernel_version-gentoo-ppc64 initramfs.img
try cp -r $path_modules $path_linux/modules/
try rm -r $path_linux/modules/$kernel_version-gentoo-ppc64/build

# Save used configuration
$path_kernel/scripts/extract-ikconfig $path_genkernel_tmp/kernel-ppc64-$kernel_version-gentoo-ppc64 > ./config

summary
