/* SPDX-License-Identifier: GPL-2.0 WITH Linux-syscall-note */
/*
 * Copyright (C) 2006 Sony Computer Entertainment Inc.
 * Copyright 2006, 2007 Sony Corporation
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

#ifndef _ASM_POWERPC_PS3FB_H_
#define _ASM_POWERPC_PS3FB_H_

#include <linux/types.h>
#include <linux/ioctl.h>

/* ioctl */
#define PS3FB_IOCTL_SETMODE       _IOW('r',  1, int) /* set video mode */
#define PS3FB_IOCTL_GETMODE       _IOR('r',  2, int) /* get video mode */
#define PS3FB_IOCTL_SCREENINFO    _IOR('r',  3, int) /* get screen info */
#define PS3FB_IOCTL_ON            _IO('r', 4)        /* use IOCTL_FSEL */
#define PS3FB_IOCTL_OFF           _IO('r', 5)        /* return to normal-flip */
#define PS3FB_IOCTL_FSEL          _IOW('r', 6, int)  /* blit and flip request */
#define PS3FB_IOCTL_GPU_SETUP     _IO('r', 7)         /* enable FIFO access */
#define PS3FB_IOCTL_GPU_INFO      _IOR('r', 8, int)   /* get GPU info */
#define PS3FB_IOCTL_GPU_ATTR      _IOW('r', 9, int)   /* set attribute */

#define PS3FB_IOCTL_CURSOR_ENABLE _IOW('r', 10, int)	/* cursor enable/disable */
#define PS3FB_IOCTL_CURSOR_POS    _IOW('r', 11, int)	/* cursor x/y pos*/
#define PS3FB_IOCTL_CURSOR_OFFS   _IOW('r', 12, int)	/* cursor data offset */

#ifndef FBIO_WAITFORVSYNC
#define FBIO_WAITFORVSYNC         _IOW('F', 0x20, __u32) /* wait for vsync */
#endif

struct ps3fb_ioctl_res {
	__u32 xres; /* frame buffer x_size */
	__u32 yres; /* frame buffer y_size */
	__u32 xoff; /* margine x  */
	__u32 yoff; /* margine y */
	__u32 num_frames; /* num of frame buffers */
};

struct ps3fb_ioctl_gpu_info {
	__u32 vram_size;      /* size of available video memory */
	__u32 fifo_size;      /* size of command buffer */
	__u32 ctrl_size;      /* size of dma control registers */
	__u32 dinfo_size;     /* size of driver info */
	__u32 reports_size;   /* size of reports */
	__u32 device_size[8]; /* size of gpu devices */
};

struct ps3fb_ioctl_gpu_attr {
	__u64 attr;           /* attribute */
	__u64 p0;             /* 1st parameter */
	__u64 p1;             /* 2nd parameter */
	__u64 p2;             /* 3rd parameter */
	__u64 p3;             /* 4th parameter */
};

#endif /* _ASM_POWERPC_PS3FB_H_ */
