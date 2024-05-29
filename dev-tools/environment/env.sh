#!/bin/bash

[ ! ${EN_ENV_LOADED} ] || return 0
readonly EN_ENV_LOADED=true

# Configs.
readonly EN_CONF_GIT_USER="Damian Dudycz"
readonly EN_CONF_GIT_EMAIL="damiandudycz@yahoo.com"
readonly EN_CONF_GIT_EDITOR="nano"
readonly EN_MAKE_FEATURES="getbinpkg"
readonly EN_PACKAGES_DEPENDENCIES=(gentoolkit ruby pkgdev crossdev dev-vcs/git)

# Helper names.
readonly EN_KE_NAME_PACKAGE_DST="sys-kernel/gentoo-kernel-ps3" # Name of customized gentoo-kernel package.

# Locations.
readonly EN_PATH_CROSSDEV_USR="${PATH_USR_SHARE}/crossdev"
readonly EN_PATH_GIT_LFS_USE="${PATH_ETC_PORTAGE_PACKAGE_USE}/PS3_ENV_git-lfs"
readonly EN_PATH_GIT_LFS_ACCEPT_KEYWORDS="${PATH_ETC_PORTAGE_PACKAGE_ACCEPT_KEYWORDS}/PS3_ENV_git-lfs"
readonly EN_PATH_HOOK_AUTOBUILDS="${PATH_ROOT}/.git/modules/autobuilds/ps3-gentoo-autobuilds/pre-commit"

# Overlay locations.
readonly EN_KE_PATH_OVERLAY_EBUILDS="${PATH_OVERLAYS_PS3_GENTOO}/${EN_KE_NAME_PACKAGE_DST}"
