#!/bin/bash

. .config

title="SETUP PATCHES"
welcome

# Repositories config
repo_t2sde="t2sde"
repo_ps3linux_patches="ps3linux-patches"

url_t2sde="http://svn.exactcode.de/t2/trunk/architecture/powerpc64/package/linux"
url_ps3linux_patches="https://github.com/CheezeCake/ps3linux-patches"

patches_t2sde=(
	"0009" "0010" "0011" "0030" "0040" "0050" "0060" "0070" "0080" "0110" "0120"
	"0140" "0150" "0160" "0170" "0180" "0190" "0200" "0210" "0220" "0230" "0240" "0250"
	"0260" "0700" "1000" "ps3-gelic-skb-alloc"
)
patches_ps3linux_patches=("0035" "0100")

# Create repositories folder if doesn't exists
if [ ! -d $path_repositories ]
then
	try mkdir -p $path_repositories
fi

# Pull repositories
try cd $path_repositories
if [ -d $repo_t2sde ]
then
	try cd $repo_t2sde
	try quiet svn update
	try cd $path_repositories
else
	try quiet svn checkout $url_t2sde $repo_t2sde
fi

if [ -d $repo_ps3linux_patches ]
then
	try cd $repo_ps3linux_patches
	try quiet git pull $quiet_flag
	try cd $path_repositories
else
	try quiet git clone --depth 1 $quiet_flag $url_ps3linux_patches
fi

# Clean patches directory
if [ -d $path_patches ]
then
	try rm -rf $path_patches
fi
try mkdir -p $path_patches

# Copy selected patches from directories
for patch in ${patches_t2sde[@]}
do
	try cp $repo_t2sde/$patch* $path_patches/
done
for patch in ${patches_ps3linux_patches[@]}
do
	try cp $repo_ps3linux_patches/$patch* $path_patches/
done

summary
