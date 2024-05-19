# This tool generates new ebuild and distfiles with current version of the installer in this repository
# Update is performed only if there are any changes in installer or config since last version released.
# This tool is automatically executed in release-builder tool.

PN="ps3-gentoo-installer"
PL="sys-apps/${PN}"

path_start=$(dirname "$(realpath "$0")")
path_root=$(realpath -m "$path_start/../..")
path_tmp="${path_root}/local/ps3-gentoo-installer-ebuild-updater"

path_overlay_ebuilds="${path_root}/overlays/ps3-gentoo-overlay"
path_overlay_distfiles="${path_root}/overlays/ps3-gentoo-overlay.distfiles"
path_overlay_ebuilds_package_location="${path_overlay_ebuilds}/${PL}"

path_installer_ebuild_ebuild="${path_start}/${PN}.ebuild"
path_installer_ebuild_installer="${path_start}/ps3-gentoo-installer"
path_installer_ebuild_config="${path_start}/config/PS3"

conf_ebuild_version_current=$(find "${path_overlay_ebuilds_package_location}" -name "*.ebuild" | grep -v "9999" | sed -r 's/.*-([0-9]+(\.[0-9]+)*)\.ebuild/\1/' | sort -V | tail -n 1)
conf_ebuild_version_new=$(echo "${conf_ebuild_version_current}" | awk -F. -v OFS=. '{ $NF=$NF+1; print }')

path_distfiles_tar_tmp="${path_tmp}/${PN}-${conf_ebuild_version_new}.tar.xz"
path_distfiles_tar_old="${path_overlay_distfiles}/${PL}/${PN}-${conf_ebuild_version_current}.tar.xz"
path_distfiles_tar_new="${path_overlay_distfiles}/${PL}/${PN}-${conf_ebuild_version_new}.tar.xz"

path_overlay_ebuild_new="${path_overlay_ebuilds_package_location}/${PN}-${conf_ebuild_version_new}.ebuild"

list_distfiles_tar_files=(
	ps3-gentoo-installer
	config
)

echo ""
echo "# Automatic updater for ps3-gentoo-installer"

mkdir -p "${path_tmp}"

# Copy distfiles to tmp
cp "${path_installer_ebuild_ebuild}" "${path_tmp}/${PN}-${conf_ebuild_version_new}.ebuild"
cp "${path_installer_ebuild_installer}" "${path_tmp}/${PN}"
cp "${path_installer_ebuild_config}" "${path_tmp}/config"

# Create tmp distfiles tar
tar --sort=name \
            --mtime="" \
            --owner=0 --group=0 --numeric-owner \
            --pax-option=exthdr.name=%d/PaxHeaders/%f,delete=atime,delete=ctime \
            -caf "${path_distfiles_tar_tmp}" \
            -C "${path_tmp}" "${list_distfiles_tar_files[@]}"

needs_update=$(diff -q "$path_distfiles_tar_tmp" "$path_distfiles_tar_old" >/dev/null && echo "false" || echo "true")
if [ ! "${needs_update}" = true ]; then
	echo "No changes in installer, skiping update"
	echo ""
	exit 0
fi

echo "Installer was updated, uploading new version: ${conf_ebuild_version_new}"

# Upload new distfiles
cp "${path_distfiles_tar_tmp}" "${path_distfiles_tar_new}"
cd "${path_overlay_distfiles}"
if [[ $(git status --porcelain) ]]; then
    git add -A
    git commit -m "Installer automatic update (Catalyst release)"
    git push
fi

# Upload new ebuild
cp "${path_tmp}/${PN}-${conf_ebuild_version_new}.ebuild" "${path_overlay_ebuild_new}"
cd "${path_overlay_ebuilds_package_location}"
pkgdev manifest
cd "${path_overlay_ebuilds}"
if [[ $(git status --porcelain) ]]; then
    git add -A
    git commit -m "Installer automatic update (Catalyst release)"
    git push
fi

echo ""
