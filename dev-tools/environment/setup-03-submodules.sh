#!/bin/bash

source ../../.env-shared.sh || exit 1

rm -f "${PATH_GIT_HOOK_RELEASES}"

cd "${PATH_ROOT}"
git submodule foreach 'git config submodule.$name.depth 1'
git submodule update --init --recursive
git submodule foreach 'git checkout main'
