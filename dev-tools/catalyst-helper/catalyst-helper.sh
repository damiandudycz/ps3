ARCHITECTURE=$(uname -m)
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
    mkdir -p /var/tmp/catalyst/builds/23-default
    mkdir -p /var/tmp/catalyst/config/stages
    mkdir -p ~/catalyst-ps3

    # Configure catalyst
    #sed -i 's/\(\s*\)# "distcc",/\1"distcc",/' /etc/catalyst/catalyst.conf
    echo "jobs = 8" >> /etc/catalyst/catalyst.conf
    echo "load-average = 12.0" >> /etc/catalyst/catalyst.conf
    #echo 'distcc_hosts = "192.168.86.114"' >> /etc/catalyst/catalyst.conf
    echo 'binhost = "https://raw.githubusercontent.com/damiandudycz/ps3-gentoo-binhosts/main/"' >> /etc/catalyst/catalyst.conf
    #echo 'export FEATURES="-pid-sandbox -network-sandbox"' >> /etc/catalyst/catalystrc

    # Configure CELL settings for catalyst
    echo '[ppc64.cell]' > /usr/share/catalyst/arch/ppc.toml
    echo 'COMMON_FLAGS = "-O2 -pipe -mcpu=cell -mtune=cell -mabi=altivec -mno-string -mno-update -mno-multiple"' >> /usr/share/catalyst/arch/ppc.toml
    echo 'CHOST = "powerpc64-unknown-linux-gnu"' >> /usr/share/catalyst/arch/ppc.toml
    echo 'USE = [ "altivec", "ibm", "ps3" ]' >> /usr/share/catalyst/arch/ppc.toml
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
        
    # Configure host features for qemu to work
    # This needs to be added to /var/tmp/catalyst/tmp/stage*/etc/portage/make.conf
    #echo 'FEATURES="-pid-sandbox -network-sandbox"' >> /etc/portage/make.conf
    
    rc-update add qemu-binfmt default
    rc-config start qemu-binfmt
    
    [ -d /proc/sys/fs/binfmt_misc ] || modprobe binfmt_misc
    [ -f /proc/sys/fs/binfmt_misc/register ] || mount binfmt_misc -t binfmt_misc /proc/sys/fs/binfmt_misc
    echo ':ppc64:M::\x7fELF\x02\x02\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x15:\xff\xff\xff\xff\xff\xff\xff\xfc\xff\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff:/usr/bin/qemu-ppc64:' > /proc/sys/fs/binfmt_misc/register
fi

path_download="/var/tmp/catalyst/builds/23-default/stage3-ppc64-openrc-latest.tar.xz"
# Fetch Stage3 seed
if [ ! -f path_download ]; then
    stageinfo_url="https://gentoo.osuosl.org/releases/ppc/autobuilds/current-stage3-ppc64-openrc/latest-stage3-ppc64-openrc.txt"
    latest_gentoo_content="$(wget -q -O - "$stageinfo_url" --no-http-keep-alive --no-cache --no-cookies)"
    latest_stage3="$(echo "$latest_gentoo_content" | grep "ppc64-openrc" | head -n 1 | cut -d' ' -f1)"
    if [ -n "$path_download" ]; then
        url_gentoo_tarball="https://gentoo.osuosl.org/releases/ppc/autobuilds/current-stage3-ppc64-openrc/$latest_stage3"
    else
        echo "Failed to download Stage3 URL"
        exit 1
    fi
    if [ ! -f "$path_download" ]; then
        # Download stage3/4 file
        wget "$url_gentoo_tarball" -O "$path_download"
    fi
fi

if [ ! -d /var/tmp/catalyst/releng ]; then
    # Fetch snapshot
    cd ~/catalyst-ps3
    catalyst --snapshot stable | tee snapshot_log.txt
    squashfs_identifier=$(cat snapshot_log.txt | grep -oP 'Creating gentoo tree snapshot \K[0-9a-f]{40}')

    # Download spec files
    wget -O stage1-openrc.spec https://gitweb.gentoo.org/proj/releng.git/plain/releases/specs/ppc/ppc64/stage1-openrc-23.spec
    wget -O stage3-openrc.spec https://gitweb.gentoo.org/proj/releng.git/plain/releases/specs/ppc/ppc64/stage3-openrc-23.spec
    cd /var/tmp/catalyst
    rm -rf "releng"
    git clone -o upstream https://github.com/gentoo/releng.git
    cd ~/catalyst-ps3

    # Modify spec files
    sed -i "s/openrc-@TIMESTAMP@/openrc-$(date +'%Y.%m.%d')/g" stage1-openrc.spec
    sed -i "s/@TREEISH@/${squashfs_identifier}/g" stage1-openrc.spec
    sed -i "s/@REPO_DIR@/\/var\/tmp\/catalyst\/releng/g" stage1-openrc.spec
    sed -i "s/subarch: ppc64/subarch: cell/g" stage1-openrc.spec
    if [ "$use_qemu" = true ]; then
        echo "interpreter: /usr/bin/qemu-ppc64" >> stage1-openrc.spec
    fi
    echo 'binrepo_path: base' >> stage1-openrc.spec
fi

# TODO: Modify stage3 spec

#NOTE: Need to add to /var/tmp/catalyst/tmp/default/stage1-cell-2024.03.26/etc/portage/make.conf:
# FEATURES="-pid-sandbox -network-sandbox"

# Run scripts
#catalyst -f stage1-openrc.spec
#catalyst -f stage3-openrc.spec
