#!/bin/bash

# Error handling function
die() {
    echo "$*" 1>&2
    exit 1
}

# Paths
readonly PATH_START=$(dirname "$(realpath "$0")") || die
readonly PATH_ROOT=$(realpath -m "${PATH_START}/../..") || die
readonly PATH_REPO_BINHOST="${PATH_ROOT}/binhosts/ps3-gentoo-binhosts/default"
readonly PATH_SANITIZE="${PATH_START}/binhost-sanitize.sh"

# Sanitize binhost - remove files larger than 100MB
$PATH_SANITIZE $PATH_REPO_BINHOST || die "Failed to sanitize binhost repository $PATH_REPO_BINHOST"

# Upload repository
cd "${PATH_REPO_BINHOST}" || die "Failed to open PATH_REPO_BINHOST"
git add -A || die "Failed to add files to repo"
git commit -m "Binhost automatic update (Catalyst release)" || die "Failed to commit files to repo"
git push || die "Failed to push files to repo"
cd "${PATH_START}" || die "Failed to return to starting location"

exit 0
