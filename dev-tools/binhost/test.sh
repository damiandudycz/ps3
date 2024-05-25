#!/bin/bash

# This script deletes a specified package version from the binhost repository.
# Usage example: ./binhost-delete-package.sh sys-apps/ps3-gentoo-installer 1.0.1.
# If the version is not specified, it deletes all versions of the specified package.

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
[[ -z "$1" ]] && die "Usage: $0 <package> [version]"

# Function to delete a specific package version
delete_package_version() {
    local PACKAGE="$1"
    local VERSION="$2"
    local TEMP_DELETE_FILE=$(mktemp) || die "Failed to create temporary file."
    local ENTRY=""
    local PACKAGES_COUNT=$(grep -oP '^PACKAGES: \K[0-9]+' "$PATH_METADATA")
    local PACKAGE_FOUND=false
    local METADATA_REMOVED=false

    # Ensure the temporary file is removed on script exit
    trap 'rm -f "$TEMP_DELETE_FILE"' EXIT

    while IFS= read -r LINE || [[ -n $LINE ]]; do
        if [[ -n "$LINE" ]]; then
            ENTRY+="$LINE"$'\n'
        else
            if [[ "$ENTRY" == *"$PACKAGE"* ]]; then
                if [[ -z "$VERSION" || "$ENTRY" == *"$PACKAGE-$VERSION"* ]]; then
                    PATH_PACKAGE=$(echo "$ENTRY" | grep -Po 'PATH: \K.*')
                    if [[ -n "$PATH_PACKAGE" && -f "$PATH_REPO_BINHOST/$PATH_PACKAGE" ]]; then
                        rm -f "$PATH_REPO_BINHOST/$PATH_PACKAGE" || die "Failed to remove file: $PATH_REPO_BINHOST/$PATH_PACKAGE"
                        echo "Removed file: $PATH_REPO_BINHOST/$PATH_PACKAGE"
                        PACKAGE_FOUND=true
                        METADATA_REMOVED=true
                    fi
                    (( PACKAGES_COUNT-- ))
                else
                    echo -e "$ENTRY" >> "$TEMP_DELETE_FILE" || die "Failed to write to temporary file."
                fi
            else
                echo -e "$ENTRY" >> "$TEMP_DELETE_FILE" || die "Failed to write to temporary file."
            fi
            ENTRY=""
        fi
    done < "$PATH_METADATA"

    # In case the last entry did not end with a newline
    if [[ -n "$ENTRY" && "$ENTRY" == *"$PACKAGE"* ]]; then
        if [[ -z "$VERSION" || "$ENTRY" == *"$PACKAGE-$VERSION"* ]]; then
            PATH_PACKAGE=$(echo "$ENTRY" | grep -Po 'PATH: \K.*')
            if [[ -n "$PATH_PACKAGE" && -f "$PATH_REPO_BINHOST/$PATH_PACKAGE" ]]; then
                rm -f "$PATH_REPO_BINHOST/$PATH_PACKAGE" || die "Failed to remove file: $PATH_REPO_BINHOST/$PATH_PACKAGE"
                echo "Removed file: $PATH_REPO_BINHOST/$PATH_PACKAGE"
                PACKAGE_FOUND=true
                METADATA_REMOVED=true
            fi
            (( PACKAGES_COUNT-- ))
        else
            echo -e "$ENTRY" >> "$TEMP_DELETE_FILE" || die "Failed to write to temporary file."
        fi
    fi

    if $METADATA_REMOVED; then
        mv "$TEMP_DELETE_FILE" "$PATH_METADATA" || die "Failed to move temporary file."
        sed -i "s/^PACKAGES: .*/PACKAGES: $PACKAGES_COUNT/" "$PATH_METADATA" || die "Failed to update package count."
        echo "Package $PACKAGE version $VERSION removed from repository."
    else
        rm -f "$TEMP_DELETE_FILE" || die "Failed to remove temporary file."
        if [[ -z "$VERSION" ]]; then
            echo "No versions of package $PACKAGE found in repository."
        else
            echo "Package $PACKAGE version $VERSION not found in repository."
        fi
    fi
}

# Delete all versions of the package if version is not specified
if [[ -z "$2" ]]; then
    while IFS= read -r -d '' file; do
        version=$(basename "$file" | grep -Po '(?<=-)[^-]+(?=-1\.gpkg\.tar)')
        delete_package_version "$1" "$version"
    done < <(find "$PATH_REPO_BINHOST/$1" -type f -print0)
else
    delete_package_version "$1" "$2"
fi

exit 0
