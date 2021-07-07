//
//  IPSWDownloader.h
//  Blackb0x
//
//  Created by spiral on 18/9/20.
//  Copyright © 2020 spiral. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libfragmentzip/libfragmentzip.h>


NS_ASSUME_NONNULL_BEGIN
@interface FragmentDownloader : NSObject

@property (strong) NSProgress *progress;

@property (strong) NSString *ipsw_url;
@property (strong) NSString *ipsw_folder;
@property (strong, nullable) NSString *componentName;

+ (int) loadIPSW:(NSString *) ipsw_url;
+ (int) downloadNumberForComponent:(NSString *) componentName;
+ (instancetype) downloaderForComponent:(NSString *) componentName;

- (void) downloadComponent:(NSString *) componentPath;

@end

NS_ASSUME_NONNULL_END




