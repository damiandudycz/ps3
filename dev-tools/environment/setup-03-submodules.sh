#!/bin/bash

source ../../.env-shared.sh || exit 1

rm -f "${PATH_GIT_HOOK_RELEASES}"

# Update links to github for guest or user
github_link="${CONF_GIT_GITHUB_LINK_GUEST}"
if [[ ${CONF_OWNER} = true ]]; then
	github_link="${CONF_GIT_GITHUB_LINK_OWNER}"
fi
sed -i "s|@GITHUB_LINK@|${github_link}|g" "${PATH_GIT_MODULES}"

cd "${PATH_ROOT}"
git submodule foreach 'git config submodule.$name.depth 1'
git submodule update --init --recursive
git submodule foreach 'git checkout main'

# Setup LFS for autobuilds.
cat <<EOF > "${PATH_GIT_HOOK_RELEASES}"
# Remove binhost packages that are too large.
for dir in "${PATH_RELEASES_PS3_GENTOO_ARCH_BINPACKAGES_PROFILE}"/*; do
    echo "[Sanitize: \$dir]"
    cd "$(dirname "${PATH_BINHOST_SCRIPT_SANITIZE}")"
    ${PATH_BINHOST_SCRIPT_SANITIZE} -p \${dir}
    cd \${dir}
    git add -u
    echo ""
done
EOF
chmod +x "${PATH_GIT_HOOK_RELEASES}"

echo "[Initialize GIT LFS for releases]"
cd "${PATH_ROOT}/releases"
git lfs install

# Create link to catalyst-binpkgs if possible
mkdir -p /var/cache/catalyst-binpkgs
if [[ ! -e /var/cache/catalyst-binpkgs/ps3 ]]; then
	ln -s ${PATH_RELEASES_PS3_GENTOO_ARCH_BINPACKAGES_PROFILE} /var/cache/catalyst-binpkgs/ps3
fi
