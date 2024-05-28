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
trap failure ERR
register_usage "$0 [package_version]"

# Apply patches
for PATCH in "${KE_PATH_PATCHES_SELECTED}"/*.patch; do
    echo "Apply patch ${PATCH}:"
    patch --batch --force -p1 -i "${PATCH}" -d "${KE_PATH_WORK_SRC_LINUX}"
done
