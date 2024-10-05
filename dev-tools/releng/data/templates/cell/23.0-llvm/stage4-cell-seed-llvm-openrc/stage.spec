# This stage is building seed for LLVM/CLANG/MUSL releases by adding required applications - clang, musl, llvm to normal stage3 release.

subarch: cell
target: stage4
version_stamp: seed-llvm-openrc-@TIMESTAMP@
source_subpath: @PLATFORM@/@REL_TYPE@/stage3-ppc64-musl-hardened-openrc-@TIMESTAMP@
snapshot_treeish: @TREEISH@
profile: default/linux/ppc64/23.0/musl
compression_mode: pixz
portage_prefix: releng
pkgcache_path: @PKGCACHE_PATH@/cell
#repos: @REPOS@

stage4/packages:
	llvm
	clang
