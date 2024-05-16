#!/bin/bash

source ../../.env-shared.sh || exit 1

# Update the system. Synchronizes emerge only once a day. TODO: This check doesn't always work correctly, due to timezone probably.
[[ "$(stat -c %Y ${PATH_PORTAGE_TIMESTAMP_CHK})" -lt "$(date -d 'today 00:00' +%s)" ]] && emerge --sync
#update_config_assign "PYTHON_TARGETS" "python3_11 python3_12" "${PATH_ETC_PORTAGE_MAKE_CONF}" # TODO: This is needed because without it catalyst fails building stages. Remove when catalyst is updated to python 3.12.
emerge --newuse --update --deep @world
emerge --depclean
