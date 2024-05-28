#!/bin/bash

source ../../.env-shared.sh || exit 1
source "${PATH_EXTRA_ENV_KERNEL_EBUILD}" || failure "Failed to load env ${PATH_EXTRA_ENV_KERNEL_EBUILD}"
register_failure_handler clean_download_folder_on_failure
register_usage "$0 [package_version]"

clean_download_folder_on_failure() {
    rm -rf "${KE_PATH_WORK_SRC}" || echo "Failed to cleanup ${KE_PATH_WORK_SRC}"
}

empty_directory "${KE_PATH_WORK_SRC}"

PORTAGE_TMPDIR="${KE_PATH_WORK_SRC}" ebuild "${KEY_PATH_EBUILD_FILE_SRC}" configure
