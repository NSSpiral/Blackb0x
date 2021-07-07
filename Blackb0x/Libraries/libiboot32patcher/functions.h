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

#ifndef FUNCTIONS_H
#define FUNCTIONS_H

#include <libiboot32patcher/arm32_defs.h>
#include <libiboot32patcher/iBoot32Patcher.h>

/*
#include <include/arm32_defs.h>
#include <include/iBoot32Patcher.h>
*/

#define ENTERING_RECOVERY_CONSOLE "Entering recovery mode, starting command prompt"
#define KERNELCACHE_PREP_STRING "__PAGEZERO"

#ifndef memmem
#define memmem _memmem
void* _memmem(const void* mem, int size, const void* pat, int size2);
#endif

void* bl_search_down(const void* start_addr, int len);
void* bl_search_up(const void* start_addr, int len);
void* iboot_memmem(struct iboot_img* iboot_in, void* pat);
void* find_last_LDR_rd(uintptr_t start, size_t len, const uint8_t rd);
void* find_next_bl_insn_to(struct iboot_img* iboot_in, uint32_t addr);
void* find_next_CMP_insn_with_value(void* start, size_t len, const uint8_t val);
void* find_next_LDR_insn_with_value(struct iboot_img* iboot_in, uint32_t value);
void* find_next_MOVW_insn_with_value(void* start, size_t len, const uint16_t val);
uint32_t get_iboot_base_address(void* iboot_buf);
uint16_t get_MOVT_W_val(struct arm32_thumb_MOVT_W* movt_w);
uint16_t get_MOVW_val(struct arm32_thumb_MOVW* movw);
int get_os_version(struct iboot_img* iboot_in);
bool has_kernel_load(struct iboot_img* iboot_in);
bool has_recovery_console(struct iboot_img* iboot_in);
bool is_BW_insn(void* offset);
bool is_LDRW_insn(void* offset);
bool is_MOVW_insn(void* offset);
bool is_IT_insn(void* offset);
void* ldr_search_down(const void* start_addr, int len);
void* ldr_search_up(const void* start_addr, int len);
void* ldr_pcrel_search_up(const void* start_addr, int len);
void* ldr32_search_up(const void* start_addr, int len);
void* ldr_to(const void* loc);
void* memstr(const void* mem, size_t size, const char* str);
void* pattern_search(const void* addr, int len, int pattern, int mask, int step);
void* push_r4_r7_lr_search_up(const void* start_addr, int len);
void* pop_search(const void* start_addr, int len, int searchup);
void* push_search(const void* start_addr, int len, int searchup);
void* branch_thumb_unconditional_search(const void* start_addr, int len, int searchup);
void* branch_thumb_conditional_search(const void* start_addr, int len, int searchup);
void* branch_search(const void* start_addr, int len, int searchup);
void* resolve_bl32(const void* bl);
void set_MOVT_W_insn_val(void* offset, uint8_t rd, uint16_t val);
void set_MOVW_insn_val(void* offset, uint8_t rd, uint16_t val);

#endif
