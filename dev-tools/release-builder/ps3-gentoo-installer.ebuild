API=8
DESCRIPTION="Automatic Gentoo Linux installer for the PlayStaion 3"
HOMEPAGE="https://github.com/damiandudycz/ps3"
LICENSE="GPL-2"
SLOT="0"
KEYWORDS="ppc64"
S="${WORKDIR}"
DEPEND="
    sys-apps/util-linux
    sys-fs/btrfs-progs
"
SRC_URI="https://raw.githubusercontent.com/damiandudycz/ps3/${PV}/dev-tools/${PN}/${PN}"

src_install() {
        dobin "${DISTDIR}"/"${PN}"
}
