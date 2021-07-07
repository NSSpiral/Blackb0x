//
//  Blackb0x.h
//  Blackb0x
//
//  Created by spiral on 16/9/20.
//  Copyright © 2020 spiral. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MainView.h"
#import "DeviceManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface Blackb0x : NSObject

@property (strong) MainView *mainView;
@property (nonatomic, strong) DeviceManager *deviceManager;


+ (instancetype) ATVKit;
- (void) setup;

@end

NS_ASSUME_NONNULL_END
