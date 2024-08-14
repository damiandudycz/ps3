/*
 *  fs/partitions/ps3.c
 *
 *  Copyright (C) 2012 glevand <geoffrey.levand@mail.ru>
 */

#include "check.h"
#include "ps3.h"

//#define SECTOR_SIZE		512
#define MAX_ACL_ENTRIES		8
#define MAX_PARTITIONS		8

#define MAGIC1			0x0FACE0FFULL
#define MAGIC2			0xDEADFACEULL

struct p_acl_entry {
	__be64 laid;
	__be64 rights;
};

struct d_partition {
	__be64 p_start;
	__be64 p_size;
	struct p_acl_entry p_acl[MAX_ACL_ENTRIES];
};

struct disklabel {
	u8 d_res1[16];
	__be64 d_magic1;
	__be64 d_magic2;
	__be64 d_res2;
	__be64 d_res3;
	struct d_partition d_partitions[MAX_PARTITIONS];
	u8 d_pad[0x600 - MAX_PARTITIONS * sizeof(struct d_partition)- 0x30];
};

static bool ps3_read_disklabel(struct parsed_partitions *state, struct disklabel *label)
{
	Sector sect;
	unsigned char *data;
	int i;

	for (i = 0; i < sizeof(struct disklabel) / SECTOR_SIZE; i++) {
		data = read_part_sector(state, i, &sect);
		if (!data)
			return (false);

		memcpy((unsigned char *) label + i * SECTOR_SIZE, data, SECTOR_SIZE);

		put_dev_sector(sect);
	}

	return (true);
}

int ps3_partition(struct parsed_partitions *state)
{
	struct disklabel *label = NULL;
	int slot = 1;
	int result = -1;
	int i;

	label = kmalloc(sizeof(struct disklabel), GFP_KERNEL);
	if (!label)
		goto out;

	if (!ps3_read_disklabel(state, label))
		goto out;

	result = 0;

	if ((be64_to_cpu(label->d_magic1) != MAGIC1) ||
	    (be64_to_cpu(label->d_magic2) != MAGIC2))
		goto out;

	for (i = 0; i < MAX_PARTITIONS; i++) {
		if (label->d_partitions[i].p_start && label->d_partitions[i].p_size) {
			put_partition(state, slot,
				be64_to_cpu(label->d_partitions[i].p_start),
				be64_to_cpu(label->d_partitions[i].p_size));
			slot++;
		}
	}

	strlcat(state->pp_buf, "\n", PAGE_SIZE);

	kfree(label);

	return (1);

out:

	if (label)
		kfree(label);

	return (result);
}
