/*
 * PS3 LV1 Debug Console
 *
 * Copyright (C) 2024 René Rebe <rene@exactcode.de>
 * Copyright (C) 2013 glevand <geoffrey.levand@mail.ru>
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

#include <asm/io.h>
#include <asm/udbg.h>
#include <asm/lv1call.h>

#define LV1_CONS_ID		1
#define LV1_CONS_LENGTH		0xff0

static int initialized = 0;

static void lv1_cons_udbg_putc(char ch)
{
	u64 data, written;
	int ret;

	if (!initialized) {
		ret = lv1_undocumented_function_105(LV1_CONS_ID, 0, 0,
			LV1_CONS_LENGTH, LV1_CONS_LENGTH, 0, 0);
		if ((ret != 0) && (ret != -7))
			return;

		initialized = 1;
	}

	data = ch;
	data <<= 56;

	lv1_undocumented_function_107(LV1_CONS_ID, 1, data, 0, 0, 0, &written);

	/* flush to console buffer in LV1 */

	lv1_undocumented_function_109(LV1_CONS_ID);
}

void __init udbg_init_ps3_lv1_cons(void)
{
	udbg_putc = lv1_cons_udbg_putc;
}
