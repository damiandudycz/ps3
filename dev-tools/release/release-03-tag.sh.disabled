#!/bin/bash

# This script adds a new tag to the repository, marking new release timestamp.
# Please use after finishing release-upload.sh.

source ../../.env-shared.sh || exit 1

# Paths
readonly PATH_LOCAL_TMP="/var/tmp/ps3/release"
readonly PATH_RELEASE_INFO="${PATH_LOCAL_TMP}/release_latest"

# Release information
readonly TIMESTAMP=$(cat "${PATH_RELEASE_INFO}") || die "Failed to read current release details. Please run release-prepare.sh first."
[ ! -z "${TIMESTAMP}" ] || die "Failed to read current release details. Please run release-prepare.sh first."

TAG="$1"
# If tag was not specified, get the latest tag from catalyst build
[ ! -z "$TAG" ] || TAG="${TIMESTAMP}"

# Create new tag and upload all the files to repository

upload_repository "${PATH_ROOT}" "New release"

# TODO: Make shared function for tags, like upload_repository -> tag_repository
cd "${PATH_ROOT}" || die "Failed to switch directory to PATH_ROOT"
git tag -a "${TAG}" -m "Release ${TAG}"
git push origin "${TAG}"
cd "${PATH_START}" || die "Failed to return to PATH_START"

exit 0
