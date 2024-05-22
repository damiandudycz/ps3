#!/bin/bash

# Install simple dependencies required by other parts of the system

# Error handling function
die() {
    echo "$*" 1>&2
    exit 1
}

# GIT-LFS requirements
echo ">=sys-devel/binutils-2.41-r5 gold" >> /etc/portage/package.use/git-lfs || die "Failed to setup GIT-LFS"
echo "dev-vcs/git-lfs ~$(portageq envvar ARCH)" >> /etc/portage/package.accept_keywords/git-lfs || die "Failed to setup GIT-LFS"

# Download various required pckages
emerge --newuse --update --deep ruby pkgdev dev-vcs/git-lfs || die "Failed to install dependencies"

exit 0
