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
for dir in "${PATH_RELEASES_PS3_GENTOO_ARCH_BINPACKAGES_PROFILE}"/{.[!.]*,*}; do
    echo "[Sanitize: \$dir]"
    cd "$(dirname "${PATH_BINHOST_SCRIPT_SANITIZE}")"
    ${PATH_BINHOST_SCRIPT_SANITIZE} -p \${dir}
    cd \${dir}
    git add -u
    echo ""
done
