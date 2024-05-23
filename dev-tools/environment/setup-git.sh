#!/bin/bash

# This script installs and configures git and git-lfs packages.

# Error handling function
die() {
    echo "$*" 1>&2
    exit 1
}

GIT_USER="Damian Dudycz"
GIT_EMAIL="damiandudycz@yahoo.com"

# Emerge git if needed.
emerge --newuse --update --deep dev-vcs/git -q

# Setup git user details
git config --global user.name "${GIT_USER}" || die "Failed to set git username"
git config --global user.email "${GIT_EMAIL}" || die "Failed to set git email"

# GIT-LFS setup
echo ">=sys-devel/binutils-2.41-r5 gold" >> /etc/portage/package.use/git-lfs || die "Failed to setup GIT-LFS"
echo "dev-vcs/git-lfs ~$(portageq envvar ARCH)" >> /etc/portage/package.accept_keywords/git-lfs || die "Failed to setup GIT-LFS"
emerge --newuse --update --deep dev-vcs/git-lfs -q || die "Failed to install GIT-LFS"

exit 0
