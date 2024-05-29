#!/bin/bash

# Load environment.
source ../../.env-shared.sh || exit 1
source "${PATH_EXTRA_ENV_KERNEL_EBUILD}" || failure "Failed to load env ${PATH_EXTRA_ENV_KERNEL_EBUILD}"

# Verify data.
[ -f "${KE_PATH_EBUILD_FILE_DISTFILES_TAR}" ] || failure "KE_PATH_EBUILD_FILE_DISTFILES_TAR not found at ${KE_PATH_EBUILD_FILE_DISTFILES_TAR}"
[ -f "${KE_PATH_EBUILD_FILE_DST}" ] || failure "KE_PATH_EBUILD_FILE_DST not found at ${KE_PATH_EBUILD_FILE_DST}"

clear_repo_files() {
    for FILE in "${KE_PATH_OVERLAY_DRAFT}"/*; do
        FILENAME=$(basename "${FILE}")
        rm -rf "${KE_PATH_WORK_EBUILD}/${FILENAME}"
    done
}
register_failure_handler clear_repo_files

clear_repo_files
rm -f "${KE_PATH_EBUILD_FILE_MANIFEST}"

# Copy empty portage overlay structure.
cp -rf "${KE_PATH_OVERLAY_DRAFT}"/* "${KE_PATH_WORK_EBUILD}"/

# Create manifest.
DISTDIR="${KE_PATH_WORK_EBUILD_DISTFILES}" ebuild "${KE_PATH_EBUILD_FILE_DST}" manifest

# Clear other downloaded distfiles, except gentoo-kernel-ps3-files.
find "${KE_PATH_WORK_EBUILD_DISTFILES}" ! -name "${KE_NAME_EBUILD_FILE_DISTFILES_TAR}" -type f -exec rm {} +
clear_repo_files
