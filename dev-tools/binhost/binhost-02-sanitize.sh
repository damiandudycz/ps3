#!/bin/bash

# This function removes packages larger than size limit in github.

source ../../.env-shared.sh || exit 1

readonly PATH_DELETE_SCRIPT="${PATH_DEV_TOOLS_BINHOST}/binhost-01-delete-packages.sh"

source ${PATH_DELETE_SCRIPT} --if-larger ${CONF_GIT_FILE_SIZE_LIMIT}
