#!/bin/bash

source ../../.env-shared.sh || exit 1
source "${PATH_EXTRA_ENV_ENVIRONMENT}" || failure "Failed to load env ${PATH_EXTRA_ENV_ENVIRONMENT}"

empty_directory "${PATH_RELENG}"

# Download and setup releng
git clone -o upstream https://github.com/gentoo/releng.git "${PATH_RELENG}"
cp -rf "${EN_PATH_RELENG_PORTAGE_CONFDIR_STAGES}" "${EN_PATH_RELENG_PORTAGE_CONFDIR_STAGES}-cell"
cp -rf "${EN_PATH_RELENG_PORTAGE_CONFDIR_ISOS}" "${EN_PATH_RELENG_PORTAGE_CONFDIR_ISOS}-cell"
echo '*/* CPU_FLAGS_PPC: altivec' > "${EN_PATH_RELENG_PORTAGE_CONFDIR_STAGES}-cell/package.use/00cpu-flags"
echo '*/* CPU_FLAGS_PPC: altivec' > "${EN_PATH_RELENG_PORTAGE_CONFDIR_ISOS}-cell/package.use/00cpu-flags"
