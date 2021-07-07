/*
 * Copyright 2013-2016, iH8sn0w. <iH8sn0w@iH8sn0w.com>
 *
 * This file is part of iBoot32Patcher.
 *
 * iBoot32Patcher is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * iBoot32Patcher is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with iBoot32Patcher.  If not, see <http://www.gnu.org/licenses/>.
 */

#ifndef FINDERS_H
#define FINDERS_H

#include <libiboot32patcher/iBoot32Patcher.h>

//#include <include/iBoot32Patcher.h>

#define RSA_PATCH_IOS_4 "\x4F\xF0\xFF\x30\xDD\xF8\x40\x24\xDB\xF8\x00\x30\x9A\x42\x01\xD0"
#define KASLR_PATCH_6 "\x4F\xF0\x04\x50"
#define KASLR_PATCH_7 "\x4F\xF0\x04\x55"
#define KASLR_PATCH_8 "\x4F\xF0\x04\x54"
#define KASLR_PATCH_9 "\x4F\xF0\x04\x51"
void* find_bl_verify_shsh(struct iboot_img* iboot_in);
void* find_rsa_check_4(struct iboot_img* iboot_in);
void* find_kaslr(struct iboot_img* iboot_in, int version);
void* find_ldr_ecid(struct iboot_img* iboot_in);
void* find_ldr_bord(struct iboot_img* iboot_in);
void* find_ldr_prod(struct iboot_img* iboot_in);
void* find_ldr_sepo(struct iboot_img* iboot_in);
void* find_boot_partition_ldr(struct iboot_img* iboot_in);
void* find_boot_ramdisk_ldr(struct iboot_img* iboot_in);
void* find_bl_verify_shsh_5_6_7(struct iboot_img* iboot_in);
void* find_bl_verify_shsh_generic(struct iboot_img* iboot_in);
void* find_bl_verify_shsh_insn(struct iboot_img* iboot_in, void* pc);
void* find_dtre_get_value_bl_insn(struct iboot_img* iboot_in, const char* var);
void* find_verify_shsh_top(void* ptr);

#endif
