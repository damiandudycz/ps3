/*
 * PS3 Flash Storage Driver
 *
 * Copyright (C) 2007 Sony Computer Entertainment Inc.
 * Copyright 2007 Sony Corp.
 * Copyright (C) 2011 graf_chokolo <grafchokolo@gmail.com>.
 * Copyright (C) 2011-2013 glevand <geoffrey.levand@mail.ru>.
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

#include <linux/blk-mq.h>
#include <linux/slab.h>
#include <linux/module.h>

#include <asm/lv1call.h>
#include <asm/ps3stor.h>
#include <asm/firmware.h>

#define DEVICE_NAME		"ps3flash"

#define BOUNCE_SIZE		(64*1024)

#define PS3FLASH_MAX_NUM_REGS	8
#define PS3FLASH_MINORS		16

#define PS3FLASH_NAME		"ps3flash%c"

struct ps3flash_private {
	spinlock_t lock;		/* Request queue spinlock */
	struct blk_mq_tag_set tag_set[PS3FLASH_MAX_NUM_REGS];
	struct gendisk *gendisk[PS3FLASH_MAX_NUM_REGS];	
	unsigned int blocking_factor;
	struct request *req;
	u64 raw_capacity;
	int is_vflash;
	unsigned char root_queue;
	unsigned char next_queue[PS3FLASH_MAX_NUM_REGS];
};

#define LV1_STORAGE_ATA_FLUSH_CACHE_EXT	(0x31)

static int ps3flash_major;

static const struct block_device_operations ps3flash_fops = {
	.owner		= THIS_MODULE,
};

static unsigned int region_flags[] =
{
	0x6, 0x2, 0x4, 0x4, 0x4, 0x0, 0x2, 0x0,
};
module_param_array(region_flags, uint, NULL, S_IRUGO);
MODULE_PARM_DESC(region_flags, "Region flags");

static void ps3flash_scatter_gather(struct ps3_storage_device *dev,
				   struct request *req, int gather)
{
	unsigned int offset = 0;
	struct req_iterator iter;
	struct bio_vec bvec;
	size_t size;
	rq_for_each_segment(bvec, req, iter) {
		size = bvec.bv_len;
		if (gather)
			memcpy_from_bvec(dev->bounce_buf + offset, &bvec);
		else
			memcpy_to_bvec(&bvec, dev->bounce_buf + offset);			
		offset += size;
	}
}

static blk_status_t ps3flash_submit_request_sg(struct ps3_storage_device *dev,
				     struct request *req)
{
	struct ps3flash_private *priv = ps3_system_bus_get_drvdata(&dev->sbd);
	int write = rq_data_dir(req), res;
	const char *op = write ? "write" : "read";
	u64 start_sector, sectors;
	unsigned int region_idx = MINOR(disk_devt(req->q->disk)) / PS3FLASH_MINORS;
	unsigned int region_id = dev->regions[region_idx].id;
	unsigned int region_flags = dev->regions[region_idx].flags;
#ifdef DEBUG
	unsigned int n = 0;
	struct bio_vec bv;
	struct req_iterator iter;
	rq_for_each_segment(bv, req, iter)
		n++;
	dev_dbg(&dev->sbd.core,
		"%s:%u: %s req has %u bvecs for %u sectors\n",
		__func__, __LINE__, op, n, blk_rq_sectors(req));
#endif
	start_sector = blk_rq_pos(req) * priv->blocking_factor;
	sectors = blk_rq_sectors(req) * priv->blocking_factor;
#ifdef DEBUG
	dev_dbg(&dev->sbd.core, "%s:%u: %s %llu sectors starting at %llu\n",
		__func__, __LINE__, op, sectors, start_sector);
#endif
	if (write) {
		ps3flash_scatter_gather(dev, req, 1);
		res = lv1_storage_write(dev->sbd.dev_id, region_id,
					start_sector, sectors, region_flags,
					dev->bounce_lpar, &dev->tag);
	} else {
		res = lv1_storage_read(dev->sbd.dev_id, region_id,
				       start_sector, sectors, region_flags,
				       dev->bounce_lpar, &dev->tag);
	}
	if (res) {
		dev_err(&dev->sbd.core, "%s:%u: %s failed %d\n", __func__,
			__LINE__, op, res);
		return BLK_STS_IOERR;
	}
	priv->req = req;
	return BLK_STS_OK;
}

static blk_status_t ps3flash_submit_flush_request(struct ps3_storage_device *dev,
					struct request *req)
{
	struct ps3flash_private *priv = ps3_system_bus_get_drvdata(&dev->sbd);
	u64 res;
#ifdef DEBUG
	dev_dbg(&dev->sbd.core, "%s:%u: flush request\n", __func__, __LINE__);
#endif
	res = lv1_storage_send_device_command(dev->sbd.dev_id,
					      LV1_STORAGE_ATA_FLUSH_CACHE_EXT, 0, 0, 0,
					      0, &dev->tag);
	if (res) {
		dev_err(&dev->sbd.core, "%s:%u: sync cache failed 0x%llx\n",
			__func__, __LINE__, res);

		return BLK_STS_IOERR;
	}
	priv->req = req;
	return BLK_STS_OK;
}

static blk_status_t ps3flash_queue_rq(struct blk_mq_hw_ctx *hctx,
				     const struct blk_mq_queue_data *bd)
{
	struct request_queue *q = hctx->queue;
	struct ps3_storage_device *dev = q->queuedata;
	struct ps3flash_private *priv = ps3_system_bus_get_drvdata(&dev->sbd);
	blk_status_t ret = BLK_STS_DEV_RESOURCE;
	spin_lock_irq(&priv->lock);
	if(priv->req) {
		spin_unlock_irq(&priv->lock);
		return ret;
	}
	blk_mq_start_request(bd->rq);	
#ifdef DEBUG
	dev_dbg(&dev->sbd.core, "%s:%u\n", __func__, __LINE__);
#endif
	if (priv->is_vflash && req_op(bd->rq) == REQ_OP_FLUSH) {
		ret = ps3flash_submit_flush_request(dev, bd->rq);
	} else if (req_op(bd->rq) == REQ_OP_READ || req_op(bd->rq) == REQ_OP_WRITE) {
		ret = ps3flash_submit_request_sg(dev, bd->rq);
	} else {
		blk_dump_rq_flags(bd->rq, DEVICE_NAME " bad request");
		ret = BLK_STS_IOERR;
	}
	spin_unlock_irq(&priv->lock);
 	return ret;
}

static irqreturn_t ps3flash_interrupt(int irq, void *data)
{
	struct ps3_storage_device *dev = data;
	struct ps3flash_private *priv;
	struct request *req;
	int res, read, error;
	u64 tag, status;
	const char *op;
	struct gendisk *gdisk;
	int region_idx;	
	res = lv1_storage_get_async_status(dev->sbd.dev_id, &tag, &status);
	if (tag != dev->tag)
		dev_err(&dev->sbd.core,
			"%s:%u: tag mismatch, got %llx, expected %llx\n",
			__func__, __LINE__, tag, dev->tag);
	if (res) {
		dev_err(&dev->sbd.core, "%s:%u: res=%d status=0x%llx\n",
			__func__, __LINE__, res, status);
		return IRQ_HANDLED;
	}
	priv = ps3_system_bus_get_drvdata(&dev->sbd);
	spin_lock(&priv->lock);	
	req = priv->req;
	if (!req) {
		dev_dbg(&dev->sbd.core,
			"%s:%u non-block layer request completed\n", __func__,
			__LINE__);
		dev->lv1_status = status;
		complete(&dev->done);
		spin_unlock(&priv->lock);	
		return IRQ_HANDLED;
	}
	if (req->cmd_flags & RQF_FLUSH_SEQ) {
		read = 0;
		op = "flush";
	} else {
		read = !rq_data_dir(req);
		op = read ? "read" : "write";
	}
	if (status) {
		dev_dbg(&dev->sbd.core, "%s:%u: %s failed 0x%llx\n", __func__,
			__LINE__, op, status);
		error = -EIO;
	} else {
#ifdef DEBUG
		dev_dbg(&dev->sbd.core, "%s:%u: %s completed\n", __func__,
			__LINE__, op);
#endif
		error = 0;
		if (read)
			ps3flash_scatter_gather(dev, req, 0);
	}
	priv->req = NULL;	
	blk_mq_end_request(req, error);	
	region_idx = priv->root_queue;	
	do {
		gdisk = priv->gendisk[region_idx];
		if(gdisk)
			blk_mq_run_hw_queues(gdisk->queue, true);
		region_idx = priv->next_queue[region_idx];
	} while (region_idx != priv->root_queue);
	priv->root_queue = priv->next_queue[priv->root_queue];
	spin_unlock(&priv->lock);	
	return IRQ_HANDLED;
}

static int ps3flash_sync_cache(struct ps3_storage_device *dev)
{
	u64 res;
	dev_dbg(&dev->sbd.core, "%s:%u: sync cache\n", __func__, __LINE__);
	res = ps3stor_send_command(dev, LV1_STORAGE_ATA_FLUSH_CACHE_EXT, 0, 0, 0, 0);
	if (res) {
		dev_err(&dev->sbd.core, "%s:%u: sync cache failed 0x%llx\n",
			__func__, __LINE__, res);
		return -EIO;
	}
	return 0;
}

static const struct blk_mq_ops ps3flash_mq_ops = {
	.queue_rq	= ps3flash_queue_rq,
};

static int ps3flash_probe(struct ps3_system_bus_device *_dev)
{
	struct ps3_storage_device *dev = to_ps3_storage_device(&_dev->core);
	struct ps3flash_private *priv;
	int error;
	unsigned int devidx;
	u64 lpar_id, flash_ext_flag, junk;
	struct queue_limits lim;
	struct request_queue *queue;
	struct gendisk *gendisk;
	BUG_ON(dev->num_regions > PS3FLASH_MAX_NUM_REGS);
	if (dev->blk_size < 512) {
		dev_err(&dev->sbd.core,
			"%s:%u: cannot handle block size %llu\n", __func__,
			__LINE__, dev->blk_size);
		return -EINVAL;
	}
	priv = kzalloc(sizeof(*priv), GFP_KERNEL);
	if (!priv) {
		error = -ENOMEM;
		goto fail;
	}
	ps3_system_bus_set_drvdata(_dev, priv);
	spin_lock_init(&priv->lock);
	dev->bounce_size = BOUNCE_SIZE;
	dev->bounce_buf = kmalloc(BOUNCE_SIZE, GFP_DMA);
	if (!dev->bounce_buf) {
		error = -ENOMEM;
		goto fail_free_priv;
	}
	for (devidx = 0; devidx < dev->num_regions; devidx++) {
		dev->regions[devidx].flags = region_flags[devidx];
		priv->next_queue[devidx] = devidx+1;
	}
	priv->next_queue[dev->num_regions-1] = 0;
	error = ps3stor_setup(dev, ps3flash_interrupt);
	if (error) goto fail_free_bounce;
	priv->raw_capacity = dev->regions[0].size;
	error = lv1_get_logical_partition_id(&lpar_id);
	if (error) goto fail_teardown;
	error = lv1_read_repository_node(1, 0x0000000073797300ul /* sys */,
					    0x666c617368000000ul /* flash */,
					    0x6578740000000000ul /* ext */,
					    0, &flash_ext_flag, &junk);
	if (error) goto fail_teardown;
	priv->is_vflash = !(flash_ext_flag & 0x1);
	dev_info(&dev->sbd.core, "VFLASH is %s\n",
		 priv->is_vflash ? "on" : "off");
	memset(&lim, 0, sizeof(struct queue_limits));
	lim.logical_block_size	= dev->blk_size;
	lim.max_hw_sectors = dev->bounce_size >> 9;
	lim.max_segments = -1;
	lim.max_segment_size	= dev->bounce_size;
	lim.dma_alignment = dev->blk_size - 1;
	for (devidx = 0; devidx < dev->num_regions; devidx++) {
		if (test_bit(devidx, &dev->accessible_regions) == 0)
			continue;
		error = blk_mq_alloc_sq_tag_set(&priv->tag_set[devidx], &ps3flash_mq_ops, 1,
						BLK_MQ_F_SHOULD_MERGE);
		if (error) {
			devidx--;
			goto fail_free_tag_set;
		}		
		gendisk = blk_mq_alloc_disk(&priv->tag_set[devidx], &lim, dev);
		if (IS_ERR(gendisk)) {
			dev_err(&dev->sbd.core, "%s:%u: blk_mq_alloc_disk failed\n",
				__func__, __LINE__);
			error = PTR_ERR(gendisk);
			blk_mq_free_tag_set(&priv->tag_set[devidx]);
			devidx--;
			goto fail_free_tag_set;
		}
		queue = gendisk->queue;	
		blk_queue_write_cache(queue, true, false);
		priv->gendisk[devidx] = gendisk;		
		gendisk->major = ps3flash_major;
		gendisk->first_minor = devidx * PS3FLASH_MINORS;
		gendisk->minors = PS3FLASH_MINORS;		
		gendisk->fops = &ps3flash_fops;
		gendisk->queue = queue;
		gendisk->private_data = dev;		
		snprintf(gendisk->disk_name, sizeof(gendisk->disk_name), PS3FLASH_NAME,
			 devidx+'a');
		priv->blocking_factor = dev->blk_size >> 9;
		set_capacity(gendisk,
		   	 dev->regions[devidx].size*priv->blocking_factor);
		dev_info(&dev->sbd.core,
			 "%s (%llu MiB total, %llu MiB region)\n",
			 gendisk->disk_name, priv->raw_capacity >> 11,
			 get_capacity(gendisk) >> 11);
		error = device_add_disk(&dev->sbd.core, gendisk, NULL);
		if (error)
			goto fail_free_tag_set;
	}	
	return 0;
fail_free_tag_set:
	for (; devidx >=0; devidx--)
		if (priv->gendisk[devidx]) {
			del_gendisk(priv->gendisk[devidx]);
			put_disk(priv->gendisk[devidx]);
			blk_mq_free_tag_set(&priv->tag_set[devidx]);
		}	
fail_teardown:
	ps3stor_teardown(dev);
fail_free_bounce:
	kfree(dev->bounce_buf);
fail_free_priv:
	kfree(priv);
	ps3_system_bus_set_drvdata(_dev, NULL);
fail:
	return error;
}

static void ps3flash_remove(struct ps3_system_bus_device *_dev)
{
	struct ps3_storage_device *dev = to_ps3_storage_device(&_dev->core);
	struct ps3flash_private *priv = ps3_system_bus_get_drvdata(&dev->sbd);
	unsigned int devidx;
	for (devidx = 0; devidx < dev->num_regions; devidx++)
		if (priv->gendisk[devidx]) {
			del_gendisk(priv->gendisk[devidx]);
			put_disk(priv->gendisk[devidx]);
			blk_mq_free_tag_set(&priv->tag_set[devidx]);
		}
	if (priv->is_vflash) {
		dev_notice(&dev->sbd.core, "Synchronizing disk cache\n");
		ps3flash_sync_cache(dev);
	}
	ps3stor_teardown(dev);
	kfree(dev->bounce_buf);
	kfree(priv);
	ps3_system_bus_set_drvdata(_dev, NULL);
}

static struct ps3_system_bus_driver ps3flash = {
	.match_id	= PS3_MATCH_ID_STOR_FLASH,
	.core.name	= DEVICE_NAME,
	.core.owner	= THIS_MODULE,
	.probe		= ps3flash_probe,
	.remove		= ps3flash_remove,
	.shutdown	= ps3flash_remove,
};


static int __init ps3flash_init(void)
{
	int error;
	if (!firmware_has_feature(FW_FEATURE_PS3_LV1))
		return -ENODEV;
	error = register_blkdev(0, DEVICE_NAME);
	if (error <= 0) {
		printk(KERN_ERR "%s:%u: register_blkdev failed %d\n", __func__,
		       __LINE__, error);
		return error;
	}
	ps3flash_major = error;
	pr_info("%s:%u: registered block device major %d\n", __func__,
		__LINE__, ps3flash_major);
	error = ps3_system_bus_driver_register(&ps3flash);
	if (error) unregister_blkdev(ps3flash_major, DEVICE_NAME);
	return error;
}

static void __exit ps3flash_exit(void)
{
	ps3_system_bus_driver_unregister(&ps3flash);
	unregister_blkdev(ps3flash_major, DEVICE_NAME);
}

module_init(ps3flash_init);
module_exit(ps3flash_exit);

MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("PS3 Flash Storage Driver");
