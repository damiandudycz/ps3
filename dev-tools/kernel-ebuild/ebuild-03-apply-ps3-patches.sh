#!/bin/bash

source ../../.env-shared.sh || exit 1
source "${PATH_EXTRA_ENV_KERNEL_EBUILD}" || { echo "Failed to load env ${PATH_EXTRA_ENV_KERNEL_EBUILD}"; exit 1; }

apply_patches() {
    local patch_dir=$1
    for PATCH in "$patch_dir"/*.patch; do
        [ -e "$PATCH" ] || continue
        echo "Apply patch ${PATCH}:"
        patch --batch --force -p1 -i "${PATCH}" -d "${KE_PATH_WORK_SRC_LINUX}"
    done
}

# Apply PS3 patches.
find "${KE_PATH_WORK_PATCHES}" -type d | while read -r subdir; do
    apply_patches "${subdir}"
done
