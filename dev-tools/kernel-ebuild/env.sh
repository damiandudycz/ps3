#!/bin/bash

[ ${KE_ENV_LOADED} ] && return 0; readonly KE_ENV_LOADED=true
register_usage "$0 [--unmask] [--default] [--save] [--savedefault] [--edit] [--version <version>]"

# Input parsing.
while [ $# -gt 0 ]; do case "$1" in
    --unmask)         KE_FLAG_UNMASK=true;;               # Use masked ~ppc64 base ebuilds and unmask created ps3 ebuild ~ppc64 -> ppc64.
    --default)        KE_FLAG_FORCE_DEFAULT=true;;        # Force using default config and patches, even if version specific data exists.
    --savedefault)    KE_FLAG_SAVE_DEFAULT=true;;         # Save config and patches also in defaults folder.
    --save)           KE_FLAG_SAVE=true;;                 # Save patches and configuration in versioned directory. Should always use, unless testing.
    --edit)           KE_FLAG_EDIT=true;;                 # Edit configuration in step ebuild-04-configure.sh.
    --version) shift; KE_PACKAGE_VERSION_SPECIFIED="$1";; # Ebuild version specified as the input value if any.
    *) show_usage
esac; shift; done

# Validate input variables;
[[ ! ${KE_PACKAGE_VERSION_SPECIFIED} ]] || [[ "${KE_PACKAGE_VERSION_SPECIFIED}" =~ ^[0-9]+\.[0-9]+\.[0-9]+([0-9]+)?$ ]] || failure "Kernel version incorrect"

# Read default configurations from main environment.
[[ ${CONF_KERNEL_PACKAGE_AUTOUNMASK} = true ]] && KE_FLAG_UNMASK=true

# Main Scripts in kernel-ebuild group.
readonly KE_SCRIPT_NAME_FIND_VERSION="ebuild-00-find-version.sh" # Finds version of gentoo-kernel - stable or unstable, depending on KE_FLAG_UNMASK.
readonly KE_CONF_SCRIPT_NAME_CALLED="$(basename $0)"

# Names of helper files and directories.
readonly KE_NAME_FOLDER_DATA="data"                         # Data folder (data).
readonly KE_NAME_FOLDER_VERSION_STORAGE="version-storage"   # Version storage folder (data/version-storage).
readonly KE_NAME_FOLDER_PATCHES="ps3_patches"               # Patches folder (data/version-storage/<version>/patches).
readonly KE_NAME_FOLDER_CONFIG="config"                     # Config folder (data/version-storage/<version>/config).
readonly KE_NAME_FOLDER_DEFAULT="default"                   # Default storage folder (data/version-storage/default).
readonly KE_NAME_FOLDER_SCRIPTS="scripts"                   # Scripts folder (data/scripts).
readonly KE_NAME_FOLDER_BINPKGS="binpkgs"                   # Directory containing created binpkg file.
readonly KE_NAME_FILE_CONF_DIFFS="ps3_defconfig_diffs"      # Config diffs file (data/version-storage/<version>/diffs).
readonly KE_NAME_FILE_CONF_DEFCONF="ps3_gentoo_defconfig"   # Default config file (data/version-storage/<version>/defconf).
readonly KE_NAME_FILE_PATCHES_CURRENT="patches-current.txt" # List of patches to download (data/patches-current.txt).
readonly KE_NAME_FILE_EBUILD_DEFCONFIG="ps3_defconfig"      # Name of ps3 kernel config file.
readonly KE_NAME_FILE_BINPKGS_PACKAGES="Packages"

# Names of ebuild files and variables.
set_if   KE_VAL_EBUILD_KEYWORD_SELECTED "\${KE_FLAG_UNMASK}" "~${CONF_TARGET_ARCH}" "${CONF_TARGET_ARCH}"

# Package version.
set_if   KE_PACKAGE_VERSION_SELECTED "\"${KE_CONF_SCRIPT_NAME_CALLED}\" = \"${KE_SCRIPT_NAME_FIND_VERSION}\"" "" "$(source ${KE_SCRIPT_NAME_FIND_VERSION})"

# Names of ebuild files and variables dependant on package version.
readonly KE_NAME_EBUILD_FILE_DISTFILES_TAR="${CONF_KERNEL_PACKAGE_NAME_SPECIAL}-files-${KE_PACKAGE_VERSION_SELECTED}.tar.xz" # Destination distfiles tarball.
readonly KE_NAME_EBUILD_FILE_PACKAGE_SRC="${CONF_KERNEL_PACKAGE_NAME_BASE}-${KE_PACKAGE_VERSION_SELECTED}.ebuild"            # Full source ebuild filename, without path.
readonly KE_NAME_EBUILD_FILE_PACKAGE_DST="${CONF_KERNEL_PACKAGE_NAME_SPECIAL}.ebuild"                                        # Full destination ebuild filename, without path.
readonly KE_NAME_PACKAGE_DST_VERSIONED="${CONF_KERNEL_PACKAGE_NAME_SPECIAL}-${KE_PACKAGE_VERSION_SELECTED}"

# Data folders and files.
readonly KE_PATH_DATA="${PATH_DEV_TOOLS_KERNEL_EBUILD}/${KE_NAME_FOLDER_DATA}"                         # Location of data folder (./data).
readonly KE_PATH_VERSION_STORAGE="${KE_PATH_DATA}/${KE_NAME_FOLDER_VERSION_STORAGE}"                   # Location of version storage folder (./data/version-storage);
readonly KE_PATH_VERSION_STORAGE_DEFAULT="${KE_PATH_VERSION_STORAGE}/${KE_NAME_FOLDER_DEFAULT}"        # Location of default version storage folder (./data/version-storage/default).
readonly KE_PATH_VERSION_STORAGE_VERSIONED="${KE_PATH_VERSION_STORAGE}/${KE_PACKAGE_VERSION_SELECTED}" # Location of specified version storage folder (./data/version-storage/<version>).
readonly KE_PATH_PATCHES_FETCH_LIST="${KE_PATH_DATA}/${KE_NAME_FILE_PATCHES_CURRENT}"                  # Location of text file containing currently used patches URL's. Used when fetching fresh set of patches.
readonly KE_PATH_PATCHES_DEFAULT="${KE_PATH_VERSION_STORAGE_DEFAULT}/${KE_NAME_FOLDER_PATCHES}"        # Location of default patches folder (./data/version-storage/default/ps3_patches).
readonly KE_PATH_PATCHES_VERSIONED="${KE_PATH_VERSION_STORAGE_VERSIONED}/${KE_NAME_FOLDER_PATCHES}"    # Location of specified version patches folder (./data/version-storage/<version>/ps3_patches).
set_if   KE_PATH_PATCHES_SAVETO "(\${KE_PACKAGE_VERSION_SPECIFIED} && !\${KE_FLAG_FORCE_DEFAULT})" "${KE_PATH_PATCHES_VERSIONED}" "${KE_PATH_PATCHES_DEFAULT}"
set_if   KE_PATH_PATCHES_SELECTED "(! -d \"\${KE_PATH_PATCHES_VERSIONED}\" || \${KE_FLAG_FORCE_DEFAULT})" "${KE_PATH_PATCHES_DEFAULT}" "${KE_PATH_PATCHES_VERSIONED}"
readonly KE_PATH_CONFIG_DEFAULT="${KE_PATH_VERSION_STORAGE_DEFAULT}/${KE_NAME_FOLDER_CONFIG}"          # Location of default configuration folder (./data/version-storage/default/config).
readonly KE_PATH_CONFIG_VERSIONED="${KE_PATH_VERSION_STORAGE_VERSIONED}/${KE_NAME_FOLDER_CONFIG}"      # Location of specified version configuration folder (./data/version-storage/<version>/config).
readonly KE_PATH_CONFIG_SAVETO="${KE_PATH_CONFIG_VERSIONED}";                                          # Location of where ebuild-04-configure.sh will save generated configuration (./data/version-storage/<version>/config).
set_if   KE_PATH_CONFIG_SELECTED "(! -f \"\${KE_PATH_CONFIG_VERSIONED}/\${KE_NAME_FILE_CONF_DIFFS}\" || \${KE_FLAG_FORCE_DEFAULT})" "${KE_PATH_CONFIG_DEFAULT}" "${KE_PATH_CONFIG_VERSIONED}"
readonly KE_PATH_CONFIG_DIFFS_DEFAULT="${KE_PATH_CONFIG_DEFAULT}/${KE_NAME_FILE_CONF_DIFFS}"           # Location of default diffs file (./data/version-storage/default/config/ps3_defconfig_diffs).
readonly KE_PATH_CONFIG_DIFFS_VERSIONED="${KE_PATH_CONFIG_VERSIONED}/${KE_NAME_FILE_CONF_DIFFS}"       # Location of specified version diffs file (./data/version-storage/<version>/config/ps3_defconfig_diffs).
readonly KE_PATH_CONFIG_DIFFS_SAVETO="${KE_PATH_CONFIG_SAVETO}/${KE_NAME_FILE_CONF_DIFFS}"             # Location where ebuild-04-configure.sh will save generated diffs file (./data/version-storage/<version>/config/ps3_defconfig_diffs).
readonly KE_PATH_CONFIG_DIFFS_SELECTED="${KE_PATH_CONFIG_SELECTED}/${KE_NAME_FILE_CONF_DIFFS}"         # Location of selected diffs file. Versioned if exists, default otherwise.
readonly KE_PATH_CONFIG_DEFCONF_DEFAULT="${KE_PATH_CONFIG_DEFAULT}/${KE_NAME_FILE_CONF_DEFCONF}"       # Location of default config file (./data/version-storage/default/config/ps3_gentoo_defconfig).
readonly KE_PATH_CONFIG_DEFCONF_VERSIONED="${KE_PATH_CONFIG_VERSIONED}/${KE_NAME_FILE_CONF_DEFCONF}"   # Location of specified version config file (./data/version-storage/<version>/config/ps3_gentoo_defconfig).
readonly KE_PATH_CONFIG_DEFCONF_SAVETO="${KE_PATH_CONFIG_SAVETO}/${KE_NAME_FILE_CONF_DEFCONF}"         # Location where ebuild-04-configure.sh will save generated config file (./data/version-storage/<version>/config/ps3_gentoo_defconfig).
readonly KE_PATH_CONFIG_DEFCONF_SELECTED="${KE_PATH_CONFIG_SELECTED}/${KE_NAME_FILE_CONF_DEFCONF}"     # Location of selected config file. Versioned if exists, default otherwise.
readonly KE_PATH_EBUILD_PATCHES="${KE_PATH_DATA}/ebuild-patches"                                       # Location of patches to be applied to generated ebuild file.

# Paths.
readonly KE_PATH_WORK_SRC="${PATH_WORK_KERNEL_EBUILD}/${KE_PACKAGE_VERSION_SELECTED}/src"                           # Location of gentoo-kernel ebuild extracted files main folder.
readonly KE_PATH_WORK_SRC_LINUX="$(find ${KE_PATH_WORK_SRC}/portage/${CONF_KERNEL_PACKAGE_BASE}-${KE_PACKAGE_VERSION_SELECTED}/work/ -maxdepth 1 -name linux-* -type d -print -quit 2>/dev/null)" # Location of linux source code from gentoo-kernel ebuild extracted package.
readonly KE_PATH_WORK_BINPKGS="${PATH_WORK_KERNEL_EBUILD}/${KE_PACKAGE_VERSION_SELECTED}/${KE_NAME_FOLDER_BINPKGS}" # Location of folder containing binpkg created with crossdev.

# Work files location.
readonly KE_PATH_EBUILD_FILE_SRC="${PATH_VAR_DB_REPOS_GENTOO}/${CONF_KERNEL_PACKAGE_BASE}/${KE_NAME_EBUILD_FILE_PACKAGE_SRC}" # Location of source ebuild file.
readonly KE_PATH_EBUILD_FILE_DST="${KE_PATH_WORK_EBUILD}/${KE_NAME_EBUILD_FILE_PACKAGE_DST}"                        # Location of destination ebuild file.
readonly KE_PATH_WORK_EBUILD="${PATH_WORK_KERNEL_EBUILD}/${KE_PACKAGE_VERSION_SELECTED}/ebuild"                     # Location of ebuild generation workdir.
readonly KE_PATH_BINPKGS_PACKAGES_SRC="${PATH_CROSSDEV_BINPKGS}/${KE_NAME_FILE_BINPKGS_PACKAGES}"
readonly KE_PATH_BINPKGS_PACKAGES_DST="${KE_PATH_WORK_BINPKGS}/${KE_NAME_FILE_BINPKGS_PACKAGES}"

# Helper scripts.
readonly KE_PATH_SCRIPTS="${KE_PATH_DATA}/${KE_NAME_FOLDER_SCRIPTS}"                             # Location of helper scripts folder for kernel-ebuild scripts set.
readonly KE_PATH_SCRIPT_APPLY_DIFFCONFIG="${KE_PATH_SCRIPTS}/apply-diffconfig.rb"                # Location of scripts that applied differences in ps3_defconfig_diffs to .config file.
readonly KE_PATH_SCRIPT_MERGE_CONFIG="${KE_PATH_WORK_SRC_LINUX}/scripts/kconfig/merge_config.sh" # Location of linux script inside src workdir, that merges selected config files.
readonly KE_PATH_SCRIPT_DIFFCONFIG="${KE_PATH_WORK_SRC_LINUX}/scripts/diffconfig"                # Location of linux script inside src workdir, that generates new diffconfig file.

# Crossdev locations.
readonly KE_PATH_CROSSDEV_BINPKGS_KERNEL_PACKAGE="${PATH_CROSSDEV_BINPKGS}/${CONF_KERNEL_PACKAGE_SPECIAL}"
