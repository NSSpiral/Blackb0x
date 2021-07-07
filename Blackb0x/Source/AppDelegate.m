//
//  AppDelegate.m
//  Blackb0x
//
//  Created by spiral on 15/9/20.
//  Copyright © 2020 spiral. All rights reserved.
//

#import "AppDelegate.h"
#import "Blackb0x.h"


@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [_window setLevel:NSFloatingWindowLevel];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {

}


@end
