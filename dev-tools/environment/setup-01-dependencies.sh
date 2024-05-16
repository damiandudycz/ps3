#!/bin/bash

source ../../.env-shared.sh || exit 1

emerge --newuse --update --deep "${CONF_PROJECT_DEPENDENCIES[@]}"

