#!/bin/bash

# Install simple dependencies required by other parts of the system

# Error handling function
die() {
    echo "$*" 1>&2
    exit 1
}

# Enable binpkg usage
echo 'FEATURES="${FEATURES} getbinpkg"' >> /etc/portage/make.conf || die "Failed to enabled getbinpkg flag"

# Refresh portage tree
emerge --sync || die "Failed to synchronize portage tree"

# Install updates
emerge --newuse --update --deep @world -q || die "Failed to update system"

exit 0
