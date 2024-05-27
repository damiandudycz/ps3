#!/bin/bash

# This script installs and configures git and git-lfs packages.

# --- Shared environment
source ../../.env-shared.sh || exit 1
trap failure ERR

readonly CONF_GIT_USER="Damian Dudycz"
readonly CONF_GIT_EMAIL="damiandudycz@yahoo.com"

# GIT setup.
emerge --newuse --update --deep dev-vcs/git
git config --global user.name "${CONF_GIT_USER}"
git config --global user.email "${CONF_GIT_EMAIL}"

# GIT-LFS setup.
readonly PATH_GIT_LFS_USE="${PATH_ETC_PORTAGE_PACKAGE_USE}/PS3_ENV_git-lfs"
readonly PATH_GIT_LFS_ACCEPT_KEYWORDS="${PATH_ETC_PORTAGE_PACKAGE_ACCEPT_KEYWORDS}/PS3_ENV_git-lfs"
echo ">=sys-devel/binutils-2.41-r5 gold" > "${PATH_GIT_LFS_USE}"
echo "dev-vcs/git-lfs ~$(portageq envvar ARCH)" > "${PATH_GIT_LFS_ACCEPT_KEYWORDS}"
emerge --newuse --update --deep dev-vcs/git-lfs
