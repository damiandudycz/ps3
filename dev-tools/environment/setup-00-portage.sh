#!/bin/bash

# This script configures portage, enabling binpkg packages usage.

# --- Shared environment --- # Imports shared environment configuration,
source ../../.env-shared.sh  # patches and functions.
trap failure ERR             # Sets a failure trap on any error.
# -------------------------- #

# Append getbinpkg to features if needed.
if ! grep -q "^FEATURES=\"[^\"]* getbinpkg" "${PATH_ETC_PORTAGE_MAKE_CONF}"; then
    if grep -q "^FEATURES=" "${PATH_ETC_PORTAGE_MAKE_CONF}"; then
        sed -i "/^FEATURES=/ s/\"\(.*\)\"/\"\1 getbinpkg\"/" "${PATH_ETC_PORTAGE_MAKE_CONF}"
    else
        echo "FEATURES=\"getbinpkg\"" | tee -a "${PATH_ETC_PORTAGE_MAKE_CONF}" >/dev/null
    fi
fi

# Update the system.
#emerge --sync
#emerge --newuse --update --deep @world

exit 0
