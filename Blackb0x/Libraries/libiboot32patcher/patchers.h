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

#ifndef PATCHERS_H
#define PATCHERS_H

#include <libiboot32patcher/iBoot32Patcher.h>

//#include <include/iBoot32Patcher.h>

#define DEBUG_ENABLED_DTRE_VAR_STR "debug-enabled"
#define DEFAULT_BOOTARGS_STR "rd=md0 nand-enable-reformat=1 -progress"
#define RELIANCE_CERT_STR "Reliance on this certificate"

int patch_boot_args(struct iboot_img* iboot_in, const char* boot_args);
int patch_cmd_handler(struct iboot_img* iboot_in, const char* cmd_str, uint32_t ptr);
int patch_debug_enabled(struct iboot_img* iboot_in);
int patch_rsa_check(struct iboot_img* iboot_in);
int ignore_nvram_patch(struct iboot_img* iboot_in);
int patch_ticket_check(struct iboot_img* iboot_in);
int patch_remote_boot(struct iboot_img* iboot_in);
int patch_bgcolor(struct iboot_img* iboot_in, const char* bgcolor);
int patch_kaslr(struct iboot_img* iboot_in);
#endif
