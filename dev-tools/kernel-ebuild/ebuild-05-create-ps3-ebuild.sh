#!/bin/bash

# Load environment.
source ../../.env-shared.sh || exit 1
source "${PATH_EXTRA_ENV_KERNEL_EBUILD}" || failure "Failed to load env ${PATH_EXTRA_ENV_KERNEL_EBUILD}"

echo "Version: $KE_PACKAGE_VERSION_SELECTED"

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
mkdir -p "${KE_PATH_WORK_EBUILD_PACKAGE}"
mkdir -p "${KE_PATH_WORK_EBUILD_DISTFILES}"
mkdir -p "${KE_PATH_WORK_EBUILD_DISTFILES_PATCHES}"

# Geather files.
cp -f "${KE_PATH_PATCHES_SELECTED}"/*.patch "${KE_PATH_WORK_EBUILD_DISTFILES_PATCHES}"/
cp -f "${KE_PATH_CONFIG_DIFFS_SELECTED}" "${KE_PATH_EBUILD_FILE_DISTFILES_DIFFS}"
cp -f "${KE_PATH_CONFIG_DEFCONF_SELECTED}" "${KE_PATH_EBUILD_FILE_DISTFILES_DEFCONF}"

# Create distfiles tarball.
tar --sort=name --mtime="" --owner=0 --group=0 --numeric-owner --pax-option=exthdr.name=%d/PaxHeaders/%f,delete=atime,delete=ctime \
    -caf "${KE_PATH_EBUILD_FILE_DISTFILES_TAR}" -C "${KE_PATH_WORK_EBUILD_DISTFILES}" "${KE_LIST_DISTFILES[@]}"
rm -rf "${KE_PATH_WORK_EBUILD_DISTFILES_PATCHES}"
rm -rf "${KE_PATH_EBUILD_FILE_DISTFILES_DIFFS}"
rm -rf "${KE_PATH_EBUILD_FILE_DISTFILES_DEFCONF}"

# Create patched ebuild file and apply patches
cp "${KE_PATH_EBUILD_FILE_SRC}" "${KE_PATH_EBUILD_FILE_DST}"
for PATCH in "${KE_PATH_EBUILD_PATCHES}"/*.patch; do
    echo "Apply patch ${PATCH}:"
    patch --batch --force -p0 -i "${PATCH}" "${KE_PATH_EBUILD_FILE_DST}"
done

# Unmask if selected
if [[ ${KE_FLAG_UNMASK} ]]; then
    echo "Unmasking ebuild ${KE_PATH_EBUILD_FILE_DST}"
    sed -i "s/\(KEYWORDS=.*\)${KE_VAR_EBUILD_KEYWORD_UNSTABLE}/\1${KE_VAR_EBUILD_KEYWORD_DEFAULT}/" "${KE_PATH_EBUILD_FILE_DST}"
fi
