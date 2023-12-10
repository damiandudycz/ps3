#!/bin/bash

chroot_call 'emerge --newuse --update app-emulation/qemu'
chroot_call '[ -d /proc/sys/fs/binfmt_misc ] || modprobe binfmt_misc'
chroot_call '[ -f /proc/sys/fs/binfmt_misc/register ] || mount binfmt_misc -t binfmt_misc /proc/sys/fs/binfmt_misc'
chroot_call "echo ':ppc64:M::\x7fELF\x02\x02\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x15:\xff\xff\xff\xff\xff\xff\xff\xfc\xff\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff:/usr/bin/qemu-ppc64:' | tee /proc/sys/fs/binfmt_misc/register"
chroot_call 'rc-service qemu-binfmt restart'
chroot_call 'rc-update add qemu-binfmt'
