target: stage1
version_stamp: desktop-openrc-@TIMESTAMP@
profile: default/linux/@BASE_ARCH@/23.0/desktop
source_subpath: @PLATFORM@/@REL_TYPE@/stage3-@BASE_ARCH@-openrc-@TIMESTAMP@
compression_mode: pixz
update_seed: yes
update_seed_command: --update --deep --newuse --usepkg --buildpkg @system @world

#subarch: cell
#portage_prefix: releng
#pkgcache_path: @PKGCACHE_PATH@/.stage1
#snapshot_treeish: @TREEISH@
