#!/bin/bash

source ../../.env-shared.sh --silent || exit 1
source "${PATH_EXTRA_ENV_KERNEL_EBUILD}" || failure "Failed to load env ${PATH_EXTRA_ENV_KERNEL_EBUILD}"

# Get package version.
if [[ $KE_PACKAGE_VERSION_SPECIFIED ]]; then
    echo ${KE_PACKAGE_VERSION_SPECIFIED}
else
    readonly PACKAGE_VERSION=$(equery m "${CONF_KERNEL_PACKAGE_BASE}" | grep " ${KE_VAL_EBUILD_KEYWORD_SELECTED}" | awk '{print $2}' | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+(-r[0-9]+)?' | sort -V | tail -n 1)
    [[ ${PACKAGE_VERSION} ]] || failure "Failed to find gentoo-kernel version"
    echo ${PACKAGE_VERSION}
fi
