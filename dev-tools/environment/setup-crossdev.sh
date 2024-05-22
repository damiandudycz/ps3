#!/bin/bash

# Error handling function
die() {
    echo "$*" 1>&2
    exit 1
}

# Constants
readonly PATH_START=$(dirname "$(realpath "$0")") || die
readonly PATH_ROOT=$(realpath -m "${PATH_START}/../..") || die
readonly PATH_CROSSDEV="/usr/share/crossdev"

# Exit if crossdev is already set up
if [ -f "${PATH_INTERPRETER}" ]; then
    echo "Crossdev already installed. Skipping."
    exit 0
fi

# Download and setup Crssdev
emerge crossdev -q || die "Failed to emerge crossdev"
mkdir -p "/var/db/repos/crossdev/{profiles,metadata}" || die "Failed to create directories"
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
crossdev -t powerpc64-unknown-linux-gnu --abis altivec || die "Failed to setup crossdev environment"

exit 0
