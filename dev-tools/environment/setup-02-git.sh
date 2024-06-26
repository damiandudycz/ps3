#!/bin/bash

source ../../.env-shared.sh || exit 1

emerge --newuse --update --deep dev-vcs/git

# GIT setup.
git config --global user.name "${CONF_GIT_USER}"
git config --global user.email "${CONF_GIT_EMAIL}"
git config --global core.editor "${CONF_GIT_EDITOR}"

# GIT-LFS setup.
use_set_package "sys-devel/binutils" "gold"
unmask_package "dev-vcs/git-lfs"
emerge --newuse --update --deep dev-vcs/git-lfs

echo "Restoring files modification dates"
update_git_files_timestamps "${PATH_ROOT}"
