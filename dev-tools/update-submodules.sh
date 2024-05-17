#!/bin/bash

# TODO: Validate if dev-vcs/git-lfs is installed, and if not install it

cd ..
dir="$(pwd)"

git submodule update --init --recursive
git submodule foreach 'git checkout main'

# Setup LFS
cd "${dir}"
cd .git/modules/binhosts/ps3-gentoo-binhosts
echo '# Find all files larger than 50MB and track them with Git LFS' >> hooks/pre-commit
echo 'find . -type f -size +50M | while read file; do' >> hooks/pre-commit
echo '    if [[ $file != *".git"* ]]; then' >> hooks/pre-commit
echo '        git lfs track "$file"' >> hooks/pre-commit
echo '        git add "$file"' >> hooks/pre-commit
echo '    fi' >> hooks/pre-commit
echo 'done' >> hooks/pre-commit
echo 'git add .gitattributes' >> hooks/pre-commit
chmod +x hooks/pre-commit
cd "${dir}"
cd .git/modules/autobuilds/ps3-gentoo-autobuilds
echo '# Find all files larger than 50MB and track them with Git LFS' >> hooks/pre-commit
echo 'find . -type f -size +50M | while read file; do' >> hooks/pre-commit
echo '    if [[ $file != *".git"* ]]; then' >> hooks/pre-commit
echo '        git lfs track "$file"' >> hooks/pre-commit
echo '        git add "$file"' >> hooks/pre-commit
echo '    fi' >> hooks/pre-commit
echo 'done' >> hooks/pre-commit
echo 'git add .gitattributes' >> hooks/pre-commit
chmod +x hooks/pre-commit

