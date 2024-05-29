#!/bin/bash

source ../../.env-shared.sh || exit 1
source "${PATH_EXTRA_ENV_ENVIRONMENT}" || failure "Failed to load env ${PATH_EXTRA_ENV_ENVIRONMENT}"

# GIT setup.
git config --global user.name "${EN_CONF_GIT_USER}"
git config --global user.email "${EN_CONF_GIT_EMAIL}"
git config --global core.editor "${EN_CONF_GIT_EDITOR}"

# GIT-LFS setup.
echo ">=sys-devel/binutils-2.41-r5 gold" > "${EN_PATH_GIT_LFS_USE}"
echo "dev-vcs/git-lfs ~$(portageq envvar ARCH)" > "${EN_PATH_GIT_LFS_ACCEPT_KEYWORDS}"
emerge --newuse --update --deep dev-vcs/git-lfs
