#!/bin/bash

. .config

title="KERNEL PROMOTE"
welcome

# Configuration

# Setup kernel configuration as current defconfig
try cd $path_kernel
ARCH=powerpc CROSS_COMPILE=powerpc64-unknown-linux-gnu- try quiet make savedefconfig
try cp defconfig $path_files/ps3_gentoo_defconfig
try cp defconfig $path_kernel/arch/powerpc/configs/ps3_gentoo_defconfig
try rm defconfig

# Copy linux files to linux directory
if [ -d $path_linux_promoted ]
then
	try rm -r $path_linux_promoted
fi
try cp -r $path_linux $path_linux_promoted

# Upload to Github
try cd $path_main/files
try quiet git add ps3_gentoo_defconfig
try cd $path_main/linux
try quiet git add .
linux_filename="linux-$kernel_version.tar.xz"
try quiet tar cpPJvf ../$linux_filename .
try quiet git add ../$linux_filename
cd $path_main
try quiet git commit -m "Default_config_update" $quiet_flag
try quiet git push $quiet_flag

summary
