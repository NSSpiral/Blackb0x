//
//  Blackb0x.m
//  Blackb0x
//
//  Created by spiral on 16/9/20.
//  Copyright © 2020 spiral. All rights reserved.
//

#import "Blackb0x.h"
#import "IPSW.h"
#import "MainView.h"
#import "DeviceManager.h"


@implementation Blackb0x

+ (instancetype) ATVKit {
    
    static Blackb0x *atvKit = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        atvKit = [[self alloc] init];
    });
    
    return atvKit;
}

- (instancetype) init {
    self = [super init];
    
    return self;
}

- (void) setup {
    _deviceManager = [[DeviceManager alloc] init];
    
    
}

@end
