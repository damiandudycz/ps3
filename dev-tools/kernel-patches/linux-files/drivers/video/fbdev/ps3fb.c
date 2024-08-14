/*
 *  linux/drivers/video/ps3fb.c -- PS3 GPU frame buffer device
 *
 *	Copyright (C) 2021-2024 René Rebe <rene@exactcode.de>
 *	Copyright (C) 2006 Sony Computer Entertainment Inc.
 *	Copyright 2006, 2007 Sony Corporation
 *	Copyright 2018-2023 René Rebe
 *
 *  This file is based on :
 *
 *  linux/drivers/video/vfb.c -- Virtual frame buffer device
 *
 *	Copyright (C) 2002 James Simmons
 *
 *	Copyright (C) 1997 Geert Uytterhoeven
 *
 *  This file is subject to the terms and conditions of the GNU General Public
 *  License. See the file COPYING in the main directory of this archive for
 *  more details.
 */

/*
 * Based on NV47 (Nvidia GeForce 7800 architecture)
 * 256 MB GDDR3 RAM at 650 MHz
 * 256 MB XDR DRAM is system memory!
 * we have 3 memory ranges
 * 1: FB
 * 2: dma/fifo ctrl
 * 3: fifo cmd ring buffer
 * DMA object handles: 0xfeed0000 RSX DDR, 0xfeed0001 targets system XDR memory
 */

#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/errno.h>
#include <linux/string.h>
#include <linux/mm.h>
#include <linux/interrupt.h>
#include <linux/console.h>
#include <linux/ioctl.h>
#include <linux/freezer.h>
#include <linux/uaccess.h>
#include <linux/fb.h>
#include <linux/fbcon.h>
#include <linux/init.h>

#include <asm/cell-regs.h>
#include <asm/lv1call.h>
#include <asm/ps3av.h>
#include <asm/ps3fb.h>
#include <asm/ps3.h>
#include <asm/ps3gpu.h>


#define DEVICE_NAME		"ps3fb"

#define DDR_SIZE				(0x0fc00000UL)
#define GPU_CMD_BUF_SIZE			(2 * 1024 * 1024)
#define GPU_FB_START				(64 * 1024)
#define GPU_IOIF				(0x0d000000UL)
#define GPU_CTRL_SIZE				(4096)
#define GPU_ALIGN_UP(x)				ALIGN((x), 64)
#define GPU_MAX_LINE_LENGTH			(65536 - 64)

#define GPU_INTR_STATUS_VSYNC_0			0	/* vsync on head A */
#define GPU_INTR_STATUS_VSYNC_1			1	/* vsync on head B */
#define GPU_INTR_STATUS_GRAPH_EXCEPTION	2	/* graphics exception */
#define GPU_INTR_STATUS_FLIP_0			3	/* flip head A */
#define GPU_INTR_STATUS_FLIP_1			4	/* flip head B */
#define GPU_INTR_STATUS_QUEUE_0			5	/* queue head A */
#define GPU_INTR_STATUS_QUEUE_1			6	/* queue head B */

#define GPU_DRIVER_INFO_VERSION			0x211

/* gpu internals */
struct display_head {
	u64 be_time_stamp;
	u32 status;
	u32 offset;
	u32 res1;
	u32 res2;
	u32 field;
	u32 reserved1;

	u64 res3;
	u32 raster;

	u64 vblank_count;
	u32 field_vsync;
	u32 reserved2;
};

struct gpu_graph_exception_info {
	u32 channel_id;
	u32 cause;
	u32 res1[8];
	u32 dma_put;
	u32 dma_get;
	u32 call;
	u32 jump;
	u32 res2;
	u32 fifo_put;
	u32 fifo_get;
	u32 fifo_ref;
	u32 fifo_cache[512];
	u32 graph_fifo[512];
};

struct gpu_irq {
	u32 irq_outlet;
	u32 status;
	u32 mask;
	u32 video_cause;
	u32 graph_cause;
	u32 user_cause;
	u32 res[8];
	struct gpu_graph_exception_info graph_exception_info;
};

struct gpu_driver_info {
	u32 version_driver;
	u32 version_gpu;
	u32 memory_size;
	u32 hardware_channel;

	u32 nvcore_frequency;
	u32 memory_frequency;

	u32 reserved[1063];
	struct display_head display_head[8];
	struct gpu_irq irq;
};

struct gpu_fifo_ctrl {
	u8 res[64];
	u32 put;
	u32 get;
	u32 ref;
};

struct gpu_fifo {
	volatile struct gpu_fifo_ctrl *ctrl;
	u32 *start;
	u32 *curr;
	unsigned int len;
	u32 ioif;
};

struct ps3fb_priv {
	unsigned int irq_no;

	u64 context_handle, memory_handle;
	struct gpu_driver_info *dinfo;
	struct gpu_fifo fifo;

  	u64 vram_lpar;
	u64 vram_size;
  	//u64 fifo_lpar;
	//u64 fifo_size;
  	u64 ctrl_lpar;
	u64 ctrl_size;
  
	u64 vblank_count;	/* frame count */
	wait_queue_head_t wait_vsync;
  
	atomic_t ext_flip;	/* on/off flip with vsync */
	atomic_t f_count;	/* fb_open count */
	int is_blanked;
};
static struct ps3fb_priv ps3fb;
static int ps3fb_gpu_major;

struct ps3fb_par {
	u32 pseudo_palette[16];
	int mode_id, new_mode_id;
	unsigned int num_frames;	/* num of frame buffers */
	unsigned int width;
	unsigned int height;
	unsigned int ddr_line_length;
	unsigned int ddr_frame_size;
	unsigned int full_offset;	/* start of fullscreen DDR fb */
	unsigned int fb_offset;		/* start of actual DDR fb */
	unsigned int pan_offset;
};


#define FIRST_NATIVE_MODE_INDEX	10

static const struct fb_videomode ps3fb_modedb[] = {
    /* 60 Hz broadcast modes (modes "1" to "5") */
    {
        /* 480i */
        "480i", 60, 576, 384, 74074, 130, 89, 78, 57, 63, 6,
        FB_SYNC_BROADCAST, FB_VMODE_INTERLACED
    },    {
        /* 480p */
        "480p", 60, 576, 384, 37037, 130, 89, 78, 57, 63, 6,
        FB_SYNC_BROADCAST, FB_VMODE_NONINTERLACED
    },    {
        /* 720p */
        "720p", 60, 1124, 644, 13481, 298, 148, 57, 44, 80, 5,
        FB_SYNC_BROADCAST, FB_VMODE_NONINTERLACED
    },    {
        /* 1080i */
        "1080i", 60, 1688, 964, 13481, 264, 160, 94, 62, 88, 5,
        FB_SYNC_BROADCAST, FB_VMODE_INTERLACED
    },    {
        /* 1080p */
        "1080p", 60, 1688, 964, 6741, 264, 160, 94, 62, 88, 5,
        FB_SYNC_BROADCAST, FB_VMODE_NONINTERLACED
    },

    /* 50 Hz broadcast modes (modes "6" to "10") */
    {
        /* 576i */
        "576i", 50, 576, 460, 74074, 142, 83, 97, 63, 63, 5,
        FB_SYNC_BROADCAST, FB_VMODE_INTERLACED
    },    {
        /* 576p */
        "576p", 50, 576, 460, 37037, 142, 83, 97, 63, 63, 5,
        FB_SYNC_BROADCAST, FB_VMODE_NONINTERLACED
    },    {
        /* 720p */
        "720p", 50, 1124, 644, 13468, 298, 478, 57, 44, 80, 5,
        FB_SYNC_BROADCAST, FB_VMODE_NONINTERLACED
    },    {
        /* 1080i */
        "1080i", 50, 1688, 964, 13468, 264, 600, 94, 62, 88, 5,
        FB_SYNC_BROADCAST, FB_VMODE_INTERLACED
    },    {
        /* 1080p */
        "1080p", 50, 1688, 964, 6734, 264, 600, 94, 62, 88, 5,
        FB_SYNC_BROADCAST, FB_VMODE_NONINTERLACED
    },

    [FIRST_NATIVE_MODE_INDEX] =
    /* 60 Hz broadcast modes (full resolution versions of modes "1" to "5") */
    {
	/* 480if */
	"480if", 60, 720, 480, 74074, 58, 17, 30, 9, 63, 6,
	FB_SYNC_BROADCAST, FB_VMODE_INTERLACED
    }, {
	/* 480pf */
	"480pf", 60, 720, 480, 37037, 58, 17, 30, 9, 63, 6,
	FB_SYNC_BROADCAST, FB_VMODE_NONINTERLACED
    }, {
	/* 720pf */
	"720pf", 60, 1280, 720, 13481, 220, 70, 19, 6, 80, 5,
	FB_SYNC_BROADCAST, FB_VMODE_NONINTERLACED
    }, {
	/* 1080if */
	"1080if", 60, 1920, 1080, 13481, 148, 44, 36, 4, 88, 5,
	FB_SYNC_BROADCAST, FB_VMODE_INTERLACED
    }, {
	/* 1080pf */
	"1080pf", 60, 1920, 1080, 6741, 148, 44, 36, 4, 88, 5,
	FB_SYNC_BROADCAST, FB_VMODE_NONINTERLACED
    },

    /* 50 Hz broadcast modes (full resolution versions of modes "6" to "10") */
    {
	/* 576if */
	"576if", 50, 720, 576, 74074, 70, 11, 39, 5, 63, 5,
	FB_SYNC_BROADCAST, FB_VMODE_INTERLACED
    }, {
	/* 576pf */
	"576pf", 50, 720, 576, 37037, 70, 11, 39, 5, 63, 5,
	FB_SYNC_BROADCAST, FB_VMODE_NONINTERLACED
    }, {
	/* 720pf */
	"720pf", 50, 1280, 720, 13468, 220, 400, 19, 6, 80, 5,
	FB_SYNC_BROADCAST, FB_VMODE_NONINTERLACED
    }, {
	/* 1080if */
	"1080if", 50, 1920, 1080, 13468, 148, 484, 36, 4, 88, 5,
	FB_SYNC_BROADCAST, FB_VMODE_INTERLACED
    }, {
	/* 1080pf */
	"1080pf", 50, 1920, 1080, 6734, 148, 484, 36, 4, 88, 5,
	FB_SYNC_BROADCAST, FB_VMODE_NONINTERLACED
    },

    /* VESA modes (modes "11" to "13") */
    {
	/* WXGA */
	"wxga", 60, 1280, 768, 12924, 160, 24, 29, 3, 136, 6,
	0, FB_VMODE_NONINTERLACED,
	FB_MODE_IS_VESA
    }, {
	/* SXGA */
	"sxga", 60, 1280, 1024, 9259, 248, 48, 38, 1, 112, 3,
	FB_SYNC_HOR_HIGH_ACT | FB_SYNC_VERT_HIGH_ACT, FB_VMODE_NONINTERLACED,
	FB_MODE_IS_VESA
    }, {
	/* WUXGA */
	"wuxga", 60, 1920, 1200, 6494, 80, 48, 26, 3, 32, 6,
	FB_SYNC_HOR_HIGH_ACT, FB_VMODE_NONINTERLACED,
	FB_MODE_IS_VESA
    }
};


#define HEAD_A
#define HEAD_B

#define BPP		4			/* number of bytes per pixel */


static int ps3fb_mode;
module_param(ps3fb_mode, int, 0);

static unsigned long ps3fb_gpu_ctx_flags = 0x820;
module_param(ps3fb_gpu_ctx_flags, ulong, 0);

static unsigned long ps3fb_gpu_mem_size[4];
static int ps3fb_gpu_mem_size_count;
module_param_array(ps3fb_gpu_mem_size, ulong, &ps3fb_gpu_mem_size_count, 0);

static char *mode_option;

static int ps3fb_fb_setup(struct device *dev,
			  u64 context_handle,
			  struct gpu_fifo *fifo)
{
	/* FIFO program for L1GPU_CONTEXT_ATTRIBUTE_FB_SETUP from LV1 */
	const static u32 fifo_setup_program[] = {
		0x00042000,
		0x31337303,

		0x00042180,
		0x66604200,

		0x00082184,
		0xFEED0001,
		0xFEED0000,

		0x00044000,
		0x3137C0DE,

		0x00044180,
		0x66604200,

		0x00084184,
		0xFEED0000,
		0xFEED0001,

		0x00046000,
		0x313371C3,

		0x00046180,
		0x66604200,

		0x00046184,
		0xFEED0000,

		0x00046188,
		0xFEED0000,

		0x0004A000,
		0x31337808,

		0x0020A180,
		0x66604200,
		0x00000000,
		0x00000000,
		0x00000000,
		0x00000000,
		0x00000000,
		0x00000000,
		0x313371C3,

		0x0008A2FC,
		0x00000003,
		0x00000004,

		0x00048000,
		0x31337A73,

		0x00048180,
		0x66604200,

		0x00048184,
		0xFEED0000,

		0x0004C000,
		0x3137AF00,

		0x0004C180,
		0x66604200,

		0x00000000,
	};
	int retval = 0;
	int status;
	volatile struct gpu_fifo_ctrl *fifo_ctrl = fifo->ctrl;
	u32 *fifo_prev = fifo->curr;
	unsigned int timeout;

	pr_debug("%s: enter\n", __func__);

	/* copy setup program to FIFO */

	pr_debug("fifo start: %p len: %x curr: %p\n", fifo->start, fifo->len, fifo->curr);
	memcpy(fifo->curr, fifo_setup_program, sizeof(fifo_setup_program));
	fifo->curr += sizeof(fifo_setup_program) / sizeof(u32);

	/* set PUT and GET registers */
	status = lv1_gpu_context_attribute(context_handle,
					   L1GPU_CONTEXT_ATTRIBUTE_FIFO_SETUP,
					   fifo->ioif,		/* PUT */
					   fifo->ioif,		/* GET */
					   0,			/* REF */
					   0);
	if (status) {
		dev_err(dev, "%s: lv1_gpu_context_attribute failed (%d)\n",
			__func__, status);
		retval = -ENXIO;
		goto done;
	}

	/* kick FIFO */
	fifo_ctrl->put += (fifo->curr - fifo_prev) * sizeof(u32);

	/* wait until FIFO is done */
	timeout = 100000;
	while (timeout--) {
		if (fifo_ctrl->put == fifo_ctrl->get)
			break;
	}

	if (fifo_ctrl->put != fifo_ctrl->get)
		retval = -ETIMEDOUT;

done:

	pr_debug("%s: leave (%d)\n", __func__, retval);

	return retval;
}

static int ps3fb_fb_blit(struct gpu_fifo *fifo,
			 u64 dst_offset, u64 src_offset,
			 u32 width, u32 height,
			 u32 dst_pitch, u32 src_pitch,
			 u64 flags)
{
#define BLEN	0x400UL

	int retval = 0;
	volatile struct gpu_fifo_ctrl *fifo_ctrl = fifo->ctrl;
	u32 *fifo_prev = fifo->curr;
	unsigned int timeout;
	u32 h, w, x, y, dx, dy;

	//pr_debug("%s: enter\n", __func__);

	/* check if there is enough free space in FIFO */
	if ((fifo->len - ((fifo->curr - fifo->start) * sizeof(u32))) < 0x1000) {
		/* no, jump back to FIFO start */

		pr_debug("%s: not enough free space left in FIFO put (0x%08x) get (0x%08x)\n",
			__func__, fifo_ctrl->put, fifo_ctrl->get);

		*fifo->curr++ = 0x20000000 /* JMP */ | fifo->ioif;

		/* kick FIFO */
		fifo_ctrl->put = fifo->ioif;

		/* wait until FIFO is done */
		timeout = 100000;
		while (timeout--) {
			if (fifo_ctrl->put == fifo_ctrl->get)
				break;
		}

		if (fifo_ctrl->put != fifo_ctrl->get) {
			retval = -ETIMEDOUT;
			goto done;
		}

		fifo->curr = fifo->start;
		fifo_prev = fifo->curr;
	}

	/* FIFO program for L1GPU_CONTEXT_ATTRIBUTE_FB_BLIT from LV1 (transfer image) */

	/* set source location */
	*fifo->curr++ = 0x0004C184;
	*fifo->curr++ = 0xFEED0001; /* GART memory */

	*fifo->curr++ = 0x0004C198;
	*fifo->curr++ = 0x313371C3;

	*fifo->curr++ = 0x00046300;
	*fifo->curr++ = 0x0000000A; /* 4 bytes per pixel */

	/*
	 * Transfer data in a block-wise fashion with block size 1024x1024x4 bytes
	 * by using RSX DMA controller. Go from top to bottom and from left to right.
	 */

	h = height;
	y = 0;

	while (h) {
		dy = (h <= BLEN) ? h : BLEN;

		w = width;
		x = 0;

		while (w) {
			dx = (w <= BLEN) ? w : BLEN;

			*fifo->curr++ = 0x0004630C;
			*fifo->curr++ = dst_offset + (y & ~(BLEN - 1)) * dst_pitch + (x & ~(BLEN - 1)) * BPP; /* destination */

			*fifo->curr++ = 0x00046304;
			*fifo->curr++ = (dst_pitch << 16) | dst_pitch;

			*fifo->curr++ = 0x0024C2FC;
			*fifo->curr++ = 0x00000001;
			*fifo->curr++ = 0x00000003; /* 4 bytes per pixel */
			*fifo->curr++ = 0x00000003;
			*fifo->curr++ = ((x & (BLEN - 1)) << 16) | (y & (BLEN - 1));
			*fifo->curr++ = (dy << 16) | dx;
			*fifo->curr++ = ((x & (BLEN - 1)) << 16) | (y & (BLEN - 1));
			*fifo->curr++ = (dy << 16) | dx;
			*fifo->curr++ = 0x00100000;
			*fifo->curr++ = 0x00100000;

			*fifo->curr++ = 0x0010C400;
			*fifo->curr++ = (dy << 16) | ((dx < 0x10) ? 0x10 : (dx + 1) & ~0x1);
			*fifo->curr++ = 0x00020000 | src_pitch;
			*fifo->curr++ = src_offset + y * src_pitch + x * BPP; /* source */
			*fifo->curr++ = 0x00000000;

			w -= dx;
			x += dx;
		}

		h -= dy;
		y += dy;
	}

#if 0
	/* wait for idle  */
	*fifo->curr++ = 0x00040110;
	*fifo->curr++ = 0x00000000;
#endif

	/* kick FIFO */
	fifo_ctrl->put += (fifo->curr - fifo_prev) * sizeof(u32);

	/* wait until FIFO is done */
	if (flags & L1GPU_FB_BLIT_WAIT_FOR_COMPLETION) {
		timeout = 100000;
		while (timeout--) {
			if (fifo_ctrl->put == fifo_ctrl->get)
				break;
		}

		if (fifo_ctrl->put != fifo_ctrl->get)
			retval = -ETIMEDOUT;
	}

done:

	pr_debug("%s: leave (%d)\n", __func__, retval);

	return retval;

#undef BLEN
}

static void ps3fb_print_graph_exception_info(struct device *dev,
					     struct gpu_graph_exception_info *info)
{
	int i;

	dev_err(dev, "channel id 0x%08x cause 0x%08x\n", info->channel_id, info->cause);

	/* print FIFO info */

	dev_err(dev, "fifo:\n");
	dev_err(dev, "\tdma get 0x%08x dma put 0x%08x\n",
		info->dma_get, info->dma_put);
	dev_err(dev, "\tcall 0x%08x jump 0x%08x\n", info->call, info->jump);
	dev_err(dev, "\tget 0x%08x put 0x%08x ref 0x%08x\n",
		info->fifo_get, info->fifo_put, info->fifo_ref);

	for (i = 0; i < 512; i += 4) {
		dev_err(dev, "\t%s %s [%03x] %08x:%08x %08x:%08x %08x:%08x %08x:%08x\n",
			(((info->fifo_put & ~0x3) == i) ? "P" : " "),
			(((info->fifo_get & ~0x3) == i) ? "G" : " "),
			i,
			info->fifo_cache[i * 4 + 0], info->graph_fifo[i * 4 + 0],
			info->fifo_cache[i * 4 + 1], info->graph_fifo[i * 4 + 1],
			info->fifo_cache[i * 4 + 2], info->graph_fifo[i * 4 + 2],
			info->fifo_cache[i * 4 + 3], info->graph_fifo[i * 4 + 3]);
	}
}

static int ps3fb_cmp_mode(const struct fb_videomode *vmode,
			  const struct fb_var_screeninfo *var)
{
	long xres, yres, left_margin, right_margin, upper_margin, lower_margin;
	long dx, dy;

	/* maximum values */
	if (var->xres > vmode->xres || var->yres > vmode->yres ||
	    var->pixclock > vmode->pixclock ||
	    var->hsync_len > vmode->hsync_len ||
	    var->vsync_len > vmode->vsync_len)
		return -1;

	/* progressive/interlaced must match */
	if ((var->vmode & FB_VMODE_MASK) != vmode->vmode)
		return -1;

	/* minimum resolution */
	xres = max(var->xres, 1U);
	yres = max(var->yres, 1U);

	/* minimum margins */
	left_margin = max(var->left_margin, vmode->left_margin);
	right_margin = max(var->right_margin, vmode->right_margin);
	upper_margin = max(var->upper_margin, vmode->upper_margin);
	lower_margin = max(var->lower_margin, vmode->lower_margin);

	/* resolution + margins may not exceed native parameters */
	dx = ((long)vmode->left_margin + (long)vmode->xres +
	      (long)vmode->right_margin) -
	     (left_margin + xres + right_margin);
	if (dx < 0)
		return -1;

	dy = ((long)vmode->upper_margin + (long)vmode->yres +
	      (long)vmode->lower_margin) -
	     (upper_margin + yres + lower_margin);
	if (dy < 0)
		return -1;

	/* exact match */
	if (!dx && !dy)
		return 0;

	/* resolution difference */
	return (vmode->xres - xres) * (vmode->yres - yres);
}

static const struct fb_videomode *ps3fb_native_vmode(enum ps3av_mode_num id)
{
	return &ps3fb_modedb[FIRST_NATIVE_MODE_INDEX + id - 1];
}

static const struct fb_videomode *ps3fb_vmode(int id)
{
	u32 mode = id & PS3AV_MODE_MASK;

	if (mode < PS3AV_MODE_480I || mode > PS3AV_MODE_WUXGA)
		return NULL;

	if (mode <= PS3AV_MODE_1080P50 && !(id & PS3AV_MODE_FULL)) {
		/* Non-fullscreen broadcast mode */
		return &ps3fb_modedb[mode - 1];
	}

	return ps3fb_native_vmode(mode);
}

static unsigned int ps3fb_find_mode(struct fb_var_screeninfo *var,
				    u32 *ddr_line_length)
{
	unsigned int id, best_id;
	int diff, best_diff;
	const struct fb_videomode *vmode;
	long gap;

	best_id = 0;
	best_diff = INT_MAX;
	pr_debug("%s: wanted %u [%u] %u x %u [%u] %u\n", __func__,
		 var->left_margin, var->xres, var->right_margin,
		 var->upper_margin, var->yres, var->lower_margin);
	for (id = PS3AV_MODE_480I; id <= PS3AV_MODE_WUXGA; id++) {
		vmode = ps3fb_native_vmode(id);
		diff = ps3fb_cmp_mode(vmode, var);
		pr_debug("%s: mode %u: %u [%u] %u x %u [%u] %u: diff = %d\n",
			 __func__, id, vmode->left_margin, vmode->xres,
			 vmode->right_margin, vmode->upper_margin,
			 vmode->yres, vmode->lower_margin, diff);
		if (diff < 0)
			continue;
		if (diff < best_diff) {
			best_id = id;
			if (!diff)
				break;
			best_diff = diff;
		}
	}

	if (!best_id) {
		pr_debug("%s: no suitable mode found\n", __func__);
		return 0;
	}

	id = best_id;
	vmode = ps3fb_native_vmode(id);

	*ddr_line_length = vmode->xres * BPP;

	/* minimum resolution */
	if (!var->xres)
		var->xres = 1;
	if (!var->yres)
		var->yres = 1;

	/* minimum virtual resolution */
	if (var->xres_virtual < var->xres)
		var->xres_virtual = var->xres;
	if (var->yres_virtual < var->yres)
		var->yres_virtual = var->yres;

	/* minimum margins */
	if (var->left_margin < vmode->left_margin)
		var->left_margin = vmode->left_margin;
	if (var->right_margin < vmode->right_margin)
		var->right_margin = vmode->right_margin;
	if (var->upper_margin < vmode->upper_margin)
		var->upper_margin = vmode->upper_margin;
	if (var->lower_margin < vmode->lower_margin)
		var->lower_margin = vmode->lower_margin;

	/* extra margins */
	gap = ((long)vmode->left_margin + (long)vmode->xres +
	       (long)vmode->right_margin) -
	      ((long)var->left_margin + (long)var->xres +
	       (long)var->right_margin);
	if (gap > 0) {
		var->left_margin += gap/2;
		var->right_margin += (gap+1)/2;
		pr_debug("%s: rounded up H to %u [%u] %u\n", __func__,
			 var->left_margin, var->xres, var->right_margin);
	}

	gap = ((long)vmode->upper_margin + (long)vmode->yres +
	       (long)vmode->lower_margin) -
	      ((long)var->upper_margin + (long)var->yres +
	       (long)var->lower_margin);
	if (gap > 0) {
		var->upper_margin += gap/2;
		var->lower_margin += (gap+1)/2;
		pr_debug("%s: rounded up V to %u [%u] %u\n", __func__,
			 var->upper_margin, var->yres, var->lower_margin);
	}

	/* fixed fields */
	var->pixclock = vmode->pixclock;
	var->hsync_len = vmode->hsync_len;
	var->vsync_len = vmode->vsync_len;
	var->sync = vmode->sync;

	if (vmode->sync & FB_SYNC_BROADCAST) {
		/* Full broadcast modes have the full mode bit set */
		if (vmode->xres == var->xres && vmode->yres == var->yres)
			id |= PS3AV_MODE_FULL;
	}

	pr_debug("%s: mode %u\n", __func__, id);
	return id;
}

static void ps3fb_sync_image(struct device *dev, u64 frame_offset)
{
	int status;

#ifdef HEAD_A
	status = lv1_gpu_display_flip(ps3fb.context_handle, 0, frame_offset);
	if (status)
		dev_err(dev, "%s: lv1_gpu_display_flip failed: %d\n", __func__,
			status);
#endif
#ifdef HEAD_B
	status = lv1_gpu_display_flip(ps3fb.context_handle, 1, frame_offset);
	if (status)
		dev_err(dev, "%s: lv1_gpu_display_flip failed: %d\n", __func__,
			status);
#endif
}

static int ps3fb_sync(struct fb_info *info, u32 frame)
{
	struct ps3fb_par *par = info->par;
	int error = 0;
	u64 ddr_base;

	if (frame > par->num_frames - 1) {
		dev_dbg(info->device, "%s: invalid frame number (%u)\n",
			__func__, frame);
		error = -EINVAL;
		goto out;
	}

	ddr_base = frame * par->ddr_frame_size;

	ps3fb_sync_image(info->device, ddr_base + par->full_offset);

out:
	return error;
}

static int ps3fb_open(struct fb_info *info, int user)
{
	atomic_inc(&ps3fb.f_count);
	return 0;
}

static int ps3fb_release(struct fb_info *info, int user)
{
	if (atomic_dec_and_test(&ps3fb.f_count)) {
		if (atomic_read(&ps3fb.ext_flip)) {
			atomic_set(&ps3fb.ext_flip, 0);
			if (console_trylock()) {
				ps3fb_sync(info, 0);	/* single buffer */
				console_unlock();
			}
		}
	}
	return 0;
}

    /*
     *  Setting the video mode has been split into two parts.
     *  First part, xxxfb_check_var, must not write anything
     *  to hardware, it should only verify and adjust var.
     *  This means it doesn't alter par but it does use hardware
     *  data from it to check this var.
     */

static int ps3fb_check_var(struct fb_var_screeninfo *var, struct fb_info *info)
{
	u32 ddr_line_length;
	int mode;

	mode = ps3fb_find_mode(var, &ddr_line_length);
	if (!mode)
		return -EINVAL;

	/* Virtual screen */
	if (var->xres_virtual > ddr_line_length / BPP) {
		dev_dbg(info->device,
			"Horizontal virtual screen size too large\n");
		return -EINVAL;
	}

	if (var->xoffset + var->xres > var->xres_virtual ||
	    var->yoffset + var->yres > var->yres_virtual) {
		dev_dbg(info->device, "panning out-of-range\n");
		return -EINVAL;
	}

	/* We support ARGB8888 only */
	if (var->bits_per_pixel > 32 || var->grayscale ||
	    var->red.offset > 16 || var->green.offset > 8 ||
	    var->blue.offset > 0 || var->transp.offset > 24 ||
	    var->red.length > 8 || var->green.length > 8 ||
	    var->blue.length > 8 || var->transp.length > 8 ||
	    var->red.msb_right || var->green.msb_right ||
	    var->blue.msb_right || var->transp.msb_right || var->nonstd) {
		dev_dbg(info->device, "We support ARGB8888 only\n");
		return -EINVAL;
	}

	var->bits_per_pixel = 32;
	var->red.offset = 16;
	var->green.offset = 8;
	var->blue.offset = 0;
	var->transp.offset = 24;
	var->red.length = 8;
	var->green.length = 8;
	var->blue.length = 8;
	var->transp.length = 8;
	var->red.msb_right = 0;
	var->green.msb_right = 0;
	var->blue.msb_right = 0;
	var->transp.msb_right = 0;

	/* Rotation is not supported */
	if (var->rotate) {
		dev_dbg(info->device, "Rotation is not supported\n");
		return -EINVAL;
	}

	/* Memory limit */
	if (var->yres_virtual * ddr_line_length > info->fix.smem_len) {
		dev_dbg(info->device, "Not enough memory\n");
		return -ENOMEM;
	}

	var->height = -1;
	var->width = -1;

	return 0;
}

    /*
     * This routine actually sets the video mode.
     */

static int ps3fb_set_par(struct fb_info *info)
{
	struct ps3fb_par *par = info->par;
	unsigned int mode, ddr_line_length;
	unsigned int ddr_xoff, ddr_yoff, offset;
	const struct fb_videomode *vmode;

	mode = ps3fb_find_mode(&info->var, &ddr_line_length);
	if (!mode)
		return -EINVAL;

	vmode = ps3fb_native_vmode(mode & PS3AV_MODE_MASK);

	info->fix.xpanstep = info->var.xres_virtual > info->var.xres ? 1 : 0;
	info->fix.ypanstep = info->var.yres_virtual > info->var.yres ? 1 : 0;
	info->fix.line_length = ddr_line_length;

	par->ddr_line_length = ddr_line_length;
	par->ddr_frame_size = vmode->yres * ddr_line_length;

	par->num_frames = info->fix.smem_len / par->ddr_frame_size;

	/* Keep the special bits we cannot set using fb_var_screeninfo */
	par->new_mode_id = (par->new_mode_id & ~PS3AV_MODE_MASK) | mode;

	par->width = info->var.xres;
	par->height = info->var.yres;

	/* Start of the virtual frame buffer (relative to fullscreen) */
	ddr_xoff = info->var.left_margin - vmode->left_margin;
	ddr_yoff = info->var.upper_margin - vmode->upper_margin;
	offset = ddr_yoff * ddr_line_length + ddr_xoff * BPP;

	par->fb_offset = GPU_ALIGN_UP(offset);
	par->full_offset = par->fb_offset - offset;
	par->pan_offset = info->var.yoffset * ddr_line_length +
			  info->var.xoffset * BPP;

	if (par->new_mode_id != par->mode_id) {
		if (ps3av_set_video_mode(par->new_mode_id)) {
			par->new_mode_id = par->mode_id;
			return -EINVAL;
		}
		par->mode_id = par->new_mode_id;
	}

	/* Clear frame buffer memory */
	memset(info->screen_buffer, 0, info->fix.smem_len);

	ps3fb_sync(info, 0);

	return 0;
}

    /*
     *  Set a single color register. The values supplied are already
     *  rounded down to the hardware's capabilities (according to the
     *  entries in the var structure). Return != 0 for invalid regno.
     */

static int ps3fb_setcolreg(unsigned int regno, unsigned int red,
			   unsigned int green, unsigned int blue,
			   unsigned int transp, struct fb_info *info)
{
	if (regno >= 16)
		return 1;

	red >>= 8;
	green >>= 8;
	blue >>= 8;
	transp >>= 8;

	((u32 *)info->pseudo_palette)[regno] = transp << 24 | red << 16 |
					       green << 8 | blue;
	return 0;
}

static int ps3fb_pan_display(struct fb_var_screeninfo *var,
			     struct fb_info *info)
{
	struct ps3fb_par *par = info->par;

	par->pan_offset = var->yoffset * info->fix.line_length +
			  var->xoffset * BPP;
	return 0;
}

    /*
     *  As we have a virtual frame buffer, we need our own mmap function
     */

static int ps3fb_mmap(struct fb_info *info, struct vm_area_struct *vma)
{
	int r;

	vma->vm_page_prot = pgprot_decrypted(vma->vm_page_prot);

	r = vm_iomap_memory(vma, info->fix.smem_start, info->fix.smem_len);

	dev_dbg(info->device, "ps3fb: mmap framebuffer P(%lx)->V(%lx)\n",
		info->fix.smem_start + (vma->vm_pgoff << PAGE_SHIFT),
		vma->vm_start);

	return r;
}

    /*
     * Blank the display
     */

static int ps3fb_blank(int blank, struct fb_info *info)
{
	int retval;

	dev_dbg(info->device, "%s: blank:%d\n", __func__, blank);
	switch (blank) {
	case FB_BLANK_POWERDOWN:
	case FB_BLANK_HSYNC_SUSPEND:
	case FB_BLANK_VSYNC_SUSPEND:
	case FB_BLANK_NORMAL:
		retval = ps3av_video_mute(1);	/* mute on */
		if (!retval)
			ps3fb.is_blanked = 1;
		break;

	default:		/* unblank */
		retval = ps3av_video_mute(0);	/* mute off */
		if (!retval)
			ps3fb.is_blanked = 0;
		break;
	}
	return retval;
}

static int ps3fb_get_vblank(struct fb_vblank *vblank)
{
	memset(vblank, 0, sizeof(*vblank));
	vblank->flags = FB_VBLANK_HAVE_VSYNC;
	return 0;
}

static int ps3fb_wait_for_vsync(u32 crtc)
{
	int ret;
	u64 count;

	count = ps3fb.vblank_count;
	ret = wait_event_interruptible_timeout(ps3fb.wait_vsync,
					       count != ps3fb.vblank_count,
					       HZ / 10);
	if (!ret)
		return -ETIMEDOUT;

	return 0;
}


    /*
     * ioctl
     */

static int ps3fb_ioctl(struct fb_info *info, unsigned int cmd,
		       unsigned long arg)
{
	void __user *argp = (void __user *)arg;
	u32 val;
	int retval = -EFAULT;

	switch (cmd) {
	case FBIOGET_VBLANK:
		{
			struct fb_vblank vblank;
			dev_dbg(info->device, "FBIOGET_VBLANK:\n");
			retval = ps3fb_get_vblank(&vblank);
			if (retval)
				break;

			if (copy_to_user(argp, &vblank, sizeof(vblank)))
				retval = -EFAULT;
			break;
		}

	case FBIO_WAITFORVSYNC:
		{
			u32 crt;
			dev_dbg(info->device, "FBIO_WAITFORVSYNC:\n");
			if (get_user(crt, (u32 __user *) arg))
				break;

			retval = ps3fb_wait_for_vsync(crt);
			break;
		}

	case PS3FB_IOCTL_SETMODE:
		{
			struct ps3fb_par *par = info->par;
			const struct fb_videomode *vmode;
			struct fb_var_screeninfo var;

			if (copy_from_user(&val, argp, sizeof(val)))
				break;

			if (!(val & PS3AV_MODE_MASK)) {
				u32 id = ps3av_get_auto_mode();
				if (id > 0)
					val = (val & ~PS3AV_MODE_MASK) | id;
			}
			dev_dbg(info->device, "PS3FB_IOCTL_SETMODE:%x\n", val);
			retval = -EINVAL;
			vmode = ps3fb_vmode(val);
			if (vmode) {
				var = info->var;
				fb_videomode_to_var(&var, vmode);
				console_lock();
				/* Force, in case only special bits changed */
				var.activate |= FB_ACTIVATE_FORCE;
				par->new_mode_id = val;
				retval = fb_set_var(info, &var);
				if (!retval)
					fbcon_update_vcs(info, var.activate & FB_ACTIVATE_ALL);
				console_unlock();
			}
			break;
		}

	case PS3FB_IOCTL_GETMODE:
		val = ps3av_get_mode();
		dev_dbg(info->device, "PS3FB_IOCTL_GETMODE:%x\n", val);
		if (!copy_to_user(argp, &val, sizeof(val)))
			retval = 0;
		break;

	case PS3FB_IOCTL_SCREENINFO:
		{
			struct ps3fb_par *par = info->par;
			struct ps3fb_ioctl_res res;
			dev_dbg(info->device, "PS3FB_IOCTL_SCREENINFO:\n");
			res.xres = info->fix.line_length / BPP;
			res.yres = info->var.yres_virtual;
			res.xoff = (res.xres - info->var.xres) / 2;
			res.yoff = (res.yres - info->var.yres) / 2;
			res.num_frames = par->num_frames;
			if (!copy_to_user(argp, &res, sizeof(res)))
				retval = 0;
			break;
		}

	case PS3FB_IOCTL_ON:
		{
	        volatile struct gpu_fifo_ctrl *fifo_ctrl = ps3fb.fifo.ctrl;
		dev_dbg(info->device, "PS3FB_IOCTL_ON: %x %x\n", fifo_ctrl->put, fifo_ctrl->get);
		atomic_inc(&ps3fb.ext_flip);
		retval = 0;
		}
		break;

	case PS3FB_IOCTL_OFF:
		{
		volatile struct gpu_fifo_ctrl *fifo_ctrl = ps3fb.fifo.ctrl;
		dev_dbg(info->device, "PS3FB_IOCTL_OFF: %x %x\n", fifo_ctrl->put, fifo_ctrl->get);
		atomic_dec_if_positive(&ps3fb.ext_flip);
		// ReneR: re-read & sync FIFO PUT/GET here? we coudl also memset all ot NOPs?
		ps3fb.fifo.curr = ps3fb.fifo.start + (fifo_ctrl->put - ps3fb.fifo.ioif) / 4;
		dev_dbg(info->device, "PS3FB_IOCTL_OFF: synced to %x\n", ps3fb.fifo.curr);
		retval = 0;
		}
		break;

	case PS3FB_IOCTL_FSEL:
		if (copy_from_user(&val, argp, sizeof(val)))
			break;

		dev_dbg(info->device, "PS3FB_IOCTL_FSEL:%d\n", val);
		console_lock();
		retval = ps3fb_sync(info, val);
		console_unlock();
		break;

	case PS3FB_IOCTL_CURSOR_ENABLE:
		retval = lv1_gpu_context_attribute(ps3fb.context_handle, 0x10c, 0/*head*/, arg ? 0x1 : 0x02, 0x0, 0x0);	/* enable/disable */
		break;

	case PS3FB_IOCTL_CURSOR_POS:
 		retval = lv1_gpu_context_attribute(ps3fb.context_handle, 0x10b, 0/*head*/, 3, arg & 0xffff, arg >> 16); /* x/y pos */
		break;

	case PS3FB_IOCTL_CURSOR_OFFS:
		retval = lv1_gpu_context_attribute(ps3fb.context_handle, 0x10b, 0/*head*/, 2, arg, 0); /* offset */
		break;

	case PS3FB_IOCTL_GPU_SETUP:
		dev_dbg(info->device, " PS3FB_IOCTL_GPU_SETUP\n");
		//ReneR: I hope we do not need this anymore?
		//retval = ps3fb_fifo_setup(info->device);
		retval = 0;
		break;

	case PS3FB_IOCTL_GPU_INFO:
		{
			int i;
			struct ps3fb_ioctl_gpu_info res;

			dev_dbg(info->device, " PS3FB_IOCTL_GPU_INFO\n");

			res.vram_size = ps3fb.vram_size;
			res.fifo_size = ps3fb.fifo.len;
			res.ctrl_size = ps3fb.ctrl_size;
			res.dinfo_size = 0; //ps3fb.dinfo_size;
			
			// this looks unused
			res.reports_size = 0; //ps3fb.reports_size;
			for (i = 0; i < 8; i++)
			  res.device_size[i] = 0; //ps3fb.device_size[i];

			if (!copy_to_user(argp, &res, sizeof(res)))
				retval = 0;
			break;
		}

	case PS3FB_IOCTL_GPU_ATTR:
		{
			struct ps3fb_ioctl_gpu_attr arg;

			if (copy_from_user(&arg, argp, sizeof(arg)))
				break;

			dev_dbg(info->device,
				" PS3FB_IOCTL_GPU_ATTR(0x%lx,0x%lx,0x%lx,0x%lx,0x%lx)\n",
				arg.attr, arg.p0, arg.p1, arg.p2, arg.p3);

			retval = lv1_gpu_context_attribute(
				     ps3fb.context_handle,
				     arg.attr, arg.p0, arg.p1, arg.p2, arg.p3);
			if (retval < 0) {
				dev_err(info->device,
					"lv1_gpu_context_attribute failed (%d)\n",
					retval);
				retval = -EIO;
			}
		}
		break;

	default:
		retval = -ENOIOCTLCMD;
		break;
	}
	return retval;
}

static irqreturn_t ps3fb_vsync_interrupt(int irq, void *ptr)
{
	struct device *dev = ptr;
	u64 v1;
	int status;
	struct display_head *head = &ps3fb.dinfo->display_head[1];

	status = lv1_gpu_context_intr(ps3fb.context_handle, &v1);
	if (status) {
		dev_err(dev, "%s: lv1_gpu_context_intr failed: %d\n", __func__,
			status);
		return IRQ_NONE;
	}
	
	if (v1 & (1 << GPU_INTR_STATUS_GRAPH_EXCEPTION)) {
		dev_err(dev, "%s: graphics exception\n", __func__);
		ps3fb_print_graph_exception_info(dev, &ps3fb.dinfo->irq.graph_exception_info);
	}

	if (v1 & (1 << GPU_INTR_STATUS_VSYNC_1)) {
		/* VSYNC */
		ps3fb.vblank_count = head->vblank_count;
		wake_up_interruptible(&ps3fb.wait_vsync);
	}

	return IRQ_HANDLED;
}


static const struct fb_ops ps3fb_ops = {
	.owner		= THIS_MODULE,
	.fb_open	= ps3fb_open,
	.fb_release	= ps3fb_release,
	__FB_DEFAULT_SYSMEM_OPS_RDWR,
	.fb_check_var	= ps3fb_check_var,
	.fb_set_par	= ps3fb_set_par,
	.fb_setcolreg	= ps3fb_setcolreg,
	.fb_pan_display	= ps3fb_pan_display,
	__FB_DEFAULT_SYSMEM_OPS_DRAW,
	.fb_mmap	= ps3fb_mmap,
	.fb_blank	= ps3fb_blank,
	.fb_ioctl	= ps3fb_ioctl,
	.fb_compat_ioctl = ps3fb_ioctl
};

static const struct fb_fix_screeninfo ps3fb_fix = {
	.id =		DEVICE_NAME,
	.type =		FB_TYPE_PACKED_PIXELS,
	.visual =	FB_VISUAL_TRUECOLOR,
	.accel =	FB_ACCEL_NONE,
};

static int ps3fb_gpu_open(struct inode *inode, struct file *filp)
{
	return 0;
}

static int ps3fb_gpu_release(struct inode *inode, struct file *filp)
{
	return 0;
}

static int ps3fb_gpu_mmap(struct file *filp, struct vm_area_struct *vma)
{
	unsigned int minor = iminor(filp->f_path.dentry->d_inode);
	unsigned long off = vma->vm_pgoff << PAGE_SHIFT;
	unsigned long vsize = vma->vm_end - vma->vm_start;
	unsigned long physical;
	unsigned long psize;
	
	printk("ps3fb_mmap: %llx %p %llx\n", ps3fb.vram_lpar, ps3fb.fifo.start, ps3fb.ctrl_lpar);
	
	switch (minor) {
		case 0: /* DDR */
			physical = ps3fb.vram_lpar + off;
			psize    = ps3fb.vram_size - off;
			break;
		case 1: /* FIFO */
			physical = ps3fb.fifo.start + off;
			psize    = ps3fb.fifo.len - off;
			break;
		case 2: /* FIFO registers */
			physical = ps3fb.ctrl_lpar + off;
			psize    = ps3fb.ctrl_size - off;
			break;
#if 0
		case 3: /* driver info */
			physical = ps3fb.dinfo_lpar + off;
			psize    = ps3fb.dinfo_size - off;
			break;
		case 4: /* reports */
			physical = ps3fb.reports_lpar + off;
			psize    = ps3fb.reports_size - off;
			break;
			
		case 8 ... 15:
			if (ps3fb.device_lpar[minor - 8]) {
				physical = ps3fb.device_lpar[minor - 8] + off;
				psize    = ps3fb.device_size[minor - 8] - off;
			} else
				return -ENODEV;
			break;
#endif
			
		default:
			return -ENODEV;
	}
	
	printk("ps3fb_mmap: %d %lx %lx\n", minor, physical, psize);
	
	if (vsize > psize)
		return -EINVAL; /* spans too high */
	
	if (remap_pfn_range(vma, vma->vm_start,
						physical >> PAGE_SHIFT,
						vsize, vma->vm_page_prot))
		return -EAGAIN;
	
	return 0;
}

struct file_operations ps3fb_gpu_fops = {
	.mmap    = ps3fb_gpu_mmap,
	.open    = ps3fb_gpu_open,
	.release = ps3fb_gpu_release,
};

static int ps3fb_probe(struct ps3_system_bus_device *dev)
{
	struct fb_info *info;
	struct ps3fb_par *par;
	int retval;
	u64 ddr_lpar = 0, xdr_lpar;
	u64 lpar_dma_control = 0;
	u64 lpar_driver_info = 0;
	u64 lpar_reports = 0;
	u64 lpar_reports_size = 0;
	struct gpu_driver_info *dinfo;
	int status;
	unsigned long max_ps3fb_size;

	if (ps3fb_videomemory.size < GPU_CMD_BUF_SIZE) {
		dev_err(&dev->core, "%s: Not enough video memory\n", __func__);
		return -ENOMEM;
	}

	retval = ps3_open_hv_device(dev);
	if (retval) {
		dev_err(&dev->core, "%s: ps3_open_hv_device failed\n",
			__func__);
		goto err;
	}

	if (!ps3fb_mode)
		ps3fb_mode = ps3av_get_mode();
	dev_dbg(&dev->core, "ps3fb_mode: %d\n", ps3fb_mode);

	atomic_set(&ps3fb.f_count, -1);	/* fbcon opens ps3fb */
	atomic_set(&ps3fb.ext_flip, 0);	/* for flip with vsync */
	init_waitqueue_head(&ps3fb.wait_vsync);

#ifdef HEAD_A
	status = lv1_gpu_display_sync(0x0, 0, L1GPU_DISPLAY_SYNC_VSYNC);
	if (status) {
		dev_err(&dev->core, "%s: lv1_gpu_display_sync failed: %d\n",
			__func__, status);
		retval = -ENODEV;
		goto err_close_device;
	}
#endif
#ifdef HEAD_B
	status = lv1_gpu_display_sync(0x0, 1, L1GPU_DISPLAY_SYNC_VSYNC);
	if (status) {
		dev_err(&dev->core, "%s: lv1_gpu_display_sync failed: %d\n",
			__func__, status);
		retval = -ENODEV;
		goto err_close_device;
	}
#endif

	max_ps3fb_size = ALIGN(GPU_IOIF, 256*1024*1024) - GPU_IOIF;
	if (ps3fb_videomemory.size > max_ps3fb_size) {
		dev_info(&dev->core, "Limiting ps3fb mem size to %lu bytes\n",
			 max_ps3fb_size);
		ps3fb_videomemory.size = max_ps3fb_size;
	}

	/* get gpu context handle */
	ps3fb.vram_size = DDR_SIZE; // ps3fb_videomemory.size;
	status = lv1_gpu_memory_allocate(ps3fb.vram_size, ps3fb_gpu_mem_size[0],
									 ps3fb_gpu_mem_size[1], ps3fb_gpu_mem_size[2], ps3fb_gpu_mem_size[3],
									 &ps3fb.memory_handle, &ps3fb.vram_lpar);
	if (status) {
		dev_err(&dev->core, "%s: lv1_gpu_memory_allocate failed: %d\n",
				__func__, status);
		goto err_close_device;
	}
	dev_dbg(&dev->core, "ddr:lpar:0x%llx\n", ps3fb.vram_lpar);
	
	if (request_mem_region(ps3fb.vram_lpar, ps3fb.vram_size,
						   "GPU DDR memory") == NULL) {
		dev_err(&dev->core,
				"%s: failed to reserve DDR video memory region: %d\n",
				__func__, status);
		goto err_gpu_memory_free;
	}
	ps3fb.ctrl_size = GPU_CTRL_SIZE;
	
	status = lv1_gpu_context_allocate(ps3fb.memory_handle, ps3fb_gpu_ctx_flags,
									  &ps3fb.context_handle,
									  &ps3fb.ctrl_lpar, &lpar_driver_info,
									  &lpar_reports, &lpar_reports_size);
	if (status) {
		dev_err(&dev->core,
			"%s: lv1_gpu_context_allocate failed: %d\n", __func__,
			status);
		retval = -ENOMEM;
		goto err_gpu_memory_free;
	}

	/* vsync interrupt */
	dinfo = (void __force *)ioremap(lpar_driver_info, 128 * 1024);
	if (!dinfo) {
		dev_err(&dev->core, "%s: ioremap failed\n", __func__);
		retval = -ENOMEM;
		goto err_gpu_context_free;
	}

	ps3fb.dinfo = dinfo;
	dev_dbg(&dev->core, "version_driver:%x\n", dinfo->version_driver);
	dev_dbg(&dev->core, "irq outlet:%x\n", dinfo->irq.irq_outlet);
	dev_dbg(&dev->core, "version_gpu: %x memory_size: %x ch: %x "
		"core_freq: %d mem_freq:%d\n", dinfo->version_gpu,
		dinfo->memory_size, dinfo->hardware_channel,
		dinfo->nvcore_frequency/1000000,
		dinfo->memory_frequency/1000000);

	if (dinfo->version_driver != GPU_DRIVER_INFO_VERSION) {
		dev_err(&dev->core, "%s: version_driver err:%x\n", __func__,
			dinfo->version_driver);
		retval = -EINVAL;
		goto err_iounmap_dinfo;
	}

	retval = ps3_irq_plug_setup(PS3_BINDING_CPU_ANY, dinfo->irq.irq_outlet,
				    &ps3fb.irq_no);
	if (retval) {
		dev_err(&dev->core, "%s: ps3_alloc_irq failed %d\n", __func__,
			retval);
		goto err_iounmap_dinfo;
	}

	retval = request_irq(ps3fb.irq_no, ps3fb_vsync_interrupt,
			     0, DEVICE_NAME, &dev->core);
	if (retval) {
		dev_err(&dev->core, "%s: request_irq failed %d\n", __func__,
			retval);
		goto err_destroy_plug;
	}

	dinfo->irq.mask = (1 << GPU_INTR_STATUS_GRAPH_EXCEPTION) |
			  (1 << GPU_INTR_STATUS_VSYNC_1) |
			  (1 << GPU_INTR_STATUS_FLIP_1);

	/* Clear memory to prevent kernel info leakage into userspace */
	memset(ps3fb_videomemory.address, 0, ps3fb_videomemory.size);

	xdr_lpar = ps3_mm_phys_to_lpar(__pa(ps3fb_videomemory.address));

	status = lv1_gpu_context_iomap(ps3fb.context_handle, GPU_IOIF,
				       xdr_lpar, ps3fb_videomemory.size,
				       CBE_IOPTE_PP_W | CBE_IOPTE_PP_R |
				       CBE_IOPTE_M);
	if (status) {
		dev_err(&dev->core, "%s: lv1_gpu_context_iomap failed: %d\n",
			__func__, status);
		retval =  -ENXIO;
		goto err_free_irq;
	}

	dev_dbg(&dev->core, "video:%p ioif:%lx lpar:%llx size:%lx\n",
		ps3fb_videomemory.address, GPU_IOIF, xdr_lpar,
		ps3fb_videomemory.size);

	/* FIFO control */
	ps3fb.fifo.ctrl = (void __force *)ioremap(ps3fb.ctrl_lpar, ps3fb.ctrl_size);
	if (!ps3fb.fifo.ctrl) {
		dev_err(&dev->core, "%s: ioremap failed\n", __func__);
		goto err_context_unmap;
	}

	ps3fb.fifo.start = ps3fb.fifo.curr = ps3fb_videomemory.address;
	ps3fb.fifo.len = GPU_FB_START;
	ps3fb.fifo.ioif = GPU_IOIF;

	status = ps3fb_fb_setup(&dev->core, ps3fb.context_handle, &ps3fb.fifo);
	if (status) {
		dev_err(&dev->core, "%s: ps3fb_fb_setup failed: %d\n",
			__func__, status);
		retval = status;
		goto err_iounmap_fifo_ctrl;
	}

	info = framebuffer_alloc(sizeof(struct ps3fb_par), &dev->core);
	if (!info) {
		retval = -ENOMEM;
		goto err_iounmap_fifo_ctrl;
	}

	par = info->par;
	par->mode_id = ~ps3fb_mode;	/* != ps3fb_mode, to trigger change */
	par->new_mode_id = ps3fb_mode;
	par->num_frames = 1;

	info->fbops = &ps3fb_ops;
	info->fix = ps3fb_fix;

	info->fix.smem_start = ddr_lpar;
	info->fix.smem_len = 32*1024*1024;
 	info->screen_buffer = (char __force __iomem *)ioremap_wc(ddr_lpar, info->fix.smem_len);

 	info->pseudo_palette = par->pseudo_palette;
	info->flags = FBINFO_HWACCEL_XPAN | FBINFO_HWACCEL_YPAN;

 	retval = fb_alloc_cmap(&info->cmap, 256, 0);
	if (retval < 0)
		goto err_framebuffer_release;

	if (!fb_find_mode(&info->var, info, mode_option, ps3fb_modedb,
			  ARRAY_SIZE(ps3fb_modedb),
			  ps3fb_vmode(par->new_mode_id), 32)) {
		retval = -EINVAL;
		goto err_fb_dealloc;
	}

	fb_videomode_to_modelist(ps3fb_modedb, ARRAY_SIZE(ps3fb_modedb),
				 &info->modelist);

	retval = register_framebuffer(info);
	if (retval < 0)
		goto err_fb_dealloc;

	ps3_system_bus_set_drvdata(dev, info);

	fb_info(info, "using %u KiB of video memory\n", info->fix.smem_len >> 10);

	/* test cursor init here */
	status = lv1_gpu_context_attribute(ps3fb.context_handle, 0x10b, 0/*head*/, 1, 0, 0); /* init */
	if (status) dev_err(info->device, "%s: cursor init failed (%d)\n", __func__, status);

	/* FIFO access */
	status = register_chrdev(ps3fb_gpu_major, DEVICE_NAME, &ps3fb_gpu_fops);
	if (status < 0) {
	  dev_err(&dev->core,
			"%s: failed to register GPU device with major %d (%d)\n",
			__func__, ps3fb_gpu_major, status);
	  /* ReneR: if this fails continue anway, ...
	     goto err_unregister_framebuffer; */
	}
	if (ps3fb_gpu_major == 0)
		ps3fb_gpu_major = status;
	
	dev_info(&dev->core, "%s: using major %d for direct GPU access\n",
		 __func__, ps3fb_gpu_major);
	
	return 0;

err_fb_dealloc:
	fb_dealloc_cmap(&info->cmap);
err_framebuffer_release:
	framebuffer_release(info);
err_iounmap_fifo_ctrl:
	iounmap((u8 __force __iomem *)ps3fb.fifo.ctrl);
err_context_unmap:
	lv1_gpu_context_iomap(ps3fb.context_handle, GPU_IOIF, xdr_lpar,
			      ps3fb_videomemory.size, CBE_IOPTE_M);
err_free_irq:
	free_irq(ps3fb.irq_no, &dev->core);
err_destroy_plug:
	ps3_irq_plug_destroy(ps3fb.irq_no);
err_iounmap_dinfo:
	iounmap((u8 __force __iomem *)ps3fb.dinfo);
err_gpu_context_free:
	lv1_gpu_context_free(ps3fb.context_handle);
err_gpu_memory_free:
	lv1_gpu_memory_free(ps3fb.memory_handle);
err_close_device:
	ps3_close_hv_device(dev);
err:
	return retval;
}

static void ps3fb_shutdown(struct ps3_system_bus_device *dev)
{
	struct fb_info *info = ps3_system_bus_get_drvdata(dev);
	u64 xdr_lpar = ps3_mm_phys_to_lpar(__pa(ps3fb_videomemory.address));

	dev_dbg(&dev->core, " -> %s:%d\n", __func__, __LINE__);

	unregister_chrdev(ps3fb_gpu_major, DEVICE_NAME);

	atomic_inc(&ps3fb.ext_flip);	/* flip off */
	ps3fb.dinfo->irq.mask = 0;

	if (ps3fb.irq_no) {
		free_irq(ps3fb.irq_no, &dev->core);
		ps3_irq_plug_destroy(ps3fb.irq_no);
	}
	if (info) {
		unregister_framebuffer(info);
		fb_dealloc_cmap(&info->cmap);
		framebuffer_release(info);
		ps3_system_bus_set_drvdata(dev, NULL);
	}
	iounmap((u8 __force __iomem *)ps3fb.dinfo);
	iounmap((u8 __force __iomem *)ps3fb.fifo.ctrl);
	lv1_gpu_context_iomap(ps3fb.context_handle, GPU_IOIF, xdr_lpar,
			      ps3fb_videomemory.size, CBE_IOPTE_M);
	lv1_gpu_context_free(ps3fb.context_handle);
	lv1_gpu_memory_free(ps3fb.memory_handle);
	ps3_close_hv_device(dev);
	dev_dbg(&dev->core, " <- %s:%d\n", __func__, __LINE__);
}

static struct ps3_system_bus_driver ps3fb_driver = {
	.match_id	= PS3_MATCH_ID_GPU,
	.match_sub_id	= PS3_MATCH_SUB_ID_GPU_FB,
	.core.name	= DEVICE_NAME,
	.core.owner	= THIS_MODULE,
	.probe		= ps3fb_probe,
	.remove		= ps3fb_shutdown,
	.shutdown	= ps3fb_shutdown,
};

static int __init ps3fb_setup(void)
{
	char *options;

	if (fb_get_options(DEVICE_NAME, &options))
		return -ENXIO;

	if (!options || !*options)
		return 0;

	while (1) {
		char *this_opt = strsep(&options, ",");

		if (!this_opt)
			break;
		if (!*this_opt)
			continue;
		if (!strncmp(this_opt, "mode:", 5))
			ps3fb_mode = simple_strtoul(this_opt + 5, NULL, 0);
		else
			mode_option = this_opt;
	}
	return 0;
}

static int __init ps3fb_init(void)
{
	if (!ps3fb_videomemory.address ||  ps3fb_setup())
		return -ENXIO;

	return ps3_system_bus_driver_register(&ps3fb_driver);
}

static void __exit ps3fb_exit(void)
{
	pr_debug(" -> %s:%d\n", __func__, __LINE__);
	ps3_system_bus_driver_unregister(&ps3fb_driver);
	pr_debug(" <- %s:%d\n", __func__, __LINE__);
}

module_init(ps3fb_init);
module_exit(ps3fb_exit);

MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("PS3 GPU Frame Buffer Driver");
MODULE_AUTHOR("Sony Computer Entertainment Inc.");
MODULE_ALIAS(PS3_MODULE_ALIAS_GPU_FB);
