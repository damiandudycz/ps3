ebuild-find-version.sh:
    This script returns the newest available version of gentoo-kernel. If executed with --unstable it returns the latest unstable version.
    Otherwise it returns the latest stable.

ebuild-fetch-patches.sh
    This script updates patches for version specified as a parameter or default patches if run without a patameter.

ebuild-emerge-gentoo-sources.sh
    This script downloads gentoo-sources package. It can grab specified version when passing it as a patameter.
    Otherwise it will download latest stable version (Stable for gentoo-kernel).

ebuild-apply-kernel-patches.sh
    This script applies scripts stored in data/patches/<version> or data/patches/default if version patches are not available.
    If using default patches and it succedes, default patches will also be copied to data/patches/<version>.
