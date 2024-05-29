#!/bin/bash

source ../../.env-shared.sh || exit 1
trap failure ERR

# Append getbinpkg to features if needed.
readonly CONF_FEATURES="getbinpkg"
if ! grep -q "^FEATURES=\"[^\"]* ${CONF_FEATURES}" "${PATH_ETC_PORTAGE_MAKE_CONF}"; then
    if grep -q "^FEATURES=" "${PATH_ETC_PORTAGE_MAKE_CONF}"; then
        sed -i "/^FEATURES=/ s/\"\(.*\)\"/\"\1 ${CONF_FEATURES}\"/" "${PATH_ETC_PORTAGE_MAKE_CONF}"
    else
        echo "FEATURES=\"${CONF_FEATURES}\"" | tee -a "${PATH_ETC_PORTAGE_MAKE_CONF}"
    fi
fi

# Update the system. Synchronizes emerge only once a day.
[[ "$(stat -c %Y /var/db/repos/gentoo/metadata/timestamp.chk)" -lt "$(date -d 'today 00:00' +%s)" ]] && emerge --sync
emerge --newuse --update --deep @world
