ebuild-find-version.sh:
    This script returns the newest available version of gentoo-kernel. If executed with --unstable it returns the latest unstable version.
    Otherwise it returns the latest stable.

ebuild-fetch-patches.sh
    This script updates patches for version specified as a parameter or default patches if run without a patameter.

ebuild-download-gentoo-kernel.sh
    This script downloads gentoo-kernel package. It can grab specified version when passing it as a patameter.
    Otherwise it will download latest stable version (Stable for gentoo-kernel).
    Package is extracted but not built.

ebuild-apply-kernel-patches.sh
    This script applies scripts stored in data/patches/<version> or data/patches/default if version patches are not available.
    If using default patches and it succedes, default patches will also be copied to data/patches/<version>.

ebuild-configure.sh
    This script creates configuration for selected version and stores it in data/config/<version> directory.
    If configuration diff file for specific version already exists, it's being used, otherwise default configuration diff is used.
    To modify configuration add --edit flag.

ebuild-create-ps3-ebuild.sh
    This script generates new ebuild and distfiles for gentoo-kernel-ps3 package.
    Ebuild and distfiles are stored in tmp location at this point, not yet uploaded to the server.

