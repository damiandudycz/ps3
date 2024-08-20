
/*
 * PS3 Eurus
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

#ifndef _PS3_EURUS_H
#define _PS3_EURUS_H

enum ps3_eurus_cmd_id {
	PS3_EURUS_CMD_0x1				= 0x0001,
	PS3_EURUS_CMD_GET_AP_SSID			= 0x0003,
	PS3_EURUS_CMD_SET_AP_SSID			= 0x0005,
	PS3_EURUS_CMD_GET_CHANNEL			= 0x000f,
	PS3_EURUS_CMD_SET_CHANNEL			= 0x0011,
	PS3_EURUS_CMD_SET_ANTENNA			= 0x0029,
	PS3_EURUS_CMD_GET_AP_WEP_CONFIG			= 0x0059,
	PS3_EURUS_CMD_SET_AP_WEP_CONFIG			= 0x005b,
	PS3_EURUS_CMD_0x61				= 0x0061,
	PS3_EURUS_CMD_0x65				= 0x0065,
	PS3_EURUS_CMD_GET_FW_VERSION			= 0x0099,
	PS3_EURUS_CMD_GET_AP_OPMODE			= 0x00b7,
	PS3_EURUS_CMD_SET_AP_OPMODE			= 0x00b9,
	PS3_EURUS_CMD_0xc5				= 0x00c5,
	PS3_EURUS_CMD_GET_AP_WPA_AKM_SUITE		= 0x00c8,
	PS3_EURUS_CMD_SET_AP_WPA_AKM_SUITE		= 0x00c9,
	PS3_EURUS_CMD_GET_AP_WPA_GROUP_CIPHER_SUITE	= 0x00cd,
	PS3_EURUS_CMD_SET_AP_WPA_GROUP_CIPHER_SUITE	= 0x00cf,
	PS3_EURUS_CMD_GET_AP_WPA_PSK_PASSPHRASE		= 0x00d1,
	PS3_EURUS_CMD_SET_AP_WPA_PSK_PASSPHRASE		= 0x00d3,
	PS3_EURUS_CMD_0xd5				= 0x00d5,
	PS3_EURUS_CMD_0x127				= 0x0127,
	PS3_EURUS_CMD_0x12b				= 0x012b,
	PS3_EURUS_CMD_GET_AP_WPA_PSK_BIN		= 0x017b,
	PS3_EURUS_CMD_SET_AP_WPA_PSK_BIN		= 0x017d,
	PS3_EURUS_CMD_GET_AP_WPA_PAIRWISE_CIPHER_SUITE	= 0x01bd,
	PS3_EURUS_CMD_SET_AP_WPA_PAIRWISE_CIPHER_SUITE	= 0x01bf,
	PS3_EURUS_CMD_0x1d9				= 0x01d9,
	PS3_EURUS_CMD_START_AP				= 0x01dd,
	PS3_EURUS_CMD_0x1ed				= 0x01ed,
	PS3_EURUS_CMD_GET_HW_REVISION			= 0x01fb,
	PS3_EURUS_CMD_0x203				= 0x0203,
	PS3_EURUS_CMD_0x207				= 0x0207,
	PS3_EURUS_CMD_ASSOCIATE				= 0x1001,
	PS3_EURUS_CMD_GET_COMMON_CONFIG			= 0x1003,
	PS3_EURUS_CMD_SET_COMMON_CONFIG			= 0x1005,
	PS3_EURUS_CMD_GET_WEP_CONFIG			= 0x1013,
	PS3_EURUS_CMD_SET_WEP_CONFIG			= 0x1015,
	PS3_EURUS_CMD_GET_WPA_CONFIG			= 0x1017,
	PS3_EURUS_CMD_SET_WPA_CONFIG			= 0x1019,
	PS3_EURUS_CMD_0x1025				= 0x1025,
	PS3_EURUS_CMD_0x1031				= 0x1031,
	PS3_EURUS_CMD_GET_SCAN_RESULTS			= 0x1033,
	PS3_EURUS_CMD_START_SCAN			= 0x1035,
	PS3_EURUS_CMD_DISASSOCIATE			= 0x1037,
	PS3_EURUS_CMD_GET_RSSI				= 0x103d,
	PS3_EURUS_CMD_GET_MAC_ADDR			= 0x103f,
	PS3_EURUS_CMD_SET_MAC_ADDR			= 0x1041,
	PS3_EURUS_CMD_0x104d				= 0x104d,
	PS3_EURUS_CMD_0x104f				= 0x104f,
	PS3_EURUS_CMD_0x105f				= 0x105f,
	PS3_EURUS_CMD_0x1109				= 0x1109,
	PS3_EURUS_CMD_0x110b				= 0x110b,
	PS3_EURUS_CMD_0x110d				= 0x110d,
	PS3_EURUS_CMD_0x1133				= 0x1133,
	PS3_EURUS_CMD_0x114b				= 0x114b,
	PS3_EURUS_CMD_0x114f				= 0x114f,
	PS3_EURUS_CMD_0x115b				= 0x115b,
	PS3_EURUS_CMD_0x115d				= 0x115d,
	PS3_EURUS_CMD_0x115f				= 0x115f,
	PS3_EURUS_CMD_SET_MCAST_ADDR_FILTER		= 0x1161,
	PS3_EURUS_CMD_CLEAR_MCAST_ADDR_FILTER		= 0x1163,
	PS3_EURUS_CMD_GET_MCAST_ADDR_FILTER		= 0x1165,
	PS3_EURUS_CMD_0x116d				= 0x116d,
	PS3_EURUS_CMD_0x116f				= 0x116f,
	PS3_EURUS_CMD_GET_MAC_ADDR_LIST			= 0x1117,
	PS3_EURUS_CMD_0x1171				= 0x1171,
	PS3_EURUS_CMD_GET_CHANNEL_INFO			= 0xfffd,
};

enum ps3_eurus_cmd_status {
	PS3_EURUS_CMD_OK				= 0x0001,
	PS3_EURUS_CMD_INVALID_LENGTH			= 0x0002,
	PS3_EURUS_CMD_UNSUPPORTED			= 0x0003,
	PS3_EURUS_CMD_INVALID_PARAMETER			= 0x0004,
};

enum ps3_eurus_event_type {
	PS3_EURUS_EVENT_TYPE_0x8			= 0x00000008,
	PS3_EURUS_EVENT_TYPE_0x10			= 0x00000010,
	PS3_EURUS_EVENT_TYPE_0x40			= 0x00000040,
	PS3_EURUS_EVENT_TYPE_0x80			= 0x00000080,
	PS3_EURUS_EVENT_TYPE_0x100			= 0x00000100,
	PS3_EURUS_EVENT_TYPE_0x400			= 0x00000400,
	PS3_EURUS_EVENT_TYPE_0x80000000			= 0x80000000
};

enum ps3_eurus_event_id {
	/* event type 0x00000008 */

	PS3_EURUS_EVENT_STA_CONNECTED			= 0x00000010,

	/* event type 0x00000010 */

	PS3_EURUS_EVENT_STA_DISCONNECTED		= 0x00000002,
	PS3_EURUS_EVENT_AP_STOPPED			= 0x00000004,

	/* event type 0x00000040 */

	PS3_EURUS_EVENT_DEAUTH				= 0x00000001,

	/* event type 0x00000080 */

	PS3_EURUS_EVENT_BEACON_LOST			= 0x00000001,
	PS3_EURUS_EVENT_CONNECTED			= 0x00000002,
	PS3_EURUS_EVENT_SCAN_COMPLETED			= 0x00000004,
	PS3_EURUS_EVENT_WPA_CONNECTED			= 0x00000020,
	PS3_EURUS_EVENT_WPA_ERROR			= 0x00000040,

	/* event type 0x00000100 */

	PS3_EURUS_EVENT_0x100_0x2			= 0x00000002,
	PS3_EURUS_EVENT_AP_STARTED			= 0x00000010,
	PS3_EURUS_EVENT_STA_WPA_CONNECTED		= 0x00000020,
	PS3_EURUS_EVENT_0x100_0x40			= 0x00000040,

	/* event type 0x80000000 */

	PS3_EURUS_EVENT_DEVICE_READY			= 0x00000001,
};

enum ps3_eurus_ap_opmode {
	PS3_EURUS_AP_OPMODE_11B				= 0x00000000,
	PS3_EURUS_AP_OPMODE_11G				= 0x00000001,
	PS3_EURUS_AP_OPMODE_11BG			= 0x00000002,
};

enum ps3_eurus_bss_type {
	PS3_EURUS_BSS_INFRA				= 0x00,
	PS3_EURUS_BSS_ADHOC				= 0x02,
};

enum ps3_eurus_auth_mode {
	PS3_EURUS_AUTH_OPEN				= 0x00,
	PS3_EURUS_AUTH_SHARED_KEY			= 0x01,
};

enum ps3_eurus_opmode {
	PS3_EURUS_OPMODE_11BG				= 0x00,
	PS3_EURUS_OPMODE_11B				= 0x01,
	PS3_EURUS_OPMODE_11G				= 0x02,
};

enum ps3_eurus_preamble_mode {
	PS3_EURUS_PREAMBLE_SHORT			= 0x00,
	PS3_EURUS_PREAMBLE_LONG				= 0x01,
};

enum ps3_eurus_wep_security_mode {
	PS3_EURUS_WEP_SECURITY_NONE			= 0x00,
	PS3_EURUS_WEP_SECURITY_40BIT			= 0x01,
	PS3_EURUS_WEP_SECURITY_104BIT			= 0x02,
};

enum ps3_eurus_wpa_security_mode {
	PS3_EURUS_WPA_SECURITY_WPA			= 0x00,
	PS3_EURUS_WPA_SECURITY_WPA2			= 0x01,
};

enum ps3_eurus_wpa_psk_type {
	PS3_EURUS_WPA_PSK_PASSPHRASE			= 0x00,
	PS3_EURUS_WPA_PSK_BIN				= 0x01,
};

enum ps3_eurus_wpa_cipher_suite {
	PS3_EURUS_WPA_CIPHER_SUITE_WPA_TKIP		= 0x0050f202,
	PS3_EURUS_WPA_CIPHER_SUITE_WPA_AES		= 0x0050f204,
	PS3_EURUS_WPA_CIPHER_SUITE_WPA2_TKIP		= 0x000fac02,
	PS3_EURUS_WPA_CIPHER_SUITE_WPA2_AES		= 0x000fac04,
};

enum ps3_eurus_wpa_akm_suite {
	PS3_EURUS_WPA_AKM_SUITE_WPA_PSK			= 0x0050f202,
	PS3_EURUS_WPA_AKM_SUITE_WPA2_PSK		= 0x000fac02,
};

struct ps3_eurus_cmd_hdr {
	__le16 id;			/* enum ps3_eurus_cmd_id */
	__le16 tag;
	__le16 status;			/* enum ps3_eurus_cmd_status */
	__le16 payload_length;
	u8 res[4];
} __packed;

struct ps3_eurus_cmd_0x1 {
	u8 unknown;
	u8 res[3];
} __packed;

struct ps3_eurus_cmd_ap_ssid {
	u8 ssid[32];
	u8 res[4];
} __packed;

struct ps3_eurus_cmd_get_channel {
	u8 unknown[35];
	__le16 channel;
} __packed;

struct ps3_eurus_cmd_set_channel {
	u8 channel;
} __packed;

struct ps3_eurus_cmd_set_antenna {
	u8 unknown1;
	u8 unknown2;
} __packed;

struct ps3_eurus_cmd_ap_wep_config {
	u8 unknown1;
	u8 unknown2;
	u8 security_mode;	/* enum ps3_eurus_wep_security_mode */
	u8 unknown3;
	u8 key[4][18];
} __packed;

struct ps3_eurus_cmd_0x61 {
	u8 unknown;
} __packed;

struct ps3_eurus_cmd_0x65 {
	u8 unknown;
} __packed;

struct ps3_eurus_cmd_get_fw_version {
	u8 version[62];	/* string */
} __packed;

struct ps3_eurus_cmd_ap_opmode {
	__le32 opmode;	/* enum ps3_eurus_ap_opmode */
} __packed;

struct ps3_eurus_cmd_0xc5 {
	__le32 unknown;
} __packed;

struct ps3_eurus_cmd_ap_wpa_akm_suite {
	__be32 suite;	/* enum ps3_eurus_wpa_akm_suite */
	u8 unknown;
} __packed;

struct ps3_eurus_cmd_ap_wpa_group_cipher_suite {
	__be32 cipher_suite;	/* enum ps3_eurus_wpa_cipher_suite */
} __packed;

struct ps3_eurus_cmd_ap_wpa_psk_passphrase {
	u8 passphrase[64];
} __packed;

struct ps3_eurus_cmd_0xd5 {
	__le32 unknown;
} __packed;

struct ps3_eurus_cmd_0x127 {
	u8 res[4];
} __packed;

struct ps3_eurus_cmd_0x12b {
	u8 res[4];
} __packed;

struct ps3_eurus_cmd_ap_wpa_psk_bin {
	u8 enable;
	u8 psk[32];
} __packed;

struct ps3_eurus_cmd_ap_wpa_pairwise_cipher_suite {
	__be32 cipher_suite;	/* enum ps3_eurus_wpa_cipher_suite */
	u8 unknown;
} __packed;

struct ps3_eurus_cmd_0x1d9 {
	u8 unknown1;
	u8 unknown2;
	u8 res[2];
} __packed;

struct ps3_eurus_cmd_start_ap {
	u8 unknown;
} __packed;

struct ps3_eurus_cmd_0x1ed {
	__le32 unknown1;
	u8 unknown2;
	u8 unknown3;
	u8 unknown4;
	u8 unknown5;
	u8 unknown6;
	u8 unknown7;
	u8 unknown8;
} __packed;

struct ps3_eurus_cmd_get_hw_revision {
	u8 unknown[4];
} __packed;

struct ps3_eurus_cmd_0x203 {
	__le32 unknown;
} __packed;

struct ps3_eurus_cmd_0x207 {
	__le32 unknown;
} __packed;

struct ps3_eurus_cmd_associate {
	u8 unknown;
} __packed;

struct ps3_eurus_cmd_common_config {
	u8 bss_type;		/* enum ps3_eurus_bss_type */
	u8 auth_mode;		/* enum ps3_eurus_auth_mode */
	u8 opmode;		/* enum ps3_eurus_opmode */
	u8 unknown;
	u8 bssid[6];
	__le16 capability;
	u8 ie[0];
} __packed;

struct ps3_eurus_cmd_wep_config {
	u8 unknown1;
	u8 security_mode;		/* enum ps3_eurus_wep_security_mode */
	__le16 unknown2;
	u8 key[4][16];
} __packed;

struct ps3_eurus_cmd_wpa_config {
	u8 unknown;
	u8 security_mode;		/* enum ps3_eurus_wpa_security_mode */
	u8 psk_type;			/* enum ps3_eurus_wpa_psk_type */
	u8 psk[64];
	__be32 group_cipher_suite;	/* enum ps3_eurus_wpa_cipher_suite */
	__be32 pairwise_cipher_suite;	/* enum ps3_eurus_wpa_cipher_suite */
	__be32 akm_suite;		/* enum ps3_eurus_wpa_akm_suite */
} __packed;

struct ps3_eurus_cmd_0x1025 {
	u8 preamble_mode;	/* enum ps3_eurus_preamble_mode */
	u8 res[3];
} __packed;

struct ps3_eurus_cmd_0x1031 {
	u8 unknown1;
	u8 unknown2;
} __packed;

struct ps3_eurus_scan_result {
	__le16 length;
	u8 bssid[6];
	u8 rssi;
	__le64 timestamp;
	__le16 beacon_period;		/* in msec */
	__le16 capability;
	u8 ie[0];
} __packed;

#define PS3_EURUS_SCAN_RESULTS_MAXSIZE	0x5b0

struct ps3_eurus_cmd_get_scan_results {
	u8 count;
	struct ps3_eurus_scan_result result[0];
} __packed;

struct ps3_eurus_cmd_start_scan {
	u8 unknown1;
	u8 unknown2;
	__le16 channel_dwell;	/* in msec */
	u8 res[6];
	u8 ie[0];
} __packed;

struct ps3_eurus_cmd_disassociate {
	u8 unknown;
} __packed;

struct ps3_eurus_cmd_get_rssi {
	u8 res[10];
	u8 rssi;
} __packed;

struct ps3_eurus_cmd_get_mac_addr {
	u8 unknown;
	u8 mac_addr[6];
} __packed;

struct ps3_eurus_cmd_set_mac_addr {
	u8 mac_addr[6];
} __packed;

struct ps3_eurus_cmd_0x104d {
	u8 unknown;
} __packed;

struct ps3_eurus_cmd_0x104f {
	u8 unknown;
} __packed;

struct ps3_eurus_cmd_0x105f {
	__le16 channel_info;
	u8 mac_addr[6];
	u8 unknown1;
	u8 unknown2;
} __packed;

struct ps3_eurus_cmd_0x1109 {
	__le16 unknown1;
	__le16 unknown2;
	__le16 unknown3;
	__le16 unknown4;
	__le16 unknown5;
	__le16 unknown6;
	__le16 unknown7;
	u8 unknown8;
	u8 res;
	u8 unknown9;
	u8 unknown10;
	__le16 unknown11;
	__le16 unknown12;
} __packed;

struct ps3_eurus_cmd_0x110b {
	__le32 unknown1;
	u8 res[4];
	__le32 unknown2;
} __packed;

struct ps3_eurus_cmd_0x110d {
	u8 res1[12];
	__le32 unknown1;
	__le32 unknown2;
	__le32 unknown3;
	__le32 unknown4;
	__le32 unknown5;
	__le32 unknown6;
	__le32 unknown7;
	u8 res2[88];
} __packed;

struct ps3_eurus_cmd_0x1133 {
	u8 unknown1;
	u8 unknown2;
	u8 unknown3;
	u8 unknown4;
	__le32 unknown5;
	u8 res[6];
} __packed;

struct ps3_eurus_cmd_0x114f {
	u8 res[1304];
} __packed;

struct ps3_eurus_cmd_0x115b {
	__le16 unknown1;
	__le16 unknown2;
	u8 mac_addr[6];
	u8 res[84];
} __packed;

struct ps3_eurus_cmd_mcast_addr_filter {
	__le32 word[8];
} __packed;

struct ps3_eurus_cmd_0x116d {
	__le32 unknown;
} __packed;

struct ps3_eurus_cmd_0x116f {
	__le32 unknown;
} __packed;

#define PS3_EURUS_MAC_ADDR_LIST_MAXSIZE	0xc2

struct ps3_eurus_cmd_get_mac_addr_list {
	__le16 count;	/* number of MAC addresses */
	u8 mac_addr[0];
} __packed;

struct ps3_eurus_cmd_get_channel_info {
	u16 channel_info;
} __packed;

struct ps3_eurus_event_hdr {
	__le32 type;			/* enum ps3_eurus_event_type */
	__le32 id;			/* enum ps3_eurus_event_id */
	__le32 timestamp;
	__le32 payload_length;
	__le32 unknown;
} __packed;

struct ps3_eurus_event {
	struct ps3_eurus_event_hdr hdr;
	u8 payload[44];
} __packed;

/*
 * ps3_eurus_rssi2percentage
 */
static inline u8 ps3_eurus_rssi2percentage(u8 rssi)
{
	if (rssi > 89)
		return 1;
	else if (rssi < 50)
		return 100;
	else
		return ((90 - rssi) * 100) / 40;
}

#define PS3_EURUS_MCAST_ADDR_HASH2VAL(h)	(1 << ((h) & 0x1f))
#define PS3_EURUS_MCAST_ADDR_HASH2POS(h)	(((h) >> 5) & 0x7)

/*
 * ps3_eurus_mcast_addr_hash
 */
static inline u8 ps3_eurus_mcast_addr_hash(const u8 mac_addr[ETH_ALEN])
{
	u8 buf[ETH_ALEN];
	u32 h;
	unsigned int i, j;

	memcpy(buf, mac_addr, ETH_ALEN);

	/* reverse bits in each byte */

	for (i = 0; i < ETH_ALEN; i++) {
		buf[i] = (buf[i] >> 4) | ((buf[i] & 0xf) << 4);
		buf[i] = ((buf[i] & 0xcc) >> 2) | ((buf[i] & 0x33) << 2);
		buf[i] = ((buf[i] & 0xaa) >> 1) | ((buf[i] & 0x55) << 1);
	}

        h = 0xffffffff;

        for (i = 0; i < ETH_ALEN; i++) {
                h = (((unsigned int) buf[i]) << 24) ^ h;

                for (j = 0; j < 8; j++) {
                        if (((int) h) >= 0) {
                                h = h << 1;
                        } else {
                                h = (h << 1) ^ 0x4c10000;
                                h = h ^ 0x1db7;
                        }
                }
        }

        h = ((h >> 24) & 0xf8) | (h & 0x7);

        return (h & 0xff);
}

/*
 * ps3_eurus_make_cmd_0x1109
 */
static inline void ps3_eurus_make_cmd_0x1109(struct ps3_eurus_cmd_0x1109 *cmd_0x1109,
	u8 arg1, u16 arg2, u16 arg3, u16 arg4, u16 arg5)
{
	memset(cmd_0x1109, 0, sizeof(*cmd_0x1109));

	cmd_0x1109->unknown1 = cpu_to_le16(0x1);
	cmd_0x1109->unknown8 = arg1;

	if (arg1 == 0x0) {
		cmd_0x1109->unknown6 = cpu_to_le16(0xa);
	} else if (arg1 == 0x1) {
		cmd_0x1109->unknown2 = cpu_to_le16(arg2);
		cmd_0x1109->unknown3 = cpu_to_le16(arg3);
		cmd_0x1109->unknown4 = cpu_to_le16(arg5);

		if (arg2 == 0x0)
			cmd_0x1109->unknown5 = cpu_to_le16(0x6);
		else
			cmd_0x1109->unknown5 = cpu_to_le16(0x2);

		cmd_0x1109->unknown7 = cpu_to_le16(arg4);
		cmd_0x1109->unknown9 = 0xff;
		cmd_0x1109->unknown10 = 0xff;
		cmd_0x1109->unknown11 = 0xffff;
		cmd_0x1109->unknown12 = 0xffff;
	}
}

#endif
