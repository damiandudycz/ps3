#!/bin/bash

[ ${PI_ENV_LOADED} ] && return 0; readonly PI_ENV_LOADED=true

readonly PI_CONF_EBUILD_PACKAGE="sys-apps/ps3-gentoo-installer"

# Path of ps3-gentoo-installer package in overlay.
readonly PI_PATH_OVERLAYS_PS3_GENTOO_PS3_GENTOO_INSTALLER_PACKAGE_DIRECTORY="${PATH_OVERLAYS_PS3_GENTOO}/${PI_CONF_EBUILD_PACKAGE}"

# Paths of files of ps3-gentoo-installer in dev-tools (recent working copy, might not be in overlay yet).
readonly PI_PATH_DEV_TOOLS_PS3_INSTALLER_INSTALLER="${PATH_DEV_TOOLS_PS3_INSTALLER}/ps3-gentoo-installer"
readonly PI_PATH_DEV_TOOLS_PS3_INSTALLER_CONFIG_PS3="${PATH_DEV_TOOLS_PS3_INSTALLER}/config/PS3"
readonly PI_PATH_DEV_TOOLS_PS3_INSTALLER_EBUILD="${PATH_DEV_TOOLS_PS3_INSTALLER}/data/ps3-gentoo-installer.ebuild"

# Path of the newest ebuild in overlay for ps3-gentoo-installer.
readonly PI_PATH_PS3_GENTOO_INSTALLER_EBUILD_LATEST=$(find "${PI_PATH_OVERLAYS_PS3_GENTOO_PS3_GENTOO_INSTALLER_PACKAGE_DIRECTORY}" -name "*.ebuild" | grep -v "9999" | sort -V | tail -n 1)
readonly PI_VAL_PS3_GENTOO_INSTALLER_EBUILD_VERSION_CURRENT="$(echo ${PI_PATH_PS3_GENTOO_INSTALLER_EBUILD_LATEST} | sed -r 's/.*-([0-9]+(\.[0-9]+)*)\.ebuild/\1/')"
readonly PI_VAL_PS3_GENTOO_INSTALLER_EBUILD_VERSION_NEW=$(echo "${PI_VAL_PS3_GENTOO_INSTALLER_EBUILD_VERSION_CURRENT}" | awk -F. -v OFS=. '{ $NF=$NF+1; print }')

readonly PI_CONF_LIST_DISTFILES_TAR_FILES=(
    ps3-gentoo-installer
    config
)

ps3_installer_needs_update() {
    PI_VAL_TIMESTAMP_OVERLAY_EBUILD=$(stat --format=%Y ${PI_PATH_PS3_GENTOO_INSTALLER_EBUILD_LATEST})
    PI_VAL_TIMESTAMP_DEV_TOOLS_INSTALLER=$(stat --format=%Y ${PI_PATH_DEV_TOOLS_PS3_INSTALLER_INSTALLER})
    PI_VAL_TIMESTAMP_DEV_TOOLS_CONFIG=$(stat --format=%Y ${PI_PATH_DEV_TOOLS_PS3_INSTALLER_CONFIG_PS3})
    if [[ ${PI_VAL_TIMESTAMP_DEV_TOOLS_INSTALLER} -gt ${PI_VAL_TIMESTAMP_OVERLAY_EBUILD} ]] || [[ ${PI_VAL_TIMESTAMP_DEV_TOOLS_CONFIG} -gt ${PI_VAL_TIMESTAMP_OVERLAY_EBUILD} ]]; then
        echo true
    fi
}
