#!/bin/bash

# This script emerges and configures crossdev.

# --- Shared environment
source ../../.env-shared.sh || exit 1
trap failure ERR

# Constants
readonly PATH_CROSSDEV="/usr/share/crossdev"
#readonly PATH_OVERLAY="${}"

# Exit if crossdev is already set up
if [ -d "${PATH_CROSSDEV}" ]; then
    echo "Crossdev already installed. Skipping."
    exit 0
fi

[ ! -f "/etc/portage/repos.conf/crossdev.conf" ] || rm -f "/etc/portage/repos.conf/crossdev.conf" || die "Failed to clean old config file"
[ ! -d "/var/db/repos/crossdev" ] || rm -rf "/var/db/repos/crossdev" || die "Failed to clean old config file"

# Download and setup Crssdev
emerge crossdev --newuse --update --deep -q || die "Failed to emerge crossdev"
mkdir -p "/var/db/repos/crossdev"/{profiles,metadata} || die "Failed to create directories"
chown -R portage:portage "/var/db/repos/crossdev" || die "Failed to update directories permissions"
mkdir -p "/etc/portage/repos.conf" || die "Failed to create repos.conf directory"
# Configure crossdev repo
echo 'crossdev' >> "/var/db/repos/crossdev/profiles/repo_name" || die "Failed to update crossdev config"
echo 'masters = gentoo' >> "/var/db/repos/crossdev/metadata/layout.conf" || die "Failed to update crossdev config"
echo '[crossdev]' >> "/etc/portage/repos.conf/crossdev.conf" || die "Failed to update crossdev config"
echo 'location = /var/db/repos/crossdev' >> "/etc/portage/repos.conf/crossdev.conf" || die "Failed to update crossdev config"
echo 'priority = 10' >> "/etc/portage/repos.conf/crossdev.conf" || die "Failed to update crossdev config"
echo 'masters = gentoo' >> "/etc/portage/repos.conf/crossdev.conf" || die "Failed to update crossdev config"
echo 'auto-sync = no' >> "/etc/portage/repos.conf/crossdev.conf" || die "Failed to update crossdev config"

# Setup crossdev environment
crossdev --b '2.41-r3' --g '13.2.1_p20240113-r1' --k '6.9' --l '2.37-r7' -t powerpc64-unknown-linux-gnu --abis altivec

exit 0
