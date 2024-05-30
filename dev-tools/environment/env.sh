#!/bin/bash

[ ! ${EN_ENV_LOADED} ] || return 0
readonly EN_ENV_LOADED=true

[[ ${VAL_QEMU_IS_NEEDED} ]] && EN_FLAG_QEMU="-qemu" || unset EN_FLAG_QEMU

# Configs.
readonly EN_PACKAGES_DEPENDENCIES=(gentoolkit ruby pkgdev crossdev dev-vcs/git)

# Helper names.
readonly EN_KE_NAME_PACKAGE_DST="sys-kernel/gentoo-kernel-ps3" # Name of customized gentoo-kernel package.

# Locations.
readonly EN_PATH_CROSSDEV_USR="${PATH_USR_SHARE}/crossdev"
readonly EN_PATH_HOOK_AUTOBUILDS="${PATH_ROOT}/.git/modules/autobuilds/ps3-gentoo-autobuilds/pre-commit"

# Overlay locations.
readonly EN_KE_PATH_OVERLAY_EBUILDS="${PATH_OVERLAYS_PS3_GENTOO}/${EN_KE_NAME_PACKAGE_DST}"

readonly EN_PATH_CATALYST_USR="${PATH_USR_SHARE}/catalyst"
readonly EN_PATH_CATALYST_TMP="${PATH_VAR_TMP}/catalyst"
readonly EN_PATH_CATALYST_BUILDS="${EN_PATH_CATALYST_TMP}/builds"
readonly EN_PATH_CATALYST_STAGES="${EN_PATH_CATALYST_TMP}/config/stages"
readonly EN_PATH_CATALYST_PACKAGES="${EN_PATH_CATALYST_TMP}/packages"
readonly EN_PATH_CATALYST_PATCH_DIR="${PATH_ETC_PORTAGE}/patches/dev-util/catalyst"
readonly EN_PATH_CATALYST_CONFIGS="${PATH_ETC}/catalyst"
readonly EN_PATH_CATALYST_CONF="${EN_PATH_CATALYST_CONFIGS}/catalyst.conf"
readonly EN_PATH_CATALYST_PPC_TOML="${EN_PATH_CATALYST_USR}/arch/ppc.toml"
readonly EN_PATH_FILES_CATALYST_PATCHES="${PATH_DEV_TOOLS_ENVIRONMENT}/data/catalyst-patches"
readonly EN_PATH_PATCH_PATHS="$(find ${EN_PATH_FILES_CATALYST_PATCHES} -maxdepth 1 -type f -name '*.patch' | sort)"
readonly EN_PATH_RELENG_PORTAGE_CONFDIR_STAGES="${PATH_RELENG}/releases/portage/stages${EN_FLAG_QEMU}"
readonly EN_PATH_RELENG_PORTAGE_CONFDIR_ISOS="${PATH_RELENG}/releases/portage/isos${EN_FLAG_QEMU}"

