#!/bin/bash

source ../../.env-shared.sh || exit 1
source "${PATH_EXTRA_ENV_ENVIRONMENT}" || failure "Failed to load env ${PATH_EXTRA_ENV_ENVIRONMENT}"

# GIT setup.
git config --global user.name "${CONF_GIT_USER}"
git config --global user.email "${CONF_GIT_EMAIL}"
git config --global core.editor "${CONF_GIT_EDITOR}"

# GIT-LFS setup.
use_set_package "sys-devel/binutils" "gold"
unmask_package "dev-vcs/git-lfs"
emerge --newuse --update --deep dev-vcs/git-lfs
