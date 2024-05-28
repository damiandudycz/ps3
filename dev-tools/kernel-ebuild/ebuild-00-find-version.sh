#!/bin/bash

# This script returns the version of the newest version of gentoo-kernel package
# available in standard gentoo repository.
# By default it returns the stable version, but it can also be called with --unstable
# flag, to determine the newest unstable available version.
# If user specified version as an argument, this script will just return user specified version number, even it it doesn't exists.

# --- Shared environment
source ../../.env-shared.sh --silent || exit 1
source "${PATH_EXTRA_ENV_KERNEL_EBUILD}" || failure "Failed to load env ${PATH_EXTRA_ENV_KERNEL_EBUILD}"
trap failure ERR
register_usage "$0 [--unstable]"

if [ $KE_PACKAGE_VERSION_SPECIFIED ]; then
    echo ${KE_PACKAGE_VERSION_SPECIFIED}
else
    readonly PACKAGE_VERSION=$(equery m "${KE_NAME_PACKAGE_SRC}" | grep " ${KE_VAR_EBUILD_KEYWORD_SELECTED}" | awk '{print $2}' | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+(-r[0-9]+)?' | sort -V | tail -n 1)
    [ ${PACKAGE_VERSION} ] || failure "Failed to find gentoo-kernel version"
    echo ${PACKAGE_VERSION}
fi
