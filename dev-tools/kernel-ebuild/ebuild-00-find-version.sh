#!/bin/bash

# This script returns the version of the newest version of gentoo-kernel package
# available in standard gentoo repository.
# By default it returns the stable version, but it can also be called with --unstable
# flag, to determine the newest unstable available version.

# --- Shared environment
source ../../.env-shared.sh --silent || exit 1
trap failure ERR
register_usage "$0 [--unstable]"

NAME_KEYWORD=" ppc64"
[ "$1" = "--unstable" ] && NAME_KEYWORD=" ~ppc64"

[ -z "$1" ] || [ "$1" = "--unstable" ] || show_usage

readonly NAME_PACKAGE="sys-kernel/gentoo-kernel"
readonly NEWEST_VERSION=$(equery m "${NAME_PACKAGE}" | grep "${NAME_KEYWORD}" | awk '{print $2}' | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+(-r[0-9]+)?' | sort -V | tail -n 1)

[ $NEWEST_VERSION ] || failure "Failed to find gentoo-kernel version"
echo $NEWEST_VERSION
