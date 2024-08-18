#!/bin/bash

[ ${KP_ENV_LOADED} ] && return 0; readonly KP_ENV_LOADED=true
register_usage "$0 [--unmask] [--save] [--edit] [--version <version>] [--use <use-flags>] [--patch <patch_set_name>] [--upload <username@ps3-host>]"

# Input parsing.
while [ $# -gt 0 ]; do case "$1" in
    *) show_usage
esac; shift; done

readonly KP_CONF_PATCH_DEFAULT_NAME="damiandudycz"

# Names of helper files and directories.
readonly KP_NAME_FOLDER_PATCHES="patches"
readonly KP_NAME_FOLDER_LINUX_FILES_VANILLA="linux-files-vanilla"

# Paths.
readonly KP_PATH_PATCHES="${PATH_DEV_TOOLS_KERNEL_PATCHES}/${KP_NAME_FOLDER_PATCHES}"
readonly KP_PATH_PATCHES_USED="${KP_PATH_PATCHES}/${KP_CONF_PATCH_DEFAULT_NAME}"
readonly KP_PATH_LINUX_FILES_VANILLA="${PATH_DEV_TOOLS_KERNEL_PATCHES}/${KP_NAME_FOLDER_LINUX_FILES_VANILLA}"
