#!/bin/bash

source ../../.env-shared.sh || exit 1

use_set_package "sys-kernel/installkernel" "dracut" # Might be not needed, but need to verify. It's still needed during host instalation tough.
emerge --newuse --update --deep "${CONF_PROJECT_DEPENDENCIES[@]}"

