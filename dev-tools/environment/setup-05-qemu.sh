#!/bin/bash

source ../../.env-shared.sh || exit 1

[[ ${VAL_QEMU_IS_NEEDED} ]] || return 0 # Qemu not needed for PPC64

sed -i "/${CONF_QEMU_SECTION_START}/,/${CONF_QEMU_SECTION_END}/d" "${PATH_ETC_PORTAGE_MAKE_CONF}" # Clean old section in make.conf if found

# Configure make.conf qemu section.
echo "${CONF_QEMU_SECTION_START}" >> "${PATH_ETC_PORTAGE_MAKE_CONF}"
echo "QEMU_SOFTMMU_TARGETS=\"${VAL_HOST_ARCHITECTURE} ${CONF_TARGET_ARCHITECTURE}\"" >> "${PATH_ETC_PORTAGE_MAKE_CONF}"
echo "QEMU_USER_TARGETS=\"${CONF_TARGET_ARCHITECTURE}\"" >> "${PATH_ETC_PORTAGE_MAKE_CONF}"
echo "${CONF_QEMU_SECTION_END}" >> "${PATH_ETC_PORTAGE_MAKE_CONF}"

# Configure portage qemu section.
use_set_package "app-emulation/qemu" "static-user"
use_set_package "dev-libs/glib" "static-libs"
use_set_package "sys-libs/zlib" "static-libs"
use_set_package "sys-apps/attr" "static-libs"
use_set_package "dev-libs/libpcre2" "static-libs"
emerge --newuse --update --deep qemu

# Setup Qemu autostart and run it
rc-update add qemu-binfmt default
rc-config stop qemu-binfmt
[[ -d "${PATH_QEMU_BINFMT}" ]] || modprobe binfmt_misc
[[ -f "${PATH_QEMU_BINFMT_REGISTER}" ]] || mount binfmt_misc -t binfmt_misc "${PATH_QEMU_BINFMT}"
[[ -f "${PATH_QEMU_BINFMT_REGISTER}" ]] || echo "${VAL_QEMU_REGISTRATION_EXPR}" > "${PATH_QEMU_BINFMT_REGISTER}"
rc-config start qemu-binfmt
