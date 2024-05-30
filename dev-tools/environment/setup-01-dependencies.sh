#!/bin/bash

source ../../.env-shared.sh || exit 1
source "${PATH_EXTRA_ENV_ENVIRONMENT}" || failure "Failed to load env ${PATH_EXTRA_ENV_ENVIRONMENT}"

use_set_package "sys-kernel/installkernel" "dracut" # Might be not needed, but need to verify. It's still needed during host instalation tough.
emerge --newuse --update --deep "${EN_PACKAGES_DEPENDENCIES[@]}"
