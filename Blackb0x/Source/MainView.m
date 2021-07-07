//
//  MainView.m
//  Blackb0x
//
//  Created by spiral on 26/9/20.
//  Copyright © 2020 spiral. All rights reserved.
//

#import "MainView.h"
#import "Blackb0x.h"
#import "DeviceManager.h"
#import "Patcher.h"
#import <CoreImage/CoreImage.h>

@implementation MainView

- (void) setSelected:(AppleTVIcon *) selected_icon {

    if(_ignoreDisconnect) return;
    
    printf("Selecting AppleTV (ECID: %llu UDID: %s)\n", selected_icon.ecid, [selected_icon.udid UTF8String]);
    
    _selected_device = selected_icon;
    _selected_ecid = selected_icon.ecid;
    _selected_udid = selected_icon.udid;
    _pwnedDFU = selected_icon.pwnedDFU;
    
    for(AppleTVIcon *icon in _AppleTVs) {
        if(selected_icon == icon) [icon select];
        else [icon unselect];
    }
    
    [self refreshInterface];
    
}

- (void) refreshInterface {
    
    if(_ignoreDisconnect) {
        _jb_button.hidden = YES;
        _boot_button.hidden = YES;
        return;
    }
    
    _jb_button.hidden = NO;
    _boot_button.hidden = NO;
    _jb_button.title = @"Install Jailbreak";
    _select_device.stringValue = @"Click Jailbreak to continue";
    
    if(_selected_device.jailbroken == 1) {
        
        _select_device.stringValue = @"Jailbreak Installed";
        
        if(_selected_device.jailbreakRunning) {
            _select_device.stringValue = @"Jailbreak is active on device";
        }
        
        _jb_button.hidden = YES;
        _boot_button.hidden = YES;
        
        if([_selected_device.deviceModel isEqual:@"AppleTV2,1"]) {
            if(![_selected_device.version isEqual:@"6.1.4"]) _boot_button.hidden = NO;
        }
    }
    else {

        if([_selected_device.mode isEqualToString:@"Normal"]) _boot_button.hidden = YES;
        else _select_device.stringValue = @"Click Jailbreak or Tethered Boot";
    }
}

- (void) spawnDFUHelper {
    
    [NSApp activateIgnoringOtherApps:YES];
    
    CGPoint pos = [[NSApplication sharedApplication] mainWindow].frame.origin;
    CGSize size = [[NSApplication sharedApplication] mainWindow].frame.size;
    
    CGSize popupSize = CGSizeMake(600, 400);
    NSRect frame = NSMakeRect(pos.x + size.width / 2 - popupSize.width / 2,
                              pos.y + size.height / 2 - popupSize.height / 2,
                              popupSize.width, popupSize.height);

    if(_dfuHelper == nil) {
        _dfuHelper = [[NSWindow alloc] initWithContentRect:frame
                                                 styleMask:NSWindowStyleMaskFullSizeContentView
                                                   backing:NSBackingStoreBuffered
                                                     defer:NO];
        
        [_dfuHelper setReleasedWhenClosed:NO];
        [_dfuHelper setLevel:NSPopUpMenuWindowLevel];
        [_dfuHelper setOpaque:NO];
        [_dfuHelper setBackgroundColor:[NSColor clearColor]];
        
        NSVisualEffectView *effect = [[NSVisualEffectView alloc] initWithFrame:_dfuHelper.frame];
        effect.blendingMode = NSVisualEffectBlendingModeBehindWindow;
        effect.state = NSVisualEffectStateActive;
        effect.material = NSVisualEffectMaterialDark;
        effect.wantsLayer = YES;

        _dfuHelper.contentView = effect;
        _dfuHelper.titlebarAppearsTransparent = YES;
        _dfuHelper.titleVisibility = NSWindowTitleHidden;

        NSImageView *remoteView = [[NSImageView alloc] initWithFrame:NSMakeRect(popupSize.width * 0.1, popupSize.height * -0.1, 232 / 3, 937 / 3)];
        NSImage *remote = [NSImage imageNamed:@"remote"];
        [remoteView setImage:remote];
        [_dfuHelper.contentView addSubview:remoteView];
        
        int instructionsWidth = popupSize.width * 0.55;
        NSRect instructionsFrame = NSMakeRect(popupSize.width / 3, popupSize.height / 3, instructionsWidth, popupSize.height / 2);
        
        _instructions = [[NSTextField alloc] initWithFrame:instructionsFrame];
        _instructions.stringValue = @"\n\nTo enter DFU mode \n\n\nHold DOWN and MENU button until Apple TV LED flashes rapidly";
        _instructions.backgroundColor = [NSColor clearColor];
        _instructions.usesSingleLineMode = NO;
        _instructions.bordered = NO;
        _instructions.font = [NSFont systemFontOfSize:18];
        _instructions.alignment = NSTextAlignmentCenter;
        _instructions.editable = NO;
        
        [_dfuHelper.contentView addSubview:_instructions];
        
        NSProgressIndicator *progress = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(instructionsFrame.origin.x + instructionsFrame.size.width / 2 - 10,
                                                                                              popupSize.height * 0.2 - 10, 20, 20)];
        progress.style = NSProgressIndicatorStyleSpinning;
        [_dfuHelper.contentView addSubview:progress];
        [progress startAnimation:nil];
            
        int width = 130;
        int height = 40;
        
        NSRect buttonFrame = NSMakeRect(instructionsFrame.origin.x + instructionsFrame.size.width / 2 - width / 2,
                                        popupSize.height * 0.1 - height / 2, width, height);
        
        NSButton *myButton = [[NSButton alloc] initWithFrame:buttonFrame];
    
        [_dfuHelper.contentView addSubview: myButton];
        [myButton setTitle: @"Cancel"];
        [myButton setBezelStyle:NSBezelStyleRounded];
        [myButton setTarget:self];
        [myButton setAction:@selector(popupClose)];
        
    }

    [_dfuHelper makeKeyAndOrderFront:NSApp];
    [[NSApplication sharedApplication] mainWindow].movable = NO;
    [[NSApplication sharedApplication] mainWindow].alphaValue = 0.9;
    
}

-(void)popupClose {

    [_dfuHelper close];
    
    [[NSApplication sharedApplication] mainWindow].alphaValue = 1.0;
    [[NSApplication sharedApplication] mainWindow].movable = YES;
}

- (void)awakeFromNib {
    
    Blackb0x *atvKit = [Blackb0x ATVKit];
    [atvKit setMainView:self];
    [atvKit setup];
    
    [_progress1 setMaxValue:100];
    [_progress1 setDoubleValue:0];
    
    [_progress2 setMaxValue:100];
    [_progress2 setDoubleValue:0];
    
    [_progress3 setMaxValue:100];
    [_progress3 setDoubleValue:0];
    
    [_progress4 setMaxValue:100];
    [_progress4 setDoubleValue:0];
    
    [_searchIndicator startAnimation:nil];
    
    _jb_button.target = self;
    _jb_button.action = @selector(jailbreakClick);
    
    _boot_button.target = self;
    _boot_button.action = @selector(tetherbootClick);
    
    _patcher = [[Patcher alloc] init];
  
}

- (void) updateSelectField:(NSString *) str {
    if(_ignoreDisconnect == YES) return;
    _select_device.stringValue = str;
}

- (int) SHAtter:(uint64_t) ecid {
    printf("Running SHAtter on ecid %llu", ecid);

    dispatch_async(dispatch_get_main_queue(), ^(void){
        self.select_device.stringValue = @"Exploiting with SHAtter...";
        self.progress1.hidden = NO;
        self.progress1.doubleValue = 0.0;
    });

    return [DeviceManager SHAtter:ecid];;
}

- (int) checkm8:(uint64_t) ecid {
    printf("Running checkm8 on ecid %llu", ecid);
    
    return [DeviceManager checkm8:ecid];
}

- (void) checkExploit:(void (^)(int success))completionBlock {
    
    if(!_pwnedDFU) {
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
            if([self.selected_device.deviceModel isEqualToString:@"AppleTV2,1"]) {
                
                    if([self SHAtter:self.selected_device.ecid] == 0) {
                        dispatch_async(dispatch_get_main_queue(), ^(void){
                            self.select_device.stringValue = @"Failed to exploit device";
                        });
                        completionBlock(0);
                        return;
                    }
                    completionBlock(1);
                    return;
            }
            
            if([self.selected_device.deviceModel isEqualToString:@"AppleTV3,1"]) {
                printf("Plug in arduino and use synackuk checkm8 to put device in pwnedDFU\n");
                completionBlock(0);
                return;
            }
            
            
            if([self.selected_device.deviceModel isEqualToString:@"AppleTV3,2"]) {
                if([self checkm8:self.selected_device.ecid] == 0) {
                    dispatch_async(dispatch_get_main_queue(), ^(void){
                        self.select_device.stringValue = @"Failed to exploit device";
                    });
                    completionBlock(0);
                    return;
                }
                completionBlock(1);
                return;
            }
        });
    }
    else {
        completionBlock(1);
    }
    return;

}

NSComboBox *comboBox;

- (void) tetherbootClick {
    
    _selected_device.jailbroken = 1;

    if(!_selected_device.version || !_selected_device.buildID) {
        if([_selected_device.deviceModel isEqual:@"AppleTV2,1"]) { //Assuming 7.1.2 for ATV2
            [_selected_device setVersion:@"7.1.2"];
            [_selected_device setBuildID:@"11D258"];
        }
        else { //Allow booting of other firmwares on ATV3
            self.select_device.stringValue = @"Please connect in Normal Mode first";
            return;
        }
    }
    
    if(![_selected_device.mode isEqualToString:@"DFU"]) {
        [self spawnDFUHelper];
        return;
    }
    
    _jb_button.hidden = YES;
    _boot_button.hidden = YES;
    
    [self checkExploit:^(int success) {
        if(success) {
            printf("Device exploited\n");
            [self downloadBoot];
        }
    }];
}

- (void) jailbreakClick {
    
    if(![_selected_device.mode isEqualToString:@"DFU"]) {
        [self spawnDFUHelper];
        return;
    }
    
    _jb_button.hidden = YES;
    _boot_button.hidden = YES;
    

    [self checkExploit:^(int success) {
        if(success) {
            printf("Device exploited\n");
            [self downloadInstall];
        }
    }];
}

- (void) downloadInstall {
    
    printf("Jailbreaking: ");
    [_selected_device printDeviceInfo];
    
    [self.patcher setOnlyBootComponents:NO];
    [self downloadComponentsForBuildID:@"10B329a"];
}

- (void) downloadBoot {
    
    printf("Tether booting: ");
    [_selected_device printDeviceInfo];
    
    [self.patcher setOnlyBootComponents:YES];
    [self downloadComponentsForBuildID:_selected_device.buildID];
}

- (void) downloadComponentsForBuildID:(NSString *) build {
    
    printf("Downloading %s components...\n", [build UTF8String]);

    dispatch_async(dispatch_get_main_queue(), ^{
        self.select_device.stringValue = @"Retrieving firmware information...";
    });

    IPSW_Fetch *ipsw_fetcher = [[IPSW_Fetch alloc] init];

    if(_selected_device.jailbroken == 1) {
        build = _selected_device.buildID;
    }

    [ipsw_fetcher firmwareForDevice:_selected_device.deviceModel buildID:build response:^(NSData * _Nonnull result) {

        NSString *firmwareURL = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
        printf("Firmware URL\n%s\n", [firmwareURL UTF8String]);

        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){

            [ipsw_fetcher loadIPSW:firmwareURL];

            dispatch_async(dispatch_get_main_queue(), ^{
                
                __block NSString *iBSS, *iBEC, *kernelCache, *restore, *deviceTree;
                
                [ipsw_fetcher downloadComponent:@"BuildManifest.plist" withCompletion:^(NSString * _Nonnull file, int slot) {
                    
                    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:file];
                    NSString *buildID = dict[@"ProductBuildVersion"];
                    NSString *deviceID = self.selected_device.deviceModel;

                    [self.patcher loadKeysForDevice:deviceID buildID:buildID];

                    NSDictionary *buildIdentity = [dict[@"BuildIdentities"] lastObject];
                    NSDictionary *manifest = buildIdentity[@"Manifest"];

                    iBSS = manifest[@"iBSS"][@"Info"][@"Path"];
                    iBEC = manifest[@"iBEC"][@"Info"][@"Path"];
                    kernelCache = manifest[@"KernelCache"][@"Info"][@"Path"];
                    deviceTree = manifest[@"DeviceTree"][@"Info"][@"Path"];

                    if([self.patcher onlyBootComponents] == 0) {
                        restore = manifest[@"RestoreRamDisk"][@"Info"][@"Path"];
                    }

                    printf("Build manifest downloaded on #%i\n", slot);
                    printf("Downloading ...\n");
                    printf("%s\n", [iBSS UTF8String]);
                    printf("%s\n", [iBEC UTF8String]);
                    printf("%s\n", [kernelCache UTF8String]);

                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.select_device.stringValue = @"Downloading firmware components...";
                    });

                    NSColor *patchColor = [NSColor colorWithRed:0.8 green:0.2 blue:0.0 alpha:1.0];
                    [ipsw_fetcher downloadComponent:iBSS withCompletion:^(NSString *file, int slot) {
                        printf("iBSS downloaded - %s\n", [file UTF8String]);
                        [self setProgressColor:patchColor forSlot:slot];
                        [self.patcher setIBSSPath:file];
                    }];

                    [ipsw_fetcher downloadComponent:iBEC withCompletion:^(NSString *file, int slot) {
                        printf("iBEC downloaded - %s\n", [file UTF8String]);
                        [self setProgressColor:patchColor forSlot:slot];
                        [self.patcher setIBECPath:file];
                    }];

                    [ipsw_fetcher downloadComponent:kernelCache withCompletion:^(NSString *file, int slot) {
                        printf("KernelCache downloaded - %s\n", [file UTF8String]);
                        [self setProgressColor:patchColor forSlot:slot];
                        [self.patcher setKernelPath:file];
                    }];

                    [ipsw_fetcher downloadComponent:deviceTree withCompletion:^(NSString *file, int slot) {
                        printf("DeviceTree downloaded - %s\n", [file UTF8String]);
                        [self setProgressColor:patchColor forSlot:slot];
                        [self.patcher setDeviceTreePath:file];
                    }];

                    if([self.patcher onlyBootComponents] == 0) {
                        [ipsw_fetcher downloadComponent:restore withCompletion:^(NSString *file, int slot) {
                          printf("Ramdisk downloaded - %s\n", [file UTF8String]);
                          [self setProgressColor:patchColor forSlot:slot];
                          [self.patcher setRamdiskPath:file];
                        }];
                    }
                }];
            });
        });
    }];
}

- (void) setProgressColor:(NSColor *) color forSlot:(int) slot {
    
    NSProgressIndicator *progress;
    NSTextField *progress_text;
           
    switch(slot) {
        case 1 :
            progress = _progress1;
            progress_text = _progress_text1;
            break;
        case 2 :
            progress = _progress2;
            progress_text = _progress_text2;
            break;
        case 3 :
            progress = _progress3;
            progress_text = _progress_text3;
            break;
        case 4 :
            progress = _progress4;
            progress_text = _progress_text4;
            break;
    }

   CIFilter *filter = [CIFilter filterWithName:@"CIColorPolynomial"];
   [filter setDefaults];
    
   CIVector *redVector = [CIVector vectorWithX:color.redComponent Y:0 Z:0 W:0];
   CIVector *greenVector = [CIVector vectorWithX:color.greenComponent Y:0 Z:0 W:0];
   CIVector *blueVector = [CIVector vectorWithX:color.blueComponent Y:0 Z:0 W:0];
   [filter setValue:redVector forKey:@"inputRedCoefficients"];
   [filter setValue:greenVector forKey:@"inputGreenCoefficients"];
   [filter setValue:blueVector forKey:@"inputBlueCoefficients"];
    
   dispatch_async(dispatch_get_main_queue(), ^{
       [progress setContentFilters:[NSArray arrayWithObjects:filter, nil]];
       
       NSString *patching = [progress_text.stringValue stringByReplacingOccurrencesOfString:@"Downloading" withString:@"Patching"];
       progress_text.stringValue = patching;
   });
    
}

#define USE_RAMDISK 1

- (void) componentsReady:(NSArray *) components {
    
    _progress_text1.hidden = YES;
    _progress1.hidden = NO;
    _select_device.stringValue = @"Sending components to device...";

    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
            
        printf("Patching complete...");
        printf("Attempting to boot %s\n", [self.selected_device.deviceModel UTF8String]);
        self.ignoreDisconnect = YES;
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            self.progress1.hidden = NO;
        });
        
        for(NSString *str in components) {
            if([str isKindOfClass:[NSNull class]]) continue;
            printf("--- %s\n", [str UTF8String]);
        }

        DeviceManager *devMan = [Blackb0x ATVKit].deviceManager;

        int i;
        printf("Sending iBSS -> ");
        i = [devMan sendiBSS:components[0] ecid:self.selected_device.ecid];
        printf("%s", (!i) ? "Sent\n" : "Error\n");
        
        if(i != 0) {
            printf("Failed to send iBSS, spawning dfu helper\n");
            dispatch_async(dispatch_get_main_queue(), ^(void){
                [self spawnDFUHelper];
                self.instructions.stringValue = @"\n\nPlease re-enter DFU mode \n\n\nHold DOWN and MENU button until Apple TV LED flashes rapidly";
            });
            return;
        }
        
        if(self.selected_device.jailbroken == 1) {
            printf("Sending iBEC -> ");
            i = [devMan sendiBEC:components[2] ecid:self.selected_device.ecid];
            printf("%s", (!i) ? "Sent\n" : "Error\n");
            self.selected_device.didTetheredBoot = 1;

        }
        else {
            printf("Sending iBEC -> ");
            i = [devMan sendiBEC:components[1] ecid:self.selected_device.ecid];
            printf("%s", (!i) ? "Sent\n" : "Error\n");
            
            printf("Sending DeviceTree -> ");
            i = [devMan sendDeviceTree:components[5] ecid:self.selected_device.ecid];
            printf("%s", (!i) ? "Sent\n" : "Error\n");
            
            printf("Sending Ramdisk -> ");
            i = [devMan sendRamdisk:components[4] ecid:self.selected_device.ecid];
            printf("%s", (!i) ? "Sent\n" : "Error\n");
            
            self.selected_device.needsPostInstall = 1;
            
        }
        
        printf("Sending KernelCache -> ");
        i = [devMan sendKernelCache:components[3] ecid:self.selected_device.ecid];
        printf("%s", (!i) ? "Sent\n" : "Error\n");
        
        if(i == 0) {
            self.selected_device.waitForRecovery = 1;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if(self.selected_device.jailbroken == 1) {
                    self.select_device.stringValue = @"Waiting for Apple TV to boot";
                }
                else {
                    self.select_device.stringValue = @"Waiting for Apple TV to reboot";
                }
                self.progress1.hidden = YES;
            });
            self.ignoreDisconnect = NO;
            
        }
    });
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
}

@end
