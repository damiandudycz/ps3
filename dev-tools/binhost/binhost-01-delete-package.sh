#!/bin/bash

# This script deletes a specified package from the binhost repository.
# Usage example: ./binhost-delete-package.sh sys-kernel/gentoo-kernel-ps3.

# Function to display error message and exit
die() {
    echo "$1" >&2
    exit 1
}

# Paths
readonly PATH_START=$(dirname "$(realpath "$0")") || die "Failed to determine script directory."
readonly PATH_ROOT=$(realpath -m "${PATH_START}/../..") || die "Failed to determine root directory."
readonly PATH_REPO_BINHOST="${PATH_ROOT}/binhosts/ps3-gentoo-binhosts/default"
readonly PATH_METADATA="${PATH_REPO_BINHOST}/Packages"
readonly PATH_TMP_FILE=$(mktemp) || die "Failed to create temporary file."

# Ensure the temporary file is removed on script exit
trap 'rm -f "$PATH_TMP_FILE"' EXIT

# Check if package parameter is provided
[[ -z "$1" ]] && die "Usage: $0 <package>"

# Check if package directory exists in the repository
[[ -d "${PATH_REPO_BINHOST}/$1" ]] || die "Package directory does not exist in the repository."

# Function to delete a specific package
delete_package() {
    local PACKAGE="$1"
    local TEMP_DELETE_FILE=$(mktemp) || die "Failed to create temporary file."
    local ENTRY=""
    local PACKAGES_COUNT=$(grep -oP '^PACKAGES: \K[0-9]+' "$PATH_METADATA")
    local PACKAGE_FOUND=false

    # Ensure the temporary file is removed on script exit
    trap 'rm -f "$TEMP_DELETE_FILE"' EXIT

    while IFS= read -r LINE || [[ -n $LINE ]]; do
        if [[ -n "$LINE" ]]; then
            ENTRY+="$LINE"$'\n'
        else
            if [[ "$ENTRY" == *"$PACKAGE"* ]]; then
                PATH_PACKAGE=$(echo "$ENTRY" | grep -Po 'PATH: \K.*')
                if [[ -n "$PATH_PACKAGE" && -f "$PATH_REPO_BINHOST/$PATH_PACKAGE" ]]; then
                    rm -f "$PATH_REPO_BINHOST/$PATH_PACKAGE" || die "Failed to remove file: $PATH_REPO_BINHOST/$PATH_PACKAGE"
                    echo "Removed file: $PATH_REPO_BINHOST/$PATH_PACKAGE"
                fi
                (( PACKAGES_COUNT-- ))
                PACKAGE_FOUND=true
            else
                echo -e "$ENTRY" >> "$TEMP_DELETE_FILE" || die "Failed to write to temporary file."
            fi
            ENTRY=""
        fi
    done < "$PATH_METADATA"

    if [[ "$ENTRY" == *"$PACKAGE"* ]]; then
        PATH_PACKAGE=$(echo "$ENTRY" | grep -Po 'PATH: \K.*')
        if [[ -n "$PATH_PACKAGE" && -f "$PATH_REPO_BINHOST/$PATH_PACKAGE" ]]; then
            rm -f "$PATH_REPO_BINHOST/$PATH_PACKAGE" || die "Failed to remove file: $PATH_REPO_BINHOST/$PATH_PACKAGE"
            echo "Removed file: $PATH_REPO_BINHOST/$PATH_PACKAGE"
        fi
        (( PACKAGES_COUNT-- ))
        PACKAGE_FOUND=true
    else
        echo -e "$ENTRY" >> "$TEMP_DELETE_FILE" || die "Failed to write to temporary file."
    fi

    if $PACKAGE_FOUND; then
        mv "$TEMP_DELETE_FILE" "$PATH_METADATA" || die "Failed to move temporary file."
        sed -i "s/^PACKAGES: .*/PACKAGES: $PACKAGES_COUNT/" "$PATH_METADATA" || die "Failed to update package count."
        echo "Package $PACKAGE removed from repository."
    else
        rm -f "$TEMP_DELETE_FILE" || die "Failed to remove temporary file."
        echo "Package $PACKAGE not found in repository."
    fi
}

delete_package "$1"
exit 0
