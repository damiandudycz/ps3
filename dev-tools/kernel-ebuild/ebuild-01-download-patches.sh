#!/bin/bash

# This script downloads patches specified in data/patches/remote.txt
# and stores in data/patches/<version> directory.
# If version is not specified it will download to default patches directory.
# If downloading of any of the patches fails, script will delete data/patches/<version>
# directory and return an error code.

die() {
    echo "$*" 1>&2
    [ ! -d "${PATH_VERSION_PATCHES_USED}" ] || rm -rf "${PATH_VERSION_PATCHES_USED}" || echo "Failed to cleanup ${PATH_VERSION_PATCHES_USED}"
    exit 1
}

readonly PACKAGE_VERSION="$1"

readonly PATH_START=$(dirname "$(realpath "$0")") || die "Failed to determine script directory."
readonly PATH_ROOT=$(realpath -m "${PATH_START}/../..") || die "Failed to determine root directory."
readonly PATH_VERSION_STORAGE="${PATH_START}/data/version-storage"
readonly PATH_FETCH_LIST="${PATH_VERSION_STORAGE}/remote.txt"
readonly PATH_WORK="${PATH_ROOT}/local/${PACKAGE_VERSION}/kernel"
readonly PATH_VERSION_PATCHES="${PATH_VERSION_STORAGE}/${PACKAGE_VERSION}/patches"
readonly PATH_VERSION_PATCHES_DEFAULT="${PATH_VERSION_STORAGE}/default/patches"
PATH_VERSION_PATCHES_USED="${PATH_VERSION_PATCHES}"
[ -z "${1}" ] && PATH_VERSION_PATCHES_USED="${PATH_VERSION_PATCHES_DEFAULT}"

# Validate data.
[ -z "${PACKAGE_VERSION}" ] || [[ "${PACKAGE_VERSION}" =~ ^[0-9]+\.[0-9]+\.[0-9]+([0-9]+)?$ ]] || die "Please provide valid version number, ie. $0 6.6.30"

# Prepare parches storege directory.
[ ! -d "${PATH_VERSION_PATCHES_USED}" ] || rm -rf "${PATH_VERSION_PATCHES_USED}" || die "Failed to cleanup previous patches in ${PATH_VERSION_PATCHES_USED}"
mkdir -p "${PATH_VERSION_PATCHES_USED}"

# Load URL of patches to download.
source "${PATH_FETCH_LIST}" || die "Failed to load list of patches from ${PATH_FETCH_LIST}"

# Download patches.
echo "Downloading patches to ${PATH_VERSION_PATCHES_USED}"
cd "${PATH_VERSION_PATCHES_USED}" || die "Failed to open patches directory ${PATH_VERSION_PATCHES_USED}"
for URL_PATCH in "${URL_PS3_PATCHES[@]}"; do
    echo "${URL_PATCH}"
    wget "${URL_PATCH}" --quiet || die "Failed to download patch ${URL_PATCH}"
done

echo "Patches for ${PATH_VERSION_PATCHES_USED} updated successfully"
exit 0
