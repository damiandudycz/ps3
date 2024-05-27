#!/bin/bash

# This script installs simple dependencies required by other parts of the system,
# which don't require special setup and configuration.

# --- Shared environment --- # Imports shared environment configuration,
source ../../.env-shared.sh  # patches and functions.
trap failure ERR             # Sets a failure trap on any error.
# -------------------------- #

readonly PACKAGES=(gentoolkit ruby pkgdev dev-vcs/subversion)
emerge --newuse --update --deep "${PACKAGES[@]}"

exit 0
