#!/bin/bash

source ../../.env-shared.sh || exit 1
source "${PATH_EXTRA_ENV_PS3_INSTALLER}" || failure "Failed to load env ${PATH_EXTRA_ENV_PS3_INSTALLER}"

# Handle script arguments
unset ASK

for arg in "$@"; do case $arg in
    --ask) ASK=true; shift;;
esac; done

# Check if update is needed.
if [[ -n $(ps3_installer_needs_update) ]]; then
    if [[ $ASK ]]; then
        while true; do
            read -p "Do you want to update ps3-gentoo-installer ebuild [yes/no]: " yn
            case $yn in
                [Yy]*) break ;;
                [Nn]*) exit 0 ;;
            esac
        done
    fi
else
    echo "No changes to installer since last release."
    exit 0
fi

# Generate new files.
empty_directory "${PATH_WORK_PS3_INSTALLER}"

# Copy distfiles to tmp.
cp "${PI_PATH_DEV_TOOLS_PS3_INSTALLER_EBUILD}" "${PATH_WORK_PS3_INSTALLER}/ps3-gentoo-installer-${PI_VAL_PS3_GENTOO_INSTALLER_EBUILD_VERSION_NEW}.ebuild"
cp "${PI_PATH_DEV_TOOLS_PS3_INSTALLER_INSTALLER}" "${PATH_WORK_PS3_INSTALLER}/ps3-gentoo-installer"
cp "${PI_PATH_DEV_TOOLS_PS3_INSTALLER_CONFIG_PS3}" "${PATH_WORK_PS3_INSTALLER}/config"

readonly PI_PATH_DISTFILES_TAR="${PATH_WORK_PS3_INSTALLER}/ps3-gentoo-installer-${PI_VAL_PS3_GENTOO_INSTALLER_EBUILD_VERSION_NEW}.tar"
tar --sort=name \
    --mtime="" \
    --owner=0 --group=0 --numeric-owner \
    --pax-option=exthdr.name=%d/PaxHeaders/%f,delete=atime,delete=ctime \
    -caf "${PI_PATH_DISTFILES_TAR}" \
    -C "${PATH_WORK_PS3_INSTALLER}" "${PI_CONF_LIST_DISTFILES_TAR_FILES[@]}"

# Copy ebuild and distfiles to overlay.
readonly PI_PATH_OVERLAY_DISTFILES_TAR="${PATH_OVERLAYS_PS3_GENTOO_DISTFILES}/${PI_CONF_EBUILD_PACKAGE}/ps3-gentoo-installer-${PI_VAL_PS3_GENTOO_INSTALLER_EBUILD_VERSION_NEW}.tar"
readonly PI_PATH_OVERLAY_EBUILD="${PATH_OVERLAYS_PS3_GENTOO}/${PI_CONF_EBUILD_PACKAGE}/ps3-gentoo-installer-${PI_VAL_PS3_GENTOO_INSTALLER_EBUILD_VERSION_NEW}.ebuild"
cp "${PATH_WORK_PS3_INSTALLER}/ps3-gentoo-installer-${PI_VAL_PS3_GENTOO_INSTALLER_EBUILD_VERSION_NEW}.ebuild" "${PI_PATH_OVERLAY_EBUILD}"
cp "${PI_PATH_DISTFILES_TAR}" "${PI_PATH_OVERLAY_DISTFILES_TAR}"

echo "PS3-Gentoo-Installer-${PI_VAL_PS3_GENTOO_INSTALLER_EBUILD_VERSION_NEW} saved in overlay"
