#!/bin/bash

source ../../.env-shared.sh --silent || exit 1
source "${PATH_EXTRA_ENV_KERNEL_EBUILD}" || failure "Failed to load env ${PATH_EXTRA_ENV_KERNEL_EBUILD}"

# Check if latest files are stored.
readonly EBUILD_FILES_DIFF=$(diff "${KE_PATH_EBUILD_FILE_DST}" "${KE_PATH_OVERLAY_EBUILD_FILE_PACKAGE}" 2> /dev/null) || failure "Files ${KE_PATH_EBUILD_FILE_DST} ${KE_PATH_OVERLAY_EBUILD_FILE_PACKAGE} differ"
[[ ! ${EBUILD_FILES_DIFF} ]] || failure "Current version of ebuild not stored in overlay."

empty_directory "${KE_PATH_WORK_BINPKGS}"
empty_directory "${KE_PATH_CROSSDEV_BINPKGS_KERNEL_PACKAGE}"

# Copy everything from distfiles overlay to cache, so that it's available during emerge even if packages were not yet uploaded to git.
source ${PATH_OVERLAY_SCRIPT_COPY_PS3_FILES}

# Build package using crossdev.
PORTDIR_OVERLAY="${PATH_OVERLAYS_PS3_GENTOO}" ${CONF_CROSSDEV_TARGET}-emerge --buildpkgonly "=${KE_NAME_PACKAGE_DST_VERSIONED}"

# Save binpkgs generaged by crossdev in KE_PATH_WORK_PKG.
cp "${KE_PATH_CROSSDEV_BINPKGS_KERNEL_PACKAGE}"/* "${KE_PATH_WORK_BINPKGS}"/
