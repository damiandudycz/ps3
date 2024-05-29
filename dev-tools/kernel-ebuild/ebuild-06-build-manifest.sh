#!/bin/bash

# Load environment.
source ../../.env-shared.sh || exit 1
source "${PATH_EXTRA_ENV_KERNEL_EBUILD}" || failure "Failed to load env ${PATH_EXTRA_ENV_KERNEL_EBUILD}"

# Verify data.
[[ -f "${KE_PATH_EBUILD_FILE_DISTFILES_TAR}" ]] || failure "KE_PATH_EBUILD_FILE_DISTFILES_TAR not found at ${KE_PATH_EBUILD_FILE_DISTFILES_TAR}"
[[ -f "${KE_PATH_EBUILD_FILE_DST}" ]] || failure "KE_PATH_EBUILD_FILE_DST not found at ${KE_PATH_EBUILD_FILE_DST}"

# Create manifest.
DISTDIR="${KE_PATH_WORK_EBUILD_DISTFILES}" ebuild "${KE_PATH_EBUILD_FILE_DST}" manifest clean

# Clear other downloaded distfiles, except gentoo-kernel-ps3-files.
find "${KE_PATH_WORK_EBUILD_DISTFILES}" ! -name "${KE_NAME_EBUILD_FILE_DISTFILES_TAR}" -type f -exec rm {} +
