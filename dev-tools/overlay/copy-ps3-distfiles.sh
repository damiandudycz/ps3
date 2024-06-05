#!/bin/bash

# This script copies all distfiles available in ps3-gentoo-overlay.distfiles to /var/cache/distfiles.
# This is needed for catalyst to be able to grab the newest files, before they are send to github.

source ../../.env-shared.sh || exit 1

find "${PATH_OVERLAYS_PS3_GENTOO_DISTFILES}" -type f ! -name ".*" -exec cp -f {} "${PATH_VAR_CACHE_DISTFILES}"/ \;
