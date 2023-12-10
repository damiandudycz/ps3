# PlayStation 3 Gentoo Linux toolset

### Note: README in progress

If you want to try Gentoo using LiveUSB / LiveDVD, download files from https://www.dropbox.com/scl/fi/qrjzexfm1owd1r1aprkd8/LiveUSB.zip?rlkey=kd3isyeo5tkhqtbb1sy57hbh6&dl=1
and extract them to USB formatted with MBR / FAT32

# Kenrel building tools

These tools should be used on a host machine, running `Gentoo`. You can use `Virtual Machine` for that puropse.

After cloning the repository, go to downloaded `ps3/tools` directory and edit hidden `.config` file
Select the version of kernel you want to work on, and make sure the version you selected is available in portage. Also in this file you can select the `address of the PS3` in your local network.

These tools will apply specific kernel patches from two seperate sources. If you want to modify the list of applied patches, edit the file `01-setup-patches.sh` and change `patches_t2sde` and `patches_ps3linux_patches`. 

After that you can run the script: `01-setup-patches.sh`. It will download all selected patches, to be used for kernel later.

Next run `02-setup-sources.sh`, this will download `gentoo-sources`, and apply previously prepared patches.

Run `03-kernel-configure.sh`, and customize configuration to your needs. Please use the script instead of running menuconfig directly, as the scripts adds special crossdev layer.
When you are sacisfied with your config, run `04-kernel-build.sh`.

At this point kernel is ready, and you can find it in `/var/cache/ps3tools/linux`

If you want you can upload it directly to the `PS3` using `05-kernel-upload-to-ps3.sh`. This required the `root access` for the SSH to be configured for the PS3. If you don't want to use `root`, you can edit `05-kernel-upload-to-ps3.sh` and change root to another user, but it needs the write access to `/boot`. Otherwise you can copy it manually from `/var/cache/ps3tools/linux`. Also make sure `/boot` is mounted on your PS3 before running it.

Currently there is no tool for automatic creation of `kboot/yaboot` files, so if you changed the kernel version, you need to add these entries manually.

# Gentoo-Installer

Automatic installer and configurator of Gentoo linux for various platforms.

To install on the PS3, boot into any recent linux distribution, setup the date and networking and:

To install on the whole drive:

`./gentoo-install.sh --device /dev/ps3dd --config ps3 --verbose`

this will format selected harddrive!

To install into selected directory without formatting the drive:

`./gentoo-install.sh --directory /mnt/gentoo --config ps3 --verbose`

and after installer finished, add fstab configuration and kboot entry.

If you want to customize configuration, you can download file config/ps3, edit it and use as

`./gentoo-install.sh --device /dev/ps3dd --custom-config ps3_file_path --verbose`

To use distcc during installation, use --distcc flag:

`./gentoo-install.sh --device /dev/ps3dd --config ps3 --distcc "192.168.0.50,cpp,lzo"`
