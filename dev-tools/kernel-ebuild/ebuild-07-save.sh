#!/bin/bash

#readonly NAME_EBUILD_FILE="gentoo-kernel-ps3-${PACKAGE_VERSION}.ebuild"
#readonly NAME_DISTFILES_FILE="gentoo-kernel-ps3-files-${PACKAGE_VERSION}.tar.xz"
#readonly NAME_DISTFILES_DIST_ENTRY="DIST ${NAME_DISTFILES_FILE}"
#readonly PATH_WORK="/var/tmp/ps3/gentoo-kernel-ps3/${PACKAGE_VERSION}/ebuild"
#readonly PATH_WORK_DISTFILES="${PATH_WORK}/distfiles"
#readonly PATH_WORK_DISTFILES_TAR="${PATH_WORK_DISTFILES}/${NAME_DISTFILES_FILE}"
#readonly PATH_WORK_EBUILD_FILE="${PATH_WORK}/sys-kernel/gentoo-kernel-ps3/${NAME_EBUILD_FILE}"
#readonly PATH_EBUILD_MANIFEST="${PATH_WORK}/sys-kernel/gentoo-kernel-ps3/Manifest"
#readonly PATH_OVERLAY_MAIN="${PATH_ROOT}/overlays/ps3-gentoo-overlay"
#readonly PATH_OVERLAY_EBUILDS="${PATH_OVERLAY_MAIN}"
#readonly PATH_OVERLAY_DISTFILES="${PATH_OVERLAY_MAIN}.distfiles"
#readonly PATH_OVERLAY_MANIFEST="${PATH_OVERLAY_EBUILDS}/sys-kernel/gentoo-kernel-ps3/Manifest"

# Verify data.
#[ -d "${PATH_WORK}" ] || die "Workdir for version ${PACKAGE_VERSION} not found."
#[ -f "${PATH_WORK_EBUILD_FILE}" ] || die "Ebuild for version ${PACKAGE_VERSION} not found."
#[ -d "${PATH_WORK_DISTFILES}" ] || die "Distfiles for version ${PACKAGE_VERSION} not found."
#[ -f "${PATH_EBUILD_MANIFEST}" ] || die "Manifest for version ${PACKAGE_VERSION} not found."

# Copy distfiles and ebuild
cp -rf "${PATH_WORK_DISTFILES}"/* "${PATH_OVERLAY_DISTFILES}/sys-kernel/gentoo-kernel-ps3"/ || die "Failed to copy distfiles"
cp -f "${PATH_WORK_EBUILD_FILE}" "${PATH_OVERLAY_EBUILDS}/sys-kernel/gentoo-kernel-ps3/${NAME_EBUILD_FILE}" || die "Failed to copy ebuild"

# Prune old manifest file from entries about ${NAME_DISTFILES_FILE} and add new entry
sed -i "/${NAME_DISTFILES_DIST_ENTRY}/d" "${PATH_OVERLAY_MANIFEST}" || die "Failed to prune Manifest from old entries"
cat "${PATH_EBUILD_MANIFEST}" >> "${PATH_OVERLAY_MANIFEST}" || die "Failed to add new entry to Manifest"
