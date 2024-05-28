#!/bin/bash

# This script generates PS3 kernel configuration.
# First it executes make ps3_defconfig to generate default PS3 configuration for current kernel.
# Next it applies changes stored in data/configs/<version> or /data/configs/default if configuration for
# selected version doesn't exists.
# If you add flag --default it will use default configuration instead.
# If you select --edit flag, system will display menuconfig, allowing you to customize configuration.
# Finally it stores selected configuration differences from default PS3_Defconfig in data/configs/<version>.

# --- Shared environment
source ../../.env-shared.sh || exit 1
source "${PATH_EXTRA_ENV_KERNEL_EBUILD}" || failure "Failed to load env ${PATH_EXTRA_ENV_KERNEL_EBUILD}"
register_usage "$0 [package_version] [--edit] [--default] [--pretend]"

[ -d "${KE_PATH_WORK_SRC}" ] || failure "${KE_PATH_WORK_SRC} not found. Please run ebuild-emerge-gentoo-sources.sh <version> first."

echo "Config used: ${KE_PATH_CONFIG_SELECTED}"

cd "${KE_PATH_WORK_SRC_LINUX}"
# Make default PS3 Defconfig.
ARCH=powerpc make ${KE_NAME_EBUILD_DEFCONFIG}
# Apply changes from diffs.
${KE_PATH_SCRIPT_APPLY_DIFFCONFIG} ${KE_PATH_CONFIG_SELECTED}/diffs ./.config > .config_modified
# Merge modified config.
ARCH=powerpc ${KE_PATH_SCRIPT_MERGE_CONFIG} .config_modified
# Menuconfig.
[ ${KE_FLAG_EDIT} ] && ARCH=powerpc make menuconfig
# Create modified defconfig.
ARCH=powerpc make savedefconfig
# Generate diffs from default PS3 Defconfig
${KE_PATH_SCRIPT_DIFFCONFIG} "arch/powerpc/configs/${KE_NAME_EBUILD_DEFCONFIG}" defconfig > diffs

# Save versioned configs
if [ ${KE_FLAG_SAVE} ]; then
    [ ! -d "${KE_PATH_CONFIG_SAVETO}" ] && mkdir -p "${KE_PATH_CONFIG_SAVETO}"
    mv "defconfig" "${KE_PATH_CONFIG_SAVETO}"/defconfig
    mv "diffs" "${KE_PATH_CONFIG_SAVETO}"/diffs
    echo "Configuration stored in ${KE_PATH_CONFIG_SAVETO}"
else
    echo_color ${COLOR_RED} "Configuration not stored! Please use --save flag, unless just testing."
fi

# Cleanup
rm -f defconfig diffs .config_modified
