#!/bin/bash

# Function to display error message and exit
die() {
    echo "$1" >&2
    exit 1
}

# Paths
readonly PATH_START=$(dirname "$(realpath "$0")") || die "Failed to determine script directory."
readonly PATH_ROOT=$(realpath -m "${PATH_START}/../..") || die "Failed to determine root directory."
readonly PATH_REPO_BINHOST="${PATH_ROOT}/binhosts/ps3-gentoo-binhosts/default"
readonly SIZE_LIMIT=104857600 # 100 MB
readonly PATH_DELETE_SCRIPT="${PATH_START}/delete_package.sh"

# Function to delete a package
delete_package() {
    local package="$1"
    echo "Removing package: $package"
    "$PATH_DELETE_SCRIPT" "$package" || die "Failed to remove package: $package"
}

# Ensure the temporary file is removed on script exit
trap 'rm -f "$TMP_FILE"' EXIT

# Check if the repository directory exists
[[ -d "$PATH_REPO_BINHOST" ]] || die "Repository directory not found: $PATH_REPO_BINHOST"

# Iterate through files in the repository directory
while IFS= read -r -d '' file; do
    # Check if file size exceeds the limit
    if [[ -f "$file" && $(stat -c %s "$file") -gt $SIZE_LIMIT ]]; then
        # Remove the package containing the file
        delete_package "$(dirname "$file")"
    fi
done < <(find "$PATH_REPO_BINHOST" -type f -print0)

echo "Sanitization complete."
exit 0
