#!/bin/bash

# This script downloads patches specified in data/patches/remote.txt
# and stores in data/patches/<version> directory.
# If version is not specified it will download to default patches directory.
# If downloading of any of the patches fails, script will delete data/patches/<version>
# directory and return an error code.

clean_download_patches_on_failure() {
    [ ! -d "${KE_PATH_PATCHES_SELECTED}" ] || rm -rf "${KE_PATH_PATCHES_SELECTED}" || echo "Failed to cleanup ${KE_PATH_PATCHES_SELECTED}"
}

# --- Shared environment
source ../../.env-shared.sh || exit 1
source "${PATH_EXTRA_ENV_KERNEL_EBUILD}" || failure "Failed to load env ${PATH_EXTRA_ENV_KERNEL_EBUILD}"
trap 'clean_download_patches_on_failure; failure' ERR
register_usage "$0 [package_version]"

# Prepare parches storege directory.
[ ! -d "${KE_PATH_PATCHES_SELECTED}" ] || rm -rf "${KE_PATH_PATCHES_SELECTED}" || failure "Failed to cleanup previous patches in ${KE_PATH_PATCHES_SELECTED}"
mkdir -p "${KE_PATH_PATCHES_SELECTED}"

# Load URL of patches to download.
source "${KE_PATH_FETCH_LIST}"

# Download patches.
echo "Downloading patches to ${KE_PATH_PATCHES_SELECTED}"
cd "${KE_PATH_PATCHES_SELECTED}"
for URL_PATCH in "${URL_PS3_PATCHES[@]}"; do
    echo "${URL_PATCH}"
    wget "${URL_PATCH}" --quiet
done
