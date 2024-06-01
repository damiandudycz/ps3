#!/bin/bash

source ../../.env-shared.sh || exit 1
source "${PATH_EXTRA_ENV_KERNEL_EBUILD}" || failure "Failed to load env ${PATH_EXTRA_ENV_KERNEL_EBUILD}"

# Apply PS3 patches.
for PATCH in "${KE_PATH_PATCHES_SELECTED}"/*.patch; do
    echo "Apply patch ${PATCH}:"
    patch --batch --force -p1 -i "${PATCH}" -d "${KE_PATH_WORK_SRC_LINUX}"
done

# Save used patches if used default patches folder.
if [[ "${KE_PATH_PATCHES_SELECTED}" != "${KE_PATH_PATCHES_VERSIONED}" ]]; then
    if [[ ${KE_FLAG_SAVE} ]]; then
        echo "Saving default patches to ${KE_PATH_PATCHES_VERSIONED}"
        empty_directory "${KE_PATH_PATCHES_VERSIONED}"
        cp "${KE_PATH_PATCHES_SELECTED}"/*.patch "${KE_PATH_PATCHES_VERSIONED}"/
    else
        echo_color ${COLOR_RED} "Patches not stored for current version ${KE_PACKAGE_VERSION}. Please use --save flag!"
    fi
fi

# Save in default folder if needed.
if [[ "${KE_PATH_PATCHES_SELECTED}" != "${KE_PATH_PATCHES_DEFAULT}" ]]; then
    if [[ ${KE_FLAG_SAVE_DEFAULT} ]]; then
        echo "Saving default patches to ${KE_PATH_PATCHES_DEFAULT}"
        empty_directory "${KE_PATH_PATCHES_DEFAULT}"
        cp "${KE_PATH_PATCHES_SELECTED}"/*.patch "${KE_PATH_PATCHES_DEFAULT}"/
    fi
fi
