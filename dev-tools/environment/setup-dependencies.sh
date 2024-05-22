#!/bin/bash

# Install simple dependencies required by other parts of the system

# Error handling function
die() {
    echo "$*" 1>&2
    exit 1
}

# Download various required pckages
emerge --newuse --update --deep ruby pkgdev dev-vcs/subversion -q || die "Failed to install dependencies"

exit 0
