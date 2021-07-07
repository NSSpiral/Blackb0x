//
//  IPSW.h
//  Blackb0x
//
//  Created by spiral on 15/9/20.
//  Copyright © 2020 spiral. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IPSW_Fetch : NSObject

@property (strong) NSURLSessionConfiguration *conf;
@property (strong) NSURLSession *session;
@property (strong) NSString *URL;

- (NSProgress *) GET: (NSString *) url apiCall:(BOOL) api response:(void(^)(NSData* result)) completion;

- (NSProgress *) firmwareForDevice:(NSString *) deviceModel buildID:(NSString *) buildID response:(void(^)(NSData *result)) completion;
- (NSProgress *) latestFirmwareForDevice:(NSString *) deviceModel response:(void(^)(NSData *result)) completion;
- (NSDictionary *) keysForDevice:(NSString *) device buildID:(NSString *) buildID;

- (void) downloadComponent:(NSString *) componentName withCompletion:(void (^)(NSString *file, int slot))completionBlock;
- (void) loadIPSW:(NSString *) url;

@end

@interface IPSW : NSObject

@property NSString *url;
@property NSProgress *progress;

- (NSProgress *) download;

@end

NS_ASSUME_NONNULL_END
