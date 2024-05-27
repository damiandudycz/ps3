#!/bin/bash

# This script installs simple dependencies required by other parts of the system,
# which don't require special setup and configuration.

# --- Shared environment
source ../../.env-shared.sh || exit 1
trap failure ERR

readonly PACKAGES_DEPENDENCIES=(gentoolkit ruby pkgdev dev-vcs/subversion)
emerge --newuse --update --deep "${PACKAGES_DEPENDENCIES[@]}"
