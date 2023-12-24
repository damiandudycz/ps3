# Rebuilds entire system from the begining
# Used by Builder tool, to prepare all packages as binpkgs.

chroot_call "emerge @system @world --deep --emptytree --with-bdeps=y $quiet_flag"
