#!/bin/bash

source ../../.env-shared.sh || exit 1
trap failure ERR

readonly PACKAGES_DEPENDENCIES=(gentoolkit ruby pkgdev crossdev)
emerge --newuse --update --deep "${PACKAGES_DEPENDENCIES[@]}"
