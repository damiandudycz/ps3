#!/bin/bash

[ ${RE_ENV_LOADED} ] && return 0; readonly RE_ENV_LOADED=true
#register_usage "$0"

readonly RE_VAL_TIMESTAMP=$(date -u +"%Y%m%dT%H%M%SZ")

# Paths
readonly RE_PATH_STAGE1="${PATH_WORK_RELEASE}/stage1-cell.$RE_VAL_TIMESTAMP.spec"
readonly RE_PATH_STAGE3="${PATH_WORK_RELEASE}/stage3-cell.$RE_VAL_TIMESTAMP.spec"
readonly RE_PATH_STAGE1_INSTALLCD="${PATH_WORK_RELEASE}/stage1-cell.installcd.$RE_VAL_TIMESTAMP.spec"
readonly RE_PATH_STAGE2_INSTALLCD="${PATH_WORK_RELEASE}/stage2-cell.installcd.$RE_VAL_TIMESTAMP.spec"
set_if   RE_VAL_INTERPRETER_ENTRY "${VAL_QEMU_IS_NEEDED}" "interpreter: ${PATH_QEMU_INTERPRETER}" ""

# TODO: Move to main env
readonly RE_PATH_LIVECD_OVERLAY_SRC="${PATH_DEV_TOOLS_RELEASE}/data/iso_overlay"
readonly RE_PATH_LIVECD_OVERLAY_DST="${PATH_WORK_RELEASE}/iso_overlay"
readonly RE_PATH_LIVECD_FSSCRIPT_SRC="${PATH_DEV_TOOLS_RELEASE}/data/iso_fsscript.sh"
readonly RE_PATH_LIVECD_FSSCRIPT_DST="${PATH_WORK_RELEASE}/iso_fsscript.sh"
readonly RE_PATH_SNAPSHOT_LOG="${PATH_WORK_RELEASE}/snapshot_log.txt"
readonly RE_PATH_RELEASE_INFO="${PATH_WORK_RELEASE}/release_latest"
