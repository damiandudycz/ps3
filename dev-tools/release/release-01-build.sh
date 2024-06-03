#!/bin/bash

# This script builds all the stages of a new release using catalyst.
# Before running this tool, please generate new stage files first, using
# release-prepare.sh.
# In the process, script also binds binhost repository to catalyst, so that catalyst can
# use and update binhost repository in the process. After finishing it unbinds binhost repository.

source ../../.env-shared.sh || exit 1
source "${PATH_EXTRA_ENV_RELEASE}" || failure "Failed to load env ${PATH_EXTRA_ENV_RELEASE}"
register_failure_handler "source ${PATH_BINHOST_SCRIPT_BIND} --unbind"

# Release information
readonly TIMESTAMP=$(cat "${RE_PATH_RELEASE_INFO}")
[ -z "${TIMESTAMP}" ] && failure "Failed to read current release details. Please run release-prepare.sh first."

# Release files paths
readonly PATH_STAGE1="${PATH_WORK_RELEASE}/stage1-cell.$TIMESTAMP.spec"
readonly PATH_STAGE3="${PATH_WORK_RELEASE}/stage3-cell.$TIMESTAMP.spec"
readonly PATH_STAGE1_INSTALLCD="${PATH_WORK_RELEASE}/stage1-cell.installcd.$TIMESTAMP.spec"
readonly PATH_STAGE2_INSTALLCD="${PATH_WORK_RELEASE}/stage2-cell.installcd.$TIMESTAMP.spec"

# Bind binhost
source ${PATH_BINHOST_SCRIPT_BIND} --bind

# Building release
catalyst -af "${PATH_STAGE1}"
catalyst -af "${PATH_STAGE3}"
catalyst -af "${PATH_STAGE1_INSTALLCD}"
catalyst -af "${PATH_STAGE2_INSTALLCD}"

# Unbind binhost
source ${PATH_BINHOST_SCRIPT_BIND} --unbind
