/*
 * PS3 Generic LV1 Call
 *
 * Copyright (C) 2012 glevand <geoffrey.levand@mail.ru>
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

#include <asm/processor.h>
#include <asm/ppc_asm.h>

#define lv1call		.long 0x44000022; extsw r3, r3

_GLOBAL(generic_lv1call)
	mflr r0
	std r0, 16(r1)
	std r3, -8(r1)
	std r4, -16(r1)
	stdu r5, -24(r1)
	mr r11, r4
	ld r3, 0(r11)
	ld r4, 8(r11)
	ld r5, 16(r11)
	ld r6, 24(r11)
	ld r7, 32(r11)
	ld r8, 40(r11)
	ld r9, 48(r11)
	ld r10, 56(r11)
	ld r11, 16(r1)
	lv1call
	addi r1, r1, 24
	ld r11, -24(r1)
	std r4, 0(r11)
	std r5, 8(r11)
	std r6, 16(r11)
	std r7, 24(r11)
	std r8, 32(r11)
	std r9, 40(r11)
	std r10, 48(r11)
	ld r0, 16(r1)
	mtlr r0
	blr
