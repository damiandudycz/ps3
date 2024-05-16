# PlayStation 3 Gentoo Linux Toolset

Welcome to the PlayStation 3 Gentoo Linux Toolset repository—a comprehensive collection of files and tools designed to facilitate the seamless installation and maintenance of Gentoo Linux on the PlayStation 3.

## Repository Contents

### Minimal Installation CD
- **install-cell-minimal.iso**: This ISO file can be burned to a CD/DVD or a USB drive and launched on the PS3 via the Petitboot menu. It supports both automatic and manual Gentoo installations. For automatic installation, use the `ps3-gentoo-installer` program included on the CD. Note that Petitboot must be installed on your PS3 to boot from this ISO.

### PS3 Gentoo Installer
- **ps3-gentoo-installer**: This tool facilitates the automatic installation and configuration of Gentoo Linux using the Minimal Installation CD. It performs the following tasks:
    - Formats and partitions the hard drive for Gentoo.
    - Downloads and extracts Stage3.
    - Synchronizes the portage tree.
    - Installs `gentoo-kernel-ps3`.
    - Configures Petitboot.
    - Installs additional tools.
    - Sets up a default user with sudo access.
    - And more…
  
    After execution, Gentoo can be booted on the PS3. Note that installation can take several hours, depending on the packages to be compiled. **Warning:** This tool will format your hard drive unless you choose the directory installation method. Please back up any sensitive data beforehand.

    To install, run:
        ps3-gentoo-installer --device /dev/ps3dd

    For more options, use:
        ps3-gentoo-installer --help

### Autobuilds
- **Autobuilds directory**: Contains the following:
    - Minimal install CD ISO files for booting on the PS3 using Petitboot.
    - Stage3 files built for the CELL CPU, offering better compatibility with the PS3 compared to the default PPC64 Stage3 files.

### Binhosts
- **Binhosts/ps3-gentoo-binhosts**: A collection of binhost repositories that can be added to your portage configuration. These repositories are generated during the release process of Autobuilds and contain pre-compiled packages optimized for the CELL CPU. If you use the `ps3-gentoo-installer`, these repositories will be added automatically. Recommended repository URLs:
    - https://raw.githubusercontent.com/damiandudycz/ps3-gentoo-binhosts/main/default/stage3-cell
    - https://raw.githubusercontent.com/damiandudycz/ps3-gentoo-binhosts/main/default/livecd-stage1-cell
    - https://raw.githubusercontent.com/damiandudycz/ps3-gentoo-binhosts/main/default/livecd-stage2-cell

### Overlays
- **Overlays/ps3-gentoo-overlay**: A portage overlay containing ebuilds for packages useful on the PS3 system, including:
    - `gentoo-kernel-ps3`: A modified gentoo-kernel package with additional patches and configurations for the PS3, which also adds a Petitboot entry.
    - `gentoo-sources-ps3`: A modified gentoo-sources package with additional patches and configurations for the PS3.
    - `ps3vram-swap`: An RC script that utilizes PS3 VRAM as a swap device and configures system parameters for better memory management on the PS3.
    - `ps3-gentoo-installer`: The automatic Gentoo installer for the PS3, available on the Minimal Installation CD.

    If you use `ps3-gentoo-installer`, this overlay will be added automatically. To manually add `ps3-gentoo-overlay` to your portage configuration, run:
        eselect repository add ps3 git https://github.com/damiandudycz/ps3-gentoo-overlay

### Development Tools
- **dev-tools directory**: Contains tools used by the repository developer for maintenance and helper tasks. These include:
    - `update-submodules.sh`: Initializes submodule repositories and githooks after cloning this repository.
    - `distcc-docker`: Configuration for a Docker image to set up a DistCC server, aiding the PS3 in compiling code faster.
    - `kernel-ebuild-builder`: Manages and updates `ps3-gentoo-overlay` ebuild files related to the kernel.
    - `ps3-gentoo-installer`: The current version of the automatic Gentoo installer for the PS3, available on the Minimal Installation CD.
    - `release-builder`: Creates and uploads new releases, including:
        - Minimal Installation CD
        - Stage3 files
        - Binhost repositories

## Feedback and Contributions
If you have any suggestions or encounter any issues, please feel free to contact me at [damiandudycz@yahoo.com](mailto:damiandudycz@yahoo.com) or find me on the Gentoo Discord @damiandudycz.

If you use any of my tools in your project, please include a reference to this repository and a link back to it. Your acknowledgment helps support the development and maintenance of these tools.
