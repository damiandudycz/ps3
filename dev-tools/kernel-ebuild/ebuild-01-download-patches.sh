#!/bin/bash

# This script downloads patches specified in data/patches/remote.txt
# and stores in data/patches/<version> directory.
# If version is not specified it will download to default patches directory.
# If downloading of any of the patches fails, script will delete data/patches/<version>
# directory and return an error code.

clean_download_patches_on_failure() {
    [ ! -d "${PATH_VERSION_PATCHES_USED}" ] || rm -rf "${PATH_VERSION_PATCHES_USED}" || echo "Failed to cleanup ${PATH_VERSION_PATCHES_USED}"
}

# --- Shared environment
source ../../.env-shared.sh || exit 1
trap 'clean_download_patches_on_failure; failure' ERR
register_usage "$0 [package_version]"

readonly PACKAGE_VERSION="$1"
readonly PATH_VERSION_STORAGE="${PATH_DEV_TOOLS_KERNEL_EBUILD}/data/version-storage"
readonly PATH_FETCH_LIST="${PATH_DEV_TOOLS_KERNEL_EBUILD}/data/patches-current.txt"
readonly PATH_VERSION_PATCHES="${PATH_VERSION_STORAGE}/${PACKAGE_VERSION}/patches"
readonly PATH_VERSION_PATCHES_DEFAULT="${PATH_VERSION_STORAGE}/default/patches"
PATH_VERSION_PATCHES_USED="${PATH_VERSION_PATCHES}"
[ -z "${1}" ] && PATH_VERSION_PATCHES_USED="${PATH_VERSION_PATCHES_DEFAULT}"

# Validate data.
[ -z "${PACKAGE_VERSION}" ] || [[ "${PACKAGE_VERSION}" =~ ^[0-9]+\.[0-9]+\.[0-9]+([0-9]+)?$ ]] || show_usage

# Prepare parches storege directory.
[ ! -d "${PATH_VERSION_PATCHES_USED}" ] || rm -rf "${PATH_VERSION_PATCHES_USED}" || failure "Failed to cleanup previous patches in ${PATH_VERSION_PATCHES_USED}"
mkdir -p "${PATH_VERSION_PATCHES_USED}"

# Load URL of patches to download.
source "${PATH_FETCH_LIST}"

# Download patches.
echo "Downloading patches to ${PATH_VERSION_PATCHES_USED}"
cd "${PATH_VERSION_PATCHES_USED}"
for URL_PATCH in "${URL_PS3_PATCHES[@]}"; do
    echo "${URL_PATCH}"
    wget "${URL_PATCH}" --quiet
done
