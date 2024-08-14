/*
 * PS3 ENCDEC Driver
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
#include <linux/sched.h>
#include <linux/mutex.h>
#include <linux/poll.h>
#include <linux/uaccess.h>
#include <linux/compat.h>
#include <linux/miscdevice.h>
#include <linux/sched/signal.h>

#include <asm/ps3.h>
#include <asm/lv1call.h>
#include <asm/ps3stor.h>
#include <asm/firmware.h>

#define DEVICE_NAME		"ps3encdec"

#define BOUNCE_SIZE		(4 * 1024)

struct ps3encdec_private
{
	struct ps3_storage_device *dev;
	struct miscdevice misc;
	char *bounce_wbuf;
	u64 bounce_wlpar;
	char *bounce_rbuf;
	u64 bounce_rlpar;
	struct mutex mtx;
	wait_queue_head_t read_wq;
	wait_queue_head_t write_wq;
	int cmd_done;
	int cmd_failed;
	int cmd_data_avail;
};

static struct ps3encdec_private *ps3encdec_priv;

static ssize_t ps3encdec_read(struct file *file, char __user *usrbuf,
	size_t count, loff_t *pos)
{
	struct ps3encdec_private *priv = ps3encdec_priv;
	int res = 0;

	if (mutex_lock_interruptible(&priv->mtx))
		return (-ERESTARTSYS);

	if (file->f_flags & O_NONBLOCK) {
		if (!priv->cmd_done || priv->cmd_failed)
			res = -EAGAIN;
	} else {
		DEFINE_WAIT(__wait);

		while (1) {
			prepare_to_wait(&priv->read_wq, &__wait, TASK_INTERRUPTIBLE);

			if (priv->cmd_data_avail)
				break;
	
			mutex_unlock(&priv->mtx);

			if (signal_pending(current)) {
				finish_wait(&priv->read_wq, &__wait);
				return (-ERESTARTSYS);
			}

			schedule();

			res = mutex_lock_interruptible(&priv->mtx);
			if (res) {
				finish_wait(&priv->read_wq, &__wait);
				return (res);
			}
		}

		finish_wait(&priv->read_wq, &__wait);
	}

	if (res)
		goto done;

	if (count > BOUNCE_SIZE)
		count = BOUNCE_SIZE;

	if (!count || (priv->cmd_done && priv->cmd_failed))
		goto done;

	if (copy_to_user(usrbuf, priv->bounce_rbuf + *pos, count)) {
		res = -EFAULT;
		goto done;
	}

	priv->cmd_data_avail = 0;

	res = count;

done:

	mutex_unlock(&priv->mtx);

	return (res);
}

static ssize_t ps3encdec_write(struct file *file, const char __user *usrbuf,
	size_t count, loff_t *pos)
{
	struct ps3encdec_private *priv = ps3encdec_priv;
	struct ps3_storage_device *dev = priv->dev;
	u32 cmd;
	int res = 0;

	if (mutex_lock_interruptible(&priv->mtx))
		return (-ERESTARTSYS);

	if (file->f_flags & O_NONBLOCK) {
		if (!priv->cmd_done)
			res = -EAGAIN;
	} else {
		DEFINE_WAIT(__wait);

		while (1) {
			prepare_to_wait(&priv->write_wq, &__wait, TASK_INTERRUPTIBLE);

			if (priv->cmd_done)
				break;
	
			mutex_unlock(&priv->mtx);

			if (signal_pending(current)) {
				finish_wait(&priv->write_wq, &__wait);
				return (-ERESTARTSYS);
			}

			schedule();

			res = mutex_lock_interruptible(&priv->mtx);
			if (res) {
				finish_wait(&priv->write_wq, &__wait);
				return (res);
			}
		}

		finish_wait(&priv->write_wq, &__wait);
	}

	if (res)
		goto done;

	if (count > BOUNCE_SIZE + sizeof(cmd))
		count = BOUNCE_SIZE + sizeof(cmd);

	if (!count)
		goto done;

	if (count < sizeof(cmd)) {
		res = -EINVAL;
		goto done;
	}

	if (copy_from_user(&cmd, usrbuf, sizeof(cmd))) {
		res = -EFAULT;
		goto done;
	}

	if (copy_from_user(priv->bounce_wbuf, usrbuf + sizeof(cmd), count - sizeof(cmd))) {
		res = -EFAULT;
		goto done;
	}

	priv->cmd_done = 0;
	priv->cmd_failed = 1;
	priv->cmd_data_avail = 0;

	res = lv1_storage_send_device_command(dev->sbd.dev_id, cmd,
		priv->bounce_wlpar, count - sizeof(cmd),
		priv->bounce_rlpar, BOUNCE_SIZE, &dev->tag);
	if (res) {
		dev_err(&dev->sbd.core, "%s:%u: res=%d\n",
			__func__, __LINE__, res);
		priv->cmd_done = 1;
		res = -EIO;
		goto done;
	}

	res = count;

done:

	mutex_unlock(&priv->mtx);

	return (res);
}

static unsigned int ps3encdec_poll(struct file *file, poll_table *wait)
{
	struct ps3encdec_private *priv = ps3encdec_priv;
	unsigned int mask = 0;

	mutex_lock(&priv->mtx);

	poll_wait(file, &priv->read_wq, wait);
	poll_wait(file, &priv->write_wq, wait);

	if (priv->cmd_data_avail)
		mask |= POLLIN | POLLRDNORM;

	if (priv->cmd_done)
		mask |= POLLOUT | POLLWRNORM;

	mutex_unlock(&priv->mtx);

	return (mask);
}

static irqreturn_t ps3encdec_interrupt(int irq, void *data)
{
	struct ps3_storage_device *dev = data;
	struct ps3encdec_private *priv;
	u64 tag, status;
	int res;

	res = lv1_storage_get_async_status(dev->sbd.dev_id, &tag, &status);

	pr_info("%s:%d: res=%d status=%llx\n", __func__, __LINE__, res, status);

	if (tag != dev->tag) {
		dev_err(&dev->sbd.core,
			"%s:%u: tag mismatch, got %llx, expected %llx\n",
			__func__, __LINE__, tag, dev->tag);
	}

	if (res) {
		dev_err(&dev->sbd.core, "%s:%u: res=%d status=0x%llx\n",
			__func__, __LINE__, res, status);
		return (IRQ_HANDLED);
	}

	priv = ps3_system_bus_get_drvdata(&dev->sbd);

	priv->cmd_done = 1;
	priv->cmd_failed = (status != 0);
	priv->cmd_data_avail = !priv->cmd_failed;

	wake_up_interruptible(&priv->read_wq);
	wake_up_interruptible(&priv->write_wq);

	return (IRQ_HANDLED);
}

static const struct file_operations ps3encdec_fops = {
	.owner = THIS_MODULE,
	.open = nonseekable_open,
	.read = ps3encdec_read,
	.write = ps3encdec_write,
	.poll = ps3encdec_poll,
};

static int ps3encdec_probe(struct ps3_system_bus_device *_dev)
{
	struct ps3_storage_device *dev = to_ps3_storage_device(&_dev->core);
	struct ps3encdec_private *priv;
	int res;

	priv = kzalloc(sizeof(*priv), GFP_KERNEL);
	if (!priv)
		return (-ENOMEM);

	ps3_system_bus_set_drvdata(_dev, priv);

	dev->bounce_size = BOUNCE_SIZE * 2;
	dev->bounce_buf = kmalloc(dev->bounce_size, GFP_DMA);
	if (!dev->bounce_buf) {
		res = -ENOMEM;
		goto fail_free_priv;
	}

	res = ps3stor_setup(dev, ps3encdec_interrupt);
	if (res)
		goto fail_free_bounce;

	mutex_init(&priv->mtx);

	init_waitqueue_head(&priv->read_wq);
	init_waitqueue_head(&priv->write_wq);

	priv->cmd_done = 1;
	priv->cmd_failed = 0;
	priv->cmd_data_avail = 0;

	priv->misc.minor = MISC_DYNAMIC_MINOR,
	priv->misc.name	= DEVICE_NAME,
	priv->misc.fops	= &ps3encdec_fops,

	res = misc_register(&priv->misc);
	if (res)
		goto fail_teardown;

	priv->dev = dev;
	priv->bounce_wbuf = dev->bounce_buf;
	priv->bounce_wlpar = dev->bounce_lpar;
	priv->bounce_rbuf = dev->bounce_buf + BOUNCE_SIZE;
	priv->bounce_rlpar = dev->bounce_lpar + BOUNCE_SIZE;

	ps3encdec_priv = priv;

	return (0);

fail_teardown:

	ps3stor_teardown(dev);

fail_free_bounce:

	kfree(dev->bounce_buf);

fail_free_priv:

	kfree(priv);
	ps3_system_bus_set_drvdata(_dev, NULL);

	return (res);
}

static void ps3encdec_remove(struct ps3_system_bus_device *_dev)
{
	struct ps3_storage_device *dev = to_ps3_storage_device(&_dev->core);
	struct ps3encdec_private *priv = ps3_system_bus_get_drvdata(&dev->sbd);

	ps3encdec_priv = NULL;

	misc_deregister(&priv->misc);
	ps3stor_teardown(dev);
	kfree(dev->bounce_buf);
	kfree(priv);
	ps3_system_bus_set_drvdata(_dev, NULL);


}

static struct ps3_system_bus_driver ps3encdec = {
	.match_id	= PS3_MATCH_ID_STOR_ENCDEC,
	.core.name	= DEVICE_NAME,
	.core.owner	= THIS_MODULE,
	.probe		= ps3encdec_probe,
	.remove		= ps3encdec_remove,
	.shutdown	= ps3encdec_remove,
};

static int __init ps3encdec_init(void)
{
	int res;

	if (!firmware_has_feature(FW_FEATURE_PS3_LV1))
		return (-ENODEV);

	res = ps3_system_bus_driver_register(&ps3encdec);

	return (res);
}

static void __exit ps3encdec_exit(void)
{
	ps3_system_bus_driver_unregister(&ps3encdec);
}

module_init(ps3encdec_init);
module_exit(ps3encdec_exit);

MODULE_AUTHOR("glevand");
MODULE_DESCRIPTION("PS3 ENCDEC Driver");
MODULE_LICENSE("GPL");
