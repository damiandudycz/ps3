#!/bin/bash

. .config

title="KERNEL CONFIGURE"
welcome

try cd $path_kernel
ARCH=powerpc CROSS_COMPILE=powerpc64-unknown-linux-gnu- try make menuconfig

summary
