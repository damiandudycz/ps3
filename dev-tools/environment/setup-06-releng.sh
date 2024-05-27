#!/bin/bash

# This script clones and configures releng for the PS3 Gentoo project.

# --- Shared environment
source ../../.env-shared.sh || exit 1
trap failure ERR

[ "$(uname -m)" != "ppc64" ] && FLAG_QEMU="-qemu"
readonly PATH_PORTAGE_CONFDIR_STAGES="${PATH_RELENG}/releases/portage/stages${FLAG_QEMU}"
readonly PATH_PORTAGE_CONFDIR_ISOS="${PATH_RELENG}/releases/portage/isos${FLAG_QEMU}"

# Create local tmp path
[ ! -d "${PATH_RELENG}" ] || rm -rf "${PATH_RELENG}"
mkdir -p "${PATH_RELENG}"

# Download and setup releng
git clone -o upstream https://github.com/gentoo/releng.git "${PATH_RELENG}"
cp -rf "${PATH_PORTAGE_CONFDIR_STAGES}" "${PATH_PORTAGE_CONFDIR_STAGES}-cell"
cp -rf "${PATH_PORTAGE_CONFDIR_ISOS}" "${PATH_PORTAGE_CONFDIR_ISOS}-cell"
echo '*/* CPU_FLAGS_PPC: altivec' > "${PATH_PORTAGE_CONFDIR_STAGES}-cell/package.use/00cpu-flags"
echo '*/* CPU_FLAGS_PPC: altivec' > "${PATH_PORTAGE_CONFDIR_ISOS}-cell/package.use/00cpu-flags"
