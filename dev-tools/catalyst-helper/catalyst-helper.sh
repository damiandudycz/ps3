timestamp=$(date -u +"%Y%m%dT%H%M%SZ")
path_download_stage3="/var/tmp/catalyst/builds/23.0-default/stage3-ppc64-openrc-$timestamp.tar.xz"
path_start="$(pwd)"
path_spec=$(realpath -m "$path_start/../../local/catalyst")
path_stage1="$path_spec/stage1-cell.$timestamp.spec"
path_stage3="$path_spec/stage3-cell.$timestamp.spec"
path_stage1_installcd="$path_spec/stage1-cell.installcd.$timestamp.spec"
path_stage2_installcd="$path_spec/stage2-cell.installcd.$timestamp.spec"
path_overlay=$(realpath -m "$path_start/../../overlays/ps3-gentoo-overlay")

# Determine if host is PS3 or another architecture
if [ "$(uname -m)" != "ppc64" ]; then
    use_qemu=true
    confdir_postfix="-qemu"
    interpreter="interpreter: /usr/bin/qemu-ppc64"
fi

# Make sure overlay directory is ready to work
if [ ! -d "$path_overlay/metadata" ]; then
    echo "Ebuild repository not ready. Run ./update-submodules.sh to prepare it in the root of repository tree."
    exit 1
fi

if [ ! -d "/usr/share/catalyst" ]; then
    # Apply patch file that fixes catalyst scripts, when using some of subarch values, such as cell
    # Remove this patch when catalyst is updated with it
    catalyst_patch_path="/etc/portage/patches/dev-util/catalyst-4.0_rc1"
    mkdir -p "$catalyst_patch_path"
    wget https://911536.bugs.gentoo.org/attachment.cgi?id=866757 -O "$catalyst_patch_path/01-basearch.patch"

    # Emerge catalyst
    echo "dev-util/catalyst ~ppc64" >> /etc/portage/package.accept_keywords/dev-util_catalyst
    echo "sys-fs/squashfs-tools-ng ~ppc64" >> /etc/portage/package.accept_keywords/dev-util_catalyst
    echo "sys-apps/util-linux python" >> /etc/portage/package.use/dev-util_catalyst
    emerge dev-util/catalyst

    # Create working dirs
    mkdir -p /var/tmp/catalyst/builds/23.0-default
    mkdir -p /var/tmp/catalyst/config/stages

    # Configure catalyst
    sed -i 's/\(\s*\)# "pkgcache",/\1"pkgcache",/' /etc/catalyst/catalyst.conf
    echo "jobs = 8" >> /etc/catalyst/catalyst.conf
    echo "load-average = 12.0" >> /etc/catalyst/catalyst.conf
    echo 'binhost = "https://raw.githubusercontent.com/damiandudycz/ps3-gentoo-binhosts/main/"' >> /etc/catalyst/catalyst.conf

    # Configure CELL settings for catalyst
    config_file="/usr/share/catalyst/arch/ppc.toml"
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
                print "USE = [ \"altivec\", \"ibm\", \"ps3\", ]"
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

# For crosscompile environment
if [ "$use_qemu" = true ] && [ ! -f "/usr/bin/qemu-ppc64" ]; then
    # Emerge Qemu
    echo "" >> /etc/portage/make.conf
    echo "# Catalyst requirements" >> /etc/portage/make.conf
    echo "QEMU_SOFTMMU_TARGETS=\"aarch64 ppc64\"" >> /etc/portage/make.conf
    echo "QEMU_USER_TARGETS=\"ppc64\"" >> /etc/portage/make.conf
    echo "# ---" >> /etc/portage/make.conf
    echo "# Catalyst requirements" >> /etc/portage/package.use/qemu
    echo "app-emulation/qemu static-user" >> /etc/portage/package.use/qemu
    echo "dev-libs/glib static-libs" >> /etc/portage/package.use/qemu
    echo "sys-libs/zlib static-libs" >> /etc/portage/package.use/qemu
    echo "sys-apps/attr static-libs" >> /etc/portage/package.use/qemu
    echo "dev-libs/libpcre2 static-libs" >> /etc/portage/package.use/qemu
    emerge qemu

    # Setup Qemu autostart and run it
    rc-update add qemu-binfmt default
    rc-config start qemu-binfmt
    [ -d /proc/sys/fs/binfmt_misc ] || modprobe binfmt_misc
    [ -f /proc/sys/fs/binfmt_misc/register ] || mount binfmt_misc -t binfmt_misc /proc/sys/fs/binfmt_misc

    # Setup Qemu for PPC64
    echo ':ppc64:M::\x7fELF\x02\x02\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x15:\xff\xff\xff\xff\xff\xff\xff\xfc\xff\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff:/usr/bin/qemu-ppc64:' > /proc/sys/fs/binfmt_misc/register
fi

# Download releng
if [ ! -d /var/tmp/catalyst/releng ]; then
    cd /var/tmp/catalyst
    git clone -o upstream https://github.com/gentoo/releng.git
    # Tweak releng configs
    echo '*/* CPU_FLAGS_PPC: altivec' > "releng/releases/portage/stages${confdir_postfix}/package.use/00cpu-flags"
    echo 'dev-libs/gmp -cpudetection' > "releng/releases/portage/stages${confdir_postfix}/package.use/10gmp"
fi

# Download Stage3 seed
if [ ! -f "${path_download_stage3}" ]; then
    stageinfo_url="https://gentoo.osuosl.org/releases/ppc/autobuilds/current-stage3-ppc64-openrc/latest-stage3-ppc64-openrc.txt"
    latest_gentoo_content="$(wget -q -O - "$stageinfo_url" --no-http-keep-alive --no-cache --no-cookies)"
    latest_stage3="$(echo "$latest_gentoo_content" | grep "ppc64-openrc" | head -n 1 | cut -d' ' -f1)"
    if [ -n "$path_download_stage3" ]; then
        url_gentoo_tarball="https://gentoo.osuosl.org/releases/ppc/autobuilds/current-stage3-ppc64-openrc/$latest_stage3"
    else
        echo "Failed to download Stage3 URL"
        exit 1
    fi
    # Download stage3 file
    wget "$url_gentoo_tarball" -O "$path_download_stage3"
fi

# Download current snapshot
if [ ! -d "$path_spec" ]; then
    mkdir -p "$path_spec"
fi
cd "$path_spec"
catalyst --snapshot stable | tee snapshot_log.txt
squashfs_identifier=$(cat snapshot_log.txt | grep -oP 'Creating gentoo tree snapshot \K[0-9a-f]{40}')
rm -f snapshot_log.txt

# Prepare spec files
cp "$path_start/spec/stage1-cell.spec" "$path_stage1"
cp "$path_start/spec/stage3-cell.spec" "$path_stage3"
cp "$path_start/spec/stage1-cell.installcd.spec" "$path_stage1_installcd"
cp "$path_start/spec/stage2-cell.installcd.spec" "$path_stage2_installcd"

sed -i "s/@TREEISH@/${squashfs_identifier}/g" "$path_stage1"
sed -i "s/@TREEISH@/${squashfs_identifier}/g" "$path_stage3"
sed -i "s/@TREEISH@/${squashfs_identifier}/g" "$path_stage1_installcd"
sed -i "s/@TREEISH@/${squashfs_identifier}/g" "$path_stage2_installcd"
sed -i "s/@TIMESTAMP@/${timestamp}/g" "$path_stage1"
sed -i "s/@TIMESTAMP@/${timestamp}/g" "$path_stage3"
sed -i "s/@TIMESTAMP@/${timestamp}/g" "$path_stage1_installcd"
sed -i "s/@TIMESTAMP@/${timestamp}/g" "$path_stage2_installcd"
sed -i "s/@CONFDIR_POSTFIX@/${confdir_postfix}/g" "$path_stage1"
sed -i "s/@CONFDIR_POSTFIX@/${confdir_postfix}/g" "$path_stage3"
sed -i "s/@CONFDIR_POSTFIX@/${confdir_postfix}/g" "$path_stage1_installcd"
sed -i "s/@CONFDIR_POSTFIX@/${confdir_postfix}/g" "$path_stage2_installcd"
sed -i "s|@INTERPRETER@|${interpreter}|g" "$path_stage1"
sed -i "s|@INTERPRETER@|${interpreter}|g" "$path_stage3"
sed -i "s|@INTERPRETER@|${interpreter}|g" "$path_stage1_installcd"
sed -i "s|@INTERPRETER@|${interpreter}|g" "$path_stage2_installcd"
sed -i "s|@REPOS@|${path_overlay}|g" "$path_stage1_installcd"
sed -i "s|@REPOS@|${path_overlay}|g" "$path_stage2_installcd"

# Run catalyst
#catalyst -f "${path_stage1}"
#catalyst -f "${path_stage3}"
#catalyst -f "${path_stage1_installcd}"
#catalyst -f "${path_stage2_installcd}"
