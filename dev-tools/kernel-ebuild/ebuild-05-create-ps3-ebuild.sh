#!/bin/bash

# This script generates new ebuild and distfiles for gentoo-kernel-ps3.
# It uses config(diffs) file and patches stored for selected version.
# This script requires that version data is prepared, it can not use default variables.

# TODO: Allow unmasking

# Error handling function
die() {
    echo "$*" 1>&2
    [ ! -d "${PATH_WORK}" ] || rm -rf "${PATH_WORK}" || echo "Failed to remove tmp directory ${PATH_WORK}"
    exit 1
}

PACKAGE_VERSION="$1"
readonly NAME_PS3_DEFCONFIG="ps3_defconfig"
readonly NAME_PACKAGE="sys-kernel/gentoo-kernel"
readonly LIST_DISTFILES_FILES=(
    # List of files and directories compressed into distfiles tarball for overlay distfiles repository.
    ps3_defconfig_diffs # Not needed, but kept for tracking changes between versions.
    ps3_gentoo_defconfig # Updated ps3_defconfig that will replace the original one.
    ps3_patches # PS3 specific patches to be applied to kernel. Snapshot created with ebuild.
)

readonly PATH_START=$(dirname "$(realpath "$0")") || die "Failed to determine script directory."
readonly PATH_ROOT=$(realpath -m "${PATH_START}/../..") || die "Failed to determine root directory."
readonly PATH_PATCHES="${PATH_START}/data/patches"
readonly PATH_CONFIGS="${PATH_START}/data/configs"
readonly PATH_EBUILD_PACTHES="${PATH_START}/data/ebuild-patches"
readonly PATH_PORTAGE_EBUILD_FILE="/var/db/repos/gentoo/${NAME_PACKAGE}/gentoo-kernel-${PACKAGE_VERSION}.ebuild"
readonly PATH_VERSION_SCRIPT="${PATH_START}/ebuild-00-find-version.sh"
[ ! -z "${PACKAGE_VERSION}" ] || PACKAGE_VERSION=$($PATH_VERSION_SCRIPT) || die "Failed to get default version of package"
readonly PATH_VERSION_PATCHES="${PATH_PATCHES}/${PACKAGE_VERSION}"
readonly PATH_VERSION_CONFIG="${PATH_CONFIGS}/${PACKAGE_VERSION}"
readonly PATH_VERSION_DEFCONFIG="${PATH_CONFIGS}/${PACKAGE_VERSION}.defconfig"
readonly PATH_WORK="${PATH_ROOT}/local/gentoo-kernel-ps3/${PACKAGE_VERSION}/ebuild"
readonly PATH_WORK_EBUILD="${PATH_WORK}/ebuild"
readonly PATH_WORK_DISTFILES="${PATH_WORK}/distfiles"
readonly PATH_WORK_DISTFILES_TAR="${PATH_WORK_DISTFILES}/gentoo-kernel-ps3-files-${PACKAGE_VERSION}.tar.xz"
readonly PATH_WORK_EBUILD_FILE="${PATH_WORK_EBUILD}/gentoo-kernel-ps3-${PACKAGE_VERSION}.ebuild"

# Verify data.
[[ "${PACKAGE_VERSION}" =~ ^[0-9]+\.[0-9]+\.[0-9]+([0-9]+)?$ ]] || die "Please provide valid version number, ie. $0 6.6.30"
[ -d "${PATH_PATCHES}" ] || die "Patches for version ${PACKAGE_VERSION} not found. Please run ebuild-apply-kernel-patches.sh first."
[ -d "${PATH_CONFIGS}" ] || die "Configs for version ${PACKAGE_VERSION} not found. Please run ebuild-configure.sh first."

# Create local working directory for distfiles and ebuild.
[ ! -d "${PATH_WORK}" ] || rm -rf "${PATH_WORK}" || die "Failed to clean work dir ${PATH_WORK}"
mkdir -p "${PATH_WORK}" || die "Failed to create workdir ${PATH_WORK}"
mkdir -p "${PATH_WORK_EBUILD}" || die "Failed to create workdir ${PATH_WORK_EBUILD}"
mkdir -p "${PATH_WORK_DISTFILES}" || die "Failed to create workdir ${PATH_WORK_DISTFILES}"
mkdir -p "${PATH_WORK_DISTFILES}/ps3_patches" || die "Failed to create workdir ${PATH_WORK_DISTFILES}/patches"

# Geather files.
cp -f "${PATH_VERSION_PATCHES}"/*.patch "${PATH_WORK_DISTFILES}/ps3_patches"/ || die "Failed to copy patches"
cp -f "${PATH_VERSION_CONFIG}" "${PATH_WORK_DISTFILES}/ps3_defconfig_diffs" || die "Failed to copy config diffs"
cp -f "${PATH_VERSION_DEFCONFIG}" "${PATH_WORK_DISTFILES}/ps3_gentoo_defconfig" || die "Failed to copy defconfig"

# Create distfiles tarball.
tar --sort=name --mtime="" --owner=0 --group=0 --numeric-owner --pax-option=exthdr.name=%d/PaxHeaders/%f,delete=atime,delete=ctime \
    -caf "${PATH_WORK_DISTFILES_TAR}" -C "${PATH_WORK_DISTFILES}" "${LIST_DISTFILES_FILES[@]}"

# Remove tmp files.
for FILE in "${LIST_DISTFILES_FILES[@]}"; do
    rm -rf "$PATH_WORK_DISTFILES/$FILE" || die "Failed to remove ${FILE}"
done

# Create patched ebuild file and apply patches
cp "${PATH_PORTAGE_EBUILD_FILE}" "${PATH_WORK_EBUILD_FILE}" || die "Failed to copy original ebuild ${PATH_PORTAGE_EBUILD_FILE}"
for PATCH in "${PATH_EBUILD_PACTHES}"/*.patch; do
    echo "Apply patch ${PATCH}:"
    patch --batch --force -p0 -i "${PATCH}" "${PATH_WORK_EBUILD_FILE}" || die "Failed to apply patch ${PATCH} to ${TARGET_FILE}"
done

echo "Gentoo-Kernel-PS3 Ebuild and distfiles generated successfully."
exit 0
