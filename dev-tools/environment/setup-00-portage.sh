#!/bin/bash

source ../../.env-shared.sh || exit 1

# Update the system. Synchronizes emerge only once a day. TODO: This check doesn't always work correctly, due to timezone probably.
[[ "$(stat -c %Y ${PATH_PORTAGE_TIMESTAMP_CHK})" -lt "$(date -d 'today 00:00' +%s)" ]] && emerge --sync
emerge --newuse --update --deep @world
emerge --depclean
