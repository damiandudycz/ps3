#!/bin/bash

source ../../.env-shared.sh || exit 1
source "${PATH_EXTRA_ENV_KERNEL_EBUILD}" || failure "Failed to load env ${PATH_EXTRA_ENV_KERNEL_EBUILD}"

# Validate values.
[[ -d "${KE_PATH_PATCHES_VERSIONED}" ]] || echo_color $COLOR_RED "WARNING! ${KE_PATH_PATCHES_VERSIONED} does not exists. Will try to use default files."
[[ -f "${KE_PATH_CONFIG_DIFFS_VERSIONED}" ]] || echo_color $COLOR_RED "WARNING! ${KE_PATH_CONFIG_DIFFS_VERSIONED} does not exists. Will try to use default file."
[[ -f "${KE_PATH_CONFIG_DEFCONF_VERSIONED}" ]] || echo_color $COLOR_RED "WARNING! ${KE_PATH_CONFIG_DEFCONF_VERSIONED} does not exists. Will try to use default file."
[[ -d "${KE_PATH_PATCHES_SELECTED}" ]] || failure "KE_PATH_PATCHES_SELECTED: ${KE_PATH_PATCHES_VERSIONED} does not exists."
[[ -f "${KE_PATH_CONFIG_DIFFS_SELECTED}" ]] || failure "KE_PATH_CONFIG_DIFFS_SELECTED: ${KE_PATH_CONFIG_DIFFS_VERSIONED} does not exists."
[[ -f "${KE_PATH_CONFIG_DEFCONF_SELECTED}" ]] || failure "KE_PATH_CONFIG_DEFCONF_SELECTED: ${KE_PATH_CONFIG_DEFCONF_VERSIONED} does not exists."

# Prepare additional error handling and cleanup before start.
register_failure_handler 'rm -rf "${PATH_WORK_EBUILD}";'
empty_directory "${KE_PATH_WORK_EBUILD}"

# Create local working directories..
mkdir -p "${KE_PATH_WORK_EBUILD}"

# Create ebuild file and apply patches.
cp "${KE_PATH_EBUILD_FILE_SRC}" "${KE_PATH_EBUILD_FILE_DST}"
for PATCH in "${KE_PATH_EBUILD_PATCHES}"/*.patch; do
    echo "Apply patch ${PATCH}:"
    patch --batch --force -p0 -i "${PATCH}" "${KE_PATH_EBUILD_FILE_DST}"
done

# Unmask if selected.
if [[ ${KE_FLAG_UNMASK} ]]; then
    echo "Unmasking ebuild ${KE_PATH_EBUILD_FILE_DST}"
    sed -i "s/\(KEYWORDS=.*\)~${CONF_TARGET_ARCH}/\1${CONF_TARGET_ARCH}/" "${KE_PATH_EBUILD_FILE_DST}"
fi

# Create package
KE_COMMAND="--category ${CONF_KERNEL_PACKAGE_SPECIAL} --ebuild ${KE_PATH_EBUILD_FILE_DST} --version ${KE_PACKAGE_VERSION_SELECTED} --distfile ${KE_PATH_PATCHES_SELECTED} --distfile ${KE_PATH_CONFIG_DIFFS_SELECTED} --distfile ${KE_PATH_CONFIG_DEFCONF_SELECTED}"
[[ ! -z "${KE_FLAG_SAVE}" ]] && KE_COMMAND="${KE_COMMAND} --save"
source ${PATH_OVERLAY_SCRIPT_CREATE_PACKAGE} ${KE_COMMAND}
