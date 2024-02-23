# PlayStation 3 Gentoo Linux Toolset

Welcome to the PlayStation 3 Gentoo Linux Toolset repository — a comprehensive collection of files and tools designed for seamless installation and maintenance of Gentoo Linux on the PlayStation 3. Here's an overview of the current features:

- Automatic Installer: Facilitates the effortless installation and configuration of Gentoo Linux on the PS3.
- Prebuilt Kernel: Compatible with both OtherOS and OtherOS++, this kernel is equipped with various patches specifically tailored for the PS3.
- Binhost Repository: Streamlines the installation process by enabling quicker access to diverse packages without the need for direct compilation.
- Portage overlay: Overlay repository featuring additional tools specifically crafted for the PS3.
- Developer Tools: Essential for building new kernel versions and managing different aspects of the repository.
- LiveDVD/LiveUSB Image: An immersive option allowing you to run Gentoo directly from a USB device.

The repository undergoes constant updates, incorporating new features and addressing any issues. Future plans include:

- Customized Petitboot: Developing an enhanced and up-to-date version of Petitboot for an optimized user experience.
- Installer Integration with Petitboot: Making adjustments to the installer to seamlessly integrate with Petitboot for user-friendly functionality.
- Enhanced Prebuilt Kernel: Continuously improving the prebuilt kernel to ensure optimal performance.
- Automatic Binrepo Update Tool: Implementing an automatic tool to keep the binhost repository up-to-date effortlessly.

I value your feedback and encourage you to share your comments or suggestions using the "Issues" tab or via email at damiandudycz@yahoo.com.
Your input is invaluable, and all comments are greatly appreciated! :)

For development puropses clone with: `git clone --recurse-submodules git@github.com:damiandudycz/ps3.git`
To download installer use: `wget https://raw.githubusercontent.com/damiandudycz/ps3/main/installer/installer.sh`

# Installer

Installer is located at `insteller/installer.sh`. You can use it from another linux to install Gentoo on the PS3 hard drive or in selected directory.
You can use it with default configuration or you can adjust the settings to match your needs.
TODO: Add more information about the installer.

### OLD description

Im constantly working on making this project more reliable and eaisy to use. Recently I added a binhost repository which is automatically added to Gentoo during installation, to make the process faster. Currently testing it. 
Please feel free to report any issues you have or some suggestions/questions using Issues tab in GitHub.

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

`./installer.sh --device /dev/ps3dd --config PS3 --verbose`

this will format selected harddrive!

To install into selected directory without formatting the drive:

`./installer.sh --directory /mnt/gentoo --config PS3 --verbose`

and after installer finished, add fstab configuration and kboot entry.

If you want to customize configuration, you can download file config/ps3, edit it and use as

`./installer.sh --device /dev/ps3dd --custom-config ps3_file_path --verbose`

To use distcc during installation, use --distcc flag:

`./installer.sh --device /dev/ps3dd --config PS3 --distcc "192.168.0.50"`

# Acknowledgement

If you use my project as a base for other forks or projects, please add contribution with url to my repository.

Special thanks to:
- Model Citizen PS3 - for sharing knowledgle about Linux on PS3,
- Rene Rebe - for updating and maintaining kernel patches for the PS3,
- Immolo - for sharing knowledge about Gentoo,
- OtherOS++ team - for making it all possible.





