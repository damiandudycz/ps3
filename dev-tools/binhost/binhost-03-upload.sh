#!/bin/bash

# This tool uploads current state of binhost repository to github.
# Before running, please use binhost-sanitize.sh, to remove packages
# that are too large for github.

# --- Shared environment
source ../../.env-shared.sh || exit 1

readonly PATH_BINHOST="${PATH_BINHOSTS_PS3_GENTOO}/${CONF_CATALYST_RELEASE_NAME_DFAULT}"
upload_repository "${PATH_BINHOST}" "Binhost automatic update"
