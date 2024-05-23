#!/bin/bash

# This script prepares current machine for working with development tools for the PS3 Gentoo project.
# Please run this script after cloning the repository.

declare -a SETUP_SCRIPTS=(
    setup-portage.sh
    setup-dependencies.sh
    setup-git.sh
    setup-submodules.sh
    setup-catalyst.sh
    setup-qemu.sh
    setup-releng.sh
    setup-crossdev.sh
)

if [ -f ../local/env_ready ]; then
    echo "Environment setup was already done. To force, delete file ../local/env_ready"
    exit 0
fi

# Run setup scripts
for SCRIPT in "${SETUP_SCRIPTS[@]}"; do
    DIR=$(dirname "environment/${SCRIPT}")
    (cd "${DIR}" && "./${SCRIPT}") || { echo "Script ${SCRIPT} failed. Exiting."; exit 1; }
done

mkdir -p ../local
touch ../local/env_ready

exit 0
