#!/bin/bash

# This file creates additional environment variables for kernel-ebuild scripts.

# Variants: _DEFAULT:   Constant or automatically determined
#           _SPECIFIED: Selected by the user with argument
#           _SELECTED:  Currently being used

[ ! ${KE_ENV_LOADED} ] || return 0
readonly KE_ENV_LOADED=true

# Input parsing.
while [ $# -gt 0 ]; do case "$1" in
    --unstable)    KE_FLAG_UNSTABLE=true;;             # Use unstable ebuilds ~ppc64.
    --unmask)      KE_FLAG_UNMASK=true;;               # Unmask created ps3 ebuild ~ppc64 -> ppc64.
    --default)     KE_FLAG_FORCE_DEFAULT=true;;        # Force using default config and patches, even if version specific data exists.
    --savepatches) KE_FLAG_SAVE_PATCHES=true;;         # Save patches in versioned directory, if used default patches. This option should be always used to keep track of working set of patches.
    --saveconfig)  KE_FLAG_SAVE_CONFIG=true;;          # Save config in versioned directory after ebuild-04-configure.sh. This option sould be always used to store changes made by this script.
    --edit)        KE_FLAG_EDIT=true;;                 # Edit configuration in step ebuild-04-configure.sh.
    *)             KE_PACKAGE_VERSION_SPECIFIED="$1";; # Ebuild version specified as the input value if any.
esac; shift; done

# Validate input variables;
[ ! ${KE_PACKAGE_VERSION_SPECIFIED} ] || [[ "${KE_PACKAGE_VERSION_SPECIFIED}" =~ ^[0-9]+\.[0-9]+\.[0-9]+([0-9]+)?$ ]] || failure "Kernel version incorrect"
[ ! ${KE_FLAG_UNMASK} ] || [ ${KE_FLAG_UNSTABLE} ] || failure "--unmask option can only be used with --unstable"

# Scripts in kernel-ebuild group.
readonly KE_SCRIPT_CURRENT="$(basename $0)"                                     # Name of script that was called by the user.
readonly KE_SCRIPT_FIND_VERSION="ebuild-00-find-version.sh"                     # Finds version of gentoo-kernel - stable or unstable, depending on KE_FLAG_UNSTABLE.
readonly KE_SCRIPT_DOWNLOAD_PATCHES="ebuild-01-download-patches.sh"             # Downloads patches and stores in KE_PATH_VERSION_STORAGE. Stores in default or in KE_PACKAGE_VERSION if explicitly specified.
readonly KE_SCRIPT_DOWNLOAD_GENTOO_KERNEL="ebuild-02-download-gentoo-kernel.sh" # Downloads gentoo-kernel files from gentoo-kernel ebuild.
readonly KE_SCRIPT_APPLY_PS3_PATCHES="ebuild-03-apply-ps3-patches.sh"           # Applies all PS3 patches available for this gentoo-kernel.
readonly KE_SCRIPT_CONFIGURE="ebuild-04-configure.sh"                           # Generates .config file in source directory.
readonly KE_SCRIPT_CREATE_PS3_EBUILD="ebuild-05-create-ps3-ebuild.sh"           # Generates gentoo-kernel-ps3 ebuild.
readonly KE_SCRIPT_BUILD_MANIFEST="ebuild-06-build-manifest.sh"                 # Generates manifest for the gentoo-kernel-ps3 ebuild.
readonly KE_SCRIPT_UPLOAD="ebuild-07-upload.sh"                                 # Adds new abuild to overlay and distfiles, and uploads them to github.
readonly KE_SCRIPT_BUILD_KERNEL="ebuild-08-build-kernel.sh"                     # Builds vmlinux and modules locally.

# Names of ebuild files and variables.
readonly KE_NAME_PACKAGE_SRC="sys-kernel/gentoo-kernel"
readonly KE_NAME_PACKAGE_DST="sys-kernel/gentoo-kernel-ps3"
readonly KE_NAME_EBUILD_FILE_SRC="gentoo-kernel"
readonly KE_NAME_EBUILD_FILE_DST="gentoo-kernel-ps3"
readonly KE_NAME_EBUILD_DEFCONFIG="ps3_defconfig"
readonly KE_VAR_EBUILD_KEYWORD_DEFAULT="ppc64"
readonly KE_VAR_EBUILD_KEYWORD_UNSTABLE="~ppc64"
         KE_VAR_EBUILD_KEYWORD_SELECTED="${KE_VAR_EBUILD_KEYWORD_DEFAULT}"; [ ${KE_FLAG_UNSTABLE} ] && KE_VAR_EBUILD_KEYWORD_SELECTED="${KE_VAR_EBUILD_KEYWORD_UNSTABLE}"

# Package version.
KE_PACKAGE_VERSION_DEFAULT=""; [ "${KE_SCRIPT_CURRENT}" = "${KE_SCRIPT_FIND_VERSION}" ] || KE_PACKAGE_VERSION_DEFAULT="$(source $KE_SCRIPT_FIND_VERSION)" || failure # Version of package returned by ebuild-00-find-version.sh.
KE_PACKAGE_VERSION_SELECTED="${KE_PACKAGE_VERSION_DEFAULT}";

# Data folders and files.
readonly KE_PATH_EBUILD_DATA="${PATH_DEV_TOOLS_KERNEL_EBUILD}/data"
readonly KE_PATH_EBUILD_SCRIPTS="${KE_PATH_EBUILD_DATA}/scripts"
readonly KE_PATH_VERSION_STORAGE="${KE_PATH_EBUILD_DATA}/version-storage"
readonly KE_PATH_VERSION_STORAGE_DEFAULT="${KE_PATH_VERSION_STORAGE}/default"
readonly KE_PATH_VERSION_STORAGE_VERSIONED="${KE_PATH_VERSION_STORAGE}/${KE_PACKAGE_VERSION_SELECTED}"
readonly KE_PATH_PATCHES_FETCH_LIST="${KE_PATH_EBUILD_DATA}/patches-current.txt"
readonly KE_PATH_PATCHES_DEFAULT="${KE_PATH_VERSION_STORAGE_DEFAULT}/patches"
readonly KE_PATH_PATCHES_VERSIONED="${KE_PATH_VERSION_STORAGE_VERSIONED}/patches"
         KE_PATH_PATCHES_SAVETO="${KE_PATH_PATCHES_DEFAULT}"; ([ ${KE_PACKAGE_VERSION_SPECIFIED} ] && [ !${KE_FLAG_FORCE_DEFAULT} ]) && KE_PATH_PATCHES_SAVETO="${KE_PATH_PATCHES_VERSIONED}" # Save to default, unless KE_PACKAGE_VERSION_SPECIFIED is set.
         KE_PATH_PATCHES_SELECTED="${KE_PATH_PATCHES_VERSIONED}"; ([ ! -d "${KE_PATH_PATCHES_SELECTED}" ] || [ ${KE_FLAG_FORCE_DEFAULT} ]) && KE_PATH_PATCHES_SELECTED="${KE_PATH_PATCHES_DEFAULT}"
readonly KE_PATH_CONFIG_DEFAULT="${KE_PATH_VERSION_STORAGE_DEFAULT}/config"
readonly KE_PATH_CONFIG_VERSIONED="${KE_PATH_VERSION_STORAGE_VERSIONED}/config"
         KE_PATH_CONFIG_SAVETO="${KE_PATH_CONFIG_VERSIONED}"; # Script ebuild-04-configure.sh will save to this dicrecoty - always in versioned directory.
         KE_PATH_CONFIG_SELECTED="${KE_PATH_CONFIG_VERSIONED}"; ([ ! -f "${KE_PATH_CONFIG_SELECTED}/diffs" ] || [ ${KE_FLAG_FORCE_DEFAULT} ]) && KE_PATH_CONFIG_SELECTED="${KE_PATH_CONFIG_DEFAULT}" # Versioned if exists, otherwise default.

# Workdirs.
readonly KE_PATH_WORK_SRC="${PATH_WORK_KERNEL_EBUILD}/${KE_PACKAGE_VERSION_SELECTED}/src"
readonly KE_PATH_WORK_SRC_LINUX="$(find ${KE_PATH_WORK_SRC}/portage/${KE_NAME_PACKAGE_SRC}-${KE_PACKAGE_VERSION_SELECTED}/work/ -maxdepth 1 -name linux-* -type d -print -quit 2>/dev/null)"

# Helper scripts.
readonly KE_PATH_SCRIPT_APPLY_DIFFCONFIG="${KE_PATH_EBUILD_SCRIPTS}/apply-diffconfig.rb"
readonly KE_PATH_SCRIPT_MERGE_CONFIG="${KE_PATH_WORK_SRC_LINUX}/scripts/kconfig/merge_config.sh"
readonly KE_PATH_SCRIPT_DIFFCONFIG="${KE_PATH_WORK_SRC_LINUX}/scripts/diffconfig"

# Other.
readonly KEY_PATH_EBUILD_FILE_SRC="${PATH_VAR_DB_REPOS_GENTOO}/${KE_NAME_PACKAGE_SRC}/${KE_NAME_EBUILD_FILE_SRC}-${KE_PACKAGE_VERSION_SELECTED}.ebuild"
