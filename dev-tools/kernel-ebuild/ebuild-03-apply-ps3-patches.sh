#!/bin/bash

# This script applies PS3 patches required for Gentoo-Sources and Gentoo-Kernel.
# If the set of patches is available for selected version in data/patches folder,
# these patches will be used.
# Otherwise standard set of patches from data/patches/default will be used.
#
# If you need to update default patches or patches for selected version, use
# ebuild-fetch-patches.sh [version] first.

# --- Shared environment
source ../../.env-shared.sh || exit 1
source "${PATH_EXTRA_ENV_KERNEL_EBUILD}" || failure "Failed to load env ${PATH_EXTRA_ENV_KERNEL_EBUILD}"
register_usage "$0 [package_version]"

# Apply patches
echo "Applying patches from ${KE_PATH_PATCHES_SELECTED} in ${KE_PATH_WORK_SRC_LINUX}"
for PATCH in "${KE_PATH_PATCHES_SELECTED}"/*.patch; do
    echo "Apply patch ${PATCH}:"
    patch --batch --force -p1 -i "${PATCH}" -d "${KE_PATH_WORK_SRC_LINUX}"
done

# Save patches if needed
if [ "${KE_PATH_PATCHES_SELECTED}" != "${KE_PATH_PATCHES_VERSIONED}" ]; then
    if [ ${KE_FLAG_SAVE} ]; then
        echo "Saving default patches to ${KE_PATH_PATCHES_VERSIONED}"
        empty_directory "${KE_PATH_PATCHES_VERSIONED}"
        cp "${KE_PATH_PATCHES_SELECTED}"/*.patch "${KE_PATH_PATCHES_VERSIONED}"/
    else
        echo_color ${COLOR_RED} "Patches not stored for current version ${KE_PACKAGE_VERSION}. Please use --save flag!"
    fi
fi
