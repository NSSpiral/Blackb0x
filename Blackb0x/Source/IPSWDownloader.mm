//
//  IPSWDownloader.m
//  Blackb0x
//
//  Created by spiral on 18/9/20.
//  Copyright © 2020 spiral. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Cocoa/Cocoa.h>

#import "Blackb0x.h"
#import "IPSWDownloader.h"
#import <libfragmentzip/libfragmentzip.h>
#import <CoreImage/CoreImage.h>

class DownloadWrapper {
    
  public:
    
    char *componentURL;
    int progress;
    int downloaderNo;
    fragmentzip_t *ipsw;
    
    void open(char *url) {
        ipsw = (fragmentzip_t *) fragmentzip_open(url);
    }
    
    void set_download_no(int i) {
        downloaderNo = i;
    }
    
    void set_component(char *url) {
        componentURL = url;
    }
    
    void download_component(char *component, char *outpath) {
            set_component(component);
        
            switch(downloaderNo) {
                case 1 : fragmentzip_download_file(ipsw, component, outpath, progress_callback1);
                    break;
                case 2 : fragmentzip_download_file(ipsw, component, outpath, progress_callback2);
                    break;
                case 3 : fragmentzip_download_file(ipsw, component, outpath, progress_callback3);
                    break;
                case 4 : fragmentzip_download_file(ipsw, component, outpath, progress_callback4);
                    break;
                case 5 : fragmentzip_download_file(ipsw, component, outpath, progress_callback5);
                    break;
                default :
                    break;
            }
    }
    
    static void set_patching(int slot, int barColor) {
        return;
    }
    
    static void progress_callback1(unsigned int progress) {

        MainView *view = [Blackb0x ATVKit].mainView;
        dispatch_async(dispatch_get_main_queue(), ^{
            if(progress == 100) {
                if(view.progress1.doubleValue == 0) {
                    return;
                }
            }
            [view.progress1 setDoubleValue:(double)progress];
            if(progress != 100) set_patching(1, 0);
            else set_patching(1, 1);
        });
    }
    
    static void progress_callback2(unsigned int progress) {

        Blackb0x *atv = [Blackb0x ATVKit];

        dispatch_async(dispatch_get_main_queue(), ^{
            [atv.mainView.progress2 setDoubleValue:(double)progress];
            if(progress != 100) set_patching(2, 0);
            else set_patching(2, 1);
        });
    }
    
    static void progress_callback3(unsigned int progress) {

        Blackb0x *atv = [Blackb0x ATVKit];
        dispatch_async(dispatch_get_main_queue(), ^{
            [atv.mainView.progress3 setDoubleValue:(double)progress];
            if(progress != 100) set_patching(3, 0);
            else set_patching(3, 1);
        });
    }
    
    static void progress_callback4(unsigned int progress) {

        Blackb0x *atv = [Blackb0x ATVKit];
        dispatch_async(dispatch_get_main_queue(), ^{
            [atv.mainView.progress4 setDoubleValue:(double)progress];
            if(progress != 100) set_patching(4, 0);
            else set_patching(4, 1);
        });
    }
    
    static void progress_callback5(unsigned int progress) {

        Blackb0x *atv = [Blackb0x ATVKit];
        dispatch_async(dispatch_get_main_queue(), ^{
            [atv.mainView.progress5 setDoubleValue:(double)progress];
            if(progress != 100) set_patching(5, 0);
            else set_patching(5, 1);
        });
    }
    
};

@interface FragmentDownloader ()
@property (nonatomic) DownloadWrapper *downloader;
@end

@implementation FragmentDownloader

static FragmentDownloader *dlone, *dltwo, *dlthree, *dlfour, *dlfive;
static dispatch_once_t onceToken;

+ (int) downloadNumberForComponent:(NSString *) componentName {
    if([dlone.componentName isEqual:componentName]) return 1;
    if([dltwo.componentName isEqual:componentName]) return 2;
    if([dlthree.componentName isEqual:componentName]) return 3;
    if([dlfour.componentName isEqual:componentName]) return 4;
    if([dlfive.componentName isEqual:componentName]) return 5;
    return 0;
}

+ (instancetype) downloaderForComponent:(NSString *) componentName {
    
    if([dlone.componentName isEqualToString:componentName]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [Blackb0x ATVKit].mainView.progress1.hidden = NO;
            [Blackb0x ATVKit].mainView.progress_text1.stringValue = [NSString stringWithFormat:@"Downloading %@", componentName];
        });
        return dlone;
    }
    if([dltwo.componentName isEqualToString:componentName]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [Blackb0x ATVKit].mainView.progress2.hidden = NO;
            [Blackb0x ATVKit].mainView.progress_text2.stringValue = [NSString stringWithFormat:@"Downloading %@", componentName];
        });
        return dltwo;
    }
    if([dlthree.componentName isEqualToString:componentName]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [Blackb0x ATVKit].mainView.progress3.hidden = NO;
            [Blackb0x ATVKit].mainView.progress_text3.stringValue = [NSString stringWithFormat:@"Downloading %@", componentName];
        });
        return dlthree;
    }
    if([dlfour.componentName isEqualToString:componentName]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [Blackb0x ATVKit].mainView.progress4.hidden = NO;
            [Blackb0x ATVKit].mainView.progress_text4.stringValue = [NSString stringWithFormat:@"Downloading %@", componentName];
        });
        return dlfour;
    }
    
    if([dlfive.componentName isEqualToString:componentName]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [Blackb0x ATVKit].mainView.progress5.hidden = NO;
            [Blackb0x ATVKit].mainView.progress_text5.stringValue = [NSString stringWithFormat:@"Downloading %@", componentName];
        });
        return dlfive;
    }
    
    NSString *displayStr;
    if([componentName containsString:@"iBSS"]) displayStr = @"iBSS";
    else if([componentName containsString:@"iBEC"]) displayStr = @"iBEC";
    else if([componentName containsString:@"kernelcache"]) displayStr = @"Kernel";
    else if([componentName containsString:@".dmg"]) displayStr = @"Ramdisk";
    
    if(dlone.componentName == nil) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [Blackb0x ATVKit].mainView.progress_text1.hidden = NO;
            [Blackb0x ATVKit].mainView.progress1.hidden = NO;
            [Blackb0x ATVKit].mainView.progress_text1.stringValue = [NSString stringWithFormat:@"Downloading %@", displayStr];
        });
        return dlone;
    }
    if(dltwo.componentName == nil) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [Blackb0x ATVKit].mainView.progress_text2.hidden = NO;
            [Blackb0x ATVKit].mainView.progress2.hidden = NO;
            [Blackb0x ATVKit].mainView.progress_text2.stringValue = [NSString stringWithFormat:@"Downloading %@", displayStr];
        });
        return dltwo;
    }
    if(dlthree.componentName == nil) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [Blackb0x ATVKit].mainView.progress_text3.hidden = NO;
            [Blackb0x ATVKit].mainView.progress3.hidden = NO;
            [Blackb0x ATVKit].mainView.progress_text3.stringValue = [NSString stringWithFormat:@"Downloading %@", displayStr];
        });
        return dlthree;
    }
    if(dlfour.componentName == nil) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [Blackb0x ATVKit].mainView.progress_text4.hidden = NO;
            [Blackb0x ATVKit].mainView.progress4.hidden = NO;
            [Blackb0x ATVKit].mainView.progress_text4.stringValue = [NSString stringWithFormat:@"Downloading %@", displayStr];
        });
        return dlfour;
    }
    
    if(dlfive.componentName == nil) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [Blackb0x ATVKit].mainView.progress_text5.hidden = NO;
            [Blackb0x ATVKit].mainView.progress5.hidden = NO;
            [Blackb0x ATVKit].mainView.progress_text5.stringValue = [NSString stringWithFormat:@"Downloading %@", displayStr];
        });
        return dlfive;
    }
    
    printf("No available downloader.\n");
    return nil;
}

+ (int) loadIPSW:(NSString *) ipsw_url {
    
    dispatch_once(&onceToken, ^{

        DownloadWrapper *downloader;
        
        downloader = new DownloadWrapper();
        downloader->set_download_no(1);
        dlone =   [[self alloc] init];
        dlone.downloader = downloader;
        
        downloader = new DownloadWrapper();
        downloader->set_download_no(2);
        dltwo =   [[self alloc] init];
        dltwo.downloader = downloader;
        
        downloader = new DownloadWrapper();
        downloader->set_download_no(3);
        dlthree = [[self alloc] init];
        dlthree.downloader = downloader;
        
        downloader = new DownloadWrapper();
        downloader->set_download_no(4);
        dlfour =  [[self alloc] init];
        dlfour.downloader = downloader;

        downloader = new DownloadWrapper();
        downloader->set_download_no(5);
        dlfive = [[self alloc] init];
        dlfive.downloader = downloader;
        
    });

    for(FragmentDownloader *dl in @[dlone, dltwo, dlthree, dlfour, dlfive]) {
 
        dl.ipsw_url = ipsw_url;

        NSString *saveLocation = [NSString stringWithFormat:@"/Users/%@/Documents/Blackb0x", NSUserName()];
        dl.ipsw_folder = [NSString stringWithFormat:@"%@/%@", saveLocation, [[dl.ipsw_url lastPathComponent] stringByDeletingPathExtension]];
        if(![dl loadURL:ipsw_url]) return 0;;

    }
    return 1;
}

- (int) loadURL:(NSString *) ipsw_url {
    
    char *url = (char *)[ipsw_url UTF8String];
    _downloader->open(url);
    _progress = [NSProgress progressWithTotalUnitCount:100];
    //printf("DL:%s \nSize: %llu bytes", _downloader->ipsw->url, _downloader->ipsw->length);
    return 1;
}

- (void) downloadComponent:(NSString *) componentPath {
    
    char * component_path;
    char * out_path;
    
    _componentName = componentPath;
    component_path = (char *)[componentPath UTF8String];
    
    NSString *outPath = [NSString stringWithFormat:@"%@/%@", _ipsw_folder, componentPath];
    
    [[NSFileManager defaultManager] createDirectoryAtPath:[NSString stringWithFormat:@"%@/%@", _ipsw_folder, [componentPath stringByDeletingLastPathComponent]]
    withIntermediateDirectories:YES
                     attributes:nil
                          error:nil];
    
    out_path = (char *) [outPath UTF8String];
    _downloader->download_component((char *)[_componentName UTF8String], out_path);

}

- (void) dealloc {
    delete _downloader;
}

@end

