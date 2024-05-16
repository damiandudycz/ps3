EAPI=8
DESCRIPTION="Automatic Gentoo Linux installer for the PlayStaion 3"
HOMEPAGE="https://github.com/damiandudycz/ps3"
LICENSE="GPL-2"
SLOT="0"
KEYWORDS="ppc64"
SRC_URI="https://github.com/damiandudycz/ps3-gentoo-overlay.distfiles/raw/main/sys-apps/${PN}/${PN}-${PVR}.tar.xz"
S="${WORKDIR}"

DEPEND="
    sys-apps/util-linux
    sys-fs/btrfs-progs
"

src_unpack() {
    default
}

src_install() {
    # Copy installer
    dobin "${S}/ps3-gentoo-installer"

    # Copy default configuration
    insinto /etc/ps3-gentoo-installer
    doins "${S}/config"
}
