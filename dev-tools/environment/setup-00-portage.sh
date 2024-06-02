#!/bin/bash

source ../../.env-shared.sh || exit 1

# Append getbinpkg to features if needed.
add_line_if_not_exists "FEATURES=\"\${FEATURES} ${CONF_PORTAGE_FEATURES}\"" "${PATH_ETC_PORTAGE_MAKE_CONF}"

# Update the system. Synchronizes emerge only once a day. TODO: This check doesn't always work correctly, due to timezone probably.
[[ "$(stat -c %Y ${PATH_PORTAGE_TIMESTAMP_CHK})" -lt "$(date -d 'today 00:00' +%s)" ]] && emerge --sync
update_config_assign "PYTHON_TARGETS" "python3_11 python3_12" "${PATH_ETC_PORTAGE_MAKE_CONF}" # TODO: This is needed because without it some packages fails, remove when not needed
emerge --newuse --update --deep @world || echo_color ${COLOR_RED} "System update failed. Please fix manually"
emerge --depclean
