#!/bin/bash

[ ${RE_ENV_LOADED} ] && return 0; readonly RE_ENV_LOADED=true
#register_usage "$0"

# Input parsing.
#while [ $# -gt 0 ]; do case "$1" in
#    --unmask)         KE_FLAG_UNMASK=true;;               # Use masked ~ppc64 base ebuilds and unmask created ps3 ebuild ~ppc64 -> ppc64.
#    --default)        KE_FLAG_FORCE_DEFAULT=true;;	  # Force using default config and patches, even if version specific data exists.
#    --savedefault)    KE_FLAG_SAVE_DEFAULT=true;;         # Save config and patches also in defaults folder.
#    --save)           KE_FLAG_SAVE=true;;                 # Save patches and configuration in versioned directory. Should always use, unless testing.
#    --edit)           KE_FLAG_EDIT=true;;                 # Edit configuration in step ebuild-04-configure.sh.
#    --version) shift; KE_PACKAGE_VERSION_SPECIFIED="$1";; # Ebuild version specified as the input value if any.
#    *) show_usage
#esac; shift; done

# Validate input variables;
#[[ ! ${KE_PACKAGE_VERSION_SPECIFIED} ]] || [[ "${KE_PACKAGE_VERSION_SPECIFIED}" =~ ^[0-9]+\.[0-9]+\.[0-9]+([0-9]+)?$ ]] || failure "Kernel version incorrect"

# Read default configurations from main environment.
#[[ ${CONF_KERNEL_PACKAGE_AUTOUNMASK} = true ]] && KE_FLAG_UNMASK=true



readonly RE_VAL_TIMESTAMP=$(date -u +"%Y%m%dT%H%M%SZ")

# Paths
readonly RE_PATH_STAGE1="${PATH_WORK_RELEASE}/stage1-cell.$RE_VAL_TIMESTAMP.spec"
readonly RE_PATH_STAGE3="${PATH_WORK_RELEASE}/stage3-cell.$RE_VAL_TIMESTAMP.spec"
readonly RE_PATH_STAGE1_INSTALLCD="${PATH_WORK_RELEASE}/stage1-cell.installcd.$RE_VAL_TIMESTAMP.spec"
readonly RE_PATH_STAGE2_INSTALLCD="${PATH_WORK_RELEASE}/stage2-cell.installcd.$RE_VAL_TIMESTAMP.spec"
readonly RE_PATH_LIVECD_OVERLAY_SRC="${PATH_DEV_TOOLS_RELEASE}/data/iso_overlay"
readonly RE_PATH_LIVECD_OVERLAY_DST="${PATH_WORK_RELEASE}/iso_overlay"
readonly RE_PATH_LIVECD_FSSCRIPT_SRC="${PATH_DEV_TOOLS_RELEASE}/data/iso_fsscript.sh"
readonly RE_PATH_LIVECD_FSSCRIPT_DST="${PATH_WORK_RELEASE}/iso_fsscript.sh"
readonly RE_PATH_SNAPSHOT_LOG="${PATH_WORK_RELEASE}/snapshot_log.txt"
readonly RE_PATH_RELEASE_INFO="${PATH_WORK_RELEASE}/release_latest"
set_if   RE_VAL_INTERPRETER_ENTRY "${VAL_QEMU_IS_NEEDED}" "interpreter: ${PATH_QEMU_INTERPRETER}" ""
