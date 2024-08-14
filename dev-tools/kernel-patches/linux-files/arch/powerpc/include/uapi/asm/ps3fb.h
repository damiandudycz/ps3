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

struct ps3fb_ioctl_res {
	__u32 xres; /* frame buffer x_size */
	__u32 yres; /* frame buffer y_size */
	__u32 xoff; /* margine x  */
	__u32 yoff; /* margine y */
	__u32 num_frames; /* num of frame buffers */
};

/*
* ioctl
*/
struct ps3gpu_ioctl_info
{	
   __u32 ioif_base;
   __u32 reset_start;
   __u32 reset_size;
   __u32 fifo_start;
   __u32 fifo_size;
   __u32 fifo_size_max;
   __u32 gart_size;
   __u32 report_size[2];
   __u32 driver_size;
   __u32 ctrl_size;
   __u32 video_size;
};

struct ps3gpu_ioctl_set_attribute
{
   __u64 p0;
   __u64 p1;
   __u64 p2;
};

struct ps3gpu_ioctl_set_context_attribute
{	
   __u32 ctx;
   __u32 reserved;
   __u64 p0;
   __u64 p1;
   __u64 p2;
   __u64 p3;
   __u64 p4;
};

struct ps3gpu_ioctl_init_cursor
{
   int ctx;
   int head;
};

struct ps3gpu_ioctl_set_cursor_image
{
   int ctx;	
   int head;	
   __u32 offset;
   __u32 pad;	
};

struct ps3gpu_ioctl_set_cursor_position
{
   int ctx;
   int head;
   int x;
   int y;
};

struct ps3gpu_ioctl_set_cursor_enable
{
   int ctx;
   int head;
   int enable;
   int pad;
};

#define PS3GPU_IOCTL_INFO                    _IOR('r', 7, struct ps3gpu_ioctl_info)
#define PS3GPU_IOCTL_EXIT                    _IOW('r', 8, int)
#define PS3GPU_IOCTL_SET_ATTRIBUTE           _IOW('r', 9, struct ps3gpu_ioctl_set_attribute)
#define PS3GPU_IOCTL_SET_CONTEXT_ATTRIBUTE   _IOW('r', 10, struct ps3gpu_ioctl_set_context_attribute)
#define PS3GPU_IOCTL_INIT_CURSOR             _IOW('r', 11, struct ps3gpu_ioctl_init_cursor)
#define PS3GPU_IOCTL_CURSOR_POS              _IOW('r', 12, struct ps3gpu_ioctl_set_cursor_position)
#define PS3GPU_IOCTL_CURSOR_IMAGE            _IOW('r', 13, struct ps3gpu_ioctl_set_cursor_image)
#define PS3GPU_IOCTL_CURSOR_ENABLE           _IOW('r', 14, struct ps3gpu_ioctl_set_cursor_enable)
#define PS3GPU_IOCTL_ENTER                   _IOW('r', 15, int)

#ifndef FBIO_WAITFORVSYNC
#define FBIO_WAITFORVSYNC         _IOW('F', 0x20, __u32) /* wait for vsync */
#endif

#endif /* _ASM_POWERPC_PS3FB_H_ */
