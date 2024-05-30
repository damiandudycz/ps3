#!/bin/bash

source ../../.env-shared.sh || exit 1
source "${PATH_EXTRA_ENV_ENVIRONMENT}" || failure "Failed to load env ${PATH_EXTRA_ENV_ENVIRONMENT}"

[[ ! -d "${EN_PATH_CROSSDEV_USR}" ]] && failure "Crossdev not installed."

[[ ! -f "/etc/portage/repos.conf/crossdev.conf" ]] || rm -f "/etc/portage/repos.conf/crossdev.conf"
[[ ! -d "/var/db/repos/crossdev" ]] || rm -rf "/var/db/repos/crossdev"

mkdir -p "/var/db/repos/crossdev"/{profiles,metadata}
chown -R portage:portage "/var/db/repos/crossdev"
mkdir -p "/etc/portage/repos.conf"
# Configure crossdev repo
echo 'crossdev' >> "/var/db/repos/crossdev/profiles/repo_name"
echo 'masters = gentoo' >> "/var/db/repos/crossdev/metadata/layout.conf"
echo '[crossdev]' >> "/etc/portage/repos.conf/crossdev.conf"
echo 'location = /var/db/repos/crossdev' >> "/etc/portage/repos.conf/crossdev.conf"
echo 'priority = 10' >> "/etc/portage/repos.conf/crossdev.conf"
echo 'masters = gentoo' >> "/etc/portage/repos.conf/crossdev.conf"
echo 'auto-sync = no' >> "/etc/portage/repos.conf/crossdev.conf"

# TODO: Move variables to env.
# Setup crossdev environment
crossdev\
    --b "2.41-r3"\
    --g "13.2.1_p20240113-r1"\
    --k "6.9"\
    --l "2.37-r7"\
    --target "powerpc64-unknown-linux-gnu"\
    --abis "altivec"\
#    --ov-extra ${PATH_OVERLAYS_PS3_GENTOO}
