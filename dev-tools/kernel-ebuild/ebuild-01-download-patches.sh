#!/bin/bash

source ../../.env-shared.sh || exit 1
source "${PATH_EXTRA_ENV_KERNEL_EBUILD}" || failure "Failed to load env ${PATH_EXTRA_ENV_KERNEL_EBUILD}"

# Prepare additional error handling and cleanup before start.
register_failure_handler 'rm -rf "${KE_PATH_PATCHES_SAVETO}";'
empty_directory "${KE_PATH_PATCHES_SAVETO}"

# Load URL of patches to download.
readarray -t URL_PS3_PATCHES < <(grep -vE '^\s*#|^\s*$' "${KE_PATH_PATCHES_FETCH_LIST}")

# Download patches.
echo "Downloading patches to ${KE_PATH_PATCHES_SAVETO}"
cd "${KE_PATH_PATCHES_SAVETO}"
for URL_PATCH in "${URL_PS3_PATCHES[@]}"; do
    echo "${URL_PATCH}"
    wget "${URL_PATCH}" --quiet
done
