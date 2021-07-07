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

/* iBoot32Patcher
 *
 * Universal 32-bit iBoot patcher for iPhone OS 2.0 --> iOS 10
 *
 * Build:
 * clang iBoot32Patcher.c finders.c functions.c patchers.c -Wno-multichar -I. -o iBoot32Patcher
 *
 * Usage:
 * ./iBoot32Patcher iBoot.n49.RELEASE.dfu.decrypted iBoot.n49.RELEASE.dfu.patched
 * ./iBoot32Patcher iBoot.n49.RELEASE.dfu.decrypted iBoot.n49.RELEASE.dfu.patched -b "cs_enforcement_disable=1 -v"
 * ./iBoot32Patcher iBoot.n49.RELEASE.dfu.decrypted iBoot.n49.RELEASE.dfu.patched -b "cs_enforcement_disable=1" -c "ticket" 0x80000000
 * ./iBoot32Patcher iBoot.n49.RELEASE.dfu.decrypted iBoot.n49.RELEASE.dfu.patched -c "ticket" 0x80000000
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

#include <libiboot32patcher/arm32_defs.h>
#include <libiboot32patcher/finders.h>
#include <libiboot32patcher/functions.h>
#include <libiboot32patcher/iBoot32Patcher.h>
#include <libiboot32patcher/patchers.h>

/*
#include <include/arm32_defs.h>
#include <include/finders.h>
#include <include/functions.h>
#include <include/iBoot32Patcher.h>
#include <include/patchers.h>
*/

#define HAS_ARG(x, y) (!strcmp(argv[i], x) && (i + y) < argc)

int iBootPatcher(char *infile, char *outfile, char *args, char *RSA, char *debug, char *ticket, char *kaslr);

int iBootPatcher(char *infile, char *outfile, char *args, char *RSA, char *debug, char *ticket, char *kaslr)
{
    int ret = 0;
    FILE *fp = NULL;
    uint32_t cmd_handler_ptr = 0;
    char *cmd_handler_str = NULL;
    char *custom_boot_args = NULL;
    bool rsa_patch = false;
    bool debug_patch = false;
    bool ticket_patch = false;
    bool remote_patch = false;
    bool kaslr_patch = false;
    char *custom_color = NULL;
    struct iboot_img iboot_in;

    memset(&iboot_in, 0, sizeof(iboot_in));

    printf("%s: Starting...\n", __FUNCTION__);

    if (strcmp(RSA, "TRUE") == 0)
    {
        rsa_patch = true;
    }

    if (strcmp(ticket, "TRUE") == 0)
    {
        ticket_patch = true;
    }

    if (strcmp(RSA, "TRUE") == 0)
    {
        debug_patch = true;
    }

    if (strcmp(kaslr, "TRUE") == 0)
    {
        kaslr_patch = true;
    }

    if (args && args[0])
    {
        custom_boot_args = args;
    }

    if (!rsa_patch && !debug_patch && !ticket_patch && !custom_boot_args && !cmd_handler_str && !remote_patch)
    {
        printf("%s: Nothing to patch!\n", __FUNCTION__);
        return -1;
    }

    fp = fopen(infile, "rb");
    if (!fp)
    {
        printf("%s: Error opening %s!\n", __FUNCTION__, infile);
        return -1;
    }

    fseek(fp, 0, SEEK_END);
    iboot_in.len = ftell(fp);
    fseek(fp, 0, SEEK_SET);

    iboot_in.buf = (void *)malloc(iboot_in.len);
    if (!iboot_in.buf)
    {
        printf("%s: Out of memory!\n", __FUNCTION__);
        fclose(fp);
        return -1;
    }

    fread(iboot_in.buf, 1, iboot_in.len, fp);
    fclose(fp);

    uint32_t image_magic = *(uint32_t *)iboot_in.buf;

    if (image_magic == IMAGE3_MAGIC)
    {
        printf("%s: The supplied image appears to be in an img3 container. Please ensure that the image is decrypted and that the img3 header is stripped.\n", __FUNCTION__);
        free(iboot_in.buf);
        return -1;
    }

    if (image_magic != IBOOT32_RESET_VECTOR_BYTES)
    {
        printf("%s: The supplied image is not a valid 32-bit iBoot.\n", __FUNCTION__);
        free(iboot_in.buf);
        return -1;
    }

    const char *iboot_vers_str = (iboot_in.buf + IBOOT_VERS_STR_OFFSET);

    iboot_in.VERS = atoi(iboot_vers_str);
    if (!iboot_in.VERS)
    {
        printf("%s: No iBoot version found!\n", __FUNCTION__);
        free(iboot_in.buf);
        return -1;
    }

    printf("%s: iBoot-%d inputted.\n", __FUNCTION__, iboot_in.VERS);

    /* Check to see if the loader has a kernel load routine before trying to apply custom boot args + debug-enabled override. */
    if (has_kernel_load(&iboot_in))
    {
        if (custom_boot_args)
        {
            ret = patch_boot_args(&iboot_in, custom_boot_args);
            if (!ret)
            {
                printf("%s: Error doing patch_boot_args()!\n", __FUNCTION__);
                free(iboot_in.buf);
                return -1;
            }
        }

        /* Only bootloaders with the kernel load routines pass the DeviceTree. */

        if (debug_patch)
        {
            ret = patch_debug_enabled(&iboot_in);
            if (!ret)
            {
                printf("%s: Error doing patch_debug_enabled()!\n", __FUNCTION__);
                free(iboot_in.buf);
                return -1;
            }
        }

        if (custom_color)
        {
            ret = patch_bgcolor(&iboot_in, custom_color);
            if (!ret)
            {
                printf("%s: Error doing patch_bgcolor()!\n", __FUNCTION__);
                free(iboot_in.buf);
                return -1;
            }
        }

        if (remote_patch)
        {
            ret = patch_remote_boot(&iboot_in);
            if (!ret)
            {
                printf("%s: Error doing patch_remote_boot()!\n", __FUNCTION__);
                free(iboot_in.buf);
                return -1;
            }
        }
    }

    if (ticket_patch)
    {
        ret = patch_ticket_check(&iboot_in);
        if (!ret)
        {
            printf("%s: Error doing patch_ticket_check()!\n", __FUNCTION__);
            free(iboot_in.buf);
            return -1;
        }
    }
    if (kaslr_patch)
    {
        ret = patch_kaslr(&iboot_in);
        if (!ret)
        {
            printf("%s: Error doing patch_kaslr()!\n", __FUNCTION__);
            free(iboot_in.buf);
            return -1;
        }
    }

    /* Ensure that the loader has a shell. */
    if (has_recovery_console(&iboot_in) && cmd_handler_str)
    {
        ret = patch_cmd_handler(&iboot_in, cmd_handler_str, cmd_handler_ptr);
        if (!ret)
        {
            printf("%s: Error doing patch_cmd_handler()!\n", __FUNCTION__);
            free(iboot_in.buf);
            return -1;
        }
    }

    /* All loaders have the RSA check. */

    if (rsa_patch)
    {
        ret = patch_rsa_check(&iboot_in);
        if (!ret)
        {
            printf("%s: Error doing patch_rsa_check()!\n", __FUNCTION__);
            free(iboot_in.buf);
            return -1;
        }
    }

    printf("%s: Writing out patched file to %s...\n", __FUNCTION__, outfile);

    /* Write out the patched file... */
    fp = fopen(outfile, "wb+");
    if (!fp)
    {
        printf("%s: Unable to open %s!\n", __FUNCTION__, outfile);
        free(iboot_in.buf);
        return -1;
    }

    fwrite(iboot_in.buf, 1, iboot_in.len, fp);
    fflush(fp);
    fclose(fp);

    free(iboot_in.buf);

    printf("%s: Quitting...\n", __FUNCTION__);
    return 0;
}


