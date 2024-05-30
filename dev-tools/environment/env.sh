#!/bin/bash

[ ! ${EN_ENV_LOADED} ] || return 0
readonly EN_ENV_LOADED=true

[[ "$(uname -m)" != "${CONF_TARGET_ARCHITECTURE}" ]] && EN_FLAG_QEMU="-qemu" || unset EN_FLAG_QEMU

# Configs.
readonly EN_CONF_GIT_USER="Damian Dudycz"
readonly EN_CONF_GIT_EMAIL="damiandudycz@yahoo.com"
readonly EN_CONF_GIT_EDITOR="nano"
readonly EN_PATH_INTERPRETER="\${PATH_USR_BIN}/qemu-${CONF_TARGET_ARCHITECTURE}"
readonly EN_CONF_QEMU_REGISTRATION_EXPR=':ppc64:M::\x7fELF\x02\x02\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x15:\xff\xff\xff\xff\xff\xff\xff\xfc\xff\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff:'"${EN_PATH_INTERPRETER}"':'
readonly EN_CONF_CATALYST_JOBS="8"
readonly EN_CONF_CATALYST_LOAD="12.0"
readonly EN_MAKE_FEATURES="getbinpkg"
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

readonly EN_NAME_QEMU_SECTION_START="# FOR CATALYST QEMU ---------- START"
readonly EN_NAME_QEMU_SECTION_END="# FOR CATALYST QEMU ---------- END"
readonly EN_PATH_BINFMT="/proc/sys/fs/binfmt_misc"
readonly EN_PATH_BINFMT_REGISTER="${PATH_BINFMT}/register"
