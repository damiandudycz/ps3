#!/bin/bash

# This function removes packages larger than size limit in github.

# --- Shared environment
source ../../.env-shared.sh || exit 1
trap failure ERR
register_usage "$0 <pckage>[-version] | --if-larger <SIZE_LIMIT>"

readonly CONF_SIZE_LIMIT="100M"
readonly PATH_DELETE_SCRIPT="${PATH_DEV_TOOLS_BINHOST}/binhost-01-delete-packages.sh"

source ${PATH_DELETE_SCRIPT} --if-larger ${CONF_SIZE_LIMIT}
