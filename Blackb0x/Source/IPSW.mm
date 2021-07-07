//
//  IPSW.m
//  Blackb0x
//
//  Created by spiral on 15/9/20.
//  Copyright © 2020 spiral. All rights reserved.
//

#define BASE_URL @"https://api.ipsw.me/v2.1/"

#import "IPSW.h"
#import "IPSWDownloader.h"

#import <libimobiledevice/libimobiledevice.h>
#import <libirecovery.h>

#include <vector>

using namespace std;

@implementation IPSW_Fetch

- (instancetype) init {
    
    self = [super init];
    self.conf = [NSURLSessionConfiguration defaultSessionConfiguration];
    self.session = [NSURLSession sessionWithConfiguration:self.conf];
    
    return self;
    
}

- (void) loadIPSW:(NSString *) url {
    _URL = url;
    [FragmentDownloader loadIPSW:url];
}

- (void) downloadComponent:(NSString *) componentName withCompletion:(void (^)(NSString *file, int slot))completionBlock {
    
    NSString *fileLocation = [NSString stringWithFormat:@"/Users/%@/Documents/Blackb0x/%@/%@",
                              NSUserName(),
                              [[_URL lastPathComponent] stringByDeletingPathExtension],
                              componentName];
    
    if([[NSFileManager defaultManager] fileExistsAtPath:fileLocation]) {
        printf("File exists, no need to download.\n");
        completionBlock(fileLocation, -1);
        return;
    }
    
    __block FragmentDownloader *dl;
        
    if((dl = [FragmentDownloader downloaderForComponent:componentName])) {
        dl.componentName = componentName;

        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){

            [dl downloadComponent:componentName];

            int slot = [FragmentDownloader downloadNumberForComponent:componentName];
            NSString *path = [NSString stringWithFormat:@"%@/%@", dl.ipsw_folder, componentName];
            
            printf("Downloaded %s on slot %i\n", [componentName UTF8String], slot);
            
            dl.componentName = nil;
            
            if([[NSFileManager defaultManager] fileExistsAtPath:path]) completionBlock(path, slot);
            else completionBlock(nil, slot);
            
        });

    }
    else {
        printf("No downloader\n");
    }
}

- (NSProgress *) GET: (NSString *) url apiCall:(BOOL) api response:(void(^)(NSData* result)) completion {

    NSString *full_url = [NSString stringWithFormat:@"%@%@", BASE_URL, url];
    if(!api) full_url = url;
    
    NSURLSessionDataTask *dataTask;
    
    dataTask = [self.session dataTaskWithURL:[NSURL URLWithString:full_url]
                           completionHandler:^(NSData * _Nullable data,
                                               NSURLResponse * _Nullable response,
                                               NSError * _Nullable error) {
                    completion(data);
                }];
    
    [dataTask resume];
    
    return dataTask.progress;
}

- (NSDictionary *) keysForDevice:(NSString *) device buildID:(NSString *) buildID  {
    
    NSString *path = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%@_%@", device, buildID] ofType:@"keys"];
    NSDictionary *keys = [NSDictionary dictionaryWithContentsOfFile:path];
    return keys;

}

- (NSProgress *) firmwareForDevice:(NSString *) deviceModel buildID:(NSString *) buildID response:(void(^)(NSData *result)) completion {
    if([buildID isEqual:@""]) {
        return [self latestFirmwareForDevice:deviceModel response:^(NSData * _Nonnull result) {
            completion(result);
        }];
    }
    NSString *url = [NSString stringWithFormat:@"%@/%@/url", deviceModel, buildID];
    return [self GET:url apiCall:YES response:^(NSData * _Nonnull result) {
        completion(result);
    }];
}

- (NSProgress *) latestFirmwareForDevice:(NSString *) deviceModel response:(void(^)(NSData *result)) completion {
    NSString *url = [NSString stringWithFormat:@"%@/latest/url", deviceModel];
    return [self GET:url apiCall:YES response:^(NSData * _Nonnull result) {
        completion(result);
    }];
}
 
@end

