#!/bin/bash

# This script combines all the tools required to release a new version of:
# - IOS File,
# - Binhost packages,
# - Stage3 File,
# - Automatic installer.
#
# Use it instead of running all the tools separately when preparing a new release.

readonly PATH_START=$(dirname "$(realpath "$0")") || die

declare -a SETUP_SCRIPTS=(
    "release-00-prepare.sh"
    "../binhost/binhost-00-bind.sh --bind"
    "release-01-build.sh"
    "release-02-upload.sh"
    "../binhost/binhost-02-sanitize.sh"
    "../binhost/binhost-03-upload.sh"
    "../binhost/binhost-00-bind.sh --unbind"
    "release-03-tag.sh"
)

for SCRIPT_ENTRY in "${SETUP_SCRIPTS[@]}"; do
    SCRIPT=$(echo "$SCRIPT_ENTRY" | awk '{print $1}')
    PARAMS=$(echo "$SCRIPT_ENTRY" | awk '{for (i=2; i<=NF; i++) printf $i" "; print ""}')

    DIR=$(dirname "${SCRIPT}")
    SCRIPT_NAME=$(basename "${SCRIPT}")

    (cd "${DIR}" && "./${SCRIPT_NAME}" ${PARAMS}) || { echo "Script ${SCRIPT} failed. Exiting."; exit 1; }
    cd "${PATH_START}"
done

echo "New version was successfully released!"

exit 0
