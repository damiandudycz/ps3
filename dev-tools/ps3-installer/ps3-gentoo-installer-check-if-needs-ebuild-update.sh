#!/bin/bash

source ../../.env-shared.sh --silent || exit 1
source "${PATH_EXTRA_ENV_PS3_INSTALLER}" || failure "Failed to load env ${PATH_EXTRA_ENV_PS3_INSTALLER}"

# Timestamps of files to compare.
readonly PI_VAL_TIMESTAMP_OVERLAY_EBUILD="$(stat --format=%Y ${PI_VAL_PS3_GENTOO_INSTALLER_EBUILD_LATEST})"
readonly PI_VAL_TIMESTAMP_DEV_TOOLS_INSTALLER="$(stat --format=%Y ${PI_PATH_DEV_TOOLS_PS3_INSTALLER_INSTALLER})"
readonly PI_VAL_TIMESTAMP_DEV_TOOLS_CONFIG="$(stat --format=%Y ${PI_PATH_DEV_TOOLS_PS3_INSTALLER_CONFIG_PS3})"

# Determine if update is needed.
readonly PI_VAL_EBUILD_NEEDS_UPDATE=$((PI_VAL_TIMESTAMP_DEV_TOOLS_INSTALLER > PI_VAL_TIMESTAMP_OVERLAY_EBUILD || PI_VAL_TIMESTAMP_DEV_TOOLS_CONFIG > PI_VAL_TIMESTAMP_OVERLAY_EBUILD))

if [[ "${PI_VAL_EBUILD_NEEDS_UPDATE}" ]]; then
    echo true
else
    echo false
fi
