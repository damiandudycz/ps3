#!/bin/bash

# Install simple dependencies required by other parts of the system

# Error handling function
die() {
    echo "$*" 1>&2
    exit 1
}

# Refresh portage tree
emerge --sync || die "Failed to synchronize portage tree"

# Install updates
emerge --newuse --update --deep @world -q || die "Failed to update system"

# Download various required pckages
emerge --newuse --update --deep ruby pkgdev -q || die "Failed to install dependencies"

exit 0
