#!/bin/bash

source ../../.env-shared.sh || exit 1
source "${PATH_EXTRA_ENV_KERNEL_EBUILD}" || { echo "Failed to load env ${PATH_EXTRA_ENV_KERNEL_EBUILD}"; exit 1; }

[[ ! -d "${KE_PATH_WORK_VERSION_PATCHES}" ]] || failure "Patches already applied"
[[ -d "${KE_PATH_WORK_PATCHES_SRC}" ]] || failure "Pathes source folder not found: ${KE_PATH_WORK_PATCHES_SRC}"

apply_patches() {
    local patch_dir=$1
    for PATCH in "$patch_dir"/*.patch; do
        [ -e "$PATCH" ] || continue
        echo "Apply patch ${PATCH}:"
        patch --batch --force -p1 -i "${PATCH}" -d "${KE_PATH_WORK_SRC_LINUX}"
    done
}

# Link patches
ln -s "${KE_PATH_WORK_PATCHES_SRC}" "${KE_PATH_WORK_VERSION_PATCHES}"

# Apply PS3 patches.
find -L "${KE_PATH_WORK_VERSION_PATCHES}" -type d | while read -r subdir; do
    apply_patches "${subdir}"
done
