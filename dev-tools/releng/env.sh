#!/bin/bash

[ ${RL_ENV_LOADED} ] && return 0; readonly RL_ENV_LOADED=true

# Input parsing.
declare -a RL_TARGETS
declare -a RL_SKIP
while [ $# -gt 0 ]; do case "$1" in
    --clean)        RL_FLAG_CLEAN=true;;
    --use)   shift; RL_SKIP+=("$1");;
    *)              RL_TARGETS+=("$1")
esac; shift; done

readonly RL_PUBLIC_STAGES=(3 4) # Create latest-stage<num>.txt for these stages.
readonly RL_PUBLIC_ISOS=("minimal")
readonly RL_PATH_CATALYST_AUTO_CONF_DST="${PATH_WORK_RELENG}/catalyst-auto-ps3.conf"
set_if   RL_VAL_INTERPRETER_ENTRY "${CONF_QEMU_IS_NEEDED}" "interpreter: ${CONF_QEMU_INTERPRETER}" ""
