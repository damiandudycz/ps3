#!/bin/bash

# Configures host crossdev environment.
# Creates and configures crossdev targets.
# To be used on PS3 Helper Host. Not for PS3 itself.

# Default configuration for the PS3 - Should be added to config of target and not stored directly here.
#chroot_call "crossdev --b '~2.40' --g '~13.2.1_p20230826' --k '~6.6' --l '~2.37' -t powerpc64-unknown-linux-gnu --abis altivec"
chroot_call "crossdev --b '~${crossdev_config['b']}' --g '~${crossdev_config['g']}' --k '~${crossdev_config['k']}' --l '~${crossdev_config['l']}' -t powerpc64-unknown-linux-gnu --abis ${crossdev_config['a']}"
