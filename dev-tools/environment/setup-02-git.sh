#!/bin/bash

# This script installs and configures git and git-lfs packages.

# --- Shared environment --- # Imports shared environment configuration,
source ../../.env-shared.sh  # patches and functions.
trap failure ERR             # Sets a failure trap on any error.
# -------------------------- #

readonly CONF_GIT_USER="Damian Dudycz"
readonly CONF_GIT_EMAIL="damiandudycz@yahoo.com"

# GIT setup.
emerge --newuse --update --deep dev-vcs/git
git config --global user.name "${CONF_GIT_USER}"
git config --global user.email "${CONF_GIT_EMAIL}"

# GIT-LFS setup.
echo ">=sys-devel/binutils-2.41-r5 gold" > /etc/portage/package.use/PS3_ENV_git-lfs
echo "dev-vcs/git-lfs ~$(portageq envvar ARCH)" > /etc/portage/package.accept_keywords/PS3_ENV_git-lfs
emerge --newuse --update --deep dev-vcs/git-lfs

exit 0
