#!/bin/bash

. .config

title="SETUP SOURCES"
welcome

# Sources config

path_sources_cache=$path_caches/sources
path_kernel_cache=$path_sources_cache/linux-$kernel_version-gentoo

# Remove current changes and download fresh version
if [ -d $path_kernel_cache ]
then
	try rm -rf $path_kernel
	try cp -r $path_kernel_cache $path_kernel
else
	ACCEPT_KEYWORDS="~*" try quiet emerge $quiet_flag =gentoo-sources-$kernel_version
	try mkdir -p $path_sources_cache
	try cp -r $path_kernel $path_kernel_cache
fi

# Apply patches
try cd $path_kernel

for patch in $path_patches/*
do
	try quiet patch -p1 < $patch
done

# Copy defconfig to kernel and make this configuration and apply
try cp $path_files/ps3_gentoo_defconfig $path_kernel/arch/powerpc/configs/
ARCH=powerpc CROSS_COMPILE=powerpc64-unknown-linux-gnu- try quiet make -j6 ps3_gentoo_defconfig

summary
