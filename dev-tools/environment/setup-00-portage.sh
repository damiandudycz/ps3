#!/bin/bash

source ../../.env-shared.sh || exit 1
source "${PATH_EXTRA_ENV_ENVIRONMENT}" || failure "Failed to load env ${PATH_EXTRA_ENV_ENVIRONMENT}"

# Append getbinpkg to features if needed.
add_line_if_not_exists "FEATURES=\"\${FEATURES} ${CONF_PORTAGE_FEATURES}\"" "${PATH_ETC_PORTAGE_MAKE_CONF}"

# Update the system. Synchronizes emerge only once a day. TODO: This check doesn't always work correctly, due to timezone probably.
[[ "$(stat -c %Y /var/db/repos/gentoo/metadata/timestamp.chk)" -lt "$(date -d 'today 00:00' +%s)" ]] && emerge --sync
emerge --newuse --update --deep @world
emerge --depclean
