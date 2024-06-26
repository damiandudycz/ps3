#!/bin/bash

source ../../.env-shared.sh || exit 1

empty_directory "${PATH_RELENG}"

# Download and setup releng
git clone -o upstream https://github.com/gentoo/releng.git "${PATH_RELENG}"
