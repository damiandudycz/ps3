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

#ifndef _PS3STRGMNGR_H
#define _PS3STRGMNGR_H

#include <linux/types.h>
#include <linux/ioctl.h>

#define PS3STRGMNGR_MAX_ACL_ENTRIES		8
#define PS3STRGMNGR_MAX_REGIONS			8
#define PS3STRGMNGR_MAX_DEVICES			8

#define PS3STRGMNGR_CTL_GET_DEVICES		_IOR('s', 0, int)
#define PS3STRGMNGR_CTL_CREATE_REGION		_IOWR('s', 1, int)
#define PS3STRGMNGR_CTL_DELETE_REGION		_IOW('s', 2, int)
#define PS3STRGMNGR_CTL_SET_REGION_ACL_ENTRY	_IOW('s', 3, int)

enum ps3strgmngr_devtype {
	PS3STRGMNGR_DEVTYPE_DISK = 0,
	PS3STRGMNGR_DEVTYPE_CDROM,
	PS3STRGMNGR_DEVTYPE_FLASH,
	PS3STRGMNGR_DEVTYPE_NOR_FLASH,
};

enum ps3strgmngr_region_access_rights {
	PS3STRGMNGR_REGION_READ		= (1ull << 0),
	PS3STRGMNGR_REGION_WRITE	= (1ull << 1),
};

struct ps3strgmngr_acl_entry {
	__u64 laid;
	__u64 access_rights;	/* enum ps3strgmngr_region_access_rights */
};

struct ps3strgmngr_region {
	__u64 id;
	__u64 start_block;
	__u64 nr_blocks;
	__u64 nr_acl_entries;
	struct ps3strgmngr_acl_entry acl_entry[PS3STRGMNGR_MAX_ACL_ENTRIES];
};

struct ps3strgmngr_device {
	__u64 type;		/* enum ps3strgmngr_devtype */
	__u64 id;
	__u64 block_size;
	__u64 nr_blocks;
	__u64 nr_regions;
	struct ps3strgmngr_region region[PS3STRGMNGR_MAX_REGIONS];
};

struct ps3strgmngr_ctl_get_devices {
	/* out */
	__u64 nr_devices;
	struct ps3strgmngr_device device[PS3STRGMNGR_MAX_DEVICES];
};

struct ps3strgmngr_ctl_create_region {
	/* in */
	__u64 device_id;
	__u64 start_block;
	__u64 nr_blocks;
	__u64 laid;
	/* out */
	__u64 region_id;
};

struct ps3strgmngr_ctl_delete_region {
	/* in */
	__u64 device_id;
	__u64 region_id;
};

struct ps3strgmngr_ctl_set_region_acl_entry {
	/* in */
	__u64 device_id;
	__u64 region_id;
	__u64 laid;
	__u64 access_rights;
};

#endif /* _PS3STRGMNGR_H */
