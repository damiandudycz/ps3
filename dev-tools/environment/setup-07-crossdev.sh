#!/bin/bash

source ../../.env-shared.sh || exit 1

rm -f "${PATH_ETC_PORTAGE_REPOS_CONF}/crossdev.conf"
rm -rf "${PATH_VAR_DB_REPOS_CROSSDEV}"

mkdir -p "${PATH_VAR_DB_REPOS_CROSSDEV}"/{profiles,metadata}
chown -R portage:portage "${PATH_VAR_DB_REPOS_CROSSDEV}"
mkdir -p "${PATH_ETC_PORTAGE_REPOS_CONF}"
# Configure crossdev repo
echo 'crossdev' >> "${PATH_VAR_DB_REPOS_CROSSDEV}/profiles/repo_name"
echo 'masters = gentoo' >> "${PATH_VAR_DB_REPOS_CROSSDEV}/metadata/layout.conf"
echo '[crossdev]' >> "${PATH_ETC_PORTAGE_REPOS_CONF}/crossdev.conf"
echo 'location = /var/db/repos/crossdev' >> "${PATH_ETC_PORTAGE_REPOS_CONF}/crossdev.conf"
echo 'priority = 10' >> "${PATH_ETC_PORTAGE_REPOS_CONF}/crossdev.conf"
echo 'masters = gentoo' >> "${PATH_ETC_PORTAGE_REPOS_CONF}/crossdev.conf"
echo 'auto-sync = no' >> "${PATH_ETC_PORTAGE_REPOS_CONF}/crossdev.conf"
emerge --newuse --update --deep crossdev

# TODO: Configure crossdev environment with CELL cpu flags. Store these flags in shared env and also use with installer.
# Setup crossdev environment
crossdev\
    --target "${VAL_CROSSDEV_TARGET}"\
    --abis "${CONF_CROSSDEV_ABI}"\
    --l "${CONF_CROSSDEV_L}"\
    --k "${CONF_CROSSDEV_K}"\
    --g "${CONF_CROSSDEV_G}"\
    --b "${CONF_CROSSDEV_B}"

update_config_assign "PORTDIR_OVERLAY" "${PATH_OVERLAYS_PS3_GENTOO}" "${PATH_USR}/${VAL_CROSSDEV_TARGET}/${PATH_ETC_PORTAGE_MAKE_CONF}"
