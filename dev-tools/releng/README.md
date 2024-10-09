Catalyst-Lab is a tool that automates the process of building various stages of gentoo release.
It handles dependencies between stages, prepares required files and performs builds of these stages.
It works by processing stage templates which contains various information about stages, like spec file,
portage confdir, overlay, root_overlay, fsscript and other.
Spec templates contains some basic information and are converted into final spec file by the script, by
applying various automatically calculated values.
Script is constructed in such a way that it makes it easy to transfer and use templates on other computers
without the need to modify templates and manually downloading seed files, even if the other computer uses
different architecture.

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
