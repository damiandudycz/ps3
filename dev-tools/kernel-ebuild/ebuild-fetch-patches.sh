#!/bin/bash

# This script downloads patches specified in data/patches/remote.txt
# and stores in data/patches/<version> directory.
# If version is not specified it will download to default patches directory.
# If downloading of any of the patches fails, script will delete data/patches/<version>
# directory and return an error code.

# Error handling function
die() {
    echo "$*" 1>&2
    # Cleanup patches directory if fetch failed.
    [ ! -d "${PATH_USED_PATCHES}" ] || rm -rf "${PATH_USED_PATCHES}" || echo "Failed to cleanup ${PATH_USED_PATCHES}"
    exit 1
}

readonly PACKAGE_VERSION="$1"

readonly PATH_START=$(dirname "$(realpath "$0")") || die "Failed to determine script directory."
readonly PATH_ROOT=$(realpath -m "${PATH_START}/../..") || die "Failed to determine root directory."
readonly PATH_LOCAL="${PATH_ROOT}/local/kernel"
readonly PATH_PATCHES="${PATH_START}/data/patches"
readonly PATH_FETCH_LIST="${PATH_PATCHES}/remote.txt"
readonly PATH_VERSION_PATCHES="${PATH_PATCHES}/${PACKAGE_VERSION}"
readonly PATH_DEFAULT_PATCHES="${PATH_PATCHES}/default"

# Determine used local patches directory - version or default.
PATH_USED_PATCHES="${PATH_VERSION_PATCHES}"
[ -z "${PACKAGE_VERSION}" ] && PATH_USED_PATCHES="${PATH_DEFAULT_PATCHES}"

# Validate package version if specified.
[ -z "${PACKAGE_VERSION}" ] || [[ "${PACKAGE_VERSION}" =~ ^[0-9]+\.[0-9]+\.[0-9]+([0-9]+)?$ ]] || die "Please provide valid version number, ie. $0 6.6.30"

# Cleanup previous packages if exists
[ ! -d "${PATH_USED_PATCHES}" ] || rm -rf "${PATH_USED_PATCHES}" || die "Failed to cleanup previous patches in ${PATH_USED_PATCHES}"
mkdir -p "${PATH_USED_PATCHES}"

# Load URL of patches to download.
source "${PATH_FETCH_LIST}" || die "Failed to load list of patches from ${PATH_FETCH_LIST}"

# Download patches.
cd "${PATH_USED_PATCHES}" || die "Failed to open patches directory ${PATH_USED_PATCHES}"
for URL_PATCH in "${URL_PS3_PATCHES[@]}"; do
    echo "Downloading patch: ${URL_PATCH} to ${PATH_USED_PATCHES}"
    wget "${URL_PATCH}" --quiet || die "Failed to download patch ${URL_PATCH}"
done

exit 0
