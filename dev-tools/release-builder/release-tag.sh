#!/bin/bash

# Error handling function
die() {
    echo "$*" 1>&2
    exit 1
}

# Handle script arguments
TAG="$1"
[ ! -z "$TAG" ] || die "Usage: $0 <TAG>"

# Paths
readonly PATH_START=$(dirname "$(realpath "$0")") || die
readonly PATH_ROOT=$(realpath -m "${PATH_START}/../..") || die

# Create new tag and upload all the files to repository

cd "${PATH_ROOT}" || die "Failed to switch directory to PATH_ROOT"
git add -A || die "Failed to add files to repo"
git commit -m "New release" || die "Failed to commit files to repo"
git push || die "Failed to push files to repo"
git tag -a "${TAG}" -m "Release ${TAG}"
git push origin "${TAG}"
cd "${PATH_START}" || die "Failed to return to PATH_START"

exit 0


