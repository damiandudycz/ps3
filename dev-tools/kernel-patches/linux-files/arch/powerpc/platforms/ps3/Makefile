# SPDX-License-Identifier: GPL-2.0
obj-y += setup.o mm.o time.o hvcall.o htab.o repository.o
obj-y += interrupt.o exports.o os-area.o
obj-y += system-bus.o

obj-$(CONFIG_PPC_EARLY_DEBUG_PS3GELIC) += gelic_udbg.o
obj-$(CONFIG_PS3_LV1_CONS_UDBG) += lv1_cons_udbg.o
obj-$(CONFIG_SMP) += smp.o
obj-$(CONFIG_SPU_BASE) += spu.o
obj-$(CONFIG_SPUISO_FS) += spuisofs.o
obj-$(CONFIG_SPULDR_FS) += spuldrfs.o
obj-y += device-init.o
