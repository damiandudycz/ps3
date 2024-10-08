/*
 * PS3 Physical Memory Driver
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
#include <linux/version.h>
#include <linux/init.h>
#include <linux/mm.h>
#include <linux/fs.h>
#include <linux/uaccess.h>
#include <linux/miscdevice.h>

#include <asm/io.h>
#include <asm/ps3.h>
#include <asm/lv1call.h>

static unsigned long ps3physmem_start = 0;
module_param(ps3physmem_start, ulong, 0);

static unsigned long ps3physmem_size = 256 * 1024 * 1024;
module_param(ps3physmem_size, ulong, 0);

static unsigned long ps3physmem_pagesize = 24;	/* 16MB */
module_param(ps3physmem_pagesize, ulong, 0);

static u64 ps3physmem_lpar;
static char *ps3physmem_virt;

static ssize_t ps3physmem_read(struct file *file, char __user *usrbuf,
    size_t count, loff_t *pos)
{
	if (*pos + count > ps3physmem_size)
		count = ps3physmem_size - *pos;

	if (!count)
		return (0);

	if (copy_to_user(usrbuf, ps3physmem_virt + *pos, count))
		return (-EFAULT);

	*pos += count;

	return (count);
}

static ssize_t ps3physmem_write(struct file *file, const char __user *usrbuf,
    size_t count, loff_t *pos)
{
	if (*pos + count > ps3physmem_size)
		count = ps3physmem_size - *pos;

	if (!count)
		return (0);

	if (copy_from_user(ps3physmem_virt + *pos, usrbuf, count))
		return (-EFAULT);

	*pos += count;

	return (count);
}

static loff_t ps3physmem_llseek(struct file *file, loff_t off, int whence)
{
	loff_t newpos;

	switch(whence) {
	case 0: /* SEEK_SET */
		newpos = off;
	break;
	case 1: /* SEEK_CUR */
		newpos = file->f_pos + off;
	break;
	case 2: /* SEEK_END */
		newpos = ps3physmem_size + off;
	break;
	default: /* can't happen */
		return (-EINVAL);
	}

	if (newpos < 0)
		return (-EINVAL);

	file->f_pos = newpos;

	return (newpos);
}

static void ps3physmem_vma_open(struct vm_area_struct *vma)
{
}

static void ps3physmem_vma_close(struct vm_area_struct *vma)
{
}

static struct vm_operations_struct ps3physmem_vm_ops = {
	.open = ps3physmem_vma_open,
	.close = ps3physmem_vma_close,
};

static int ps3physmem_mmap(struct file *file, struct vm_area_struct *vma)
{
	unsigned long size, pfn;
	int res;

	size = vma->vm_end - vma->vm_start;

	if (((vma->vm_pgoff << PAGE_SHIFT) + size) > ps3physmem_size)
		return (-EINVAL);

#if LINUX_VERSION_CODE >= KERNEL_VERSION(3,7,0)
	vm_flags_set(vma, vma->vm_flags |  VM_DONTEXPAND | VM_DONTDUMP | VM_IO);
#else
	vm_flags_set(vma, vma->vm_flags | VM_RESERVED | VM_IO);
#endif
	vma->vm_page_prot = pgprot_noncached(vma->vm_page_prot);

	pfn = (ps3physmem_lpar >> PAGE_SHIFT) + vma->vm_pgoff;

	res = io_remap_pfn_range(vma, vma->vm_start, pfn, size,
	    vma->vm_page_prot);
	if (res)
		return (res);

	vma->vm_ops = &ps3physmem_vm_ops;

	ps3physmem_vma_open(vma);

	return (0);
}

static const struct file_operations ps3physmem_fops = {
	.owner = THIS_MODULE,
	.read = ps3physmem_read,
	.write = ps3physmem_write,
	.llseek = ps3physmem_llseek,
	.mmap = ps3physmem_mmap,
};

static struct miscdevice ps3physmem_misc = {
	.minor	= MISC_DYNAMIC_MINOR,
	.name	= "ps3physmem",
	.fops	= &ps3physmem_fops,
};

static int __init ps3physmem_init(void)
{
	int res;

	res = lv1_undocumented_function_114(ps3physmem_start,
	    ps3physmem_pagesize, ps3physmem_size, &ps3physmem_lpar);
	if (res) {
		pr_info("%s:%u: lv1_undocumented_function_114 failed %d\n",
		    __func__, __LINE__, res);
		return (-ENXIO);
	}

	ps3physmem_virt = ioremap_wc(ps3physmem_lpar, ps3physmem_size);
	if (!ps3physmem_virt) {
		pr_info("%s:%u: ioremap_wc failed\n", __func__, __LINE__);
		goto destroy_lpar;
	}

	res = misc_register(&ps3physmem_misc);
	if (res) {
		pr_info("%s:%u: misc_register failed %d\n",
		    __func__, __LINE__, res);
		goto unmap_lpar;
	}

	return (0);

unmap_lpar:

	iounmap((void *) ps3physmem_virt);

destroy_lpar:

	lv1_undocumented_function_115(ps3physmem_lpar);

	return (res);
}

static void __exit ps3physmem_exit(void)
{
	misc_deregister(&ps3physmem_misc);

	iounmap((void *) ps3physmem_virt);

	lv1_undocumented_function_115(ps3physmem_lpar);
}

module_init(ps3physmem_init);
module_exit(ps3physmem_exit);

MODULE_AUTHOR("glevand");
MODULE_DESCRIPTION("PS3 Physical Memory Driver");
MODULE_LICENSE("GPL");
