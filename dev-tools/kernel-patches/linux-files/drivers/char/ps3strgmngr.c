/*
 * PS3 Storage Manager Driver
 *
 * Copyright (C) 2011 graf_chokolo <grafchokolo@gmail.com>
 * Copyright (C) 2011, 2012 glevand <geoffrey.levand@mail.ru>
 * All rights reserved.
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published
 * by the Free Software Foundation; version 2 of the License.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */

#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/slab.h>
#include <linux/fs.h>
#include <linux/uaccess.h>
#include <linux/compat.h>
#include <linux/miscdevice.h>

#include <asm/ps3.h>
#include <asm/lv1call.h>
#include <asm/ps3strgmngr.h>

#define STORAGE_BUS_TYPE		5

#define STORAGE_DEV_TYPE_DISK		0	
#define STORAGE_DEV_TYPE_CDROM		5	
#define STORAGE_DEV_TYPE_FLASH		14
#define STORAGE_DEV_TYPE_NOR_FLASH	254

static int ps3strgmngr_read_acl(u64 dev_id, struct ps3strgmngr_region *rgn)
{
	struct ps3strgmngr_acl_entry *acl_entry;
	unsigned int acl_entry_index;
	int res;

	rgn->nr_acl_entries = 0;
	acl_entry = rgn->acl_entry;

	for (acl_entry_index = 0; acl_entry_index < PS3STRGMNGR_MAX_ACL_ENTRIES; acl_entry_index++) {
		res = lv1_storage_get_region_acl(dev_id, rgn->id, acl_entry_index,
		    &acl_entry->laid, &acl_entry->access_rights);
		if (res)
			continue;

		rgn->nr_acl_entries++;
		acl_entry++;
	}

	return (0);
}

static int ps3strgmngr_read_region(u64 bus_index, u64 dev_index, u64 dev_id, u64 dev_type,
    u64 rgn_index, struct ps3strgmngr_region *rgn)
{
	u64 flash_ext_flag, junk;
	int res;

	res = lv1_read_repository_node(1, 0x0000000062757300ul | bus_index /* bus */,
					  0x6465760000000000ul | dev_index /* dev */,
					  0x726567696f6e0000ul | rgn_index /* region */,
					  0x6964000000000000ul /* id */,
					  &rgn->id, &junk);
	if (res)
		return (-ENXIO);

	if (dev_type == STORAGE_DEV_TYPE_DISK) {
		res = lv1_read_repository_node(1, 0x0000000073797300ul /* sys */,
						  0x666c617368000000ul /* flash */,
						  0x6578740000000000ul /* ext */,
						  0, &flash_ext_flag, &junk);
		if (res)
			return (-ENXIO);

		if (!(flash_ext_flag & 0x1) && (rgn->id > 0))
			rgn->id += 1;
	}

	res = lv1_read_repository_node(1, 0x0000000062757300ul | bus_index /* bus */,
					  0x6465760000000000ul | dev_index /* dev */,
					  0x726567696f6e0000ul | rgn_index /* region */,
					  0x7374617274000000ul /* start */,
					  &rgn->start_block, &junk);
	if (res)
		return (-ENXIO);

	res = lv1_read_repository_node(1, 0x0000000062757300ul | bus_index /* bus */,
					  0x6465760000000000ul | dev_index /* dev */,
					  0x726567696f6e0000ul | rgn_index /* region */,
					  0x73697a6500000000ul /* size */,
					  &rgn->nr_blocks, &junk);
	if (res)
		return (-ENXIO);

	res = ps3strgmngr_read_acl(dev_id, rgn);
	if (res)
		return (res);

	return (0);
}

static int ps3strgmngr_read_device(u64 bus_index, u64 dev_index,
    struct ps3strgmngr_device *dev)
{
	struct ps3strgmngr_region *rgn;
	u64 type, nr_regions, junk;
	unsigned int rgn_index;
	int res;

	res = lv1_read_repository_node(1, 0x0000000062757300ul | bus_index /* bus */,
					  0x6465760000000000ul | dev_index /* dev */,
					  0x7479706500000000ul /* type */,
					  0, &type, &junk);
	if (res)
		return (-ENXIO);

	switch (type) {
	case STORAGE_DEV_TYPE_DISK:
		dev->type = PS3STRGMNGR_DEVTYPE_DISK;
	break;
	case STORAGE_DEV_TYPE_CDROM:
		dev->type = PS3STRGMNGR_DEVTYPE_CDROM;
	break;
	case STORAGE_DEV_TYPE_FLASH:
		dev->type = PS3STRGMNGR_DEVTYPE_FLASH;
	break;
	case STORAGE_DEV_TYPE_NOR_FLASH:
		dev->type = PS3STRGMNGR_DEVTYPE_NOR_FLASH;
	break;
	default:
		return (-ENOTSUPP);
	break;
	}

	res = lv1_read_repository_node(1, 0x0000000062757300ul | bus_index /* bus */,
					  0x6465760000000000ul | dev_index /* dev */,
					  0x6964000000000000ul /* id */,
					  0, &dev->id, &junk);
	if (res)
		return (-ENXIO);

	res = lv1_read_repository_node(1, 0x0000000062757300ul | bus_index /* bus */,
					  0x6465760000000000ul | dev_index /* dev */,
					  0x626c6b5f73697a65ul /* blk_size */,
					  0, &dev->block_size, &junk);
	if (res)
		return (-ENXIO);

	res = lv1_read_repository_node(1, 0x0000000062757300ul | bus_index /* bus */,
					  0x6465760000000000ul | dev_index /* dev */,
					  0x6e5f626c6f636b73ul /* n_blocks */,
					  0, &dev->nr_blocks, &junk);
	if (res)
		return (-ENXIO);

	res = lv1_read_repository_node(1, 0x0000000062757300ul | bus_index /* bus */,
					  0x6465760000000000ul | dev_index /* dev */,
					  0x6e5f726567730000ul /* n_regs */,
					  0, &nr_regions, &junk);
	if (res)
		return (-ENXIO);

	rgn = dev->region;

	for (rgn_index = 0; rgn_index < nr_regions; rgn_index++) {
		res = ps3strgmngr_read_region(bus_index, dev_index, dev->id, type,
		    rgn_index, rgn);
		if (res)
			continue;

		dev->nr_regions++;
		rgn++;
	}

	return (0);
}

static int ps3strgmngr_ctl_get_devices(struct ps3strgmngr_ctl_get_devices *get_devices)
{
	struct ps3strgmngr_device *dev;
	unsigned int bus_index, dev_index;
	u64 bus_type, bus_id, nr_devices, junk;
	int res;

	get_devices->nr_devices = 0;
	dev = get_devices->device;

	for (bus_index = 0; bus_index < 10; bus_index++) {
		res = lv1_read_repository_node(1, 0x0000000062757300ul | bus_index /* bus */,
						  0x7479706500000000ul /* type */,
						  0, 0, &bus_type, &junk);
		if (res)
			continue;

		if (bus_type == STORAGE_BUS_TYPE)
			break;
	}

	if (bus_index >= 10)
		return (-ENXIO);

	res = lv1_read_repository_node(1, 0x0000000062757300ul | bus_index /* bus */,
					  0x6964000000000000ul /* id */,
					  0, 0, &bus_id, &junk);
	if (res)
		return (-ENXIO);

	res = lv1_read_repository_node(1, 0x0000000062757300ul | bus_index /* bus */,
					  0x6e756d5f64657600ul /* num_dev */,
					  0, 0, &nr_devices, &junk);
	if (res)
		return (-ENXIO);

	for (dev_index = 0; dev_index < nr_devices; dev_index++) {
		res = ps3strgmngr_read_device(bus_index, dev_index, dev);
		if (res)
			continue;

		get_devices->nr_devices++;
		dev++;
	}

	return (0);
}

static int ps3strgmngr_ctl_create_region(struct ps3strgmngr_ctl_create_region *create_region)
{
	u64 tag;
	int res;

	res = lv1_storage_create_region(create_region->device_id, create_region->start_block,
	    create_region->nr_blocks, 0, create_region->laid, &create_region->region_id, &tag);
	if (res)
		return (-ENXIO);

	return (0);
}

static int ps3strgmngr_ctl_delete_region(struct ps3strgmngr_ctl_delete_region *delete_region)
{
	u64 tag;
	int res;

	res = lv1_storage_delete_region(delete_region->device_id, delete_region->region_id, &tag);
	if (res)
		return (-ENXIO);

	return (0);
}

static int ps3strgmngr_ctl_set_region_acl_entry(struct ps3strgmngr_ctl_set_region_acl_entry *set_region_acl_entry)
{
	u64 tag;
	int res;

	res = lv1_storage_set_region_acl(set_region_acl_entry->device_id, set_region_acl_entry->region_id,
	    set_region_acl_entry->laid, set_region_acl_entry->access_rights,
	    &tag);
	if (res)
		return (-ENXIO);

	return (0);
}

static long ps3strgmngr_ioctl(struct file *file, unsigned int cmd,
    unsigned long arg)
{
	void __user *argp = (void __user *) arg;
	struct ps3strgmngr_ctl_get_devices *get_devices;
	struct ps3strgmngr_ctl_create_region *create_region;
	struct ps3strgmngr_ctl_delete_region *delete_region;
	struct ps3strgmngr_ctl_set_region_acl_entry *set_region_acl_entry;
	int res;

	if (is_compat_task())
		argp = compat_ptr(arg);
	else
		argp = (void __user *) arg;

	switch (cmd) {
	case PS3STRGMNGR_CTL_GET_DEVICES:
		get_devices = kmalloc(sizeof(*get_devices), GFP_KERNEL);
		if (!get_devices)
			return (-ENOMEM);

		if (copy_from_user(get_devices, argp, sizeof(*get_devices))) {
			kfree(get_devices);
			return (-EFAULT);
		}

		res = ps3strgmngr_ctl_get_devices(get_devices);
		if (res) {
			kfree(get_devices);
			return (res);
		}

		if (copy_to_user(argp, get_devices, sizeof(*get_devices))) {
			kfree(get_devices);
			return (-EFAULT);
		}

		kfree(get_devices);
	break;
	case PS3STRGMNGR_CTL_CREATE_REGION:
		create_region = kmalloc(sizeof(*create_region), GFP_KERNEL);
		if (!create_region)
			return (-ENOMEM);

		if (copy_from_user(create_region, argp, sizeof(*create_region))) {
			kfree(create_region);
			return (-EFAULT);
		}

		res = ps3strgmngr_ctl_create_region(create_region);
		if (res) {
			kfree(create_region);
			return (res);
		}

		if (copy_to_user(argp, create_region, sizeof(*create_region))) {
			kfree(create_region);
			return (-EFAULT);
		}

		kfree(create_region);
	break;
	case PS3STRGMNGR_CTL_DELETE_REGION:
		delete_region = kmalloc(sizeof(*delete_region), GFP_KERNEL);
		if (!delete_region)
			return (-ENOMEM);

		if (copy_from_user(delete_region, argp, sizeof(*delete_region))) {
			kfree(delete_region);
			return (-EFAULT);
		}

		res = ps3strgmngr_ctl_delete_region(delete_region);
		if (res) {
			kfree(delete_region);
			return (res);
		}

		if (copy_to_user(argp, delete_region, sizeof(*delete_region))) {
			kfree(delete_region);
			return (-EFAULT);
		}

		kfree(delete_region);
	break;
	case PS3STRGMNGR_CTL_SET_REGION_ACL_ENTRY:
		set_region_acl_entry = kmalloc(sizeof(*set_region_acl_entry), GFP_KERNEL);
		if (!set_region_acl_entry)
			return (-ENOMEM);

		if (copy_from_user(set_region_acl_entry, argp, sizeof(*set_region_acl_entry))) {
			kfree(set_region_acl_entry);
			return (-EFAULT);
		}

		res = ps3strgmngr_ctl_set_region_acl_entry(set_region_acl_entry);
		if (res) {
			kfree(set_region_acl_entry);
			return (res);
		}

		if (copy_to_user(argp, set_region_acl_entry, sizeof(*set_region_acl_entry))) {
			kfree(set_region_acl_entry);
			return (-EFAULT);
		}

		kfree(set_region_acl_entry);
	break;
	default:
		return (-ENOIOCTLCMD);
	break;
	}

	return (0);
}

static const struct file_operations ps3strgmngr_fops = {
	.owner		= THIS_MODULE,
	.unlocked_ioctl	= ps3strgmngr_ioctl,
	.compat_ioctl	= ps3strgmngr_ioctl,
};

static struct miscdevice ps3strgmngr_misc = {
	.minor	= MISC_DYNAMIC_MINOR,
	.name	= "ps3strgmngr",
	.fops	= &ps3strgmngr_fops,
};

static int __init ps3strgmngr_init(void)
{
	int res;

	res = misc_register(&ps3strgmngr_misc);
	if (res) {
		pr_info("%s:%u: misc_register failed %d\n",
		    __func__, __LINE__, res);
		return (res);
	}

	return (0);
}

static void __exit ps3strgmngr_exit(void)
{
	misc_deregister(&ps3strgmngr_misc);
}

module_init(ps3strgmngr_init);
module_exit(ps3strgmngr_exit);

MODULE_AUTHOR("glevand");
MODULE_DESCRIPTION("PS3 Storage Manager Driver");
MODULE_LICENSE("GPL");
