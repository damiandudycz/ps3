#!/bin/bash

# Load environment.
source ../../.env-shared.sh || exit 1
source "${PATH_EXTRA_ENV_KERNEL_EBUILD}" || failure "Failed to load env ${PATH_EXTRA_ENV_KERNEL_EBUILD}"

# Prepare additional error handling and cleanup before start.
register_failure_handler 'rm -rf "${KE_PATH_WORK_SRC}";'
empty_directory "${KE_PATH_WORK_SRC}"

# Download ebuild files.
PORTAGE_TMPDIR="${KE_PATH_WORK_SRC}" ebuild "${KE_PATH_EBUILD_FILE_SRC}" configure
