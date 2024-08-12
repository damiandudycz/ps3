for patch in ../Patches/New/*.patch; do echo $patch; patch -p1 -d . < $patch; done
