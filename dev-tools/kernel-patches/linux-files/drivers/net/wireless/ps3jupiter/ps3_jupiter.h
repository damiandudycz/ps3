
/*
 * PS3 Jupiter
 *
 * Copyright (C) 2011 glevand <geoffrey.levand@mail.ru>
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

#ifndef _PS3_JUPITER_H
#define _PS3_JUPITER_H

int ps3_jupiter_register_event_listener(struct notifier_block *listener);

int ps3_jupiter_unregister_event_listener(struct notifier_block *listener);

int ps3_jupiter_exec_eurus_cmd(enum ps3_eurus_cmd_id cmd,
	void *payload, unsigned int payload_length,
	unsigned int *response_status,
	unsigned int *response_length, void *response);

#endif
