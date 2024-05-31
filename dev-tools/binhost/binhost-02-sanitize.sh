#!/bin/bash

# This function removes packages larger than size limit in github.

source ../../.env-shared.sh || exit 1

source ${PATH_BINHOST_SCRIPT_DELETE} --if-larger ${CONF_GIT_FILE_SIZE_LIMIT}
