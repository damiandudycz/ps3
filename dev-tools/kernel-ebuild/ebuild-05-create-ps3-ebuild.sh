#!/bin/bash

source ../../.env-shared.sh || exit 1
source "${PATH_EXTRA_ENV_KERNEL_EBUILD}" || failure "Failed to load env ${PATH_EXTRA_ENV_KERNEL_EBUILD}"

# Validate values.
[[ -f "${KE_PATH_WORK_SRC_LINUX}/diffs" ]] || failure "missing ${KE_PATH_WORK_SRC_LINUX}/diffs"
[[ -f "${KE_PATH_WORK_SRC_LINUX}/defconfig" ]] || failure "missing ${KE_PATH_WORK_SRC_LINUX}/defconfig"

# Prepare additional error handling and cleanup before start.
register_failure_handler 'rm -rf "${PATH_WORK_EBUILD}";'
empty_directory "${KE_PATH_WORK_EBUILD}"

# Create local working directories.
mkdir -p "${KE_PATH_WORK_EBUILD}"

# Copy configuration files.
cp "${KE_PATH_WORK_SRC_LINUX}/diffs" "${KE_PATH_WORK_EBUILD}/${KE_NAME_FILE_CONF_DIFFS}"
cp "${KE_PATH_WORK_SRC_LINUX}/defconfig" "${KE_PATH_WORK_EBUILD}/${KE_NAME_FILE_CONF_DEFCONF}"

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
KE_COMMAND="--category ${CONF_KERNEL_PACKAGE_SPECIAL} --ebuild ${KE_PATH_EBUILD_FILE_DST} --version ${KE_PACKAGE_VERSION_SELECTED} --distfile ${KE_PATH_WORK_PATCHES} --distfile ${KE_PATH_WORK_EBUILD}/${KE_NAME_FILE_CONF_DIFFS} --distfile ${KE_PATH_WORK_EBUILD}/${KE_NAME_FILE_CONF_DEFCONF}"
[[ ! -z "${KE_FLAG_SAVE}" ]] && KE_COMMAND="${KE_COMMAND} --save"
source ${PATH_OVERLAY_SCRIPT_CREATE_PACKAGE} ${KE_COMMAND}
