#!/bin/bash

source ../../.env-shared.sh --silent || exit 1
source "${PATH_EXTRA_ENV_KERNEL_EBUILD}" || failure "Failed to load env ${PATH_EXTRA_ENV_KERNEL_EBUILD}"

# Check if latest files are stored.
readonly EBUILD_FILES_DIFF=$(diff "${KE_PATH_EBUILD_FILE_DST}" "${KE_PATH_OVERLAY_EBUILD_FILE_PACKAGE}" 2> /dev/null) || failure "Files ${KE_PATH_EBUILD_FILE_DST} ${KE_PATH_OVERLAY_EBUILD_FILE_PACKAGE} differ"
[[ ! ${EBUILD_FILES_DIFF} ]] || failure "Current version of ebuild not stored in overlay."

# Copy distfiles, so that they can be used by emerge without uploading to github.
cp "${KE_PATH_WORK_EBUILD_DISTFILES}"/* "${PATH_VAR_CACHE_DISTFILES}"/

# Build package using crossdev.
powerpc64-unknown-linux-gnu-emerge "${KE_NAME_PACKAGE_DST}"
