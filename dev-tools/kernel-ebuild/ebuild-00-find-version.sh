#!/bin/bash

# This script returns the version of the newest version of gentoo-kernel package
# available in standard gentoo repository.
# By default it returns the stable version, but it can also be called with --unstable
# flag, to determine the newest unstable available version.

# Error handling function
die() {
    echo "$*" 1>&2
    exit 1
}

readonly NAME_PACKAGE="sys-kernel/gentoo-kernel"

NAME_KEYWORD=" ppc64"
[ "$1" = "--unstable" ] && NAME_KEYWORD="~ppc64"

readonly NEWEST_VERSION=$(equery m "${NAME_PACKAGE}" | grep "${NAME_KEYWORD}" | awk '{print $2}' | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+(-r[0-9]+)?' | sort -V | tail -n 1)

[ $NEWEST_VERSION ] || die "Failed to find gentoo-kernel version"

echo $NEWEST_VERSION
exit 0
