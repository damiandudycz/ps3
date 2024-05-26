#!/bin/bash

# This sctipt emerges and configures Qemu for the PS3 Gentoo project.

# Error handling function
die() {
    echo "$*" 1>&2
    exit 1
}

# Constants
readonly PATH_START=$(dirname "$(realpath "$0")") || die
readonly PATH_ROOT=$(realpath -m "${PATH_START}/../..") || die
readonly PATH_LOCAL_TMP="/var/tmp/ps3/release"
readonly PATH_RELENG="${PATH_LOCAL_TMP}/releng"
readonly PATH_INTERPRETER="/usr/bin/qemu-ppc64"
readonly PATH_PORTAGE="/etc/portage"

# QEMU registration expression
readonly QEMU_REGISTRATION_EXPR=':ppc64:M::\x7fELF\x02\x02\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x15:\xff\xff\xff\xff\xff\xff\xff\xfc\xff\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff:'"${PATH_INTERPRETER}"':'

# Determine if host is PS3 or another architecture
[ "$(uname -m)" != "ppc64" ] && use_qemu=true

# Exit if Qemu is already set up
if [ ! "$use_qemu" ] || [ -f "${PATH_INTERPRETER}" ]; then
    echo "Qemu already installed or not needed. Skipping."
    exit 0
fi

# Download and setup Qemu
echo "" >> "${PATH_PORTAGE}/make.conf" || die "Failed to update make.conf"
echo "# Catalyst requirements" >> "${PATH_PORTAGE}/make.conf" || die "Failed to update make.conf"
echo "QEMU_SOFTMMU_TARGETS=\"aarch64 ppc64\"" >> "${PATH_PORTAGE}/make.conf" || die "Failed to update make.conf"
echo "QEMU_USER_TARGETS=\"ppc64\"" >> "${PATH_PORTAGE}/make.conf" || die "Failed to update make.conf"
echo "# ---" >> "${PATH_PORTAGE}/make.conf" || die "Failed to update make.conf"
echo "" >> "${PATH_PORTAGE}/package.use/qemu" || die "Failed to update package.use"
echo "# Catalyst requirements" >> "${PATH_PORTAGE}/package.use/qemu" || die "Failed to update package.use"
echo "app-emulation/qemu static-user" >> "${PATH_PORTAGE}/package.use/qemu" || die "Failed to update package.use"
echo "dev-libs/glib static-libs" >> "${PATH_PORTAGE}/package.use/qemu" || die "Failed to update package.use"
echo "sys-libs/zlib static-libs" >> "${PATH_PORTAGE}/package.use/qemu" || die "Failed to update package.use"
echo "sys-apps/attr static-libs" >> "${PATH_PORTAGE}/package.use/qemu" || die "Failed to update package.use"
echo "dev-libs/libpcre2 static-libs" >> "${PATH_PORTAGE}/package.use/qemu" || die "Failed to update package.use"
echo "# ---" >> "${PATH_PORTAGE}/package.use/qemu" || die "Failed to update package.use"

emerge qemu -q || die "Failed to emerge qemu"

# Setup Qemu autostart and run it
rc-update add qemu-binfmt default || die "Failed to add qemu-binfmt to autostart"
rc-config start qemu-binfmt || die "Failed to start qemu-binfmt service"
[ -d /proc/sys/fs/binfmt_misc ] || modprobe binfmt_misc || die "Failed to load binfmt_misc module"
[ -f /proc/sys/fs/binfmt_misc/register ] || mount binfmt_misc -t binfmt_misc /proc/sys/fs/binfmt_misc || die "Failed to mount binfmt_misc"

# Setup Qemu for PPC64
echo "${QEMU_REGISTRATION_EXPR}" > /proc/sys/fs/binfmt_misc/register || die "Failed to setup QEMU for PPC64"

exit 0
