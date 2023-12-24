# Rebuilds entire system from the begining

chroot_call "emerge @system @world --deep --emptytree --with-bdeps=y $quiet_flag"
