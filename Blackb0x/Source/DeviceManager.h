//
//  DeviceManager.h
//  Blackb0x
//
//  Created by spiral on 15/9/20.
//  Copyright © 2020 spiral. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IPSW.h"

NS_ASSUME_NONNULL_BEGIN

#define S518947X_OVERWRITE (unsigned char*)"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x34\x00\x00\x00\x00"

#define s5l8947x_config (unsigned char*)"\x00\x00\x6c\x45\x00\x00\x60\x55\x00\x00\x5a\x89\x00\x00\x0d\x89\x00\x00\xa3\x39\x00\x00\x32\x4d\x00\x00\x4e\xb1\x00\x00\x6c\x75\x00\x00\x9a\x3c\x00\x02\xc0\x00\x34\x00\x00\x00"

typedef struct checkm8_config {
    uint16_t large_leak;
    uint16_t hole;
    int overwrite_offset;
    uint16_t leak;
    unsigned char* overwrite;
    size_t overwrite_len;
    unsigned char* payload;
    size_t payload_len;
} checkm8_config_t;

int get_payload_configuration(uint16_t cpid, const char* identifier, checkm8_config_t* config);

@interface AppleTVIcon : NSImageView

@property (nonatomic, strong) NSString *deviceModel;
@property (nonatomic, strong) NSString *mode;
@property (nonatomic, strong) NSString *version;
@property (nonatomic, strong) NSString *buildID;

@property (nonatomic) uint64_t ecid;
@property (nonatomic) NSString *udid;
@property (nonatomic) int connected;
@property (nonatomic) int pwnedDFU;
@property (nonatomic) int jailbroken;
@property (nonatomic) int jailbreakRunning;
@property (nonatomic) int didTetheredBoot;
@property (nonatomic) int needsPostInstall;
@property (nonatomic) int waitForRecovery;

@property (strong) NSImageView *ATVImage;
@property (strong) NSTextField *deviceField;
@property (strong) NSTextField *versionField;

@property (strong) NSProgressIndicator *checkingIndicator;

- (void) select;
- (void) unselect;
- (void) setBuildID:(nullable NSString *)buildID;
- (void) printDeviceInfo;

@end


@interface DeviceManager : NSObject

+ (int) SHAtter:(uint64_t) ecid;
+ (int) checkm8:(uint64_t) ecid;

- (irecv_client_t) get_tv:(uint64_t) i_ecid;

- (int) sendiBSS:(NSString *) iBSSpath ecid:(uint64_t) ecid;
- (int) sendiBEC:(NSString *) iBECpath ecid:(uint64_t) ecid;
- (int) sendRamdisk:(NSString *) Ramdisk_Path ecid:(uint64_t) ecid;
- (int) sendKernelCache:(NSString *) KernelCache_Path ecid:(uint64_t) ecid;
- (int) sendDeviceTree:(NSString *) DeviceTree_Path ecid:(uint64_t) ecid;
//- (int) boot;

@end

NS_ASSUME_NONNULL_END
