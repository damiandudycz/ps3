#!/bin/bash

source ../../.env-shared.sh || exit 1

rm -f "${PATH_GIT_HOOK_RELEASES}"

cd "${PATH_ROOT}"
git submodule foreach 'git config submodule.$name.depth 1'
git submodule update --init --recursive
git submodule foreach 'git checkout main'

# Setup LFS for autobuilds.
cat <<EOF > "${PATH_GIT_HOOK_RELEASES}"
# Remove binhost packages that are too large.
cd "$(dirname "${PATH_BINHOST_SCRIPT_SANITIZE}")"
${PATH_BINHOST_SCRIPT_SANITIZE}
git add -u
# Find all files larger than ${CONF_GIT_FILE_SIZE_LIMIT} and track them with Git LFS
cd "${PATH_RELEASES}"
find . -type f -size +${CONF_GIT_FILE_SIZE_LIMIT} | while read file; do
    if [[ \$file != *".git"* ]]; then
        git lfs track "\$file"
        git add "\$file"
    fi
done
git add .gitattributes
EOF
chmod +x "${PATH_GIT_HOOK_RELEASES}"
