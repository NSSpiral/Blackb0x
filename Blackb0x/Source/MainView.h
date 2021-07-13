//
//  MainView.h
//  Blackb0x
//
//  Created by spiral on 26/9/20.
//  Copyright © 2020 spiral. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DeviceManager.h"
#import "Patcher.h"

NS_ASSUME_NONNULL_BEGIN

@interface MainView : NSView

@property (strong) NSWindow *dfuHelper;
@property (strong) NSTextField *instructions;

@property (weak) IBOutlet NSProgressIndicator *progress1;
@property (weak) IBOutlet NSProgressIndicator *progress2;
@property (weak) IBOutlet NSProgressIndicator *progress3;
@property (weak) IBOutlet NSProgressIndicator *progress4;
@property (weak) IBOutlet NSProgressIndicator *progress5;
 
@property (weak) IBOutlet NSProgressIndicator *searchIndicator;

@property (weak) IBOutlet NSTextField *progress_text1;
@property (weak) IBOutlet NSTextField *progress_text2;
@property (weak) IBOutlet NSTextField *progress_text3;
@property (weak) IBOutlet NSTextField *progress_text4;
@property (weak) IBOutlet NSTextField *progress_text5;

@property (weak) IBOutlet NSTextField *select_device;

@property (weak) IBOutlet NSButton *jb_button;
@property (weak) IBOutlet NSButton *boot_button;

@property (strong) NSMutableArray *AppleTVs;

@property (strong) AppleTVIcon *selected_device;
@property (nonatomic) uint64_t selected_ecid;
@property (strong) NSString *selected_udid;
@property (nonatomic) int pwnedDFU;

@property (nonatomic) BOOL ignoreDisconnect;
@property (nonatomic) BOOL ignoreProgress;

@property (strong) Patcher *patcher;

- (void) setSelected:(AppleTVIcon *) icon;
- (void) refreshInterface;
- (void) updateSelectField:(NSString *) str;


- (void) setProgressColor:(NSColor *) color forSlot:(int) slot;
- (void) componentsReady:(NSArray *) components;
- (void) spawnDFUHelper;

- (void) tetherbootClick;
- (void) jailbreakClick;
-(void)popupClose;

@end

NS_ASSUME_NONNULL_END
