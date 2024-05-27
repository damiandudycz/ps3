#!/bin/bash

# This script clones and configures releng for the PS3 Gentoo project.

source ../../.env-shared.sh
trap failure ERR

cleanup() {
echo "CLEAN"
    rm -rf "${PATH_LOCAL_TMP}" || echo "Failed to remove temporary directory: ${PATH_LOCAL_TMP}" 1>&2
}
trap 'cleanup' EXIT

# Constants
readonly PATH_START=$(dirname "$(realpath "$0")")
readonly PATH_ROOT=$(realpath -m "${PATH_START}/../..") || die
readonly PATH_LOCAL_TMP="/var/tmp/ps3/releng"

PATH_PORTAGE_CONFDIR_STAGES="${PATH_LOCAL_TMP}/releases/portage/stages"
PATH_PORTAGE_CONFDIR_ISOS="${PATH_LOCAL_TMP}/releases/portage/isos"

if [ -d "${PATH_LOCAL_TMP}" ]; then
    echo "Releng already installed. Skipping"
sdssdasd
    exit 0
fi

# Determine if host is PS3 or another architecture
[ "$(uname -m)" != "ppc64" ] && use_qemu=true

if [ "${use_qemu}" ]; then
    PATH_PORTAGE_CONFDIR_STAGES="${PATH_PORTAGE_CONFDIR_STAGES}-qemu"
    PATH_PORTAGE_CONFDIR_ISOS="${PATH_PORTAGE_CONFDIR_ISOS}-qemu"
fi

# Create local tmp path
mkdir -p "${PATH_LOCAL_TMP}"

# Download and setup releng
git clone -o upstream https://github.com/gentoo/releng.git "${PATH_LOCAL_TMP}" || die "Failed to clone releng repository"
cp -rf "${PATH_PORTAGE_CONFDIR_STAGES}" "${PATH_PORTAGE_CONFDIR_STAGES}-cell" || die "Failed to copy portage stages directory"
cp -rf "${PATH_PORTAGE_CONFDIR_ISOS}" "${PATH_PORTAGE_CONFDIR_ISOS}-cell" || die "Failed to copy portage isos directory"
echo '*/* CPU_FLAGS_PPC: altivec' > "${PATH_PORTAGE_CONFDIR_STAGES}-cell/package.use/00cpu-flags" || die "Failed to update package.use in stages directory"
echo '*/* CPU_FLAGS_PPC: altivec' > "${PATH_PORTAGE_CONFDIR_ISOS}-cell/package.use/00cpu-flags" || die "Failed to update package.use in isos directory"

exit 0
