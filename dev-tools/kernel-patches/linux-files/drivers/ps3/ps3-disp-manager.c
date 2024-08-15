/*
 *  PS3 Dispatcher Manager.
 *
 *  Copyright (C) 2011 graf_chokolo <grafchokolo@gmail.com>.
 *  Copyright (C) 2011, 2012 glevand <geoffrey.levand@mail.ru>.
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; version 2 of the License.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/slab.h>
#include <linux/uaccess.h>
#include <linux/fs.h>
#include <linux/miscdevice.h>

#include <asm/firmware.h>
#include <asm/lv1call.h>
#include <asm/ps3.h>

#include "vuart.h"

#define DEVICE_NAME		"ps3dispmngr"

static struct ps3dm {
	struct ps3_system_bus_device *dev;
	struct miscdevice misc;
} *ps3dm;

static ssize_t ps3_disp_manager_read(struct file *file, char __user *usrbuf,
				     size_t count, loff_t *pos)
{
	char *buf;
	int result;

	buf = kmalloc(count, GFP_KERNEL);
	if (!buf)
		return -ENOMEM;

	result = ps3_vuart_read(ps3dm->dev, buf, count);
	if (result)
		goto out;

	if (copy_to_user(usrbuf, buf, count)) {
		result = -EFAULT;
		goto out;
	}

	result = count;

out:

	kfree(buf);

	return result;
}

static ssize_t ps3_disp_manager_write(struct file *file, const char __user *usrbuf,
				      size_t count, loff_t *pos)
{
	char *buf;
	int result;

	buf = kmalloc(count, GFP_KERNEL);
	if (!buf)
		return -ENOMEM;

	if (copy_from_user(buf, usrbuf, count)) {
		result = -EFAULT;
		goto out;
	}

	result = ps3_vuart_write(ps3dm->dev, buf, count);
	if (result)
		goto out;

	result = count;

out:

	kfree(buf);

	return result;
}

static const struct file_operations ps3_disp_manager_fops = {
	.owner	= THIS_MODULE,
	.read	= ps3_disp_manager_read,
	.write	= ps3_disp_manager_write,
};

static int ps3_disp_manager_probe(struct ps3_system_bus_device *dev)
{
	int result;

	dev_dbg(&dev->core, "%s:%d\n", __func__, __LINE__);

	if (ps3dm) {
		dev_err(&dev->core, "Only one Dispatcher Manager is supported\n");
		return -EBUSY;
	}

	ps3dm = kzalloc(sizeof(*ps3dm), GFP_KERNEL);
	if (!ps3dm)
		return -ENOMEM;

	ps3dm->dev = dev;

	ps3dm->misc.parent = &dev->core;
	ps3dm->misc.minor = MISC_DYNAMIC_MINOR,
	ps3dm->misc.name = DEVICE_NAME,
	ps3dm->misc.fops = &ps3_disp_manager_fops,

	result = misc_register(&ps3dm->misc);
	if (result) {
		dev_err(&dev->core, "%s:%u: misc_register failed %d\n",
			__func__, __LINE__, result);
		goto fail;
	}

	dev_info(&dev->core, "%s:%u: registered misc device %d\n",
		             __func__, __LINE__, ps3dm->misc.minor);

	dev_dbg(&dev->core, "%s:%d\n", __func__, __LINE__);

	return 0;

fail:

	kfree(ps3dm);
	ps3dm = NULL;

	return result;
}

static int ps3_disp_manager_remove(struct ps3_system_bus_device *dev)
{
	dev_dbg(&dev->core, "%s:%d\n", __func__, __LINE__);

	if (ps3dm) {
		misc_deregister(&ps3dm->misc);
		kfree(ps3dm);
		ps3dm = NULL;
	}

	return 0;
}

static void ps3_disp_manager_shutdown(struct ps3_system_bus_device *dev)
{
	dev_dbg(&dev->core, "%s:%d\n", __func__, __LINE__);
}

static struct ps3_vuart_port_driver ps3_disp_manager = {
	.core.match_id = PS3_MATCH_ID_DISP_MANAGER,
	.core.core.name = "ps3_disp_manager",
	.probe = ps3_disp_manager_probe,
	.remove = ps3_disp_manager_remove,
	.shutdown = ps3_disp_manager_shutdown,
};

static int __init ps3_disp_manager_init(void)
{
	if (!firmware_has_feature(FW_FEATURE_PS3_LV1))
		return -ENODEV;

	return ps3_vuart_port_driver_register(&ps3_disp_manager);
}

static void __exit ps3_disp_manager_exit(void)
{
	pr_debug(" -> %s:%d\n", __func__, __LINE__);

	ps3_vuart_port_driver_unregister(&ps3_disp_manager);

	pr_debug(" <- %s:%d\n", __func__, __LINE__);
}

module_init(ps3_disp_manager_init);
module_exit(ps3_disp_manager_exit);

MODULE_AUTHOR("glevand");
MODULE_LICENSE("GPL v2");
MODULE_DESCRIPTION("PS3 Dispatcher Manager");
MODULE_ALIAS(PS3_MODULE_ALIAS_DISP_MANAGER);
