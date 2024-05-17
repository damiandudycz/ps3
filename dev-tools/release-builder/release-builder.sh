branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo main)" # Name of current branch if running from git repository
latest_tag=$(git tag -l | grep -E "^[0-9]+\.[0-9]+\.[0-9]+$" | sort -V | tail -n 1)
new_tag=$(echo "$latest_tag" | awk -F. '{ printf "%d.%d.%d\n", $1, $2+1, $3 }')

timestamp=$(date -u +"%Y%m%dT%H%M%SZ")
path_start=$(dirname "$(realpath "$0")")
path_root=$(realpath -m "$path_start/../..")
path_local_tmp="$path_root/local/release"
path_releng="$path_local_tmp/releng"
path_portage_confdir_stages="$path_releng/releases/portage/stages"
path_portage_confdir_isos="$path_releng/releases/portage/isos"
path_catalyst_usr="/usr/share/catalyst"
path_catalyst_tmp="/var/tmp/catalyst"
path_catalyst_configs="/etc/catalyst"
path_catalyst_builds="$path_catalyst_tmp/builds/default"
path_catalyst_stages="$path_catalyst_tmp/config/stages"
path_catalyst_patch_dir="/etc/portage/patches/dev-util/catalyst"
path_catalyst_binhost="/var/tmp/catalyst/packages/default"
path_repo_binhost="$path_root/binhosts/ps3-gentoo-binhosts/default"
path_repo_autobuilds="$path_root/autobuilds/ps3-gentoo-autobuilds"
path_autobuild_new="${path_repo_autobuilds}/${timestamp}"
path_stage3_seed="$path_catalyst_builds/stage3-ppc64-openrc-$timestamp.tar.xz"
path_overlay="$path_root/overlays/ps3-gentoo-overlay"
path_stage1="$path_local_tmp/stage1-cell.$timestamp.spec"
path_stage3="$path_local_tmp/stage3-cell.$timestamp.spec"
path_stage1_installcd="$path_local_tmp/stage1-cell.installcd.$timestamp.spec"
path_stage2_installcd="$path_local_tmp/stage2-cell.installcd.$timestamp.spec"
path_livecd_overlay_original="$path_start/iso_overlay"
path_livecd_overlay="$path_local_tmp/iso_overlay"
path_livecd_fsscript_original="$path_start/iso_fsscript.sh"
path_livecd_fsscript="$path_local_tmp/iso_fsscript.sh"
path_interpreter="/usr/bin/qemu-ppc64"
path_installer_ebuild_draft="${path_start}/ps3-gentoo-installer.ebuild"
path_installer_ebuild_repo="${path_overlay}/sys-apps/ps3-gentoo-installer"
url_release_gentoo="https://gentoo.osuosl.org/releases/ppc/autobuilds/current-stage3-ppc64-openrc"
url_binhost="https://raw.githubusercontent.com/damiandudycz/ps3-gentoo-binhosts/main"
url_overlay="https://github.com/damiandudycz/ps3-gentoo-overlay"
url_catalyst_patch1="https://github.com/damiandudycz/ps3/raw/${branch}/dev-tools/release-builder/patches/0001-Introduce-basearch-settings.patch"
url_catalyst_patch2="https://github.com/damiandudycz/ps3/raw/${branch}/dev-tools/release-builder/patches/0002-Fix-missing-vmlinux-filename-support.patch"
conf_jobs="8"
conf_load="12.0"

die() { echo "$*" 1>&2 ; exit 1; }

# Determine if host is PS3 or another architecture
if [ "$(uname -m)" != "ppc64" ]; then
    use_qemu=true
    path_portage_confdir_stages="$path_portage_confdir_stages-qemu"
    path_portage_confdir_isos="$path_portage_confdir_isos-qemu"
    interpreter="interpreter: $path_interpreter"
fi

# Create local tmp path
mkdir -p "$path_local_tmp"

# Copy iso overlay
if [ ! -d "$path_livecd_overlay" ]; then
    cp -rf "$path_livecd_overlay_original" "$path_livecd_overlay"
fi

# Copy fsscript
if [ ! -f "$path_livecd_fsscript" ]; then
    cp "$path_livecd_fsscript_original" "$path_livecd_fsscript"
fi

# Download and setup catalyst
if [ ! -d "$path_catalyst_usr" ]; then
    # Apply patch file that fixes catalyst scripts, when using some of subarch values, such as cell
    # Remove this patch when catalyst is updated with it
    if [ ! -f "$path_catalyst_patch_dir/0001.patch" ] || [ ! -f "$path_catalyst_patch_dir/0002.patch" ]; then
        mkdir -p "$path_catalyst_patch_dir"
        wget "$url_catalyst_patch1" -O "$path_catalyst_patch_dir/0001.patch"
        wget "$url_catalyst_patch2" -O "$path_catalyst_patch_dir/0002.patch"
    fi

    # Emerge catalyst
    if [ ! -f "/etc/portage/package.accept_keywords/dev-util_catalyst" ]; then
        echo "# Catalyst requirements" >> /etc/portage/package.accept_keywords/dev-util_catalyst
        echo "dev-util/catalyst **" >> /etc/portage/package.accept_keywords/dev-util_catalyst
	echo "sys-fs/squashfs-tools-ng ~*" >> /etc/portage/package.accept_keywords/dev-util_catalyst
        echo "sys-apps/util-linux python" >> /etc/portage/package.use/dev-util_catalyst
    fi
    emerge dev-util/catalyst

    # Create working dirs
    mkdir -p $path_catalyst_builds
    mkdir -p $path_catalyst_stages
    mkdir -p $path_catalyst_binhost

    # Configure catalyst
    sed -i 's/\(\s*\)# "pkgcache",/\1"pkgcache",/' $path_catalyst_configs/catalyst.conf
    echo "jobs = $conf_jobs" >> $path_catalyst_configs/catalyst.conf
    echo "load-average = $conf_load" >> $path_catalyst_configs/catalyst.conf
    echo "binhost = \"$url_binhost/\"" >> $path_catalyst_configs/catalyst.conf

    # Configure CELL settings for catalyst
    config_file="$path_catalyst_usr/arch/ppc.toml"
    temp_file=$(mktemp)
    awk '
    BEGIN { inside_section = 0 }
    {
        if ($0 ~ /^\[ppc64\.cell\]$/) {
            inside_section = 1
        } else if ($0 ~ /^\[.*\]/) {
            if (inside_section == 1) {
                inside_section = 0
            }
        }
        if (inside_section == 1) {
            if ($0 ~ /^COMMON_FLAGS/) {
                print "COMMON_FLAGS = \"-O2 -pipe -mcpu=cell -mtune=cell -mabi=altivec -mno-string -mno-update -mno-multiple\""
            } else if ($0 ~ /^USE/) {
                print "USE = [ \"altivec\", \"ibm\", \"ps3\",]"
            } else {
                print  # Retain any other lines within the section
            }
        } else {
            print  # Outside the target section, retain the original lines
        }
    }
    ' "$config_file" > "$temp_file"
    mv "$temp_file" "$config_file"
fi

# Download and setup Qemu
if [ "$use_qemu" = true ] && [ ! -f "$path_interpreter" ]; then
    # Emerge Qemu
    echo "" >> /etc/portage/make.conf
    echo "# Catalyst requirements" >> /etc/portage/make.conf
    echo "QEMU_SOFTMMU_TARGETS=\"aarch64 ppc64\"" >> /etc/portage/make.conf
    echo "QEMU_USER_TARGETS=\"ppc64\"" >> /etc/portage/make.conf
    echo "# ---" >> /etc/portage/make.conf
    if [ ! -f "/etc/portage/package.use/qemu" ]; then
        echo "# Catalyst requirements" >> /etc/portage/package.use/qemu
        echo "app-emulation/qemu static-user" >> /etc/portage/package.use/qemu
        echo "dev-libs/glib static-libs" >> /etc/portage/package.use/qemu
        echo "sys-libs/zlib static-libs" >> /etc/portage/package.use/qemu
        echo "sys-apps/attr static-libs" >> /etc/portage/package.use/qemu
        echo "dev-libs/libpcre2 static-libs" >> /etc/portage/package.use/qemu
        echo "# ---" >> /etc/portage/package.use/qemu
    fi
    emerge qemu

    # Setup Qemu autostart and run it
    rc-update add qemu-binfmt default
    rc-config start qemu-binfmt
    [ -d /proc/sys/fs/binfmt_misc ] || modprobe binfmt_misc
    [ -f /proc/sys/fs/binfmt_misc/register ] || mount binfmt_misc -t binfmt_misc /proc/sys/fs/binfmt_misc

    # Setup Qemu for PPC64
    echo ':ppc64:M::\x7fELF\x02\x02\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x15:\xff\xff\xff\xff\xff\xff\xff\xfc\xff\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff:'$path_interpreter':' > /proc/sys/fs/binfmt_misc/register
fi

# Download and setup releng
if [ ! -d $path_releng ]; then
    git clone -o upstream https://github.com/gentoo/releng.git $path_releng
    cp -rf "$path_portage_confdir_stages" "$path_portage_confdir_stages-cell"
    cp -rf "$path_portage_confdir_isos" "$path_portage_confdir_isos-cell"
    echo '*/* CPU_FLAGS_PPC: altivec' > "$path_portage_confdir_stages-cell/package.use/00cpu-flags"
    echo '*/* CPU_FLAGS_PPC: altivec' > "$path_portage_confdir_isos-cell/package.use/00cpu-flags"
    # Enable usage of the latest installer (9999)
    echo 'sys-apps/ps3-gentoo-installer ~ppc64' > "$path_portage_confdir_stages-cell/package.accept_keywords/sys-apps_ps3-gentoo-installer"
    echo 'sys-apps/ps3-gentoo-installer ~ppc64' > "$path_portage_confdir_isos-cell/package.accept_keywords/sys-apps_ps3-gentoo-installer"
fi

# Download current snapshot
if [ -f "$path_local_tmp/snapshot_log.txt" ]; then
    rm -f "$path_local_tmp/snapshot_log.txt"
fi
catalyst --snapshot stable | tee "$path_local_tmp/snapshot_log.txt"
squashfs_identifier=$(cat "$path_local_tmp/snapshot_log.txt" | grep -oP 'Creating gentoo tree snapshot \K[0-9a-f]{40}')

# Download stage3 seed
if [ ! -f "${path_stage3_seed}" ]; then
    stageinfo_url="$url_release_gentoo/latest-stage3-ppc64-openrc.txt"
    latest_gentoo_content="$(wget -q -O - "$stageinfo_url" --no-http-keep-alive --no-cache --no-cookies)"
    latest_stage3="$(echo "$latest_gentoo_content" | grep "ppc64-openrc" | head -n 1 | cut -d' ' -f1)"
    if [ -n "$path_stage3_seed" ]; then
        url_gentoo_tarball="$url_release_gentoo/$latest_stage3"
    else
        echo "Failed to download Stage3 URL"
        exit 1
    fi
    # Download stage3 file
    wget "$url_gentoo_tarball" -O "$path_stage3_seed"
fi

# Clone or pull current copy of custom overlay
if [ ! -d "${path_overlay}" ]; then
    echo "${path_overlay} is not ready. Please clone binhost repository."
    exit 1
fi

# Check if binrepo is fetched
if [ ! -d "${path_repo_binhost}" ]; then
    echo "Binhost github repository is not prepared. Please clone first to ${path_repo_binhost}"
    exit 1
fi

# Bind github_repo
mount -o bind ${path_repo_binhost} ${path_catalyst_binhost} || die "Failed to bind binhost repo to ${path_catalyst_binhost}"

# Prepare spec files
cp "$path_start/spec/stage1-cell.spec" "$path_stage1"
cp "$path_start/spec/stage3-cell.spec" "$path_stage3"
cp "$path_start/spec/stage1-cell.installcd.spec" "$path_stage1_installcd"
cp "$path_start/spec/stage2-cell.installcd.spec" "$path_stage2_installcd"
sed -i "s|@TREEISH@|${squashfs_identifier}|g" "$path_stage1"
sed -i "s|@TREEISH@|${squashfs_identifier}|g" "$path_stage3"
sed -i "s|@TREEISH@|${squashfs_identifier}|g" "$path_stage1_installcd"
sed -i "s|@TREEISH@|${squashfs_identifier}|g" "$path_stage2_installcd"
sed -i "s|@TIMESTAMP@|${timestamp}|g" "$path_stage1"
sed -i "s|@TIMESTAMP@|${timestamp}|g" "$path_stage3"
sed -i "s|@TIMESTAMP@|${timestamp}|g" "$path_stage1_installcd"
sed -i "s|@TIMESTAMP@|${timestamp}|g" "$path_stage2_installcd"
sed -i "s|@PORTAGE_CONFDIR@|${path_portage_confdir_stages}|g" "$path_stage1"
sed -i "s|@PORTAGE_CONFDIR@|${path_portage_confdir_stages}-cell|g" "$path_stage3"
sed -i "s|@PORTAGE_CONFDIR@|${path_portage_confdir_isos}|g" "$path_stage1_installcd"
sed -i "s|@PORTAGE_CONFDIR@|${path_portage_confdir_isos}-cell|g" "$path_stage2_installcd"
sed -i "s|@INTERPRETER@|${interpreter}|g" "$path_stage1"
sed -i "s|@INTERPRETER@|${interpreter}|g" "$path_stage3"
sed -i "s|@INTERPRETER@|${interpreter}|g" "$path_stage1_installcd"
sed -i "s|@INTERPRETER@|${interpreter}|g" "$path_stage2_installcd"
sed -i "s|@REPOS@|${path_overlay}|g" "$path_stage1_installcd"
sed -i "s|@REPOS@|${path_overlay}|g" "$path_stage2_installcd"
sed -i "s|@LIVECD_OVERLAY@|${path_livecd_overlay}|g" "$path_stage2_installcd"
sed -i "s|@LIVECD_FSSCRIPT@|${path_livecd_fsscript}|g" "$path_stage2_installcd"

# Run catalyst
(
  catalyst -f "${path_stage1}" &&
  catalyst -f "${path_stage3}" &&
  catalyst -f "${path_stage1_installcd}" &&
  catalyst -f "${path_stage2_installcd}"
) ||
(
  umount ${path_catalyst_binhost} &&
  die "Catalyst build failed"
)

# Create and upload overlay for ps3-gentoo-installer changes
new_ebuild_path="${path_installer_ebuild_repo}/ps3-gentoo-installer-${new_tag}.ebuild"
cp "${path_installer_ebuild_draft}" "${new_ebuild_path}"
cd "${path_overlay}"
pkgdev manifest
if [[ $(git status --porcelain) ]]; then
    git add -A
    git commit -m "Overlay automatic update (Catalyst release)"
    git push
fi

# Upload binhost repo
cd "${path_repo_binhost}"
if [[ $(git status --porcelain) ]]; then
    git add -A
    git commit -m "Binrepo automatic update (Catalyst release)"
    git push
fi

# Save new release in autobuilds
mkdir -p "${path_autobuild_new}"
mv "${path_catalyst_builds}"/stage3-cell-openrc-${timestamp}.tar.xz* "${path_autobuild_new}"/
mv "${path_catalyst_builds}"/install-cell-minimal-${timestamp}.iso* "${path_autobuild_new}"/
echo "${timestamp}/stage3-cell-openrc-${timestamp}.tar.xz" > "${path_repo_autobuilds}/latest-stage3-cell-openrc.txt"
echo "${timestamp}/install-cell-minimal-${timestamp}.iso" > "${path_repo_autobuilds}/latest-install-cell-minimal.txt"

# Add new version tag to git and upload it
cd "${path_root}"
if [[ $(git status --porcelain) ]]; then
    git add -A
    git commit -m "Release ${new_tag}"
    git push
    git tag -a "${new_tag}" -m "Release ${new_tag}"
    git push origin "${new_tag}"
fi

# Umount binhost repo
umount ${path_catalyst_binhost}

