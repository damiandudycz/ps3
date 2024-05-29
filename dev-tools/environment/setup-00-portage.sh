#!/bin/bash

source ../../.env-shared.sh || exit 1
source "${PATH_EXTRA_ENV_ENVIRONMENT}" || failure "Failed to load env ${PATH_EXTRA_ENV_ENVIRONMENT}"

# Append getbinpkg to features if needed.
if ! grep -q "^FEATURES=\"[^\"]* ${EN_MAKE_FEATURES}" "${PATH_ETC_PORTAGE_MAKE_CONF}"; then
    if grep -q "^FEATURES=" "${PATH_ETC_PORTAGE_MAKE_CONF}"; then
        sed -i "/^FEATURES=/ s/\"\(.*\)\"/\"\1 ${EN_MAKE_FEATURES}\"/" "${PATH_ETC_PORTAGE_MAKE_CONF}"
    else
        echo "FEATURES=\"${EN_MAKE_FEATURES}\"" | tee -a "${PATH_ETC_PORTAGE_MAKE_CONF}"
    fi
fi

# Update the system. Synchronizes emerge only once a day.
[[ "$(stat -c %Y /var/db/repos/gentoo/metadata/timestamp.chk)" -lt "$(date -d 'today 00:00' +%s)" ]] && emerge --sync
emerge --newuse --update --deep @world
