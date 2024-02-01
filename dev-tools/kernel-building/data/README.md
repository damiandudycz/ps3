# Helper files used by update-gentoo-kernel-ps3.sh

- apply-diffconfig.rb
Ruby script used to apply changes from ps3_defconfig_diffs file to new default ps3_defconfig.
This includes information about all manually changed settings for the PS3 OtherOS++ kernel, used by new ebuilds.

- gentoo-kernel-ps3.ebuild.patch
Patch file that converts default gentoo-kernel.ebuild into gentoo-kernel-ps3.ebuild.
Need to be manually updated sometimes, when it's changed between versions.
To create new patch, edit gentoo-kernel.ebuild with all required changes, and run against original file:
diff -u1 gentoo-kernel-<version>.ebuild gentoo-kernel-ps3-<version>.ebuild > data/gentoo-kernel-ps3.ebuild.patch

- gentoo.conf
Default configuration for gentoo portage repository. Required by pkgdev manifest to work correctly.

- patches_ps3_list.txt
List of PS3 patches to be downloaded and packed for this ebuild.
Patches are stored in their form in the time of running update-gentoo-kernel-ps3.sh, compressed and stored
inside overlay distfiles archive (alongide other files).

- ps3_defconfig_diffs
List of changes to be applied to configuration. These files are applied to original ps3_defconfig file, and later
it is merged with another helper configs from Gentoo.
This file is updated automatically when using --save flag, by comparing the default configuration with configuration stored inside ps3/local/gentoo-kernel/<version>.
