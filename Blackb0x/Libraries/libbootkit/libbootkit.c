#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/types.h>
#include "libbootkit.h"
#include "payload.h"
#include "config.h"

typedef struct {
    uint32_t magic;
    uint32_t magic2;
#define USB_COMMAND_MAGIC 'exec'
    uint32_t function;
    uint8_t padding[4];
} usb_command_t;

const config_t *get_config(uint32_t cpid) {

    for (int i = 0; i < sizeof(configs) / sizeof(config_t); i++) {
        const config_t *config = &configs[i];

        if (config->cpid == cpid)
            return config;
    }

    return NULL;
}

#define MAX_PACKET_SIZE     0x800
#define USB_SMALL_TIMEOUT   100
#define USB_TIMEOUT         5000

size_t min(size_t first, size_t second) {
    if (first < second)
        return first;
    else
        return second;
}

int send_chunks(irecv_client_t client, unsigned char *command, size_t length) {
    size_t index = 0;

    while (index < length) {
        size_t amount = min(length - index, MAX_PACKET_SIZE);
        if (irecv_usb_control_transfer(client, 0x21, 1, 0, 0, command + index, amount, USB_TIMEOUT) != amount)
            return -1;
        index += amount;
    }

    return 0;
}

int send_command(irecv_client_t client, unsigned char *command, size_t length) {
    printf("sending command...\n");

    unsigned char dummy_data[16];
    memset(&dummy_data, 0x0, sizeof(dummy_data));

    if (send_chunks(client, (unsigned char*)&dummy_data, sizeof(dummy_data)) != 0) {
        printf("ERROR: failed to send dummy data\n");
        return -1;        
    }

    irecv_usb_control_transfer(client, 0x21, 1, 0, 0, NULL, 0, USB_SMALL_TIMEOUT);
    irecv_usb_control_transfer(client, 0xA1, 3, 0, 0, (unsigned char*)&dummy_data, 6, USB_SMALL_TIMEOUT);
    irecv_usb_control_transfer(client, 0xA1, 3, 0, 0, (unsigned char*)&dummy_data, 6, USB_SMALL_TIMEOUT);

    if (send_chunks(client, command, length) != 0) {
        printf("ERROR: failed to send command buffer\n");
        return -1;        
    }

    irecv_usb_control_transfer(client, 0xA1, 2, 0xFFFF, 0, (unsigned char*)&dummy_data, 1, USB_TIMEOUT);

    return 0;
}

typedef struct __attribute__((packed)) {
    uint32_t loadaddr;
    uint32_t imageaddr;
    uint32_t imagesize;
    uint32_t memmove;
    uint32_t platform_get_boot_trampoline;
    uint32_t platform_bootprep;
    uint32_t usb_quiesce_no_free;
    uint32_t interrupt_mask_all;
    uint32_t timer_stop_all;
    uint32_t clocks_quiesce;
    uint32_t enter_critical_section;
    uint32_t arch_cpu_quiesce;
} payload_offsets_t;

unsigned char *construct_payload(const config_t *config, off_t bootloader_offset, size_t bootloader_length) {
    printf("constructing payload...\n");
    
    unsigned char *payload_copy = malloc(sizeof(payload));
    if (!payload_copy) {
        printf("ERROR: out of memory\n");
        return NULL;
    }

    memmove(payload_copy, &payload, sizeof(payload));

    static const uint32_t magic = 0xDEAD0001;
    
    unsigned char *offset = memmem(payload_copy, sizeof(payload), &magic, sizeof(magic));
    if (!offset) {
        printf("ERROR: improper payload\n");
        return NULL;
    }

    if (sizeof(payload) - (size_t)(offset - payload_copy) < sizeof(payload_offsets_t)) {
        printf("ERROR: improper payload\n");
        return NULL;
    }

    payload_offsets_t *payload_offsets = (payload_offsets_t *)offset;

    payload_offsets->loadaddr = config->loadaddr;
    payload_offsets->imageaddr = (uint32_t)(config->loadaddr + bootloader_offset);
    payload_offsets->imagesize = (uint32_t) bootloader_length;
    payload_offsets->memmove = config->memmove;
    payload_offsets->platform_get_boot_trampoline = config->platform_get_boot_trampoline;
    payload_offsets->platform_bootprep = config->platform_bootprep;
    payload_offsets->usb_quiesce_no_free = config->usb_quiesce_no_free;
    payload_offsets->interrupt_mask_all = config->interrupt_mask_all;
    payload_offsets->timer_stop_all = config->timer_stop_all;
    payload_offsets->clocks_quiesce = config->clocks_quiesce;
    payload_offsets->enter_critical_section = config->enter_critical_section;
    payload_offsets->arch_cpu_quiesce = config->arch_cpu_quiesce;

    return payload_copy;
}

#define ARM_RESET_VECTOR 0xEA00000E

int construct_command(irecv_client_t client,
                      const char *bootloader,
                      size_t bootloader_length,
                      unsigned char **result,
                      size_t *result_length) {

    printf("constructing command...\n");

    if (*(uint32_t*)bootloader != ARM_RESET_VECTOR) {
        printf("ERROR: provided bootloader doesn't seem to be an ARM image\n");
        return -1;
    }

    const struct irecv_device_info *info = irecv_get_device_info(client);

    const config_t *config = get_config(info->cpid);
    if (!config) {
        printf("ERROR: no config available for CPID:%04X\n", info->cpid);
        return -1;
    }

    size_t command_length = sizeof(payload) + bootloader_length + sizeof(usb_command_t);

    if (command_length > config->loadsize) {
        printf("ERROR: resulting command is too big, use smaller bootloader (at least %lu smaller)\n", command_length - config->loadsize);
        return -1;
    }

    unsigned char *buffer = malloc(command_length);
    if (!buffer) {
        printf("ERROR: out of memory");
        return -1;
    }

    memset(buffer, 0x0, command_length);

    off_t bootloader_offset = sizeof(usb_command_t);
    off_t payload_offset = bootloader_offset + bootloader_length;

    usb_command_t *command = (usb_command_t *)buffer;
    command->magic = USB_COMMAND_MAGIC;
    command->magic2 = USB_COMMAND_MAGIC;
    command->function = (uint32_t)(config->loadaddr + payload_offset + 1);
    memset(&command->padding, 0x0, sizeof(command->padding));

    memmove(buffer + bootloader_offset, bootloader, bootloader_length);

    unsigned char *prepared_payload = construct_payload(config, bootloader_offset, bootloader_length);

    if (!prepared_payload) {
        printf("ERROR: failed to construct payload\n");
        free(buffer);
        return -1;
    }

    memmove(buffer + payload_offset, prepared_payload, sizeof(payload));

    free((void*)prepared_payload);

    *result = buffer;
    *result_length = command_length;

    return 0;
}

int validate_device(irecv_client_t client) {
    const struct irecv_device_info *info = irecv_get_device_info(client);

    int mode;

    if (irecv_get_mode(client, &mode) != IRECV_E_SUCCESS) {
        printf("ERROR: failed to get device mode\n");
        return -1;
    }

    if (mode != IRECV_K_DFU_MODE) {
        printf("ERROR: non-DFU device found\n");
        return -1;
    }

    if (!info->srtg) {
        printf("ERROR: soft-DFU device found\n");
        return -1;
    }

    if (!strstr(info->serial_string, "PWND:[checkm8]")) {
        printf("ERROR: non-pwned-DFU device found\n");
        return -1;
    }

    return 0;
}

int save_command(irecv_client_t client, unsigned char *command, size_t length) {
    const struct irecv_device_info *info = irecv_get_device_info(client);

    char path[40];
    snprintf((char *)&path, sizeof(path), "/tmp/%04X-%016llX_%08X", info->cpid, info->ecid, arc4random_uniform(UINT32_MAX));

    int fd = open(path, O_WRONLY | O_CREAT, 0644);

    if (fd < 0) {
        printf("ERROR: failed to create output file\n");
        return -1;
    }

    if (write(fd, command, length) != length) {
        printf("ERROR: failed to write to output file\n");
        return -1;
    }

    printf("written to %s\n", path);

    return 0;
}

int dfu_boot(irecv_client_t client, const char *bootloader, size_t bootloader_length, bool debug) {
    if (validate_device(client) != 0) {
        printf("ERROR: device validation failed\n");
        return -1;
    }

    unsigned char *command;
    size_t command_length;

    if (construct_command(client, bootloader, bootloader_length, &command, &command_length) != 0) {
        printf("ERROR: failed to construct command\n");
        return -1;
    }

    if (debug) {
        int ret = save_command(client, command, command_length);
        irecv_close(client);
        return ret;
    }

    if (send_command(client, command, command_length) != 0) {
        printf("ERROR: failed to send command\n");
        return -1;
    }

    return 0;
}
