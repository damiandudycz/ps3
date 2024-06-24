#!/bin/bash

source ../../.env-shared.sh || exit 1

empty_directory "${PATH_RELENG}"

# Download and setup releng
git clone -o upstream https://github.com/gentoo/releng.git "${PATH_RELENG}"

# TODO: Moving this to releng scripts, to prepare on demand
#cp -rf "${PATH_RELENG_PORTAGE_CONFDIR_STAGES}" "${PATH_RELENG_PORTAGE_CONFDIR_STAGES}-cell"
#cp -rf "${PATH_RELENG_PORTAGE_CONFDIR_ISOS}" "${PATH_RELENG_PORTAGE_CONFDIR_ISOS}-cell"
#echo '*/* CPU_FLAGS_PPC: altivec' > "${PATH_RELENG_PORTAGE_CONFDIR_STAGES}-cell/package.use/00cpu-flags"
#echo '*/* CPU_FLAGS_PPC: altivec' > "${PATH_RELENG_PORTAGE_CONFDIR_ISOS}-cell/package.use/00cpu-flags"
