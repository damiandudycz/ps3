#!/bin/bash

[ ${RL_ENV_LOADED} ] && return 0; readonly RL_ENV_LOADED=true

# File names
readonly RL_CONF_STAGE1_NAME="stage1-openrc-23.spec"
readonly RL_CONF_STAGE3_NAME="stage3-openrc-23.spec"
readonly RL_CONF_STAGE4_NAME="stage4-openrc-23.spec"
readonly RL_CONF_INSTALLCD_STAGE1_NAME="installcd-stage1.spec"
readonly RL_CONF_INSTALLCD_STAGE2_NAME="installcd-stage2-minimal.spec"
readonly RL_CONF_CATALYST_AUTO_CONF_NAME="catalyst-auto-ps3.conf"
readonly RL_CONF_ISO_OVERLAY_NAME="iso_overlay"
readonly RL_CONF_ISO_FSSCRIPT_NAME="iso_fsscript.sh"
#readonly RL_CONF_SNAPSHOT_LOG_NAME="snapshot_log.txt"

# Paths
readonly RL_PATH_CATALYST_AUTO_CONF_SRC="${PATH_RELENG_DATA}/${RL_CONF_CATALYST_AUTO_CONF_NAME}"
readonly RL_PATH_CATALYST_AUTO_CONF_DST="${PATH_WORK_RELENG}/${RL_CONF_CATALYST_AUTO_CONF_NAME}"
readonly RL_PATH_SPECS_PS3_SRC="${PATH_RELENG_DATA_SPEC}/cell/ps3"
readonly RL_PATH_SPECS_PS3_DST="${PATH_WORK_RELENG}/specs/cell/ps3"
readonly RL_PATH_STAGE1_SRC="${RL_PATH_SPECS_PS3_SRC}/${RL_CONF_STAGE1_NAME}"
readonly RL_PATH_STAGE1_DST="${RL_PATH_SPECS_PS3_DST}/${RL_CONF_STAGE1_NAME}"
readonly RL_PATH_STAGE3_SRC="${RL_PATH_SPECS_PS3_SRC}/${RL_CONF_STAGE3_NAME}"
readonly RL_PATH_STAGE3_DST="${RL_PATH_SPECS_PS3_DST}/${RL_CONF_STAGE3_NAME}"
readonly RL_PATH_STAGE4_SRC="${RL_PATH_SPECS_PS3_SRC}/${RL_CONF_STAGE4_NAME}"
readonly RL_PATH_STAGE4_DST="${RL_PATH_SPECS_PS3_DST}/${RL_CONF_STAGE4_NAME}"
readonly RL_PATH_STAGE1_INSTALLCD_SRC="${RL_PATH_SPECS_PS3_SRC}/${RL_CONF_INSTALLCD_STAGE1_NAME}"
readonly RL_PATH_STAGE1_INSTALLCD_DST="${RL_PATH_SPECS_PS3_DST}/${RL_CONF_INSTALLCD_STAGE1_NAME}"
readonly RL_PATH_STAGE2_INSTALLCD_SRC="${RL_PATH_SPECS_PS3_SRC}/${RL_CONF_INSTALLCD_STAGE2_NAME}"
readonly RL_PATH_STAGE2_INSTALLCD_DST="${RL_PATH_SPECS_PS3_DST}/${RL_CONF_INSTALLCD_STAGE2_NAME}"
readonly RL_PATH_LIVECD_OVERLAY_SRC="${PATH_RELENG_DATA}/${RL_CONF_ISO_OVERLAY_NAME}"
readonly RL_PATH_LIVECD_OVERLAY_DST="${PATH_WORK_RELENG}/${RL_CONF_ISO_OVERLAY_NAME}"
readonly RL_PATH_LIVECD_FSSCRIPT_SRC="${PATH_RELENG_DATA}/${RL_CONF_ISO_FSSCRIPT_NAME}"
readonly RL_PATH_LIVECD_FSSCRIPT_DST="${PATH_WORK_RELENG}/${RL_CONF_ISO_FSSCRIPT_NAME}"
#readonly RL_PATH_SNAPSHOT_LOG="${PATH_WORK_RELENG}/${RL_CONF_SNAPSHOT_LOG_NAME}"
set_if   RL_VAL_INTERPRETER_ENTRY "${CONF_QEMU_IS_NEEDED}" "interpreter: ${CONF_QEMU_INTERPRETER}" ""
set_if   RL_VAL_PORTAGE_CONFDIR_POSTFIX_PPC64 "${CONF_QEMU_IS_NEEDED}" "-qemu" ""
set_if   RL_VAL_PORTAGE_CONFDIR_POSTFIX_CELL "${CONF_QEMU_IS_NEEDED}" "-qemu-cell" "-cell"

# Lists
readonly RL_SPECS_MAIN=(${RL_CONF_STAGE1_NAME} ${RL_CONF_STAGE3_NAME})
readonly RL_SPECS_OPTIONAL=(${RL_CONF_INSTALLCD_STAGE1_NAME} ${RL_CONF_INSTALLCD_STAGE2_NAME} ${RL_CONF_STAGE4_NAME})
