/*
 * libirecovery.h
 * Communication to iBoot/iBSS on Apple iOS devices via USB
 *
 * Copyright (c) 2012-2019 Nikias Bassen <nikias@gmx.li>
 * Copyright (c) 2012-2013 Martin Szulecki <m.szulecki@libimobiledevice.org>
 * Copyright (c) 2010 Chronic-Dev Team
 * Copyright (c) 2010 Joshua Hill
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the GNU Lesser General Public License
 * (LGPL) version 2.1 which accompanies this distribution, and is available at
 * http://www.gnu.org/licenses/lgpl-2.1.html
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 */

#ifndef LIBIRECOVERY_H
#define LIBIRECOVERY_H

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>

enum irecv_mode {
	IRECV_K_RECOVERY_MODE_1   = 0x1280,
	IRECV_K_RECOVERY_MODE_2   = 0x1281,
	IRECV_K_RECOVERY_MODE_3   = 0x1282,
	IRECV_K_RECOVERY_MODE_4   = 0x1283,
	IRECV_K_WTF_MODE          = 0x1222,
	IRECV_K_DFU_MODE          = 0x1227
};

typedef enum {
	IRECV_E_SUCCESS           =  0,
	IRECV_E_NO_DEVICE         = -1,
	IRECV_E_OUT_OF_MEMORY     = -2,
	IRECV_E_UNABLE_TO_CONNECT = -3,
	IRECV_E_INVALID_INPUT     = -4,
	IRECV_E_FILE_NOT_FOUND    = -5,
	IRECV_E_USB_UPLOAD        = -6,
	IRECV_E_USB_STATUS        = -7,
	IRECV_E_USB_INTERFACE     = -8,
	IRECV_E_USB_CONFIGURATION = -9,
	IRECV_E_PIPE              = -10,
	IRECV_E_TIMEOUT           = -11,
	IRECV_E_UNSUPPORTED       = -254,
	IRECV_E_UNKNOWN_ERROR     = -255
} irecv_error_t;

typedef enum {
	IRECV_RECEIVED            = 1,
	IRECV_PRECOMMAND          = 2,
	IRECV_POSTCOMMAND         = 3,
	IRECV_CONNECTED           = 4,
	IRECV_DISCONNECTED        = 5,
	IRECV_PROGRESS            = 6
} irecv_event_type;

typedef struct {
	int size;
	const char* data;
	double progress;
	irecv_event_type type;
} irecv_event_t;

struct irecv_device {
	const char* product_type;
	const char* hardware_model;
	unsigned int board_id;
	unsigned int chip_id;
	const char* display_name;
};
typedef struct irecv_device* irecv_device_t;

struct irecv_device_info {
	unsigned int cpid;
	unsigned int cprv;
	unsigned int cpfm;
	unsigned int scep;
	unsigned int bdid;
	unsigned long long ecid;
	unsigned int ibfl;
	char* srnm;
	char* imei;
	char* srtg;
	char* serial_string;
	unsigned char* ap_nonce;
	unsigned int ap_nonce_size;
	unsigned char* sep_nonce;
	unsigned int sep_nonce_size;	
};

typedef enum {
	IRECV_DEVICE_ADD     = 1,
	IRECV_DEVICE_REMOVE  = 2
} irecv_device_event_type;

typedef struct {
	irecv_device_event_type type;
	enum irecv_mode mode;
	struct irecv_device_info *device_info;
} irecv_device_event_t;

typedef struct irecv_client_private irecv_client_private;
typedef irecv_client_private* irecv_client_t;

/* library */
void irecv_set_debug_level(int level);
const char* irecv_strerror(irecv_error_t error);
void irecv_init(void); /* deprecated: libirecovery has constructor now */
void irecv_exit(void); /* deprecated: libirecovery has destructor now */

/* device connectivity */
irecv_error_t irecv_open_with_ecid(irecv_client_t* client, unsigned long long ecid);
irecv_error_t irecv_open_with_ecid_and_attempts(irecv_client_t* pclient, unsigned long long ecid, int attempts);
irecv_error_t irecv_reset(irecv_client_t client);
irecv_error_t irecv_close(irecv_client_t client);
irecv_client_t irecv_reconnect(irecv_client_t client, int initial_pause);

/* misc */
irecv_error_t irecv_receive(irecv_client_t client);
irecv_error_t irecv_execute_script(irecv_client_t client, const char* script);
irecv_error_t irecv_reset_counters(irecv_client_t client);
irecv_error_t irecv_finish_transfer(irecv_client_t client);
irecv_error_t irecv_async_usb_control_transfer(irecv_client_t client, uint8_t bm_request_type, uint8_t b_request, uint16_t w_value, uint16_t w_index, unsigned char *data, uint16_t w_length);
irecv_error_t irecv_async_usb_control_transfer_with_cancel(irecv_client_t client, uint8_t bm_request_type, uint8_t b_request, uint16_t w_value, uint16_t w_index, unsigned char *data, uint16_t w_length, unsigned int ns_time);
irecv_error_t irecv_trigger_limera1n_exploit(irecv_client_t client);

/* usb helpers */
irecv_error_t irecv_usb_set_configuration(irecv_client_t client, int configuration);
irecv_error_t irecv_usb_set_interface(irecv_client_t client, int usb_interface, int usb_alt_interface);
int irecv_usb_control_transfer(irecv_client_t client, uint8_t bm_request_type, uint8_t b_request, uint16_t w_value, uint16_t w_index, unsigned char *data, uint16_t w_length, unsigned int timeout);
int irecv_usb_bulk_transfer(irecv_client_t client, unsigned char endpoint, unsigned char *data, int length, int *transferred, unsigned int timeout);

/* events */
typedef void(*irecv_device_event_cb_t)(const irecv_device_event_t* event, void *user_data);
typedef struct irecv_device_event_context* irecv_device_event_context_t;
irecv_error_t irecv_device_event_subscribe(irecv_device_event_context_t *context, irecv_device_event_cb_t callback, void *user_data);
irecv_error_t irecv_device_event_unsubscribe(irecv_device_event_context_t context);
typedef int(*irecv_event_cb_t)(irecv_client_t client, const irecv_event_t* event);
irecv_error_t irecv_event_subscribe(irecv_client_t client, irecv_event_type type, irecv_event_cb_t callback, void *user_data);
irecv_error_t irecv_event_unsubscribe(irecv_client_t client, irecv_event_type type);

/* I/O */
irecv_error_t irecv_send_file(irecv_client_t client, const char* filename, int dfu_notify_finished);
irecv_error_t irecv_send_command(irecv_client_t client, const char* command);
irecv_error_t irecv_send_buffer(irecv_client_t client, unsigned char* buffer, unsigned long length, int dfu_notify_finished);
irecv_error_t irecv_recv_buffer(irecv_client_t client, char* buffer, unsigned long length);

/* commands */
irecv_error_t irecv_saveenv(irecv_client_t client);
irecv_error_t irecv_getenv(irecv_client_t client, const char* variable, char** value);
irecv_error_t irecv_setenv(irecv_client_t client, const char* variable, const char* value);
irecv_error_t irecv_reboot(irecv_client_t client);
irecv_error_t irecv_getret(irecv_client_t client, unsigned int* value);

/* device information */
irecv_error_t irecv_get_mode(irecv_client_t client, int* mode);
const struct irecv_device_info* irecv_get_device_info(irecv_client_t client);

/* device database queries */
irecv_device_t irecv_devices_get_all(void);
irecv_error_t irecv_devices_get_device_by_client(irecv_client_t client, irecv_device_t* device);
irecv_error_t irecv_devices_get_device_by_product_type(const char* product_type, irecv_device_t* device);
irecv_error_t irecv_devices_get_device_by_hardware_model(const char* hardware_model, irecv_device_t* device);

#ifdef __cplusplus
}
#endif

#endif
