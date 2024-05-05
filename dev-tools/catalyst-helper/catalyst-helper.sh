ARCHITECTURE=$(uname -m)
timestamp=$(date +"%Y.%m.%d")
path_download_stage3="/var/tmp/catalyst/builds/23.0-default/stage3-ppc64-openrc-$timestamp.tar.xz"
path_start="$(pwd)"
spec_dir=$(realpath -m "$path_start/../../local/catalyst")
path_stage1="$spec_dir/stage1-cell.$timestamp.spec"
path_stage3="$spec_dir/stage3-cell.$timestamp.spec"
path_stage1_installcd="$spec_dir/stage1-cell.installcd.$timestamp.spec"
path_stage2_installcd="$spec_dir/stage2-cell.installcd.$timestamp.spec"

if [ "$ARCHITECTURE" != "ppc64" ]; then
    use_qemu=true
else
    use_qemu=false
fi

if [ ! -d "/usr/share/catalyst" ]; then
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
    #sed -i 's/\(\s*\)# "distcc",/\1"distcc",/' /etc/catalyst/catalyst.conf
    #echo 'distcc_hosts = "192.168.86.114"' >> /etc/catalyst/catalyst.conf

    # Configure CELL settings for catalyst
    echo '' >> /usr/share/catalyst/arch/ppc.toml
    echo '[ppc64.cell]' >> /usr/share/catalyst/arch/ppc.toml
    echo 'COMMON_FLAGS = "-O2 -pipe -mcpu=cell -mtune=cell -mabi=altivec -mno-string -mno-update -mno-multiple"' >> /usr/share/catalyst/arch/ppc.toml
    echo 'CHOST = "powerpc64-unknown-linux-gnu"' >> /usr/share/catalyst/arch/ppc.toml
    echo 'USE = [ "altivec", "ibm", "ps3",]' >> /usr/share/catalyst/arch/ppc.toml
fi

# For crosscompile environment
if [ "$use_qemu" = true ] && [ ! -f "/usr/bin/qemu-ppc64" ]; then
    # Emerge QEmu
    echo "QEMU_SOFTMMU_TARGETS=\"aarch64 ppc64\"" >> /etc/portage/make.conf
    echo "QEMU_USER_TARGETS=\"ppc64\"" >> /etc/portage/make.conf
    echo "app-emulation/qemu static-user" >> /etc/portage/package.use/qemu
    echo "dev-libs/glib static-libs" >> /etc/portage/package.use/qemu
    echo "sys-libs/zlib static-libs" >> /etc/portage/package.use/qemu
    echo "sys-apps/attr static-libs" >> /etc/portage/package.use/qemu
    echo "dev-libs/libpcre2 static-libs" >> /etc/portage/package.use/qemu
    emerge qemu

    rc-update add qemu-binfmt default
    rc-config start qemu-binfmt

    [ -d /proc/sys/fs/binfmt_misc ] || modprobe binfmt_misc
    [ -f /proc/sys/fs/binfmt_misc/register ] || mount binfmt_misc -t binfmt_misc /proc/sys/fs/binfmt_misc
    echo ':ppc64:M::\x7fELF\x02\x02\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x15:\xff\xff\xff\xff\xff\xff\xff\xfc\xff\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff:/usr/bin/qemu-ppc64:' > /proc/sys/fs/binfmt_misc/register
fi

# Download releng
if [ ! -d /var/tmp/catalyst/releng ]; then
    cd /var/tmp/catalyst
    git clone -o upstream https://github.com/gentoo/releng.git
fi

# Fetch Stage3 seed
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

# Fetch snapshot
if [ ! -d "$spec_dir" ]; then
    mkdir -p "$spec_dir"
fi
cd "$spec_dir"
catalyst --snapshot stable | tee snapshot_log.txt
squashfs_identifier=$(cat snapshot_log.txt | grep -oP 'Creating gentoo tree snapshot \K[0-9a-f]{40}')
rm -f snapshot_log.txt

# Prepare spec files
cp "$path_start/spec/stage1-cell.spec" "$path_stage1"
cp "$path_start/spec/stage3-cell.spec" "$path_stage3"
cp "$path_start/spec/stage1-cell.installcd.spec" "$path_stage1_installcd"
cp "$path_start/spec/stage2-cell.installcd.spec" "$path_stage2_installcd"

# Modify spec files
sed -i "s/@TREEISH@/${squashfs_identifier}/g" "$path_stage1"
sed -i "s/@TREEISH@/${squashfs_identifier}/g" "$path_stage3"
sed -i "s/@TREEISH@/${squashfs_identifier}/g" "$path_stage1_installcd"
sed -i "s/@TREEISH@/${squashfs_identifier}/g" "$path_stage2_installcd"
sed -i "s/@TIMESTAMP@/${timestamp}/g" "$path_stage1"
sed -i "s/@TIMESTAMP@/${timestamp}/g" "$path_stage3"
sed -i "s/@TIMESTAMP@/${timestamp}/g" "$path_stage1_installcd"
sed -i "s/@TIMESTAMP@/${timestamp}/g" "$path_stage2_installcd"

# Run catalyst
catalyst -f "${path_stage1}"
catalyst -f "${path_stage3}"
catalyst -f "${path_stage1_installcd}"
catalyst -f "${path_stage2_installcd}"

# TODO: Rempve interpreter if running on PS3
# TODO: Use spec versions without -qemu when running on PS3
