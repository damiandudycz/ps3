#!/bin/bash

# Configures host crossdev environment.
# To be used on PS3 Helper Host. Not for PS3 itself.

# Default configuration for the PS3 helper.
chroot_call "crossdev --b '~${crossdev_config['b']}' --g '~${crossdev_config['g']}' --k '~${crossdev_config['k']}' --l '~${crossdev_config['l']}' -t powerpc64-unknown-linux-gnu --abis ${crossdev_config['a']}"
