//
//  libprerestore.h
//  Deca5
//

#ifndef libprerestore_h
#define libprerestore_h

#include <stdio.h>
#include <stdint.h>
#include "libirecovery.h"

int sendiBEC(char * _Nonnull iBECpath, uint64_t ecid);
//int get_dev();

//char * send_state();
//static int read_file_into_buffer(char* path, char** buf, size_t* len);
//static int load_ibec(char* path, char** ibec, size_t* ibec_len);
int boot_client(irecv_client_t client, void* buf, size_t sz);
int sendiBSS(char *iBSSpath, uint64_t ecid);
int sendDeviceTree(char *DeviceTree_Path, uint64_t ecid);
int sendKernelCache(char *KernelCache_Path, uint64_t ecid);
int dfu_send_iBSS(char *iBSSpath, uint64_t ecid);
int dfu_send_iBEC(char *iBECpath, uint64_t ecid);
int ipsw_outside_file_extract_to_memory_boot(const char *infile, unsigned char **pbuffer, size_t *psize, char* outside_path);
int extract_outside_component_boot(const char* path, unsigned char** component_data, size_t* component_size, char* outside_path);
//static int read_file_into_buffer(char* path, char** buf, size_t* len);
int boot_ibec(const char* outside_path, uint64_t ecid);
int boot_ibss(const char* outside_path, uint64_t ecid);
int download_component(const char* url, const char* component, const char* outdir);
///

struct swift_callbacks {
    void (* _Nonnull send_output_to_swift)(const char * _Nonnull modifier);
};
typedef struct swift_callbacks swift_callbacks;

extern void callback_setup(const swift_callbacks * _Nonnull callbacks);

///

struct swift_progresss {
    void (* _Nonnull send_output_progress_to_swift)(double modifier);
};
typedef struct swift_progresss swift_progress;

extern void progress_setup(const swift_progress* _Nonnull callbacks);
//int test_prog();
//char * send_ecid();
#endif /* libprerestore_h */
