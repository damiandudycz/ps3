#!/bin/bash

[ ${KE_ENV_LOADED} ] && return 0; readonly KE_ENV_LOADED=true
register_usage "$0 [--unmask] [--save] [--edit] [--version <version>] [--use <use-flags>] [--patch <patch_set_name>] [--upload <username@ps3-host>]"

# Input parsing.
while [ $# -gt 0 ]; do case "$1" in
    --unmask)         KE_FLAG_UNMASK=true;;               # Use masked ~ppc64 base ebuilds and unmask created ps3 ebuild ~ppc64 -> ppc64.
    --save)           KE_FLAG_SAVE=true;;                 # Save patches and configuration in versioned directory. Should always use, unless testing.
    --edit)           KE_FLAG_EDIT=true;;                 # Edit configuration in step ebuild-04-configure.sh.
    --version) shift; KE_PACKAGE_VERSION_SPECIFIED="$1";; # Ebuild version specified as the input value if any.
    --upload)  shift; KE_UPLOAD_ADDRESS="$1";;            # Address of PS3 machine where to upload build kernel with ssh.
    --use)     shift; KE_PACKAGE_USE="$1";;               # Extra use flags to be added when building locally. For example: --use "X debug"
    --patch)   shift; KE_PATCH_SET="$1";;                 # Which set of patches to use. If not selected, uses default.
    --accept-custom-flags) KE_ACCEPT_CUSTOM_FLAGS=true;;
    *) [[ ${KE_ACCEPT_CUSTOM_FLAGS} = true ]] || show_usage
esac; shift; done

# Validate input variables;
[[ ! ${KE_PACKAGE_VERSION_SPECIFIED} ]] || [[ "${KE_PACKAGE_VERSION_SPECIFIED}" =~ ^[0-9]+\.[0-9]+\.[0-9]+([0-9]+)?$ ]] || failure "Kernel version incorrect"

# Read default configurations from main environment.
[[ ${CONF_KERNEL_PACKAGE_AUTOUNMASK} = true ]] && KE_FLAG_UNMASK=true

readonly KE_CONF_PATCH_DEFULT_NAME="selected"

# Main Scripts in kernel-ebuild group.
readonly KE_SCRIPT_NAME_FIND_VERSION="ebuild-00-find-version.sh" # Finds version of gentoo-kernel - stable or unstable, depending on KE_FLAG_UNMASK.
readonly KE_CONF_SCRIPT_NAME_CALLED="$(basename $0)"

# Names of helper files and directories.
readonly KE_NAME_FOLDER_DATA="data"                         # Data folder (data).
readonly KE_NAME_FOLDER_PATCHES="patches"                   # Data folder (data).
readonly KE_NAME_FOLDER_PS3_PATCHES="ps3_patches"           # Patches folder (data/version-storage/<version>/patches).
readonly KE_NAME_FOLDER_CONFIG="config"                     # Config folder (data/version-storage/<version>/config).
readonly KE_NAME_FOLDER_DEFAULT="default"                   # Default storage folder (data/version-storage/default).
readonly KE_NAME_FOLDER_SCRIPTS="scripts"                   # Scripts folder (data/scripts).
readonly KE_NAME_FOLDER_BINPKGS="binpkgs"                   # Directory containing created binpkg file.
readonly KE_NAME_FOLDER_LOCALBUILD="localbuild"             # Kernel build locally on this host with ARCH=powerpc.
readonly KE_NAME_FILE_CONF_DIFFS="ps3_defconfig_diffs"      # Config diffs file (data/version-storage/<version>/diffs).
readonly KE_NAME_FILE_CONF_DEFCONF="ps3_gentoo_defconfig"   # Default config file (data/version-storage/<version>/defconf).
readonly KE_NAME_FILE_EBUILD_DEFCONFIG="ps3_defconfig"      # Name of ps3 kernel config file.
readonly KE_NAME_FILE_BINPKGS_PACKAGES="Packages"

# Variables..
set_if   KE_VAL_EBUILD_KEYWORD_SELECTED "\${KE_FLAG_UNMASK}" "~${CONF_TARGET_ARCH}" "${CONF_TARGET_ARCH}"
set_if   KE_PACKAGE_VERSION_SELECTED "\"${KE_CONF_SCRIPT_NAME_CALLED}\" = \"${KE_SCRIPT_NAME_FIND_VERSION}\"" "" "$(source ${KE_SCRIPT_NAME_FIND_VERSION})"
set_if   KE_PATCH_SET_SELECTED "-n \"${KE_PATCH_SET}\"" "${KE_PATCH_SET}" "${KE_CONF_PATCH_DEFULT_NAME}"

# Names of ebuild files and variables dependant on package version.
readonly KE_NAME_EBUILD_FILE_DISTFILES_TAR="${CONF_KERNEL_PACKAGE_NAME_SPECIAL}-files-${KE_PACKAGE_VERSION_SELECTED}.tar.xz" # Destination distfiles tarball.
readonly KE_NAME_EBUILD_FILE_PACKAGE_SRC="${CONF_KERNEL_PACKAGE_NAME_BASE}-${KE_PACKAGE_VERSION_SELECTED}.ebuild"            # Full source ebuild filename, without path.
readonly KE_NAME_EBUILD_FILE_PACKAGE_DST="${CONF_KERNEL_PACKAGE_NAME_SPECIAL}.ebuild"                                        # Full destination ebuild filename, without path.
readonly KE_NAME_PACKAGE_DST_VERSIONED="${CONF_KERNEL_PACKAGE_NAME_SPECIAL}-${KE_PACKAGE_VERSION_SELECTED}"

# Data folders and files.
readonly KE_PATH_DATA="${PATH_DEV_TOOLS_KERNEL_EBUILD}/${KE_NAME_FOLDER_DATA}"                         # Location of data folder (./data).
readonly KE_PATH_DATA_CONFIG="${KE_PATH_DATA}/${KE_NAME_FOLDER_CONFIG}"
readonly KE_PATH_DATA_CONFIG_DIFFS="${KE_PATH_DATA_CONFIG}/${KE_NAME_FILE_CONF_DIFFS}"
readonly KE_PATH_DATA_PATCHES_LISTS="${KE_PATH_DATA}/patches"
readonly KE_PATH_EBUILD_PATCHES="${KE_PATH_DATA}/ebuild-patches"                                       # Location of patches to be applied to generated ebuild file.

# Paths.
readonly KE_PATH_WORK_SRC="${PATH_WORK_KERNEL_EBUILD}/${KE_PACKAGE_VERSION_SELECTED}/src"                           # Location of gentoo-kernel ebuild extracted files main folder.
readonly KE_PATH_WORK_SRC_LINUX="$(find ${KE_PATH_WORK_SRC}/portage/${CONF_KERNEL_PACKAGE_BASE}-${KE_PACKAGE_VERSION_SELECTED}/work/ -maxdepth 1 -name linux-* -type d -print -quit 2>/dev/null)" # Location of linux source code from gentoo-kernel ebuild extracted package.
readonly KE_PATH_WORK_BINPKGS="${PATH_WORK_KERNEL_EBUILD}/${KE_PACKAGE_VERSION_SELECTED}/${KE_NAME_FOLDER_BINPKGS}" # Location of folder containing binpkg created with crossdev.
readonly KE_PATH_WORK_PATCHES="${PATH_WORK_KERNEL_EBUILD}/${KE_NAME_FOLDER_PATCHES}"
readonly KE_PATH_WORK_PATCHES_SRC="${KE_PATH_WORK_PATCHES}/${KE_PATCH_SET_SELECTED}"
readonly KE_PATH_WORK_VERSION_PATCHES="${PATH_WORK_KERNEL_EBUILD}/${KE_PACKAGE_VERSION_SELECTED}/${KE_NAME_FOLDER_PS3_PATCHES}"
readonly KE_PATH_WORK_LOCALBUILD="${PATH_WORK_KERNEL_EBUILD}/${KE_PACKAGE_VERSION_SELECTED}/${KE_NAME_FOLDER_LOCALBUILD}"

# Work files location.
readonly KE_PATH_WORK_EBUILD="${PATH_WORK_KERNEL_EBUILD}/${KE_PACKAGE_VERSION_SELECTED}/ebuild"                     # Location of ebuild generation workdir.
readonly KE_PATH_EBUILD_FILE_SRC="${PATH_VAR_DB_REPOS_GENTOO}/${CONF_KERNEL_PACKAGE_BASE}/${KE_NAME_EBUILD_FILE_PACKAGE_SRC}" # Location of source ebuild file.
readonly KE_PATH_EBUILD_FILE_DST="${KE_PATH_WORK_EBUILD}/${KE_NAME_EBUILD_FILE_PACKAGE_DST}"                        # Location of destination ebuild file.
readonly KE_PATH_BINPKGS_PACKAGES_SRC="${PATH_CROSSDEV_BINPKGS}/${KE_NAME_FILE_BINPKGS_PACKAGES}"
readonly KE_PATH_BINPKGS_PACKAGES_DST="${KE_PATH_WORK_BINPKGS}/${KE_NAME_FILE_BINPKGS_PACKAGES}"

# Helper scripts.
readonly KE_PATH_SCRIPTS="${KE_PATH_DATA}/${KE_NAME_FOLDER_SCRIPTS}"                             # Location of helper scripts folder for kernel-ebuild scripts set.
readonly KE_PATH_SCRIPT_APPLY_DIFFCONFIG="${KE_PATH_SCRIPTS}/apply-diffconfig.rb"                # Location of scripts that applied differences in ps3_defconfig_diffs to .config file.
readonly KE_PATH_SCRIPT_MERGE_CONFIG="${KE_PATH_WORK_SRC_LINUX}/scripts/kconfig/merge_config.sh" # Location of linux script inside src workdir, that merges selected config files.
readonly KE_PATH_SCRIPT_DIFFCONFIG="${KE_PATH_WORK_SRC_LINUX}/scripts/diffconfig"                # Location of linux script inside src workdir, that generates new diffconfig file.

# Crossdev locations.
readonly KE_PATH_CROSSDEV_BINPKGS_KERNEL_PACKAGE="${PATH_CROSSDEV_BINPKGS}/${CONF_KERNEL_PACKAGE_SPECIAL}"
