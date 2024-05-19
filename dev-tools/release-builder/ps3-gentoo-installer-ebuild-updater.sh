path_start=$(dirname "$(realpath "$0")")
path_root=$(realpath -m "$path_start/../..")
path_overlay="${path_root}/overlays/ps3-gentoo-overlay"
path_installer_ebuild_repo="${path_overlay}/sys-apps/ps3-gentoo-installer"

conf_ebuild_version_current=$(find "${path_installer_ebuild_repo}" -name "*.ebuild" | grep -v "9999" | sed -r 's/.*-([0-9]+(\.[0-9]+)*)\.ebuild/\1/' | sort -V | tail -n 1)
conf_ebuild_version_new=$(echo "${conf_ebuild_version_current}" | awk -F. -v OFS=. '{ $NF=$NF+1; print }')



echo "Current: ${conf_ebuild_version_current}"
echo "New: ${conf_ebuild_version_new}"
