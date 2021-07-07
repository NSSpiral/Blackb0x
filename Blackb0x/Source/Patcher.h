//
//  Patcher.h
//  Blackb0x
//
//  Created by spiral on 5/10/20.
//  Copyright © 2020 spiral. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IPSW.h"

NS_ASSUME_NONNULL_BEGIN

@interface Patcher : NSObject

@property (nonatomic, strong) IPSW *ipsw;
@property (nonatomic, strong) IPSW_Fetch *ipsw_fetcher;

@property BOOL onlyBootComponents;

@property int iBSS;
@property (nonatomic, strong) NSString *iBSSPath;
@property int iBEC;
@property (nonatomic, strong) NSString *iBECPath;
@property int kernelCache;
@property (nonatomic, strong) NSString *KernelPath;
@property int ramdisk;
@property (nonatomic, strong) NSString *RamdiskPath;
@property int deviceTree;
@property (nonatomic, strong) NSString *DeviceTreePath;

@property (nonatomic, strong) NSDictionary *keys;

@property (nonatomic, strong) NSString *kernelBuild;
@property int kernelBuildPatched;

@property (nonatomic, strong) NSMutableArray *outputPaths;

- (void) loadKeysForDevice:(NSString *) deviceID buildID:(NSString *) buildID;

@end

NS_ASSUME_NONNULL_END
