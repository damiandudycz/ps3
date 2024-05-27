#!/bin/bash

# This script emerges git-lfs and adds hooks,
# that makes files larger than 100MB upload using LFS functionality.

# --- Shared environment --- # Imports shared environment configuration,
source ../../.env-shared.sh  # patches and functions.
trap failure ERR             # Sets a failure trap on any error.
# -------------------------- #

cd "${PATH_ROOT}"
#git submodule update --init --recursive
#git submodule foreach 'git checkout main'

# Setup LFS for autobuilds
cd "${PATH_ROOT}/.git/modules/autobuilds/ps3-gentoo-autobuilds"
echo '# Find all files larger than 100MB and track them with Git LFS' >> hooks/pre-commit
echo 'find . -type f -size +100M | while read file; do' >> hooks/pre-commit
echo '    if [[ $file != *".git"* ]]; then' >> hooks/pre-commit
echo '        git lfs track "$file"' >> hooks/pre-commit
echo '        git add "$file"' >> hooks/pre-commit
echo '    fi' >> hooks/pre-commit
echo 'done' >> hooks/pre-commit
echo 'git add .gitattributes' >> hooks/pre-commit
chmod +x hooks/pre-commit

exit 0
