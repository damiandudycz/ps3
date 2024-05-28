#!/bin/bash

# This file creates additional environment variables for kernel-ebuild scripts.

# Variants: _DEFAULT:   Constant or automatically determined
#           _SPECIFIED: Selected by the user with argument
#           _SELECTED:  Currently being used

[ ! ${KE_ENV_LOADED} ] || return 0
readonly KE_ENV_LOADED=true

# Input parsing.
while [ $# -gt 0 ]; do case "$1" in
    --unmask)  KE_FLAG_UNMASK=true;;               # Use masked ~ppc64 base ebuilds and unmask created ps3 ebuild ~ppc64 -> ppc64.
    --default) KE_FLAG_FORCE_DEFAULT=true;;        # Force using default config and patches, even if version specific data exists.
    --save)    KE_FLAG_SAVE=true;;                 # Save patches and configuration in versioned directory. Should always use, unless testing.
    --edit)    KE_FLAG_EDIT=true;;                 # Edit configuration in step ebuild-04-configure.sh.
    *)         KE_PACKAGE_VERSION_SPECIFIED="$1";; # Ebuild version specified as the input value if any.
esac; shift; done

# Validate input variables;
[ ! ${KE_PACKAGE_VERSION_SPECIFIED} ] || [[ "${KE_PACKAGE_VERSION_SPECIFIED}" =~ ^[0-9]+\.[0-9]+\.[0-9]+([0-9]+)?$ ]] || failure "Kernel version incorrect"

# Main Scripts in kernel-ebuild group.
readonly KE_SCRIPT_CURRENT="$(basename $0)"                                     # Name of script that was called by the user.
readonly KE_SCRIPT_FIND_VERSION="ebuild-00-find-version.sh"                     # Finds version of gentoo-kernel - stable or unstable, depending on KE_FLAG_UNMASK.
readonly KE_SCRIPT_DOWNLOAD_PATCHES="ebuild-01-download-patches.sh"             # Downloads patches and stores in KE_PATH_VERSION_STORAGE. Stores in default or in KE_PACKAGE_VERSION if explicitly specified.
readonly KE_SCRIPT_DOWNLOAD_GENTOO_KERNEL="ebuild-02-download-gentoo-kernel.sh" # Downloads gentoo-kernel files from gentoo-kernel ebuild.
readonly KE_SCRIPT_APPLY_PS3_PATCHES="ebuild-03-apply-ps3-patches.sh"           # Applies all PS3 patches available for this gentoo-kernel.
readonly KE_SCRIPT_CONFIGURE="ebuild-04-configure.sh"                           # Generates .config file in source directory.
readonly KE_SCRIPT_CREATE_PS3_EBUILD="ebuild-05-create-ps3-ebuild.sh"           # Generates gentoo-kernel-ps3 ebuild.
readonly KE_SCRIPT_BUILD_MANIFEST="ebuild-06-build-manifest.sh"                 # Generates manifest for the gentoo-kernel-ps3 ebuild.
readonly KE_SCRIPT_UPLOAD="ebuild-07-upload.sh"                                 # Adds new abuild to overlay and distfiles, and uploads them to github.
readonly KE_SCRIPT_BUILD_KERNEL="ebuild-08-build-kernel.sh"                     # Builds vmlinux and modules locally.

# Helper names.
readonly KE_NAME_PACKAGE_SRC="sys-kernel/gentoo-kernel"     # Name of base package.
readonly KE_NAME_PACKAGE_DST="sys-kernel/gentoo-kernel-ps3" # Name of customized package.

# Names of helper files and directories.
readonly KE_NAME_FOLDER_DATA="data"                         # Data folder (data).
readonly KE_NAME_FOLDER_VERSION_STORAGE="version-storage"   # Version storage folder (data/version-storage).
readonly KE_NAME_FOLDER_PATCHES="patches"                   # Patches folder (data/version-storage/<version>/patches).
readonly KE_NAME_FOLDER_CONFIG="config"                     # Config folder (data/version-storage/<version>/config).
readonly KE_NAME_FOLDER_DEFAULT="default"                   # Default storage folder (data/version-storage/default).
readonly KE_NAME_FOLDER_REPO_DRAFT="repo"                   # Draft of empty overlay repository (data/repo).
readonly KE_NAME_FOLDER_SCRIPTS="scripts"                   # Scripts folder (data/scripts).
readonly KE_NAME_FILE_CONF_DIFFS="diffs"                    # Config diffs file (data/version-storage/<version>/diffs).
readonly KE_NAME_FILE_CONF_DEFCONF="defconfig"              # Default config file (data/version-storage/<version>/defconf).
readonly KE_NAME_FILE_PATCHES_CURRENT="patches-current.txt" # List of patches to download (data/patches-current.txt).

# Names of ebuild files and variables.
readonly KE_NAME_EBUILD_FILE_SRC="gentoo-kernel"
readonly KE_NAME_EBUILD_FILE_DST="gentoo-kernel-ps3"
readonly KE_NAME_EBUILD_DEFCONFIG="ps3_defconfig"
readonly KE_VAR_EBUILD_KEYWORD_DEFAULT="ppc64"
readonly KE_VAR_EBUILD_KEYWORD_UNSTABLE="~ppc64"
         KE_VAR_EBUILD_KEYWORD_SELECTED="${KE_VAR_EBUILD_KEYWORD_DEFAULT}"; [ ${KE_FLAG_UNMASK} ] && KE_VAR_EBUILD_KEYWORD_SELECTED="${KE_VAR_EBUILD_KEYWORD_UNSTABLE}"

# Package version.
KE_PACKAGE_VERSION_DEFAULT=""; [ "${KE_SCRIPT_CURRENT}" = "${KE_SCRIPT_FIND_VERSION}" ] || KE_PACKAGE_VERSION_DEFAULT="$(source $KE_SCRIPT_FIND_VERSION)" || failure # Version of package returned by ebuild-00-find-version.sh.
KE_PACKAGE_VERSION_SELECTED="${KE_PACKAGE_VERSION_DEFAULT}";

# Data folders and files.
readonly KE_PATH_DATA="${PATH_DEV_TOOLS_KERNEL_EBUILD}/${KE_NAME_FOLDER_DATA}"
readonly KE_PATH_VERSION_STORAGE="${KE_PATH_DATA}/${KE_NAME_FOLDER_VERSION_STORAGE}"
readonly KE_PATH_VERSION_STORAGE_DEFAULT="${KE_PATH_VERSION_STORAGE}/${KE_NAME_FOLDER_DEFAULT}"
readonly KE_PATH_VERSION_STORAGE_VERSIONED="${KE_PATH_VERSION_STORAGE}/${KE_PACKAGE_VERSION_SELECTED}"
readonly KE_PATH_PATCHES_FETCH_LIST="${KE_PATH_DATA}/${KE_NAME_FILE_PATCHES_CURRENT}"
readonly KE_PATH_PATCHES_DEFAULT="${KE_PATH_VERSION_STORAGE_DEFAULT}/${KE_NAME_FOLDER_PATCHES}"
readonly KE_PATH_PATCHES_VERSIONED="${KE_PATH_VERSION_STORAGE_VERSIONED}/${KE_NAME_FOLDER_PATCHES}"
         KE_PATH_PATCHES_SAVETO="${KE_PATH_PATCHES_DEFAULT}"; ([ ${KE_PACKAGE_VERSION_SPECIFIED} ] && [ !${KE_FLAG_FORCE_DEFAULT} ]) && KE_PATH_PATCHES_SAVETO="${KE_PATH_PATCHES_VERSIONED}" # Save to default, unless KE_PACKAGE_VERSION_SPECIFIED is set.
         KE_PATH_PATCHES_SELECTED="${KE_PATH_PATCHES_VERSIONED}"; ([ ! -d "${KE_PATH_PATCHES_SELECTED}" ] || [ ${KE_FLAG_FORCE_DEFAULT} ]) && KE_PATH_PATCHES_SELECTED="${KE_PATH_PATCHES_DEFAULT}"
readonly KE_PATH_CONFIG_DEFAULT="${KE_PATH_VERSION_STORAGE_DEFAULT}/${KE_NAME_FOLDER_CONFIG}"
readonly KE_PATH_CONFIG_VERSIONED="${KE_PATH_VERSION_STORAGE_VERSIONED}/${KE_NAME_FOLDER_CONFIG}"
         KE_PATH_CONFIG_SAVETO="${KE_PATH_CONFIG_VERSIONED}"; # Script ebuild-04-configure.sh will save to this dicrecoty - always in versioned directory.
         KE_PATH_CONFIG_SELECTED="${KE_PATH_CONFIG_VERSIONED}"; ([ ! -f "${KE_PATH_CONFIG_SELECTED}/${KE_NAME_FILE_CONF_DIFFS}" ] || [ ${KE_FLAG_FORCE_DEFAULT} ]) && KE_PATH_CONFIG_SELECTED="${KE_PATH_CONFIG_DEFAULT}" # Versioned if exists, otherwise default.

readonly KE_PATH_OVERLAY_DRAFT="${KE_PATH_DATA}/${KE_NAME_FOLDER_REPO_DRAFT}"

# Workdirs.
readonly KE_PATH_WORK_SRC="${PATH_WORK_KERNEL_EBUILD}/${KE_PACKAGE_VERSION_SELECTED}/src"
readonly KE_PATH_WORK_SRC_LINUX="$(find ${KE_PATH_WORK_SRC}/portage/${KE_NAME_PACKAGE_SRC}-${KE_PACKAGE_VERSION_SELECTED}/work/ -maxdepth 1 -name linux-* -type d -print -quit 2>/dev/null)"

# Helper scripts.
readonly KE_PATH_SCRIPTS="${KE_PATH_DATA}/${KE_NAME_FOLDER_SCRIPTS}"
readonly KE_PATH_SCRIPT_APPLY_DIFFCONFIG="${KE_PATH_SCRIPTS}/apply-diffconfig.rb"
readonly KE_PATH_SCRIPT_MERGE_CONFIG="${KE_PATH_WORK_SRC_LINUX}/scripts/kconfig/merge_config.sh"
readonly KE_PATH_SCRIPT_DIFFCONFIG="${KE_PATH_WORK_SRC_LINUX}/scripts/diffconfig"

# Other.
readonly KEY_PATH_EBUILD_FILE_SRC="${PATH_VAR_DB_REPOS_GENTOO}/${KE_NAME_PACKAGE_SRC}/${KE_NAME_EBUILD_FILE_SRC}-${KE_PACKAGE_VERSION_SELECTED}.ebuild"
