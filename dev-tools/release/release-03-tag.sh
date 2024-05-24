#!/bin/bash

# This script adds a new tag to the repository, marking new release timestamp.
# Please use after finishing release-upload.sh.

# Error handling function
die() {
    echo "$*" 1>&2
    exit 1
}

# Paths
readonly PATH_START=$(dirname "$(realpath "$0")") || die
readonly PATH_ROOT=$(realpath -m "${PATH_START}/../..") || die
readonly PATH_ENV_READY="${PATH_ROOT}/local/env_ready"
readonly PATH_LOCAL_TMP="${PATH_ROOT}/local/release"
readonly PATH_RELEASE_INFO="${PATH_LOCAL_TMP}/release_latest"

# Check if env is ready
[ -f "${PATH_ENV_READY}" ] || die "Dev environment was not initialized. Please run dev-tools/setup-environment.sh first."

# Release information
readonly TIMESTAMP=$(cat "${PATH_RELEASE_INFO}") || die "Failed to read current release details. Please run release-prepare.sh first."
[ -z "${TIMESTAMP}" ] && die "Failed to read current release details. Please run release-prepare.sh first."

TAG="$1"
# If tag was not specified, get the latest tag from catalyst build
[ -z "$TAG" ] && TAG="${TIMESTAMP}"

# Create new tag and upload all the files to repository
cd "${PATH_ROOT}" || die "Failed to switch directory to PATH_ROOT"
git add -A || die "Failed to add files to repo"
git commit -m "New release" || die "Failed to commit files to repo"
git push || die "Failed to push files to repo"
git tag -a "${TAG}" -m "Release ${TAG}"
git push origin "${TAG}"
cd "${PATH_START}" || die "Failed to return to PATH_START"

exit 0
