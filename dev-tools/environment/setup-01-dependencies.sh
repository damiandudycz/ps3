#!/bin/bash

source ../../.env-shared.sh || exit 1
source "${PATH_EXTRA_ENV_ENVIRONMENT}" || failure "Failed to load env ${PATH_EXTRA_ENV_ENVIRONMENT}"

emerge --newuse --update --deep "${EN_PACKAGES_DEPENDENCIES[@]}"
