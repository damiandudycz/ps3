#!/bin/bash

[ ! ${EN_ENV_LOADED} ] || return 0
readonly EN_ENV_LOADED=true

# Helper names.
readonly EN_KE_NAME_PACKAGE_DST="sys-kernel/gentoo-kernel-ps3" # Name of customized package.

# Locations.
readonly EN_PATH_CROSSDEV_USR="${PATH_USR_SHARE}/crossdev"

# Overlay locations.
readonly EN_KE_PATH_OVERLAY_EBUILDS="${PATH_OVERLAYS_PS3_GENTOO}/${EN_KE_NAME_PACKAGE_DST}"
