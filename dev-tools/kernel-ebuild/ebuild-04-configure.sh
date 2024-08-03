#!/bin/bash

source ../../.env-shared.sh || exit 1
source "${PATH_EXTRA_ENV_KERNEL_EBUILD}" || failure "Failed to load env ${PATH_EXTRA_ENV_KERNEL_EBUILD}"

# Validate values.
[[ -d "${KE_PATH_WORK_SRC}" ]] || failure "KE_PATH_WORK_SRC: ${KE_PATH_WORK_SRC} not found."

# Prepare additional error handling and cleanup before start.
KE_EBUILD_CONFIGURE_FILES_TO_CLEAN="defconfig diffs .config_modified"
register_failure_handler "rm -f ${KE_EBUILD_CONFIGURE_FILES_TO_CLEAN};"

# Open SRC directory.
cd "${KE_PATH_WORK_SRC_LINUX}"

# Make default PS3 Defconfig.
if [[ ! -f "diffs" ]]; then
    ARCH=powerpc make ${KE_NAME_FILE_EBUILD_DEFCONFIG}
    # Apply changes from diffs.
    if [[ -f "${KE_PATH_DATA_CONFIG_DIFFS}" ]]; then
        ruby ${KE_PATH_SCRIPT_APPLY_DIFFCONFIG} ${KE_PATH_DATA_CONFIG_DIFFS} ./.config > .config_modified
        ARCH=powerpc ${KE_PATH_SCRIPT_MERGE_CONFIG} .config_modified
    fi
fi

# Menuconfig.
[[ ${KE_FLAG_EDIT} ]] && ARCH=powerpc make menuconfig

# Create modified defconfig.
ARCH=powerpc make savedefconfig

# Generate diffs from default PS3 Defconfig.
${KE_PATH_SCRIPT_DIFFCONFIG} "arch/powerpc/configs/${KE_NAME_FILE_EBUILD_DEFCONFIG}" defconfig > diffs

# Save versioned configs.
if [[ ${KE_FLAG_SAVE} ]]; then
    cp "diffs" "${KE_PATH_DATA_CONFIG_DIFFS}"
    echo "Configuration stored in ${KE_PATH_DATA_CONFIG_DIFFS}"
fi
