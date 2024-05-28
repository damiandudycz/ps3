#!/bin/bash

# This script emerges gentoo-sources package of given version to local temp directory.
# Gentoo-Sources is emerged instead of Gentoo-Kernel, because it's only needed to patch and modify the sources.
# It's not needed to actually build and install kernel at this stage, hence gentoo-sources fits this puropuse better.
# If package was already downloaded, this will remove the previous version.
# Pass the version number as a parameter of this function.
# If no version is specified, script will use current stable version available.

clean_download_folder_on_failure() {
    [ ! -d "${KE_PATH_WORK_SRC}" ] || rm -rf "${KE_PATH_WORK_SRC}" || echo "Failed to cleanup ${KE_PATH_WORK_SRC}"
}

# --- Shared environment
source ../../.env-shared.sh || exit 1
source "${PATH_EXTRA_ENV_KERNEL_EBUILD}" || failure "Failed to load env ${PATH_EXTRA_ENV_KERNEL_EBUILD}"
trap 'clean_download_folder_on_failure; failure' ERR
register_usage "$0 [package_version]"

# Prepare workdir.
[ ! -d "${KE_PATH_WORK_SRC}" ] || rm -rf "${KE_PATH_WORK_SRC}"
mkdir -p "${KE_PATH_WORK_SRC}"

PORTAGE_TMPDIR="${KE_PATH_WORK_SRC}" ebuild "${KEY_PATH_EBUILD_FILE_SRC}" configure
