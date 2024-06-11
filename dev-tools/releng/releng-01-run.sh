#!/bin/bash

source ../../.env-shared.sh || exit 1
source "${PATH_EXTRA_ENV_RELENG}" || failure "Failed to load env ${PATH_EXTRA_ENV_RELENG}"

[[ ! -d "${PATH_WORK_RELENG}" ]] && failure "No work files at ${PATH_WORK_RELENG}"
cd ${PATH_WORK_RELENG}
${PATH_RELENG_CATALYST_AUTO} -X -v -j ${CONF_CATALYST_JOBS} -c ${RL_PATH_CATALYST_AUTO_CONF_DST}
