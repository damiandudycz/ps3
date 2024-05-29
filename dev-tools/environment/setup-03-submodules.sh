#!/bin/bash

source ../../.env-shared.sh || exit 1
trap failure ERR

cd "${PATH_ROOT}"
git submodule foreach 'git config submodule.$name.depth 1'
git submodule update --init --recursive
git submodule foreach 'git checkout main'

# Setup LFS for autobuilds
readonly PATH_HOOK_AUTOBUILDS="${PATH_ROOT}/.git/modules/autobuilds/ps3-gentoo-autobuilds/pre-commit"
[ ! -f "${PATH_HOOK_AUTOBUILDS}" ] || rm -f "${PATH_HOOK_AUTOBUILDS}"
echo '# Find all files larger than 100MB and track them with Git LFS' >> "${PATH_HOOK_AUTOBUILDS}"
echo 'find . -type f -size +100M | while read file; do' >> "${PATH_HOOK_AUTOBUILDS}"
echo '    if [[ $file != *".git"* ]]; then' >> "${PATH_HOOK_AUTOBUILDS}"
echo '        git lfs track "$file"' >> "${PATH_HOOK_AUTOBUILDS}"
echo '        git add "$file"' >> "${PATH_HOOK_AUTOBUILDS}"
echo '    fi' >> "${PATH_HOOK_AUTOBUILDS}"
echo 'done' >> "${PATH_HOOK_AUTOBUILDS}"
echo 'git add .gitattributes' >> "${PATH_HOOK_AUTOBUILDS}"
chmod +x "${PATH_HOOK_AUTOBUILDS}"
