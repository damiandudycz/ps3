#!/bin/bash

die() {
    echo "$*" 1>&2
    exit 1
}

PACKAGE_VERSION="$1"

readonly PATH_START=$(dirname "$(realpath "$0")") || die "Failed to determine script directory."
readonly PATH_ROOT=$(realpath -m "${PATH_START}/../..") || die "Failed to determine root directory."
readonly PATH_VERSION_SCRIPT="${PATH_START}/ebuild-00-find-version.sh"
[ ! -z "${PACKAGE_VERSION}" ] || PACKAGE_VERSION=$($PATH_VERSION_SCRIPT) || die "Failed to get default version of package"
readonly PATH_WORK="${PATH_ROOT}/local/gentoo-kernel-ps3/${PACKAGE_VERSION}/ebuild"
readonly PATH_WORK_DISTFILES="${PATH_WORK}/distfiles"
readonly PATH_WORK_DISTFILES_TAR="${PATH_WORK_DISTFILES}/gentoo-kernel-ps3-files-${PACKAGE_VERSION}.tar.xz"
readonly PATH_WORK_EBUILD_FILE="${PATH_WORK}/sys-kernel/gentoo-kernel-ps3/gentoo-kernel-ps3-${PACKAGE_VERSION}.ebuild"

# Verify data.
[[ "${PACKAGE_VERSION}" =~ ^[0-9]+\.[0-9]+\.[0-9]+([0-9]+)?$ ]] || die "Please provide valid version number, ie. $0 6.6.30"
[ -d "${PATH_WORK}" ] || die "Workdir for version ${PACKAGE_VERSION} not found."
[ -f "${PATH_WORK_EBUILD_FILE}" ] || die "Ebuild for version ${PACKAGE_VERSION} not found."
[ -f "${PATH_WORK_DISTFILES_TAR}" ] || die "Distfiles for version ${PACKAGE_VERSION} not found."

# Create manifest and digest
cd "${PATH_WORK}" || die "Failed to open ${PATH_WORK}"
DISTDIR="${PATH_WORK_DISTFILES}" ebuild sys-kernel/gentoo-kernel-ps3/gentoo-kernel-ps3-${PACKAGE_VERSION}.ebuild manifest || die "Failed to build manifest"

echo "Gentoo-Kernel-PS3 Ebuild manifest generated successfully."
exit 0
