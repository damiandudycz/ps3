#!/bin/bash

source ../../.env-shared.sh || exit 1
source "${PATH_EXTRA_ENV_PS3_INSTALLER}" || failure "Failed to load env ${PATH_EXTRA_ENV_PS3_INSTALLER}"

# Handle script arguments
unset ASK

for arg in "$@"; do case $arg in
    --ask) ASK=true; shift;;
esac; done

# Check if update is needed.
if [[ -n $(ps3_installer_needs_update) ]]; then
    if [[ $ASK ]]; then
        while true; do
            read -p "Do you want to update ps3-gentoo-installer ebuild to version ${PI_VAL_OVERLAY_EBUILD_NEW_VERSION} [yes/no]: " yn
            case $yn in
                [Yy]*) break ;;
                [Nn]*) exit 0 ;;
            esac
        done
    fi
else
    echo "No changes to installer since last release."
    exit 0
fi

# Create package
PI_COMMAND="--category ${PI_CONF_PACKAGE_GROUP} --ebuild ${PI_PATH_EBUILD_SRC} --version-increment --distfile ${PI_PATH_CONFIG_SRC} --distfile ${PI_PATH_INSTALLER_SRC} --save"
source ${PATH_OVERLAY_SCRIPT_CREATE_PACKAGE} ${PI_COMMAND}
