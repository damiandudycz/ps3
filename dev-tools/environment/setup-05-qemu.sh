#!/bin/bash

source ../../.env-shared.sh || exit 1
source "${PATH_EXTRA_ENV_ENVIRONMENT}" || failure "Failed to load env ${PATH_EXTRA_ENV_ENVIRONMENT}"

[[ "$(uname -m)" != "${CONF_TARGET_ARCHITECTURE}" ]] || return 0 # Qemu not needed for PPC64

sed -i "/${EN_NAME_QEMU_SECTION_START}/,/${EN_NAME_QEMU_SECTION_END}/d" "${PATH_ETC_PORTAGE_MAKE_CONF}" # Clean old section in make.conf if found

# Configure make.conf qemu section.
echo "${EN_NAME_QEMU_SECTION_START}" >> "${PATH_ETC_PORTAGE_MAKE_CONF}"
echo "QEMU_SOFTMMU_TARGETS=\"${VAL_HOST_ARCHITECTURE} ${CONF_TARGET_ARCHITECTURE}\"" >> "${PATH_ETC_PORTAGE_MAKE_CONF}"
echo "QEMU_USER_TARGETS=\"${CONF_TARGET_ARCHITECTURE}\"" >> "${PATH_ETC_PORTAGE_MAKE_CONF}"
echo "${EN_NAME_QEMU_SECTION_END}" >> "${PATH_ETC_PORTAGE_MAKE_CONF}"

# Configure portage qemu section.
use_set_package "app-emulation/qemu" "static-user"
use_set_package "dev-libs/glib" "static-libs"
use_set_package "sys-libs/zlib" "static-libs"
use_set_package "sys-apps/attr" "static-libs"
use_set_package "dev-libs/libpcre2" "static-libs"

emerge --newuse --update --deep qemu

# Setup Qemu autostart and run it
rc-update add qemu-binfmt default
rc-config start qemu-binfmt
[[ -d "${EN_PATH_BINFMT}" ]] || modprobe binfmt_misc
[[ -f "${EN_PATH_BINFMT_REGISTER}" ]] || mount binfmt_misc -t binfmt_misc "${EN_PATH_BINFMT}" || echo "mount binfmt_misc failed, probably already mounted"
[[ -f "${EN_PATH_BINFMT_REGISTER}" ]] || echo "${EN_CONF_QEMU_REGISTRATION_EXPR}" > "${EN_PATH_BINFMT_REGISTER}"
