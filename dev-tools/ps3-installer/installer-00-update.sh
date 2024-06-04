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
            read -p "Do you want to update ps3-gentoo-installer ebuild to version ${PI_VAL_OVERLAY_EBUILD_NEW_VERSION} [yes/no]: " yn
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
cp "${PI_PATH_EBUILD_SRC}" "${PI_PATH_EBUILD_DST}"
cp "${PI_PATH_CONFIG_SRC}" "${PI_PATH_CONFIG_DST}"
cp "${PI_PATH_INSTALLER_SRC}" "${PI_PATH_INSTALLER_DST}"

tar --sort=name \
    --mtime="" \
    --owner=0 --group=0 --numeric-owner \
    --pax-option=exthdr.name=%d/PaxHeaders/%f,delete=atime,delete=ctime \
    -caf "${PI_PATH_DISTFILES_DST}" \
    -C "${PATH_WORK_PS3_INSTALLER}" "${PI_CONF_LIST_DISTFILES_TAR_FILES[@]}"

# TODO: Build new manifest and merge with existing, like in kernel tools.

# Copy ebuild and distfiles to overlay.
cp "${PI_PATH_EBUILD_DST}" "${PI_PATH_EBUILD_OVERLAY}"
cp "${PI_PATH_DISTFILES_DST}" "${PI_PATH_DISTFILES_OVERLAY}"

echo "${PI_CONF_PACKAGE}-${PI_VAL_OVERLAY_EBUILD_NEW_VERSION} saved in overlay"
