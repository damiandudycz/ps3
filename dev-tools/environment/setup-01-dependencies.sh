#!/bin/bash

# This script installs simple dependencies required by other parts of the system,
# which don't require special setup and configuration.

# Error handling function
die() {
    echo "$*" 1>&2
    exit 1
}

# Download various required pckages
emerge --newuse --update --deep gentoolkit ruby pkgdev dev-vcs/subversion -q || die "Failed to install dependencies"

exit 0
