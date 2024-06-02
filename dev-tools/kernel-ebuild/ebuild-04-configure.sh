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

echo "Config used: ${KE_PATH_CONFIG_SELECTED}"

# Make default PS3 Defconfig.
ARCH=powerpc make ${KE_NAME_FILE_EBUILD_DEFCONFIG}

# Apply changes from diffs.
echo "${KE_PATH_SCRIPT_APPLY_DIFFCONFIG} ${KE_PATH_CONFIG_SELECTED}/${KE_NAME_FILE_CONF_DIFFS} ./.config > .config_modified"
source ${KE_PATH_SCRIPT_APPLY_DIFFCONFIG} ${KE_PATH_CONFIG_SELECTED}/${KE_NAME_FILE_CONF_DIFFS} ./.config > .config_modified

# Merge modified config.
ARCH=powerpc ${KE_PATH_SCRIPT_MERGE_CONFIG} .config_modified

# Menuconfig.
[[ ${KE_FLAG_EDIT} ]] && ARCH=powerpc make menuconfig

# Create modified defconfig.
ARCH=powerpc make savedefconfig

# Generate diffs from default PS3 Defconfig.
source ${KE_PATH_SCRIPT_DIFFCONFIG} "arch/powerpc/configs/${KE_NAME_FILE_EBUILD_DEFCONFIG}" defconfig > diffs

# Save versioned configs.
if [[ ${KE_FLAG_SAVE} ]]; then
    [[ ! -d "${KE_PATH_CONFIG_SAVETO}" ]] && mkdir -p "${KE_PATH_CONFIG_SAVETO}"
    cp "defconfig" "${KE_PATH_CONFIG_DEFCONF_SAVETO}"
    cp "diffs" "${KE_PATH_CONFIG_DIFFS_SAVETO}"
    echo "Configuration stored in ${KE_PATH_CONFIG_SAVETO}"
else
    echo_color ${COLOR_RED} "Configuration not stored for version ${KE_PACKAGE_VERSION_SELECTED}! Please use --save flag, unless just testing."
fi

if [[ ${KE_FLAG_SAVE_DEFAULT} ]]; then
    [[ ! -d "${KE_PATH_CONFIG_DEFAULT}" ]] && mkdir -p "${KE_PATH_CONFIG_DEFAULT}"
    cp "defconfig" "${KE_PATH_CONFIG_DEFCONF_DEFAULT}"
    cp "diffs" "${KE_PATH_CONFIG_DIFFS_DEFAULT}"
    echo "Configuration stored in ${KE_PATH_CONFIG_DEFAULT}"
fi

# Cleanup.
rm -f ${KE_EBUILD_CONFIGURE_FILES_TO_CLEAN}
