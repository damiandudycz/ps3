#!/bin/bash

readonly PI_CONF_EBUILD_PACKAGE="sys-apps/ps3-gentoo-installer"

# Path of ps3-gentoo-installer package in overlay.
readonly PI_PATH_OVERLAYS_PS3_GENTOO_PS3_GENTOO_INSTALLER_PACKAGE_DIRECTORY="${PATH_OVERLAYS_PS3_GENTOO}/${PI_CONF_EBUILD_PACKAGE}"

# Paths of files of ps3-gentoo-installer in dev-tools (recent working copy, might not be in overlay yet).
readonly PI_PATH_DEV_TOOLS_PS3_INSTALLER_INSTALLER="${PATH_DEV_TOOLS_PS3_INSTALLER}/ps3-gentoo-installer"
readonly PI_PATH_DEV_TOOLS_PS3_INSTALLER_CONFIG_PS3="${PATH_DEV_TOOLS_PS3_INSTALLER}/config/PS3"

# Path of the newest ebuild in overlay for ps3-gentoo-installer.
readonly PI_VAL_PS3_GENTOO_INSTALLER_EBUILD_LATEST=$(find "${PI_PATH_OVERLAYS_PS3_GENTOO_PS3_GENTOO_INSTALLER_PACKAGE_DIRECTORY}" -name "*.ebuild" | grep -v "9999" | sort -V | tail -n 1)
