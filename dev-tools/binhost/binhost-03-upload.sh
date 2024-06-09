#!/bin/bash

# This tool uploads current state of binhost repository to github.
# Before running, please use binhost-sanitize.sh, to remove packages
# that are too large for github.

source ../../.env-shared.sh || exit 1

# TODO:
upload_repository "${PATH_BINHOSTS_PS3_GENTOO_DEFAULT}" "Binhost automatic update"
