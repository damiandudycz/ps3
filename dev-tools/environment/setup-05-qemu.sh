#!/bin/bash

source ../../.env-shared.sh || exit 1
source "${PATH_EXTRA_ENV_ENVIRONMENT}" || failure "Failed to load env ${PATH_EXTRA_ENV_ENVIRONMENT}"

# QEMU registration expression
readonly CONF_QEMU_REGISTRATION_EXPR=':ppc64:M::\x7fELF\x02\x02\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x15:\xff\xff\xff\xff\xff\xff\xff\xfc\xff\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff:'"${PATH_INTERPRETER}"':'
readonly NAME_QEMU_SECTION_START="# FOR CATALYST QEMU ---------- START"
readonly NAME_QEMU_SECTION_END="# FOR CATALYST QEMU ---------- END"
readonly PATH_PACKAGE_USE_QEMU="${PATH_ETC_PORTAGE_PACKAGE_USE}/PS3_ENV_qemu"
readonly PATH_BINFMT="/proc/sys/fs/binfmt_misc"
readonly PATH_BINFMT_REGISTER="${PATH_BINFMT}/register"

[ "$(uname -m)" != "ppc64" ] || return 0 # Qemu not needed for PPC64

# Configure make.conf qemu section.
[ ! -f "${PATH_ETC_PORTAGE_MAKE_CONF}" ] || sed -i "/${NAME_QEMU_SECTION_START}/,/${NAME_QEMU_SECTION_END}/d" "${PATH_ETC_PORTAGE_MAKE_CONF}" # Clean old section in make.conf if found
echo "${NAME_QEMU_SECTION_START}" >> "${PATH_ETC_PORTAGE_MAKE_CONF}"
echo "QEMU_SOFTMMU_TARGETS=\"aarch64 ppc64\"" >> "${PATH_ETC_PORTAGE_MAKE_CONF}"
echo "QEMU_USER_TARGETS=\"ppc64\"" >> "${PATH_ETC_PORTAGE_MAKE_CONF}"
echo "${NAME_QEMU_SECTION_END}" >> "${PATH_ETC_PORTAGE_MAKE_CONF}"

# Configure portage qemu section.
[ ! -f "${PATH_PACKAGE_USE_QEMU}" ] || sed -i "/${NAME_QEMU_SECTION_START}/,/${NAME_QEMU_SECTION_END}/d" "${PATH_PACKAGE_USE_QEMU}" # Clean old section in package.use/PS3_ENV_qemu if found
echo "${NAME_QEMU_SECTION_START}" >> "${PATH_PACKAGE_USE_QEMU}"
echo "app-emulation/qemu static-user" >> "${PATH_PACKAGE_USE_QEMU}"
echo "dev-libs/glib static-libs" >> "${PATH_PACKAGE_USE_QEMU}"
echo "sys-libs/zlib static-libs" >> "${PATH_PACKAGE_USE_QEMU}"
echo "sys-apps/attr static-libs" >> "${PATH_PACKAGE_USE_QEMU}"
echo "dev-libs/libpcre2 static-libs" >> "${PATH_PACKAGE_USE_QEMU}"
echo "${NAME_QEMU_SECTION_END}" >> "${PATH_PACKAGE_USE_QEMU}"

emerge --newuse --update --deep qemu

# Setup Qemu autostart and run it
rc-update add qemu-binfmt default
rc-config start qemu-binfmt
[ -d "${PATH_BINFMT}" ] || modprobe binfmt_misc
[ -f "${PATH_BINFMT_REGISTER}" ] || mount binfmt_misc -t binfmt_misc "${PATH_BINFMT}"
[ -f "${PATH_BINFMT_REGISTER}" ] || echo "${CONF_QEMU_REGISTRATION_EXPR}" > "${PATH_BINFMT_REGISTER}"
