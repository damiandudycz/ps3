
/*
 * PS3 Jupiter
 *
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

#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/slab.h>
#include <linux/usb.h>
#include <linux/notifier.h>

#include <linux/etherdevice.h>
#include <linux/if_ether.h>

#include <asm/byteorder.h>
#include <asm/ps3.h>
#include <asm/lv1call.h>

#include "ps3_eurus.h"
#include "ps3_jupiter.h"

#define PS3_JUPITER_EP			0x5

#define PS3_JUPITER_IRQ_BUFSIZE		2048
#define PS3_JUPITER_CMD_BUFSIZE		2048

#define LV1_SB_BUS_ID			0x1
#define LV1_GELIC_DEV_ID		0x0
#define LV1_GET_MAC_ADDRESS		0x1
#define LV1_GET_CHANNEL_INFO		0x6

enum ps3_jupiter_pkt_type {
	PS3_JUPITER_PKT_CMD	= 6,
	PS3_JUPITER_PKT_EVENT	= 8,
};

struct ps3_jupiter_dev {
	struct usb_device *udev;
	struct urb *irq_urb, *cmd_urb;
	void *irq_buf, *cmd_buf;

	u16 cmd_tag, eurus_cmd, eurus_tag;
	struct completion cmd_done_comp;
	spinlock_t cmd_lock;
	int cmd_busy, cmd_err;

	struct workqueue_struct *event_queue;
	struct delayed_work event_work;
	struct blocking_notifier_head event_listeners;
	struct list_head event_list;
	spinlock_t event_list_lock;

	struct notifier_block event_listener;
	struct completion event_comp;

	unsigned char mac_addr[ETH_ALEN];
	u64 channel_info;

	u16 dev_status;
	int dev_ready;
};

struct ps3_jupiter_pkt_hdr {
	u8 unknown1;
	u8 unknown2;
	u8 type;
} __packed;

struct ps3_jupiter_cmd_hdr {
	u8 unknown1;
	__le16 unknown2;
	u8 res1[2];
	__le16 tag;
	u8 res2[14];
} __packed;

struct ps3_jupiter_event_hdr {
	u8 count;
} __packed;

struct ps3_jupiter_list_event {
	struct list_head list;
	struct ps3_eurus_event event;
};

static struct ps3_jupiter_dev *ps3jd;

static unsigned char ps3_jupiter_devkey[] = {
	0x76, 0x4e, 0x4b, 0x07, 0x24, 0x42, 0x53, 0xfb, 0x5a, 0xc7, 0xcc, 0x1d, 0xae, 0x00, 0xc6, 0xd8,
	0x14, 0x40, 0x61, 0x8b, 0x13, 0x17, 0x4d, 0x7c, 0x3b, 0xb6, 0x90, 0xb8, 0x6e, 0x8b, 0xbb, 0x1d,
};

/*
 * ps3_jupiter_event_worker
 */
static void ps3_jupiter_event_worker(struct work_struct *work)
{
	struct ps3_jupiter_dev *jd = container_of(work, struct ps3_jupiter_dev, event_work.work);
	struct ps3_jupiter_list_event *list_event;
	unsigned long flags;

	/* dispatch received events to each listener */

	while (1) {
		spin_lock_irqsave(&jd->event_list_lock, flags);

		if (list_empty(&jd->event_list)) {
			spin_unlock_irqrestore(&jd->event_list_lock, flags);
			break;
		}

		list_event = list_entry(jd->event_list.next, struct ps3_jupiter_list_event, list);
		list_del(&list_event->list);

		spin_unlock_irqrestore(&jd->event_list_lock, flags);

		blocking_notifier_call_chain(&jd->event_listeners, 0, &list_event->event);

		kfree(list_event);
	}
}

/*
 * ps3_jupiter_event_irq
 */
static void ps3_jupiter_event_irq(struct ps3_jupiter_dev *jd,
	void *buf, unsigned int length)
{
	struct usb_device *udev = jd->udev;
	struct ps3_jupiter_pkt_hdr *pkt_hdr;
	struct ps3_jupiter_event_hdr *event_hdr;
	struct ps3_jupiter_list_event *list_event;
	unsigned long flags;
	int i;

	dev_dbg(&udev->dev, "got event IRQ packet\n");

	if (length < sizeof(*pkt_hdr) + sizeof(*event_hdr)) {
		dev_err(&udev->dev, "got event IRQ packet with invalid length (%d)\n",
		    length);
		return;
	}

	pkt_hdr = (struct ps3_jupiter_pkt_hdr *) buf;
	event_hdr = (struct ps3_jupiter_event_hdr *) (pkt_hdr + 1);

	if (length < sizeof(*pkt_hdr) + sizeof(*event_hdr) +
		event_hdr->count * sizeof(struct ps3_eurus_event)) {
		dev_err(&udev->dev, "got event IRQ packet with invalid length (%d)\n",
		    length);
		return;
	}

	dev_dbg(&udev->dev, "got %d event(s)\n", event_hdr->count);

	for (i = 0; i < event_hdr->count; i++) {
		list_event = kmalloc(sizeof(*list_event), GFP_ATOMIC);
		if (!list_event) {
			dev_err(&udev->dev, "could not allocate memory for new event\n");
			continue;
		}

		memcpy(&list_event->event, (unsigned char *) event_hdr + sizeof(*event_hdr) +
		    i * sizeof(struct ps3_eurus_event), sizeof(struct ps3_eurus_event));
		list_event->event.hdr.type = le32_to_cpu(list_event->event.hdr.type);
		list_event->event.hdr.id = le32_to_cpu(list_event->event.hdr.id);
		list_event->event.hdr.timestamp = le32_to_cpu(list_event->event.hdr.timestamp);
		list_event->event.hdr.payload_length = le32_to_cpu(list_event->event.hdr.payload_length);
		list_event->event.hdr.unknown = le32_to_cpu(list_event->event.hdr.unknown);

		spin_lock_irqsave(&jd->event_list_lock, flags);
		list_add_tail(&list_event->list, &jd->event_list);
		spin_unlock_irqrestore(&jd->event_list_lock, flags);
	}

	if (event_hdr->count)
		queue_delayed_work(jd->event_queue, &jd->event_work, 0);
}

/*
 * ps3_jupiter_cmd_irq
 */
static void ps3_jupiter_cmd_irq(struct ps3_jupiter_dev *jd,
	void *buf, unsigned int length)
{
	struct usb_device *udev = jd->udev;
	struct ps3_jupiter_pkt_hdr *pkt_hdr;
	struct ps3_jupiter_cmd_hdr *cmd_hdr;
	struct ps3_eurus_cmd_hdr *eurus_cmd_hdr;
	u16 cmd_tag, eurus_cmd, eurus_tag, payload_length;

	dev_dbg(&udev->dev, "got command IRQ packet\n");

	if (length < sizeof(*pkt_hdr) + sizeof(*cmd_hdr) + sizeof(*eurus_cmd_hdr)) {
		dev_err(&udev->dev, "got command IRQ packet with invalid length (%d)\n",
		    length);
		return;
	}

	pkt_hdr = (struct ps3_jupiter_pkt_hdr *) buf;
	cmd_hdr = (struct ps3_jupiter_cmd_hdr *) (pkt_hdr + 1);
	eurus_cmd_hdr = (struct ps3_eurus_cmd_hdr *) (cmd_hdr + 1);
	payload_length = le16_to_cpu(eurus_cmd_hdr->payload_length);

	if (length < sizeof(*pkt_hdr) + sizeof(*cmd_hdr) + sizeof(*eurus_cmd_hdr) + payload_length) {
		dev_err(&udev->dev, "got command IRQ packet with invalid length (%d)\n",
		    length);
		return;
	}

	cmd_tag = le16_to_cpu(cmd_hdr->tag);

	if (jd->cmd_tag != cmd_tag)
		dev_err(&udev->dev, "got command IRQ packet with invalid command tag, "
		    "got (0x%04x), expected (0x%04x)\n", cmd_tag, jd->cmd_tag);

	eurus_cmd = le16_to_cpu(eurus_cmd_hdr->id);

	if ((jd->eurus_cmd + 1) != eurus_cmd)
		dev_err(&udev->dev, "got command IRQ packet with invalid EURUS command, "
		    "got (0x%04x), expected (0x%04x)\n", eurus_cmd, jd->eurus_cmd);

	eurus_tag = le16_to_cpu(eurus_cmd_hdr->tag);

	if (jd->eurus_tag != eurus_tag)
		dev_err(&udev->dev, "got command IRQ packet with invalid EURUS tag, "
		    "got (0x%04x), expected (0x%04x)\n", eurus_tag, jd->eurus_tag);

	memcpy(jd->cmd_buf, buf, length);

	jd->cmd_err = 0;
	complete(&jd->cmd_done_comp);
}

/*
 * ps3_jupiter_irq_urb_complete
 */
static void ps3_jupiter_irq_urb_complete(struct urb *urb)
{
	struct ps3_jupiter_dev *jd = urb->context;
	struct usb_device *udev = jd->udev;
	struct ps3_jupiter_pkt_hdr *pkt_hdr;
	int err;

	dev_dbg(&udev->dev, "IRQ URB completed (%d)\n", urb->status);

	switch (urb->status) {
	case 0:
		if (urb->actual_length < sizeof(*pkt_hdr)) {
			dev_err(&udev->dev, "got IRQ packet with invalid length (%d)\n",
			    urb->actual_length);
			break;
		}

		pkt_hdr = (struct ps3_jupiter_pkt_hdr *) jd->irq_buf;

		switch (pkt_hdr->type) {
		case PS3_JUPITER_PKT_CMD:
			ps3_jupiter_cmd_irq(jd, pkt_hdr, urb->actual_length);
		break;
		case PS3_JUPITER_PKT_EVENT:
			ps3_jupiter_event_irq(jd, pkt_hdr, urb->actual_length);
		break;
		default:
			dev_err(&udev->dev, "got unknown IRQ packet type (%d)\n",
			    pkt_hdr->type);
		}
	break;
	case -EINPROGRESS:
		/* ignore */
	break;
	case -ECONNRESET:
	case -ENOENT:
	case -ESHUTDOWN:
	case -ENODEV:
	return;
	default:
		dev_err(&udev->dev, "IRQ URB failed (%d)\n", urb->status);
	}

	err = usb_submit_urb(jd->irq_urb, GFP_ATOMIC);
	if (err)
		dev_err(&udev->dev, "could not submit IRQ URB (%d)\n", err);
}

/*
 * ps3_jupiter_cmd_urb_complete
 */
static void ps3_jupiter_cmd_urb_complete(struct urb *urb)
{
	struct ps3_jupiter_dev *jd = urb->context;
	struct usb_device *udev = jd->udev;

	dev_dbg(&udev->dev, "command URB completed (%d)\n", urb->status);

	switch (urb->status) {
	case 0:
		/* success */
	break;
	case -EINPROGRESS:
		/* ignore */
	break;
	case -ECONNRESET:
	case -ENOENT:
	case -ESHUTDOWN:
	case -ENODEV:
	default:
		dev_err(&udev->dev, "command URB failed (%d)\n", urb->status);
		jd->cmd_err = urb->status;
		complete(&jd->cmd_done_comp);
	}
}

/*
 * _ps3_jupiter_register_event_listener
 */
static int _ps3_jupiter_register_event_listener(struct ps3_jupiter_dev *jd,
	struct notifier_block *listener)
{
	BUG_ON(!jd);

	return blocking_notifier_chain_register(&jd->event_listeners, listener);
}

/*
 * ps3_jupiter_register_event_listener
 */
int ps3_jupiter_register_event_listener(struct notifier_block *listener)
{
	struct ps3_jupiter_dev *jd = ps3jd;
	int err;

	if (!jd || !jd->dev_ready)
		return -ENODEV;

	err = _ps3_jupiter_register_event_listener(jd, listener);

	return err;
}

EXPORT_SYMBOL_GPL(ps3_jupiter_register_event_listener);

/*
 * _ps3_jupiter_unregister_event_listener
 */
static int _ps3_jupiter_unregister_event_listener(struct ps3_jupiter_dev *jd,
	struct notifier_block *listener)
{
	BUG_ON(!jd);

	return blocking_notifier_chain_unregister(&jd->event_listeners, listener);
}

/*
 * ps3_jupiter_unregister_event_listener
 */
int ps3_jupiter_unregister_event_listener(struct notifier_block *listener)
{
	struct ps3_jupiter_dev *jd = ps3jd;
	int err;

	if (!jd || !jd->dev_ready)
		return -ENODEV;

	err = _ps3_jupiter_unregister_event_listener(jd, listener);

	return err;
}

EXPORT_SYMBOL_GPL(ps3_jupiter_unregister_event_listener);

/*
 * _ps3_jupiter_exec_eurus_cmd
 */
static int _ps3_jupiter_exec_eurus_cmd(struct ps3_jupiter_dev *jd,
	enum ps3_eurus_cmd_id cmd,
	void *payload, unsigned int payload_length,
	unsigned int *response_status,
	unsigned int *response_length, void *response)
{
	struct usb_device *udev = jd->udev;
	struct ps3_jupiter_pkt_hdr *pkt_hdr;
	struct ps3_jupiter_cmd_hdr *cmd_hdr;
	struct ps3_eurus_cmd_hdr *eurus_cmd_hdr;
	struct ps3_eurus_cmd_get_channel_info *eurus_cmd_get_channel_info;
	u16 status;
	unsigned long flags;
	int err;

	BUG_ON(!jd);

	if (!payload && payload_length)
		return -EINVAL;

	spin_lock_irqsave(&jd->cmd_lock, flags);

	if (jd->cmd_busy) {
		spin_unlock_irqrestore(&jd->cmd_lock, flags);
		dev_dbg(&udev->dev,
		    "trying to execute multiple commands at the same time\n");
		return -EAGAIN;
	}

	jd->cmd_busy = 1;

	spin_unlock_irqrestore(&jd->cmd_lock, flags);

	dev_dbg(&udev->dev, "EURUS command 0x%04x payload length %d\n",
	    cmd, payload_length);

	/* internal commands */

	if (cmd == PS3_EURUS_CMD_GET_CHANNEL_INFO) {
		if (payload_length < sizeof(*eurus_cmd_get_channel_info)) {
			err = -EINVAL;
			goto done;
		}

		if (response_status)
			*response_status = PS3_EURUS_CMD_OK;

		if (response_length && response) {
			*response_length = sizeof(*eurus_cmd_get_channel_info);
			eurus_cmd_get_channel_info = (struct ps3_eurus_cmd_get_channel_info *) response;
			memset(eurus_cmd_get_channel_info, 0, sizeof(*eurus_cmd_get_channel_info));
			eurus_cmd_get_channel_info->channel_info = jd->channel_info >> 48;
		}

		err = 0;

		goto done;
	}

	pkt_hdr = (struct ps3_jupiter_pkt_hdr *) jd->cmd_buf;
	memset(pkt_hdr, 0, sizeof(*pkt_hdr));
	pkt_hdr->unknown1 = 1;
	pkt_hdr->unknown2 = 1;
	pkt_hdr->type = PS3_JUPITER_PKT_CMD;

	cmd_hdr = (struct ps3_jupiter_cmd_hdr *) (pkt_hdr + 1);
	memset(cmd_hdr, 0, sizeof(*cmd_hdr));
	jd->cmd_tag++;
	cmd_hdr->unknown1 = 0;
	cmd_hdr->unknown2 = cpu_to_le16(1);
	cmd_hdr->tag = cpu_to_le16(jd->cmd_tag);

	eurus_cmd_hdr = (struct ps3_eurus_cmd_hdr *) (cmd_hdr + 1);
	memset(eurus_cmd_hdr, 0, sizeof(*eurus_cmd_hdr));
	jd->eurus_cmd = cmd;
	eurus_cmd_hdr->id = cpu_to_le16(cmd);
	jd->eurus_tag++;
	eurus_cmd_hdr->tag = cpu_to_le16(jd->eurus_tag);
	eurus_cmd_hdr->status = cpu_to_le16(0xa);
	eurus_cmd_hdr->payload_length = cpu_to_le16(payload_length);

	if (payload_length)
		memcpy(eurus_cmd_hdr + 1, payload, payload_length);

	init_completion(&jd->cmd_done_comp);

	usb_fill_int_urb(jd->cmd_urb, udev, usb_sndintpipe(udev, PS3_JUPITER_EP),
	    jd->cmd_buf, sizeof(*pkt_hdr) + sizeof(*cmd_hdr) + sizeof(*eurus_cmd_hdr) + payload_length,
	    ps3_jupiter_cmd_urb_complete, jd, 1);

	err = usb_submit_urb(jd->cmd_urb, GFP_KERNEL);
	if (err) {
		dev_err(&udev->dev, "could not submit command URB (%d)\n", err);
		goto done;
	}

	err = wait_for_completion_timeout(&jd->cmd_done_comp, HZ);
	if (!err) {
		err = -ETIMEDOUT;
		goto done;
	}

	err = jd->cmd_err;
	if (!err) {
		status = le16_to_cpu(eurus_cmd_hdr->status);

		if (response_status)
			*response_status = status;

		if (response_length && response) {
			*response_length = le16_to_cpu(eurus_cmd_hdr->payload_length);
			memcpy(response, eurus_cmd_hdr + 1, *response_length);
		}

		if (status != PS3_EURUS_CMD_OK)
			dev_err(&udev->dev, "EURUS command 0x%04x status (0x%04x)\n", cmd, status);
	}

done:

	if (err)
		dev_err(&udev->dev, "EURUS command 0x%04x failed (%d)\n", cmd, err);

	jd->cmd_busy = 0;

	return err;
}

/*
 * _ps3_jupiter_exec_eurus_cmd
 */
int ps3_jupiter_exec_eurus_cmd(enum ps3_eurus_cmd_id cmd,
	void *payload, unsigned int payload_length,
	unsigned int *response_status,
	unsigned int *response_length, void *response)
{
	struct ps3_jupiter_dev *jd = ps3jd;
	int err;

	if (!jd || !jd->dev_ready)
		return -ENODEV;

	err = _ps3_jupiter_exec_eurus_cmd(jd, cmd, payload, payload_length,
	    response_status, response_length, response);

	return err;
}

EXPORT_SYMBOL_GPL(ps3_jupiter_exec_eurus_cmd);

/*
 * ps3_jupiter_create_event_worker
 */
static int ps3_jupiter_create_event_worker(struct ps3_jupiter_dev *jd)
{
	jd->event_queue = create_singlethread_workqueue("ps3_jupiter_event");
	if (!jd->event_queue)
		return -ENOMEM;

	INIT_DELAYED_WORK(&jd->event_work, ps3_jupiter_event_worker);

	return 0;
}

/*
 * ps3_jupiter_destroy_event_worker
 */
static void ps3_jupiter_destroy_event_worker(struct ps3_jupiter_dev *jd)
{
	if (jd->event_queue) {
		cancel_delayed_work(&jd->event_work);
		flush_workqueue(jd->event_queue);
		destroy_workqueue(jd->event_queue);
		jd->event_queue = NULL;
	}
}

/*
 * ps3_jupiter_free_event_list
 */
static void ps3_jupiter_free_event_list(struct ps3_jupiter_dev *jd)
{
	struct ps3_jupiter_list_event *event, *tmp;

	list_for_each_entry_safe(event, tmp, &jd->event_list, list) {
		list_del(&event->list);
		kfree(event);
	}
}

/*
 * ps3_jupiter_alloc_urbs
 */
static int ps3_jupiter_alloc_urbs(struct ps3_jupiter_dev *jd)
{
	struct usb_device *udev = jd->udev;

	jd->irq_urb = usb_alloc_urb(0, GFP_KERNEL);
	if (!jd->irq_urb)
		return -ENOMEM;

	jd->irq_buf = usb_alloc_coherent(udev, PS3_JUPITER_IRQ_BUFSIZE,
	    GFP_KERNEL, &jd->irq_urb->transfer_dma);
	if (!jd->irq_buf)
		return -ENOMEM;

	usb_fill_int_urb(jd->irq_urb, udev, usb_rcvintpipe(udev, PS3_JUPITER_EP),
	    jd->irq_buf, PS3_JUPITER_IRQ_BUFSIZE, ps3_jupiter_irq_urb_complete, jd, 1);
	jd->irq_urb->transfer_flags |= URB_NO_TRANSFER_DMA_MAP;

	jd->cmd_urb = usb_alloc_urb(0, GFP_KERNEL);
	if (!jd->cmd_urb)
		return -ENOMEM;

	jd->cmd_buf = usb_alloc_coherent(udev, PS3_JUPITER_CMD_BUFSIZE,
	    GFP_KERNEL, &jd->cmd_urb->transfer_dma);
	if (!jd->cmd_buf)
		return -ENOMEM;

	usb_fill_int_urb(jd->cmd_urb, udev, usb_sndintpipe(udev, PS3_JUPITER_EP),
	    jd->cmd_buf, PS3_JUPITER_CMD_BUFSIZE, ps3_jupiter_cmd_urb_complete, jd, 1);
	jd->cmd_urb->transfer_flags |= URB_NO_TRANSFER_DMA_MAP;

	return 0;
}

/*
 * ps3_jupiter_free_urbs
 */
static void ps3_jupiter_free_urbs(struct ps3_jupiter_dev *jd)
{
	struct usb_device *udev = jd->udev;

	if (jd->irq_urb) {
		usb_kill_urb(jd->irq_urb);

		if (jd->irq_buf)
			usb_free_coherent(udev, PS3_JUPITER_IRQ_BUFSIZE,
			    jd->irq_buf, jd->irq_urb->transfer_dma);

		usb_free_urb(jd->irq_urb);
	}

	if (jd->cmd_urb) {
		usb_kill_urb(jd->cmd_urb);

		if (jd->cmd_buf)
			usb_free_coherent(udev, PS3_JUPITER_CMD_BUFSIZE,
			    jd->cmd_buf, jd->cmd_urb->transfer_dma);

		usb_free_urb(jd->cmd_urb);
	}
}

/*
 * ps3_jupiter_dev_auth
 */
static int ps3_jupiter_dev_auth(struct ps3_jupiter_dev *jd)
{
	struct usb_device *udev = jd->udev;
	void *buf;
	int err;

	buf = kmalloc(sizeof(ps3_jupiter_devkey), GFP_KERNEL);
	if (!buf)
		return -ENOMEM;

	memcpy(buf, ps3_jupiter_devkey, sizeof(ps3_jupiter_devkey));

	err = usb_control_msg(udev, usb_sndctrlpipe(udev, 0),
	    0x1, USB_TYPE_VENDOR | USB_DIR_OUT | USB_RECIP_DEVICE, 0x9, 0x0,
	    buf, sizeof(ps3_jupiter_devkey), USB_CTRL_SET_TIMEOUT);
	kfree(buf);
	if (err < 0) {
		dev_dbg(&udev->dev, "could not send device key (%d)\n", err);
		return err;
	}


	err = usb_control_msg(udev, usb_rcvctrlpipe(udev, 0),
	    0x0, USB_TYPE_VENDOR | USB_DIR_IN | USB_RECIP_DEVICE, 0x2, 0x0,
	    &jd->dev_status, sizeof(jd->dev_status), USB_CTRL_GET_TIMEOUT);
	if (err < 0) {
		dev_dbg(&udev->dev, "could not read device status (%d)\n", err);
		return err;
	}

	dev_info(&udev->dev, "device status (0x%04x)\n", jd->dev_status);

	return 0;
}

/*
 * ps3_jupiter_event_handler
 */
static int ps3_jupiter_event_handler(struct notifier_block *n,
	unsigned long val, void *v)
{
	struct ps3_jupiter_dev *jd = container_of(n, struct ps3_jupiter_dev, event_listener);
	struct usb_device *udev = jd->udev;
	struct ps3_eurus_event *event = v;

	dev_dbg(&udev->dev, "got event (0x%08x 0x%08x 0x%08x 0x%08x 0x%08x)\n",
	    event->hdr.type, event->hdr.id, event->hdr.timestamp, event->hdr.payload_length,
	    event->hdr.unknown);

	if (event->hdr.type == PS3_EURUS_EVENT_TYPE_0x400) {
		if ((event->hdr.id == 0x8) || (event->hdr.id == 0x10))
			complete(&jd->event_comp);
	}

	return NOTIFY_OK;
}

/*
 * ps3_jupiter_dev_init
 */
static int ps3_jupiter_dev_init(struct ps3_jupiter_dev *jd)
{
	struct usb_device *udev = jd->udev;
	struct ps3_eurus_cmd_0x114f *eurus_cmd_0x114f;
	struct ps3_eurus_cmd_0x116f *eurus_cmd_0x116f;
	struct ps3_eurus_cmd_0x115b *eurus_cmd_0x115b;
	const u8 bcast_addr[] = { 0xff, 0xff, 0xff, 0xff, 0xff, 0xff };
	u8 h;
	struct ps3_eurus_cmd_mcast_addr_filter *eurus_cmd_mcast_addr_filter;
	struct ps3_eurus_cmd_0x110d *eurus_cmd_0x110d;
	struct ps3_eurus_cmd_0x1031 *eurus_cmd_0x1031;
	struct ps3_eurus_cmd_set_mac_addr *eurus_cmd_set_mac_addr;
	struct ps3_eurus_cmd_set_antenna *eurus_cmd_set_antenna;
	struct ps3_eurus_cmd_0x110b *eurus_cmd_0x110b;
	struct ps3_eurus_cmd_0x1109 *eurus_cmd_0x1109;
	struct ps3_eurus_cmd_0x207 *eurus_cmd_0x207;
	struct ps3_eurus_cmd_0x203 *eurus_cmd_0x203;
	struct ps3_eurus_cmd_0x105f *eurus_cmd_0x105f;
	struct ps3_eurus_cmd_get_fw_version *eurus_cmd_get_fw_version;
	unsigned char *buf;
	unsigned int status, response_length;
	int err;

	buf = kmalloc(PS3_JUPITER_CMD_BUFSIZE, GFP_KERNEL);
	if (!buf)
		return -ENOMEM;

	/* state 1 */

	eurus_cmd_0x114f = (struct ps3_eurus_cmd_0x114f *) buf;
	memset(eurus_cmd_0x114f, 0, sizeof(*eurus_cmd_0x114f));

	err = _ps3_jupiter_exec_eurus_cmd(jd, PS3_EURUS_CMD_0x114f,
	    eurus_cmd_0x114f, sizeof(*eurus_cmd_0x114f), &status, NULL, NULL);
	if (err)
		goto done;

	/* do not check command status here !!! */

	/* state 2 */

	init_completion(&jd->event_comp);

	err = _ps3_jupiter_exec_eurus_cmd(jd, PS3_EURUS_CMD_0x1171, NULL, 0, &status, NULL, NULL);
	if (err)
		goto done;

	if (status != PS3_EURUS_CMD_OK) {
		err = -EIO;
		goto done;
	}

	/* state 3 */

	err = wait_for_completion_timeout(&jd->event_comp, HZ);
	if (!err) {
		err = -ETIMEDOUT;
		goto done;
	}

	/* state 4 */

	eurus_cmd_0x116f = (struct ps3_eurus_cmd_0x116f *) buf;
	memset(eurus_cmd_0x116f, 0, sizeof(*eurus_cmd_0x116f));
	eurus_cmd_0x116f->unknown = cpu_to_le32(0x1);

	err = _ps3_jupiter_exec_eurus_cmd(jd, PS3_EURUS_CMD_0x116f,
	    eurus_cmd_0x116f, sizeof(*eurus_cmd_0x116f), &status, NULL, NULL);
	if (err)
		goto done;

	if (status != PS3_EURUS_CMD_OK) {
		err = -EIO;
		goto done;
	}

	/* state 5 */

	eurus_cmd_0x115b = (struct ps3_eurus_cmd_0x115b *) buf;
	memset(eurus_cmd_0x115b, 0, sizeof(*eurus_cmd_0x115b));
	eurus_cmd_0x115b->unknown1 = cpu_to_le16(0x1);
	eurus_cmd_0x115b->unknown2 = cpu_to_le16(0x0);
	memcpy(eurus_cmd_0x115b->mac_addr, jd->mac_addr, sizeof(jd->mac_addr));

	err = _ps3_jupiter_exec_eurus_cmd(jd, PS3_EURUS_CMD_0x115b,
	    eurus_cmd_0x115b, sizeof(*eurus_cmd_0x115b), &status, NULL, NULL);
	if (err)
		goto done;

	if (status != PS3_EURUS_CMD_OK) {
		err = -EIO;
		goto done;
	}

	/* state 6 */

	h = ps3_eurus_mcast_addr_hash(bcast_addr);

	eurus_cmd_mcast_addr_filter = (struct ps3_eurus_cmd_mcast_addr_filter *) buf;
	memset(eurus_cmd_mcast_addr_filter, 0, sizeof(*eurus_cmd_mcast_addr_filter));
	eurus_cmd_mcast_addr_filter->word[PS3_EURUS_MCAST_ADDR_HASH2POS(h)] |=
	    cpu_to_le32(PS3_EURUS_MCAST_ADDR_HASH2VAL(h));

	err = _ps3_jupiter_exec_eurus_cmd(jd, PS3_EURUS_CMD_SET_MCAST_ADDR_FILTER,
	    eurus_cmd_mcast_addr_filter, sizeof(*eurus_cmd_mcast_addr_filter), &status, NULL, NULL);
	if (err)
		goto done;

	if (status != PS3_EURUS_CMD_OK) {
		err = -EIO;
		goto done;
	}

	/* state 7 */

	eurus_cmd_0x110d = (struct ps3_eurus_cmd_0x110d *) buf;
	memset(eurus_cmd_0x110d, 0, sizeof(*eurus_cmd_0x110d));
	eurus_cmd_0x110d->unknown1 = cpu_to_le32(0xffffffff);
	eurus_cmd_0x110d->unknown2 = cpu_to_le32(0xffffffff);
	eurus_cmd_0x110d->unknown3 = cpu_to_le32(0xffffffff);
	eurus_cmd_0x110d->unknown4 = cpu_to_le32(0xffffffff);
	eurus_cmd_0x110d->unknown5 = cpu_to_le32(0xffffffff);
	eurus_cmd_0x110d->unknown6 = cpu_to_le32(0xffffffff);
	eurus_cmd_0x110d->unknown7 = cpu_to_le32(0xffffffff);

	err = _ps3_jupiter_exec_eurus_cmd(jd, PS3_EURUS_CMD_0x110d,
	    eurus_cmd_0x110d, sizeof(*eurus_cmd_0x110d), &status, NULL, NULL);
	if (err)
		goto done;

	if (status != PS3_EURUS_CMD_OK) {
		err = -EIO;
		goto done;
	}

	/* state 8 */

	eurus_cmd_0x1031 = (struct ps3_eurus_cmd_0x1031 *) buf;
	memset(eurus_cmd_0x1031, 0, sizeof(*eurus_cmd_0x1031));
	eurus_cmd_0x1031->unknown1 = 0x0;
	eurus_cmd_0x1031->unknown2 = 0x0;

	err = _ps3_jupiter_exec_eurus_cmd(jd, PS3_EURUS_CMD_0x1031,
	    eurus_cmd_0x1031, sizeof(*eurus_cmd_0x1031), &status, NULL, NULL);
	if (err)
		goto done;

	if (status != PS3_EURUS_CMD_OK) {
		err = -EIO;
		goto done;
	}

	/* state 9 */

	eurus_cmd_set_mac_addr = (struct ps3_eurus_cmd_set_mac_addr *) buf;
	memset(eurus_cmd_set_mac_addr, 0, sizeof(*eurus_cmd_set_mac_addr));
	memcpy(eurus_cmd_set_mac_addr->mac_addr, jd->mac_addr, sizeof(jd->mac_addr));

	err = _ps3_jupiter_exec_eurus_cmd(jd, PS3_EURUS_CMD_SET_MAC_ADDR,
	    eurus_cmd_set_mac_addr, sizeof(*eurus_cmd_set_mac_addr), &status, NULL, NULL);
	if (err)
		goto done;

	if (status != PS3_EURUS_CMD_OK) {
		err = -EIO;
		goto done;
	}

	/* state 10 */

	eurus_cmd_set_antenna = (struct ps3_eurus_cmd_set_antenna *) buf;
	memset(eurus_cmd_set_antenna, 0, sizeof(*eurus_cmd_set_antenna));

	if (((jd->channel_info >> 40) & 0xff) == 0x1) {
		eurus_cmd_set_antenna->unknown1 = 0x1;
		eurus_cmd_set_antenna->unknown2 = 0x0;
	} else if (((jd->channel_info >> 40) & 0xff) == 0x2) {
		eurus_cmd_set_antenna->unknown1 = 0x1;
		eurus_cmd_set_antenna->unknown2 = 0x1;
	} else {
		eurus_cmd_set_antenna->unknown1 = 0x2;
		eurus_cmd_set_antenna->unknown2 = 0x2;
	}

	err = _ps3_jupiter_exec_eurus_cmd(jd, PS3_EURUS_CMD_SET_ANTENNA,
	    eurus_cmd_set_antenna, sizeof(*eurus_cmd_set_antenna), &status, NULL, NULL);
	if (err)
		goto done;

	if (status != PS3_EURUS_CMD_OK) {
		err = -EIO;
		goto done;
	}

	/* state 11 */

	eurus_cmd_0x110b = (struct ps3_eurus_cmd_0x110b *) buf;
	memset(eurus_cmd_0x110b, 0, sizeof(*eurus_cmd_0x110b));
	eurus_cmd_0x110b->unknown1 = cpu_to_le32(0x1);
	eurus_cmd_0x110b->unknown2 = cpu_to_le32(0x200000);

	err = _ps3_jupiter_exec_eurus_cmd(jd, PS3_EURUS_CMD_0x110b,
	    eurus_cmd_0x110b, sizeof(*eurus_cmd_0x110b), &status, NULL, NULL);
	if (err)
		goto done;

	if (status != PS3_EURUS_CMD_OK) {
		err = -EIO;
		goto done;
	}

	/* state 12 */

	eurus_cmd_0x1109 = (struct ps3_eurus_cmd_0x1109 *) buf;
	ps3_eurus_make_cmd_0x1109(eurus_cmd_0x1109, 0x1, 0x0, 0x2715, 0x9, 0x12);

	err = _ps3_jupiter_exec_eurus_cmd(jd, PS3_EURUS_CMD_0x1109,
	    eurus_cmd_0x1109, sizeof(*eurus_cmd_0x1109), &status, NULL, NULL);
	if (err)
		goto done;

	if (status != PS3_EURUS_CMD_OK) {
		err = -EIO;
		goto done;
	}

	/* state 13 */

	eurus_cmd_0x207 = (struct ps3_eurus_cmd_0x207 *) buf;
	memset(eurus_cmd_0x207, 0, sizeof(*eurus_cmd_0x207));
	eurus_cmd_0x207->unknown = cpu_to_le32(0x1);

	err = _ps3_jupiter_exec_eurus_cmd(jd, PS3_EURUS_CMD_0x207,
	    eurus_cmd_0x207, sizeof(*eurus_cmd_0x207), &status, NULL, NULL);
	if (err)
		goto done;

	if (status != PS3_EURUS_CMD_OK) {
		err = -EIO;
		goto done;
	}

	/* state 14 */

	eurus_cmd_0x203 = (struct ps3_eurus_cmd_0x203 *) buf;
	memset(eurus_cmd_0x203, 0, sizeof(*eurus_cmd_0x203));
	eurus_cmd_0x203->unknown = cpu_to_le32(0x1);

	err = _ps3_jupiter_exec_eurus_cmd(jd, PS3_EURUS_CMD_0x203,
	    eurus_cmd_0x203, sizeof(*eurus_cmd_0x203), &status, NULL, NULL);
	if (err)
		goto done;

	if (status != PS3_EURUS_CMD_OK) {
		err = -EIO;
		goto done;
	}

	/* state 15 */

	eurus_cmd_0x105f = (struct ps3_eurus_cmd_0x105f *) buf;
	memset(eurus_cmd_0x105f, 0, sizeof(*eurus_cmd_0x105f));
	eurus_cmd_0x105f->channel_info = cpu_to_le16(jd->channel_info >> 48);
	memcpy(eurus_cmd_0x105f->mac_addr, jd->mac_addr, sizeof(jd->mac_addr));

	if (((jd->channel_info >> 40) & 0xff) == 0x1) {
		eurus_cmd_0x105f->unknown1 = 0x1;
		eurus_cmd_0x105f->unknown2 = 0x0;
	} else if (((jd->channel_info >> 40) & 0xff) == 0x2) {
		eurus_cmd_0x105f->unknown1 = 0x1;
		eurus_cmd_0x105f->unknown2 = 0x1;
	} else {
		eurus_cmd_0x105f->unknown1 = 0x2;
		eurus_cmd_0x105f->unknown2 = 0x2;
	}

	err = _ps3_jupiter_exec_eurus_cmd(jd, PS3_EURUS_CMD_0x105f,
	    eurus_cmd_0x105f, sizeof(*eurus_cmd_0x105f), &status, NULL, NULL);
	if (err)
		goto done;

	if (status != PS3_EURUS_CMD_OK) {
		err = -EIO;
		goto done;
	}

	/* device is ready now */

	/* read firmware version */

	eurus_cmd_get_fw_version = (struct ps3_eurus_cmd_get_fw_version *) buf;
	memset(eurus_cmd_get_fw_version, 0, sizeof(*eurus_cmd_get_fw_version));

	err = _ps3_jupiter_exec_eurus_cmd(jd, PS3_EURUS_CMD_GET_FW_VERSION,
	    eurus_cmd_get_fw_version, sizeof(*eurus_cmd_get_fw_version),
	    &status, &response_length, eurus_cmd_get_fw_version);
	if (err)
		goto done;

	if (status != PS3_EURUS_CMD_OK) {
		err = -EIO;
		goto done;
	}

	dev_info(&udev->dev, "firmware version: %s\n", (char *) eurus_cmd_get_fw_version->version);

	err = 0;

done:

	kfree(buf);

	return err;
}

/*
 * ps3_jupiter_probe
 */
static int ps3_jupiter_probe(struct usb_interface *interface,
	const struct usb_device_id *id)
{
	struct usb_device *udev = interface_to_usbdev(interface);
	struct ps3_jupiter_dev *jd;
	u64 v1, v2;
	int err;

	if (ps3jd) {
		dev_err(&udev->dev, "only one device is supported\n");
		return -EBUSY;
	}

	ps3jd = jd = kzalloc(sizeof(struct ps3_jupiter_dev), GFP_KERNEL);
	if (!jd)
		return -ENOMEM;

	jd->udev = usb_get_dev(udev);
	usb_set_intfdata(interface, jd);

	spin_lock_init(&jd->cmd_lock);

	BLOCKING_INIT_NOTIFIER_HEAD(&jd->event_listeners);
	INIT_LIST_HEAD(&jd->event_list);
	spin_lock_init(&jd->event_list_lock);

	init_completion(&jd->event_comp);

	jd->event_listener.notifier_call = ps3_jupiter_event_handler;

	err = _ps3_jupiter_register_event_listener(jd, &jd->event_listener);
	if (err) {
		dev_err(&udev->dev, "could not register event listener (%d)\n", err);
		goto fail;
	}

	err = ps3_jupiter_create_event_worker(jd);
	if (err) {
		dev_err(&udev->dev, "could not create event work queue (%d)\n", err);
		goto fail;
	}

	err = ps3_jupiter_alloc_urbs(jd);
	if (err) {
		dev_err(&udev->dev, "could not allocate URBs (%d)\n", err);
		goto fail;
	}

	err = usb_submit_urb(jd->irq_urb, GFP_KERNEL);
	if (err) {
		dev_err(&udev->dev, "could not submit IRQ URB (%d)\n", err);
		goto fail;
	}

	err = ps3_jupiter_dev_auth(jd);
	if (err) {
		dev_err(&udev->dev, "could not authenticate device (%d)\n", err);
		goto fail;
	}

	/* get MAC address */

	err = lv1_net_control(LV1_SB_BUS_ID, LV1_GELIC_DEV_ID,
	    LV1_GET_MAC_ADDRESS, 0, 0, 0, &v1, &v2);
	if (err) {
		dev_err(&udev->dev, "could not get MAC address (%d)\n", err);
		err = -ENODEV;
		goto fail;
	}

	v1 <<= 16;

	if (!is_valid_ether_addr((unsigned char *) &v1)) {
		dev_err(&udev->dev, "got invalid MAC address\n");
		err = -ENODEV;
		goto fail;
	}

	memcpy(jd->mac_addr, &v1, ETH_ALEN);

	dev_info(&udev->dev, "MAC address: %02x:%02x:%02x:%02x:%02x:%02x\n",
	    jd->mac_addr[0], jd->mac_addr[1], jd->mac_addr[2],
	    jd->mac_addr[3], jd->mac_addr[4], jd->mac_addr[5]);

	/* get channel info */

	err = lv1_net_control(LV1_SB_BUS_ID, LV1_GELIC_DEV_ID,
	    LV1_GET_CHANNEL_INFO, 0, 0, 0, &v1, &v2);
	if (err) {
		/* don't quit here and try to recover later */
		dev_err(&udev->dev, "could not get channel info (%d)\n", err);
	}

	if (err)
		jd->channel_info = (0x7ffull << 48);
	else
		jd->channel_info = v1;

	dev_info(&udev->dev, "channel info: %016llx\n", jd->channel_info);

	err = ps3_jupiter_dev_init(jd);
	if (err) {
		dev_err(&udev->dev, "could not initialize device (%d)\n", err);
		goto fail;
	}

	jd->dev_ready = 1;

	return 0;

fail:

	ps3_jupiter_free_urbs(jd);

	ps3_jupiter_destroy_event_worker(jd);

	ps3_jupiter_free_event_list(jd);

	usb_set_intfdata(interface, NULL);
	usb_put_dev(udev);

	kfree(jd);
	ps3jd = NULL;

	return err;
}

/*
 * ps3_jupiter_disconnect
 */
static void ps3_jupiter_disconnect(struct usb_interface *interface)
{
	struct ps3_jupiter_dev *jd = usb_get_intfdata(interface);
	struct usb_device *udev = jd->udev;

	jd->dev_ready = 0;

	ps3_jupiter_free_urbs(jd);

	ps3_jupiter_destroy_event_worker(jd);

	ps3_jupiter_free_event_list(jd);

	usb_set_intfdata(interface, NULL);
	usb_put_dev(udev);

	kfree(jd);
	ps3jd = NULL;
}

#ifdef CONFIG_PM
/*
 * ps3_jupiter_suspend
 */
static int ps3_jupiter_suspend(struct usb_interface *interface, pm_message_t state)
{
	/*XXX: implement */

	return 0;
}

/*
 * ps3_jupiter_resume
 */
static int ps3_jupiter_resume(struct usb_interface *interface)
{
	/*XXX: implement */

	return 0;
}
#endif /* CONFIG_PM */

static struct usb_device_id ps3_jupiter_devtab[] = {
	{
		.match_flags = USB_DEVICE_ID_MATCH_VENDOR | USB_DEVICE_ID_MATCH_INT_INFO,
		.idVendor = 0x054c,
		.idProduct = 0x036f,
		.bInterfaceClass = USB_CLASS_VENDOR_SPEC,
		.bInterfaceSubClass = 2,
		.bInterfaceProtocol = 1
	},
	{ }
};

static struct usb_driver ps3_jupiter_drv = {
	.name		= KBUILD_MODNAME,
	.id_table	= ps3_jupiter_devtab,
	.probe		= ps3_jupiter_probe,
	.disconnect	= ps3_jupiter_disconnect,
#ifdef CONFIG_PM
	.suspend	= ps3_jupiter_suspend,
	.resume		= ps3_jupiter_resume,
#endif /* CONFIG_PM */
};

/*
 * ps3_jupiter_init
 */
static int __init ps3_jupiter_init(void)
{
	return usb_register(&ps3_jupiter_drv);
}

/*
 * ps3_jupiter_exit
 */
static void __exit ps3_jupiter_exit(void)
{
	usb_deregister(&ps3_jupiter_drv);
}

module_init(ps3_jupiter_init);
module_exit(ps3_jupiter_exit);

MODULE_DEVICE_TABLE(usb, ps3_jupiter_devtab);
MODULE_DESCRIPTION("PS3 Jupiter");
MODULE_AUTHOR("glevand");
MODULE_LICENSE("GPL");
MODULE_ALIAS(PS3_MODULE_ALIAS_JUPITER);
