/*
 * PS3 LV1 Call
 *
 * Copyright (C) 2012, 2013 glevand <geoffrey.levand@mail.ru>
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
#include <linux/mm.h>
#include <linux/fs.h>
#include <linux/uaccess.h>
#include <linux/miscdevice.h>

static struct
{
	int num_in_args;
	int num_out_args;
} ps3lv1call_args[256] = {
	[8]	= { 0, 1 },		/* lv1_undocumented_function_8 */
	[44]	= { 1, 0 },		/* lv1_shutdown_logical_partition */
	[91]	= { 5, 2 },		/* lv1_read_repository_node */
	[102]	= { 0, 1 },		/* lv1_undocumented_function_102 */
	[105]	= { 7, 0 },		/* lv1_undocumented_function_105 */
	[106]	= { 1, 0 },		/* lv1_undocumented_function_106 */
	[107]	= { 6, 1 },		/* lv1_undocumented_function_107 */
	[108]	= { 1, 5 },		/* lv1_undocumented_function_108 */
	[109]	= { 1, 0 },		/* lv1_undocumented_function_109 */
	[127]	= { 0, 2 },		/* lv1_get_version_info */
	[194]	= { 6, 2 },		/* lv1_net_control */
	[231]	= { 1, 0 },		/* lv1_undocumented_function_231 */
	[232]	= { 0, 2 },		/* lv1_get_rtc */
	[255]	= { 1, 0 },		/* lv1_panic */
};

extern int generic_lv1call(int num_lv1call, u64 *in_args, u64 *out_args);

static ssize_t ps3lv1call_do_call(char *buf, size_t size)
{
	u64 num_lv1call;
	u64 args[8];
	s64 err;
	int num_args, i, rv;

	if (size < sizeof(u64))
		return (-EINVAL);

	if (size % sizeof(u64))
		return (-EINVAL);

	num_lv1call = *(u64 *) buf;
	if (num_lv1call > 255)
		return (-EINVAL);

	num_args = (size - sizeof(u64)) / sizeof(u64);
	if (num_args > 8)
		return (-EINVAL);

	memset(args, 0, sizeof(args));

	for (i = 0; i < num_args; i++)
		args[i] = *(u64 *) (buf + (i + 1) * sizeof(u64));

	err = generic_lv1call(num_lv1call, args, args);

	rv = sizeof(err);
	memcpy(buf, &err, sizeof(err));

	if (!err) {
		rv += ps3lv1call_args[num_lv1call].num_out_args * sizeof(u64);
		memcpy(buf + sizeof(err), args,
			ps3lv1call_args[num_lv1call].num_out_args * sizeof(u64));
	}

	return (rv);
}

static ssize_t ps3lv1call_write(struct file *file, const char __user *buf,
    size_t size, loff_t *pos)
{
	char *data;
	ssize_t rv;
 
	data = simple_transaction_get(file, buf, size);
	if (IS_ERR(data))
		return PTR_ERR(data);

	rv = ps3lv1call_do_call(data, size);
	if (rv >= 0) {
		simple_transaction_set(file, rv);
		rv = size;
	}

	return (rv);
}

static ssize_t ps3lv1call_read(struct file *file, char __user *buf,
    size_t size, loff_t *pos)
{
	ssize_t rv;

	if (!file->private_data) {
		rv = ps3lv1call_write(file, buf, 0, pos);
		if (rv < 0)
			return (rv);
	}

	return simple_transaction_read(file, buf, size, pos);
}

static int ps3lv1call_open(struct inode *inode, struct file *file)
{
	if(file)
		file->private_data = NULL;
	return 0;
}

static const struct file_operations ps3lv1call_fops = {
	.owner		= THIS_MODULE,
	.open		= ps3lv1call_open,
	.write		= ps3lv1call_write,
	.read		= ps3lv1call_read,
	.release	= simple_transaction_release,
	.llseek		= default_llseek,
};

static struct miscdevice ps3lv1call_misc = {
	.minor	= MISC_DYNAMIC_MINOR,
	.name	= "ps3lv1call",
	.fops	= &ps3lv1call_fops,
};

static int __init ps3lv1call_init(void)
{
	int err;

	err = misc_register(&ps3lv1call_misc);

	return (err);
}

static void __exit ps3lv1call_exit(void)
{
	misc_deregister(&ps3lv1call_misc);
}

module_init(ps3lv1call_init);
module_exit(ps3lv1call_exit);

MODULE_AUTHOR("glevand");
MODULE_DESCRIPTION("PS3 LV1 Call");
MODULE_LICENSE("GPL");
