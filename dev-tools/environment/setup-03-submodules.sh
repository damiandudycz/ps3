#!/bin/bash

source ../../.env-shared.sh || exit 1
source "${PATH_EXTRA_ENV_ENVIRONMENT}" || failure "Failed to load env ${PATH_EXTRA_ENV_ENVIRONMENT}"

rm -f "${EN_PATH_HOOK_AUTOBUILDS}"

cd "${PATH_ROOT}"
git submodule foreach 'git config submodule.$name.depth 1'
git submodule update --init --recursive
git submodule foreach 'git checkout main'

# Setup LFS for autobuilds
echo '# Find all files larger than 100MB and track them with Git LFS' >> "${EN_PATH_HOOK_AUTOBUILDS}"
echo 'find . -type f -size +100M | while read file; do' >> "${EN_PATH_HOOK_AUTOBUILDS}"
echo '    if [[ $file != *".git"* ]]; then' >> "${EN_PATH_HOOK_AUTOBUILDS}"
echo '        git lfs track "$file"' >> "${EN_PATH_HOOK_AUTOBUILDS}"
echo '        git add "$file"' >> "${EN_PATH_HOOK_AUTOBUILDS}"
echo '    fi' >> "${EN_PATH_HOOK_AUTOBUILDS}"
echo 'done' >> "${EN_PATH_HOOK_AUTOBUILDS}"
echo 'git add .gitattributes' >> "${EN_PATH_HOOK_AUTOBUILDS}"
chmod +x "${EN_PATH_HOOK_AUTOBUILDS}"
