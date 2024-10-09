Catalyst-Lab is a tool that automates the process of building various stages of gentoo release.
It handles dependencies between stages, prepares required files and performs builds of these stages.
It works by processing stage templates which contains various information about stages, like spec file,
portage confdir, overlay, root_overlay, fsscript and other.
Spec templates contains some basic information and are converted into final spec file by the script, by
applying various automatically calculated values.
Script is constructed in such a way that it makes it easy to transfer and use templates on other computers
without the need to modify templates and manually downloading seed files, even if the other computer uses
different architecture.
The purpuse of this script is to help maintaining scheduled releases, by automatically building
all/selected templates without the need to change anything in previously prepared templates.

# Templates

Templates are stored in /etc/catalyst-lab/templates directory and contain all the data needed to prepare
the final spec file. Each template is stored in a structured directory inside /etc/catalyst-lab/templates,
with this folder structure:
${PLATFORM}/${RELEASE}/${STAGE} - for example - ps3/23.0-default/stage3-cell-base-openrc.

Template structure elements:

## PLATFORM
represents the device or collection of devices using the same type of CPU architecture. This
could be for exmaple: ppc64, ps3, rpi5, amd64, etc.

## RELEASE
combines stages for specific system configuration and base profile. This can be used for example to diffrienciate
default builds from llvm/clang builds. Examples: 23.0-default, 23.0-llvm.

## STAGE
contains information about specific stage to build. Stage contains things like spec file template, portage confdir,
overlay folder, root_overlay folder, fsscript.

User should prepare templates inside /etc/catalyst-lab/templates, defining the builds that he/she want's to create.
By default script will build every template, but it's also possible to specify only selected templates to build.
In this situation, script will automatically detect if required source stages are already available and if they are not
will also build these first.


# Releng
Script can use releng portage confdirs as a base for templates. This can be done by creating file releng_base inside
portage folder (which is in template stage directory). This file should contain just the name of base releng portage
directory (for example: stages or isos). Template's portage folder can then contain only additional files that should
be also applied to portage confdir during build, and the script will automatically combine it's content with releng base.
When specifying releng base, don't add -qemu postfix - script automatially detects if qemu usage is needed when building
the stage and applies it when needed. If user choose not to use releng base portage confdir, he/she can just not create
releng_base file, and provide all required files inside portage directory.
Script also automatically handles downloading releng repository, by default to /opt/releng.


# Portage napshots
Script autoamtically handles getting portage snapshots by catalyst. First it checks if there are some snapshots available
and if it doesn't detect one, it downloads it automatically. User can also specify --update-snapshot flag, to ensure that
script will refresh available snapshot to the latest.


# QEmu
Script will automatically detect if qemu interpreter is required for every stage, and will add this information to final
spec file if needed. User don't need to add interpreter entry to template stage.spec files. For this functionality to work,
make sure that variables in platform.conf are set correctly. This way qemu will be used automatically when building stage
for architecture different than host architecture and templates can still be shared between different computers without
any changes.

# Catalyst conf
Templates can provide customized catalyst.conf file to be used for specific stages build. This way user can have different
catalyst configuration used for specific platforms, releases or single stages.
To achieve this add correct catalyst.conf file inside one of template folders:
 - in ${PLATFORM} to use it for all builds in this platform.
 - in ${PLATFORM}/${RELEASE} to use it for all builds in this release.
 - in ${PLATFORM}/${RELEASE}/${STAGE} to use it only for single stage.
If no catalyst.conf is included in any of template structure directories, script will use default catlyst.conf file for the system.


# Platform configuration
inside templates ${PLATFORM} directory, there needs to be a platform.conf file, containing some basic information about the platform.
This file contains:
 - arch_family - for example ppc, arm64, amd64. This information is used when script needs to download a missing seed file, that is not
otherwise definied by other stages. For example when building stage1, we need a stage3 seed, and if no template provides this seed, and
it's not available inside catalyst builds directory, then script will try to download this seed directly from Gentoo.
 - arch_basearch - for example ppc64, arm64. This definies the architecture of stages produced by this template platform. This information
is used by the script to decide if qemu interpreter needs to be used for the build.
 - arch_subarch - for example ppc64. This definies the subarch used in this platform templates. It should correspond to entries in catalyst
toml files.
 - arch_interpreter - for example /usr/bin/qemu-ppc64. This definies which interpreter should be used when needed. Provide this value even if
building for the same architecture as current host machine. Script will detect automatically if interpreter usage is required and only use it
when needed. By providing this value, it's possible to transfer templates to different host architecture, and still build it.
 - repos. Optional list of portage overlay repos (separated by comma) used in all templates from this platform. Use this if you need to install additional software
that is not available in gentoo default repository. Repos can be definied as a local folder or as a git repository. Script will automatically
clone git based repos to /tmp/catalyst-lab/repos. Repos can also be specified in single stage in stage.spec file. Use this value inside platform.conf
to add this information automatially to all stages inside this platform.


# Inheritance
The script uses information in stage.spec template files to determine the inheritance between stages, and then build
them in correct order. It's important to set fields like target, version_stamp and source in such a way, that inheritance
could be determined. This information is obtained by determining the name of file that will be produced by one stage, and
comparing it with source_subpath of another stage.
For example if you want to define stage3 and stage4, and make sure that stage4 uses stage3 as it's seed:
in stage3 set:
 - target: stage3
 - version_stamp: desktop-openrc-@TIMESTAMP@
This will result in producing a file named:
${PLATFORM}/${RELEASE}/stage3-${arch_subarch}-desktop-openrc-@TIMESTAMP@
so for example ps3/23.0-default/stage3-cell-desktop-openrc-20241009T135241Z
Then in stage4, you can define:
 - source_subpath: @PLATFORM@/@REL_TYPE@/stage3-cell-desktop-openrc-@TIMESTAMP@
By setting these values in this form, you can make sure that the order and inheritance will be handled propertly.
Notice, that when defining these values, you can use some placeholders, like @PLATFORM@, @REL_TYPE@, @TIMESTAMP@.
These values will be converted to correct values by the script in final spec file.
If you need to use source seed from another platform or release, then these can be set manually to provide correct
data. So for example, when building stage1 for the CELL cpu, you might want to use generic PPC64 as a seed, and then use:
 - source_subpath: ${arch_basearch}/23.0-default/stage3-${arch_basearch}-openrc-@TIMESTAMP@
which translates for example to ppc64/23.0-default/stage3-ppc64-openrc-20241009T135241Z.
If no template provides a build for source_subpath and local build file is also not availablem then script will try to get the
seed from gentoo servers. In this situation it is important to name source_subpath file in a form that is used on gentoo servers.
Subdirectories can still be used, only the filename itself is important. Remember to add @TIMESTAMP@ to the name in this situation.


# Binary packages
When building stages, catalyst will use and create binrepo. By default these binrepos are created in /var/cache/catalyst-binpkgs/${platform}/${release}.
This means that binrepos are shared between all stages for single RELEASE, for example: ps3/23.0-default. If user wish to use different directory for specific
stages, he/she can set correct pkgcache value in template stage.spec file. Otherwise, if default value should be used, then stage.spec should not contain this
variable at all, as it will be automatically added by the script.


# How to prepare templates
1. Create a folder representing the platform in /etc/catalyst-lab/templates. For example /etc/catalyst-lab/templates/ps3.
2. Create platform.conf file inside this platoform template directory and fill these information:

arch_family=ppc                         # Use this arch when downloading missing stages. This can ba obteined from stage3 URL: https://distfiles.gentoo.org/releases/**ppc**/autobuilds/20241003T034858Z/stage3-ppc-openrc-20241003T034858Z.tar.xz
arch_basearch=ppc64                     # Used to compare with building host arch to know if should use qemu.
arch_subarch=cell                       # Used to fill spec files if not specified in template. This should represent a subarch from toml files.
arch_interpreter=/usr/bin/qemu-ppc64    # Qemu interpreter for this build. Only added to spec if needed. Always set this value, even if building for the same architecture as host.
# Optional:
repos=""				# Comma seperated list of additional overlay repos, shared for the whole platform templates. This can be local file or link to git repository.

Replace values from this sample to match your requirements.

3. If you wish to use custom catalyst.conf file for all builds in this platform, add catalyst.conf file to platform template directory (eq: /etc/catalyst-lab/templates/ps3/catalyst.conf).
4. Add release directory. For example /etc/catalyst-lab/templates/ps3/23.0-default.
5. If you wish to use custom catalyst.conf file for all builds in this release, add catalyst.conf file to release template directory (eq: /etc/catalyst-lab/templates/ps3/23.0-default/catalyst.conf.conf).
5. Add stage directory. For example: /etc/catalyst-lab/templates/ps3/23.0-default/stage1-cell-base-openrc.
6. If you wish to use custom catalyst.conf file for this stage only, add catalyst.conf file to stage template directory (eq: /etc/catalyst-lab/templates/ps3/23.0-default/stage1-cell-base-openrc/catalyst.conf.conf).
7. Create stage.spec template file in stage directory: /etc/catalyst-lab/templates/ps3/23.0-default/stage1-cell-base-openrc/stage.spec.

This file is a stage spec template, not the final spec file. Script will fill this template with multiple automatically generated values.
There are multiple keywords that can be used in this template, like @PLATFORM@, @RELEASE@, @TIMESTAMP@, and more. These are described in detail later in this document.

8. Create portage directory in stage directory: /etc/catalyst-lab/templates/ps3/23.0-default/stage1-cell-base-openrc/portage.

This directory is your portage_confdir. Add all the changes you want for your system here, like package.use, env, etc.
Prefferebly add a file named releng_base here and in this file specify the name of base portage folder from releng - for example "stages".
Avoid adding -qemu postfix, script will add it automatically if it's needed.

9. Optionally add overlay, root_overlay directories, and fsscript.sh, if you wish to use them. No need to specify them in stage.spec template,
script adds these entries automatically if these directories and files exists.

That's all, template can now be build with catalyst-lab script.


# stage.spec template structure
stage.spec file is a template of spec file, that will be generated automatically by the script. This template dont need to contain
all the fields required in the final spec file, and for some values user avoid specifing them. These are described later in this section.
Stage spec template also allows specyfing some keywords, that will be replaced with automatically generated values, like @TIMESTAMP@, @PLATFORM@, etc.

Bellow is the list of common values that should or should not be stored in spec template with short description:
[+] target - needs to be set correctly, for example: stage1.
[+] version_stamp - needs to be set correctly. It's adviced to add -@TIMESTAMP@ in this value, to generate and use timestamp marked files. Eq: base-openrc-@TIMESTAMP@.
[+] profile - needs to be set correctly. Here user could use @BASE_ARCH@ placeholder, to get the value from platform.config: Eq: default/linux/@BASE_ARCH@/23.0.
[+] source_subpath - needs to be set correctly, and it's used to determine inheritance. Can contain templates to automatically fill the values. It's important to make sure, that it's source can be correctly identified from this value, Eq: @BASE_ARCH@/@REL_TYPE@/stage3-ppc64-openrc-@TIMESTAMP@.
[+] compression_mode - should be added. Eq: pixz.
[+] update_seed - should be added for some stages. Eq: yes.
[+] update_seed_command - should be added for some stages. Eq: --update --deep --newuse --usepkg --buildpkg @system @world.
[+] livecd/use, livecd/packages, livecd/rm, livecd/rcadd, livecd/unmerge, livecd/empty - sould be added for liveCD stages.
[-] subarch - don't set this value, it will be added automatically from platform.config.
[-] rel_type - don't set this value, it will be added automatically based on template directory.
[-] portage_confdir - don't add this value, it will be created automatically.
[-] snapshot_treeish - don't add this value, it will be created automatically, unless you with to use very specific treeish.
[-] repos - only add this if you wish to specify custom repos just for this build. Otherwise it will be added automatically from platform.conf.
[-] portage_prefix - don't add this value if you are using releng_base file for portage confdir template. Otherwise, if portage confdir template is created without the use of releng, if can be added.
[-] pkgcache_path - don't add this value, unless you want to specify custom directory for pkgcache. By default this is set by the script to /var/cache/catalyst-binpkgs/${PLATFORM}/${RELEASE}.
[-] interpreter - don't add this value, it will be added automatically if emulation is needed.
[-] */overlay, */root_overlay, */fsscript - don't add these values, they will be added automatically if corresponding files and directories exists in template.

## Examples

### Example of stage1 spec template - ps3/23.0-default/stage1-cell-base-openrc:

target: stage1
version_stamp: base-openrc-@TIMESTAMP@
profile: default/linux/@BASE_ARCH@/23.0
source_subpath: @BASE_ARCH@/@REL_TYPE@/stage3-@BASE_ARCH@-openrc-@TIMESTAMP@
compression_mode: pixz
update_seed: yes
update_seed_command: --update --deep --newuse --usepkg --buildpkg @system @world

### Example of stage3 spec template - ps3/23.0-default/stage3-cell-base-openrc:

target: stage3
version_stamp: base-openrc-@TIMESTAMP@
source_subpath: @PLATFORM@/@REL_TYPE@/stage1-cell-base-openrc-@TIMESTAMP@
profile: default/linux/@BASE_ARCH@/23.0
compression_mode: pixz

### Example of livecd-stage1 template - ps3/23.0-default/livecd-stage1-cell:

version_stamp: @TIMESTAMP@
source_subpath: @PLATFORM@/@REL_TYPE@/stage3-cell-base-openrc-@TIMESTAMP@
target: livecd-stage1
profile: default/linux/@BASE_ARCH@/23.0
compression_mode: pixz

livecd/use:
 	ps3
	compile-locales
	fbcon
	livecd
	socks5
	unicode
	xml

livecd/packages:
	sys-apps/ps3-gentoo-installer
	sys-apps/ps3vram-swap
	sys-block/zram-init
 	app-portage/gentoolkit
 	net-misc/ntp
	sys-block/zram-init
	net-misc/networkmanager
	app-accessibility/brltty
	app-admin/pwgen
	app-arch/lbzip2
	app-arch/pigz
	app-arch/zstd
	app-crypt/gnupg
	app-misc/livecd-tools
	app-portage/mirrorselect
	app-shells/bash-completion
	app-shells/gentoo-bashcomp
	net-analyzer/tcptraceroute
	net-analyzer/traceroute
	net-misc/dhcpcd
	net-misc/iputils
	net-misc/openssh
	net-misc/rdate
	net-wireless/iw
	net-wireless/iwd
	net-wireless/wireless-tools
	net-wireless/wpa_supplicant
	sys-apps/busybox
	sys-apps/ethtool
	sys-apps/fxload
	sys-apps/gptfdisk
	sys-apps/hdparm
	sys-apps/ibm-powerpc-utils
	sys-apps/ipmitool
	sys-apps/iproute2
	sys-apps/lsvpd
	sys-apps/memtester
	sys-apps/merge-usr
	sys-apps/ppc64-diag
	sys-apps/sdparm
	sys-apps/usbutils
	sys-auth/ssh-import-id
	sys-block/parted
	sys-fs/bcache-tools
	sys-fs/btrfs-progs
	sys-fs/cryptsetup
	sys-fs/dosfstools
	sys-fs/e2fsprogs
	sys-fs/f2fs-tools
	sys-fs/iprutils
	sys-fs/lsscsi
	sys-fs/lvm2
	sys-fs/mdadm
	sys-fs/mtd-utils
	sys-fs/sysfsutils
	sys-fs/xfsprogs
	sys-libs/gpm
	sys-process/lsof
	www-client/links


# Usage

After preparing templates, they can be build just by calling:
./catalyst-lab.sh
This will prepare final stage files, download required seeds, setup releng and portage snapshot and finally build all stages.

If you with to build just some stages, you can specify these in the script:
./catalyst-lab.sh ps3/23.0-default/stage3-cell-base-openrc
One or more templates can be added. If some stage needs to build a seed first, it will be added automatically. If a previous
version of corresponding seed already exists it will be used instead.

Additional flags that can be used with the script:
--update-snapshot - get the latest portage snapshot before building.
--update-releng - pull changes in releng repository before building.
--clean - build all required seeds, even if there are previous builds available.
