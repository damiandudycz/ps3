#!/bin/bash

# This tool uploads current state of binhost repository to github.
# Before running, please use binhost-sanitize.sh, to remove packages
# that are too large for github.

# Error handling function
die() {
    echo "$*" 1>&2
    exit 1
}

# Paths
readonly PATH_START=$(dirname "$(realpath "$0")") || die
readonly PATH_ROOT=$(realpath -m "${PATH_START}/../..") || die
readonly PATH_REPO_BINHOST="${PATH_ROOT}/binhosts/ps3-gentoo-binhosts/default"

# Upload repository
cd "${PATH_REPO_BINHOST}" || die "Failed to open PATH_REPO_BINHOST"
git add -A || die "Failed to add files to repo"
git commit -m "Binhost automatic update (Catalyst release)" || die "Failed to commit files to repo"
git push || die "Failed to push files to repo"
cd "${PATH_START}" || die "Failed to return to starting location"

exit 0
