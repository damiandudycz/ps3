#!/bin/bash

# This function generates partial manifest for new package and it's distfiles.
# This information can later be merged with full overlay repository.

readonly PATH_START=$(dirname "$(realpath "$0")") || die "Failed to determine script directory."
readonly PATH_ROOT=$(realpath -m "${PATH_START}/../..") || die "Failed to determine root directory."
readonly PATH_VERSION_SCRIPT="${PATH_START}/ebuild-00-find-version.sh"
[ ! -z "${PACKAGE_VERSION}" ] || PACKAGE_VERSION=$($PATH_VERSION_SCRIPT) || die "Failed to get default version of package"
readonly NAME_DISTFILES_FILE="gentoo-kernel-ps3-files-${PACKAGE_VERSION}.tar.xz"
readonly NAME_EBUILD_FILE="gentoo-kernel-ps3-${PACKAGE_VERSION}.ebuild"
readonly PATH_WORK="/var/tmp/ps3/gentoo-kernel-ps3/${PACKAGE_VERSION}/ebuild"
readonly PATH_WORK_DISTFILES="${PATH_WORK}/distfiles"
readonly PATH_WORK_DISTFILES_TAR="${PATH_WORK_DISTFILES}/${NAME_DISTFILES_FILE}"
readonly PATH_WORK_EBUILD_FILE="${PATH_WORK}/sys-kernel/gentoo-kernel-ps3/${NAME_EBUILD_FILE}"
readonly PATH_EBUILD_MANIFEST="${PATH_WORK}/sys-kernel/gentoo-kernel-ps3/Manifest"

# Verify data.
[ -d "${PATH_WORK}" ] || die "Workdir for version ${PACKAGE_VERSION} not found."
[ -f "${PATH_WORK_EBUILD_FILE}" ] || die "Ebuild for version ${PACKAGE_VERSION} not found."
[ -f "${PATH_WORK_DISTFILES_TAR}" ] || die "Distfiles for version ${PACKAGE_VERSION} not found."


# Create empty portage overlay structure.
#cp -rf "${KE_PATH_OVERLAY_DRAFT}"/* "${KE_PATH_WORK_EBUILD}"/


# Clear old Manifest file if eists:
[ ! -f "${PATH_EBUILD_MANIFEST}" ] || rm "${PATH_EBUILD_MANIFEST}" || die "Failed to remove old manifest at ${PATH_EBUILD_MANIFEST}"

# Create manifest and digest
cd "${PATH_WORK}" || die "Failed to open ${PATH_WORK}"
DISTDIR="${PATH_WORK_DISTFILES}" ebuild sys-kernel/gentoo-kernel-ps3/${NAME_EBUILD_FILE} manifest || die "Failed to build manifest"

# Clear other downloaded distfiles, except gentoo-kernel-ps3-files.
find "${PATH_WORK_DISTFILES}" ! -name "${NAME_DISTFILES_FILE}" -type f -exec rm {} + || die "Failed to prunt distfiles"
rm -rf "${PATH_WORK}/profiles" || die "Failed to remove profiles directory"
rm -rf "${PATH_WORK}/metadata" || die "Failed to remove metadata directory"

# TODO: Instead of pruning here, all should be stored, and during migration all duplicates should be removed.
# Prune manifest from files other than custom distfiles.
if ! while IFS= read -r line; do
    if [ -e "${PATH_WORK_DISTFILES}/$(echo "$line" | cut -d' ' -f2)" ]; then
        echo "$line"
    fi
done < "${PATH_EBUILD_MANIFEST}" > "${PATH_EBUILD_MANIFEST}.tmp"; then
    die "Failed to prune manifest"
fi
mv "${PATH_EBUILD_MANIFEST}.tmp" "${PATH_EBUILD_MANIFEST}"

