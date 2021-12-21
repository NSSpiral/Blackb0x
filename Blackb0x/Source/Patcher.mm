//
//  Patcher.mm
//  Blackb0x
//
//  Created by spiral on 5/10/20.
//  Copyright © 2020 spiral. All rights reserved.
//

#import "Patcher.h"
#import "IPSW.h"
#import "xpwntool.h"
#import "libiboot32patcher.h"
#import "CBPatcher.h"
#import "Blackb0x.h"
#import "MainView.h"

@implementation Patcher

- (instancetype) init {
    self = [super init];
    
    _ipsw_fetcher = [[IPSW_Fetch alloc] init];
    [self clearComponents];
  
/*
    _realVersions[@"4.0"] = @"4.0";
    _realVersions[@"4.1"] = @"4.0";
    _realVersions[@"4.1.1"] = @"4.0";
    _realVersions[@"4.2"] = @"4.0";
    _realVersions[@"4.2.1"] = @"4.0";
    _realVersions[@"4.2.2"] = @"4.0";
    _realVersions[@"4.3"] = @"4.0";
    
    _realVersions[@"4.4"] = @"5.0";
    _realVersions[@"4.4.1"] = @"5.0";
    _realVersions[@"4.4.2"] = @"5.0";
    _realVersions[@"4.4.3"] = @"5.0";
    _realVersions[@"4.4.4"] = @"5.0";
    _realVersions[@"5.0"] = @"5.0";
    _realVersions[@"5.0.1"] = @"5.0";
    _realVersions[@"5.0.2"] = @"5.0";
    
    _realVersions[@"5.1"] = @"6.0";
    _realVersions[@"5.1.1"] = @"6.0";
    _realVersions[@"5.2"] = @"6.0";
    _realVersions[@"5.2.1"] = @"6.0";
    _realVersions[@"5.3"] = @"6.0";
    
    _realVersions[@"6.0"] = @"7.0";
    _realVersions[@"6.0.1"] = @"7.0";
    _realVersions[@"6.0.2"] = @"7.0";
    _realVersions[@"6.1"] = @"7.0";
    _realVersions[@"6.1.1"] = @"7.0";
    _realVersions[@"6.2"] = @"7.0";
    _realVersions[@"6.2.1"] = @"7.0";
    
    _realVersions[@"7.0"] = @"8.0";
    _realVersions[@"7.0.1"] = @"8.0";
    _realVersions[@"7.0.2"] = @"8.0";
    _realVersions[@"7.1"] = @"8.0";
    _realVersions[@"7.2"] = @"8.0";
    _realVersions[@"7.2.1"] = @"8.0";
    _realVersions[@"7.2.2"] = @"8.0";
    _realVersions[@"7.3"] = @"8.0";
    _realVersions[@"7.3.1"] = @"8.0";
    _realVersions[@"7.4"] = @"8.0";
    _realVersions[@"7.5"] = @"8.0";
    _realVersions[@"7.6"] = @"8.0";
*/
    return self;
}

- (NSString *) getRealVersion:(NSString *) version {
    
    if(!version) return nil;
    
    int first, second, third;
    
    NSArray *arr = [version componentsSeparatedByString:@"."];
    first = [arr[0] intValue];
    second = [arr[1] intValue];
    third = 0;
    if([arr count] > 2) {
        third = [arr[2] intValue];
    }
    
    printf("Version: %i.%i.%i\n", first, second, third);
    switch(first) {
        case 4 :
            if(second < 4) return @"4.0";
            else return @"5.0";
        case 5 :
            if(second == 0) return @"5.0";
            else return @"6.0";
        case 6 : return @"7.0";
        case 7 :
            if(second || third) {
                return @"8.1";
            }
            return @"8.0";
        default : return @"8.1";
    }
}

- (void) loadKeysForDevice:(NSString *) deviceID buildID:(NSString *) buildID {
    
    printf("Finding firmware keys for %s, %s\n", [deviceID UTF8String], [buildID UTF8String]);
    
    self.keys = [_ipsw_fetcher keysForDevice:deviceID buildID:buildID];
    
    if(self.iBSSPath) [self patchiBSS:self.iBSSPath];
    
    if(self.iBECPath) {
        if([self.iBECPath containsString:@"4."]) [self patchiBEC:self.iBECPath flags:(char*)"" ticket:0];
        else [self patchiBEC:self.iBECPath];
    }

    if(self.KernelPath) [self patchKernel:self.KernelPath];
    if(self.RamdiskPath) [self patchRamdisk:self.RamdiskPath ssh:NO]; //TODO: Have this use a check box
    
}

- (char *) iv:(NSString *) imageName {
    NSArray *arr = _keys[imageName];
    NSString *ivstr = arr[0];
    char *iv = (char *)[ivstr UTF8String];
    return iv;
}

- (char *) key:(NSString *) imageName {
    NSArray *arr = _keys[imageName];
    NSString *keystr = arr[1];
    char *key = (char *)[keystr UTF8String];
    
    if(key == nil) NSLog(@"Keys : %@", _keys);
    return key;
}

- (char *)input:(NSString *) str {
    char *input = (char *)[str UTF8String];
    return input;
}

- (char *)replaceExtension:(NSString *) path with:(NSString *) ext {
    NSString *str = [[path stringByDeletingPathExtension] stringByAppendingPathExtension:ext];
    char *s = (char *)[str UTF8String];
    return s;
}

- (char *)decrypted:(NSString *) str {
    return [self replaceExtension:str with:@"dec"];
}

- (char *)patched:(NSString *) str {
    return [self replaceExtension:str with:@"patched"];
}

- (char *)preboot:(NSString *) str {
    return [self replaceExtension:str with:@"preboot"];
}

- (char *)output:(NSString *) str {
    NSString *outputStr = [str stringByDeletingPathExtension];
    char *output = (char *)[outputStr UTF8String];
    return output;
}

- (char *)patchedDMG:(NSString *) str {
    NSString *patchedStr = [NSString stringWithFormat:@"%@-patched.dmg", [str stringByDeletingPathExtension]];
    char *patched = (char *)[patchedStr UTF8String];
    return patched;
}

- (char *)decryptedDMG:(NSString *) str {
    NSString *decryptedStr = [NSString stringWithFormat:@"%@-decrypted.dmg", [str stringByDeletingPathExtension]];
    char *decrypted = (char *)[decryptedStr UTF8String];
    return decrypted;
}

- (char *)downgrade:(NSString *) str {
    return [self replaceExtension:str with:@"downgrade"];
}

- (NSString *)versionString:(NSString *) str {
    NSString *device;
    NSString *version;

    NSArray *pathArr = [str componentsSeparatedByString:@"/"];
    NSString *firmwareStr = pathArr[[pathArr count] - 2];
    
    NSArray *arr = [firmwareStr componentsSeparatedByString:@"_"];
    device = arr[0];
    version = arr[1];
    
    printf("Device: %s - Version: %s\n", [device UTF8String], [version UTF8String]);
    return version;
}

//decrypt(char *input_path, char *ouput_path, char *ip_key, char *ip_iv, char *decrypt, char *template_path);
//iBootPatcher(char *infile, char *outfile, char *args, char *RSA, char *debug, char *ticket, char *kaslr)

- (int) patchiBSS:(NSString *) path {
    
    printf("----\nDecrypting iBSS at %s\n", [self input:path]);
    printf("--> %s\n", [self decrypted:path]);
    printf("iv %s\n", [self iv:@"iBSS"]);
    printf("key %s\n", [self key:@"iBSS"]);

    decrypt([self input:path], [self decrypted:path], [self key:@"iBSS"], [self iv:@"iBSS"], (char *)"FALSE", NULL);
    iBootPatcher([self decrypted:path], [self patched:path], nil, (char *)"TRUE", (char *)"FALSE", (char *)"FALSE", (char *)"FALSE");
    decrypt([self patched:path], [self output:path], [self key:@"iBSS"], [self iv:@"iBSS"], (char *)"FALSE", [self input:path]);
    
    [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithUTF8String:[self decrypted:path]] error:nil];
    
    if([path containsString:@"j33i"] || [path containsString:@"j33ap"]) { //Apple TV 3
        [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithUTF8String:[self output:path]] error:nil];
        _outputPaths[0] = [NSString stringWithUTF8String:[self patched:path]];
    }
    else { //Apple TV 2
        [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithUTF8String:[self patched:path]] error:nil];
        _outputPaths[0] = [NSString stringWithUTF8String:[self output:path]];
    }
    
    [self checkPatching];
    
    return 1;
}

- (int) patchiBEC:(NSString *) path {
    return [self patchiBEC:path flags:(char *)"" ticket:1];
}

- (int) patchiBEC:(NSString *) path flags:(char *) flags ticket:(int) ticket {
    
    printf("----\nDecrypting iBEC at %s\n", [self input:path]);
    printf("--> %s\n", [self decrypted:path]);
    printf("iv %s\n", [self iv:@"iBEC"]);
    printf("key %s\n", [self key:@"iBEC"]);
    
    decrypt([self input:path], [self decrypted:path], [self key:@"iBEC"], [self iv:@"iBEC"], (char *)"FALSE", NULL);
    
    char *args1 = (char *)"rd=md0 amfi=0xff cs_enforcement_disable=1 pio-error=0"; //-v
    char *args2 = (char *)"amfi=0xff cs_enforcement_disable=1 pio-error=0 amfi_get_out_of_my_way=1 cs_enforcement_disable=1"; //-v
    
    char *t = (char *)"TRUE";
    if(!ticket) t = (char *)"FALSE";
    
    iBootPatcher([self decrypted:path], [self patched:path], args1, (char *)"TRUE", (char *)"FALSE", t, (char *)"TRUE");
    iBootPatcher([self decrypted:path], [self preboot:path], args2, (char *)"TRUE", (char *)"FALSE", t, (char *)"TRUE");
    
    decrypt([self patched:path], [self downgrade:path], [self key:@"iBEC"], [self iv:@"iBEC"], (char *)"FALSE", [self input:path]);
    decrypt([self preboot:path], [self output:path], [self key:@"iBEC"], [self iv:@"iBEC"], (char *)"FALSE", [self input:path]);
    
    [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithUTF8String:[self decrypted:path]] error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithUTF8String:[self patched:path]] error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithUTF8String:[self preboot:path]] error:nil];
    
    _outputPaths[1] = [NSString stringWithUTF8String:[self downgrade:path]];
    _outputPaths[2] = [NSString stringWithUTF8String:[self output:path]];
    
    [self checkPatching];
    
    return 1;
}

- (int) patchKernel:(NSString *) path {
    
    printf("----\nDecrypting kernelcache at %s\n", [self input:path]);
    printf("--> %s\n", [self decrypted:path]);
    printf("iv %s\n", [self iv:@"Kernelcache"]);
    printf("key %s\n", [self key:@"Kernelcache"]);
    
    NSString *internalFirmware = [self versionString:path];
    
    if([path containsString:@"AppleTV"]) {
        internalFirmware = [self getRealVersion:[self versionString:path]];
    }
    
    printf("Real version: %s\n", [internalFirmware UTF8String]);
    
    decrypt([self input:path], [self decrypted:path], [self key:@"Kernelcache"], [self iv:@"Kernelcache"], (char *)"FALSE", NULL);
    patch_kernel([self decrypted:path], [self patched:path], (char *)[internalFirmware UTF8String]);
    decrypt([self patched:path], [self output:path], [self key:@"Kernelcache"], [self iv:@"Kernelcache"], (char *)"FALSE", [self input:path]);
    
    [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithUTF8String:[self decrypted:path]] error:nil];
    
    _outputPaths[3] = [NSString stringWithUTF8String:[self output:path]];
    [self checkPatching];
    
    return 1;
}

- (int) runCommand:(NSString *) cmd withArguments:(NSArray *) args {
    
    int ret;
    NSPipe *outpipe = [NSPipe pipe];
    NSPipe *inpipe = [NSPipe pipe];
  
    NSFileHandle *outhandle;
    NSFileHandle *inhandle;
    
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:cmd];
    [task setArguments:args];
    
    [task setStandardOutput:outpipe];
    [task setStandardInput:inpipe];
    //[task setStandardOutput:errorpipe];
    
    outhandle = [outpipe fileHandleForReading];
    inhandle = [inpipe fileHandleForReading];
    
    [task launch];
    [task waitUntilExit];
    
    ret = [task terminationStatus];
    
    printf("Running: %s(", [cmd UTF8String]);
    
    for(NSString *arg in args) {
        printf("%s ", [arg UTF8String]);
    }
    printf(") -> %s\n", (ret == 0) ? "Success" : "Fail");
    
    NSData *data = [outhandle readDataToEndOfFile];
    
    if([data length]) {
        //NSString *output = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
        //NSLog(@"[Task] %@", output);
    }

    return !ret;
}

- (int) patchRamdisk:(NSString *) path ssh:(BOOL) ssh {
    printf("----\nDecrypting ramdisk at %s\n", [self input:path]);
    printf("--> %s\n", [self decryptedDMG:path]);
    printf("iv %s\n", [self iv:@"RestoreRamdisk"]);
    printf("key %s\n", [self key:@"RestoreRamdisk"]);
    
    decrypt([self input:path], [self decryptedDMG:path], [self key:@"RestoreRamdisk"], [self iv:@"RestoreRamdisk"], (char *)"FALSE", NULL);
    
/*
     mount_hfs /dev/disk0s1s1 /mnt1
     mount_hfs /dev/disk0s1s2 /mnt1/private/var
*/
    
    MainView *view = [Blackb0x ATVKit].mainView;
    AppleTVIcon *icon = view.selected_device;
    
    NSArray *arr = [icon.version componentsSeparatedByString:@"."];
    int version = [arr[0] intValue];
    if(!version) version = 8;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
 
    BOOL success = NO;
    
    NSString *mountPoint = @"/tmp/ramdisk_create/";
    
    //Make sure not already mounted
    [self runCommand:@"/usr/bin/hdiutil" withArguments:@[@"detach", mountPoint]];
    [self runCommand:@"/usr/bin/hdiutil" withArguments:@[@"eject", @"/Volumes/ramdisk"]];
    
    //Create mount point
    [fileManager removeItemAtPath:@"/tmp/ramdisk_create/" error:nil];
    success = [fileManager createDirectoryAtPath:@"/tmp/ramdisk_create/" withIntermediateDirectories:NO attributes:nil error:NULL];
    
    if(!success) {
        printf("Failed to create mountpoint\n");
        return -1;
    }
    
    if([path containsString:@"AppleTV2,1_4."]) { //Recreate ramdisk for older Apple TV OS
        
        [self runCommand:@"/usr/bin/hdiutil" withArguments:@[@"attach", @"-mountpoint", mountPoint, [NSString stringWithUTF8String:[self decryptedDMG:path]]]];
        [self runCommand:@"/usr/bin/hdiutil" withArguments:@[@"create", @"/tmp/Ramdisk.dmg", @"-volname", @"Ramdisk", @"-srcfolder", @"/tmp/ramdisk_create", @"-format", @"UDRW", @"-layout", @"NONE"]];
        [self runCommand:@"/usr/bin/hdiutil" withArguments:@[@"detach", @"/tmp/ramdisk_create/"]];
        
        [self runCommand:@"/bin/rm" withArguments:@[[NSString stringWithUTF8String:[self decryptedDMG:path]]]];
        [self runCommand:@"/bin/mv" withArguments:@[@"/tmp/Ramdisk.dmg", [NSString stringWithUTF8String:[self decryptedDMG:path]]]];
        
    }
    
    //Resize ramdisk
    NSString *rdSize = @"60MB";//@"38MB";
    if(ssh) rdSize = @"40MB"; //17MB
    
    if(![self runCommand:@"/usr/bin/hdiutil" withArguments:@[@"resize", @"-size", rdSize, [NSString stringWithUTF8String:[self decryptedDMG:path]]]]) {
        printf("Failed to resize ramdisk\n");
        return -1;
    }
    
    //Mount ramdisk to mount point
    if(![self runCommand:@"/usr/bin/hdiutil" withArguments:@[@"attach", @"-mountpoint", mountPoint, [NSString stringWithUTF8String:[self decryptedDMG:path]]]]) {
        printf("Failed to mount ramdisk\n");
        return -1;
    }
    
    //Untar SSH
    NSString *sshPath = [[NSBundle mainBundle] pathForResource:@"ssh" ofType:@"tar"];
    if(![self runCommand:@"/usr/bin/tar" withArguments:@[@"-xvf", sshPath, @"-C", mountPoint]]) {
        printf("Failed to untar ssh\n");
        return -1;
    }

    //Untar Ramdisk Bins
    NSString *binsPath = [[NSBundle mainBundle] pathForResource:@"RamdiskBins" ofType:@"tar"];
    if(![self runCommand:@"/usr/bin/tar" withArguments:@[@"-xvf", binsPath, @"-C", mountPoint]]) {
        printf("Failed to untar bins\n");
        return -1;
    }
    
    if(!ssh) {
        
        //Make space by removing system files
/*
        [self runCommand:@"/bin/rm" withArguments:@[@"-rf", @"/tmp/ramdisk_create/System"]];
        [self runCommand:@"/bin/rm" withArguments:@[@"-rf", @"/tmp/ramdisk_create/usr/lib"]];
        [self runCommand:@"/bin/rm" withArguments:@[@"-rf", @"/tmp/ramdisk_create/usr/standalone/firmware"]];
        [self runCommand:@"/bin/rm" withArguments:@[@"-rf", @"/tmp/ramdisk_create/usr/local/standalone/firmware"]];
*/
        
        //Cydia
        success = [fileManager createDirectoryAtPath:@"/tmp/ramdisk_create/files/cydia/" withIntermediateDirectories:YES attributes:nil error:NULL];
        if(success) printf("Created cydia directory...\n");
        else {
            printf("Failed to create directory\n");
            return -1;
        }
        
        NSString *cydiaPath = [[NSBundle mainBundle] pathForResource:@"ATV-Cydia" ofType:@"tgz"];
        if(![self runCommand:@"/usr/bin/tar" withArguments:@[@"-xpzf", cydiaPath, @"-C", [NSString stringWithFormat:@"%@/files/cydia/", mountPoint]]]) {
            printf("Failed to untar cydia\n");
            return -1;
        }

        //Compatibility debs
        NSString *debsPath = [[NSBundle mainBundle] pathForResource:@"Debs" ofType:@"tar"];
        if(![self runCommand:@"/usr/bin/tar" withArguments:@[@"-xvf", debsPath, @"-C", [NSString stringWithFormat:@"%@/files/", mountPoint]]]) {
            printf("Failed to untar debs\n");
            return -1;
        }
            
        //P0sixspwn untether
        if(![fileManager createDirectoryAtPath:@"/tmp/ramdisk_create/files/p0sixspwn/" withIntermediateDirectories:YES attributes:nil error:NULL]) {
            printf("Failed to create p0sixspwn directory\n");
            return -1;
        }
        
        NSString *posixPath = [[NSBundle mainBundle] pathForResource:@"p0sixspwn" ofType:@"tgz"];
        
        if(![self runCommand:@"/usr/bin/tar" withArguments:@[@"-xpzf", posixPath, @"-C", [NSString stringWithFormat:@"%@/files/p0sixspwn/", mountPoint]]]) {
            printf("Failed to untar p0sixspwn\n");
            return -1;
        }

        //Anthrax
        NSString *launchdPath = [[NSBundle mainBundle] pathForResource:@"launchd" ofType:@""];
        [fileManager removeItemAtPath:@"/tmp/ramdisk_create/sbin/launchd" error:nil];
        [fileManager copyItemAtPath:launchdPath toPath:@"/tmp/ramdisk_create/sbin/launchd" error:nil];
        [fileManager createDirectoryAtPath:@"/tmp/ramdisk_create/mnt/" withIntermediateDirectories:NO attributes:nil error:nil];
        
        //LaunchDaemons and config
        [self moveFileFromBundle:@"" fileType:@"blackb0x"];
        [self moveFileFromBundle:@"com.blackb0x.postinstall" fileType:@"plist"];
        [self moveFileFromBundle:@"com.openssh.sshd" fileType:@"plist"];
        [self moveFileFromBundle:@"setup" fileType:@"sh"];
        [self moveFileFromBundle:@"profile" fileType:nil];
        [self moveFileFromBundle:@"fstab" fileType:@"atv"];
        //[self moveFileFromBundle:@"afc2d" fileType:nil];
        //[self moveFileFromBundle:@"afc2dService" fileType:@"d"];
        //[self moveFileFromBundle:@"afc2dService" fileType:@"plist"];
                
    
        //EtasonATV Untether
        if(![fileManager createDirectoryAtPath:@"/tmp/ramdisk_create/files/etasonATV/" withIntermediateDirectories:YES attributes:nil error:NULL]) {
            printf("Failed to create etasonATV directory\n");
            return -1;
        }

        NSString *untetherPath = [[NSBundle mainBundle] pathForResource:@"tihmstar-untether" ofType:@"tar"];
        if(![self runCommand:@"/usr/bin/tar" withArguments:@[@"-xpvf", untetherPath, @"-C", [NSString stringWithFormat:@"%@/files/etasonATV/", mountPoint]]])  {
            printf("Failed to untar etason untether\n");
            return -1;
        }
        
        //Blackb0x Tether
        [self moveFileFromBundle:@"rtbuddyd" fileType:@"bin"];
        
        //Icons
        [self moveFileFromBundle:@"kodi" fileType:@"png"];
        [self moveFileFromBundle:@"nito" fileType:@"png"];
        
        //Repos
        [self moveFileFromBundle:@"joshtv" fileType:@"list"];
        [self moveFileFromBundle:@"pubkey" fileType:@"key"];
        [self moveFileFromBundle:@"xbmc" fileType:@"list"];
        
    }
    
    [fileManager copyItemAtPath:sshPath toPath:@"/tmp/ramdisk_create/ssh.tar" error:nil];
    
    //Detach image from mount point
    if(![self runCommand:@"/usr/bin/hdiutil" withArguments:@[@"detach", mountPoint]]) {
        printf("Failed to detach dmg\n");
        return -1;
    }
    
    decrypt([self decryptedDMG:path], [self patchedDMG:path], [self key:@"RestoreRamdisk"], [self iv:@"RestoreRamdisk"], (char *)"FALSE", [self input:path]);
    
    _outputPaths[4] = [NSString stringWithUTF8String:[self patchedDMG:path]];
    [self checkPatching];
    
    return 1;
}

- (void) moveFileFromBundle:(NSString *) fileName fileType:(NSString *) fileType {
    NSString *path = [[NSBundle mainBundle] pathForResource:fileName ofType:fileType];
    printf("Moving file from %s to ramdisk\n", [path UTF8String]);
    
    NSString *outputPath;
    if(fileType == nil)
        outputPath = [NSString stringWithFormat:@"/tmp/ramdisk_create/files/%@", fileName];
    else
        outputPath = [NSString stringWithFormat:@"/tmp/ramdisk_create/files/%@.%@", fileName, fileType];
    
    [[NSFileManager defaultManager] copyItemAtPath:path toPath:outputPath error:nil];
}

- (void) checkPatching {
    
    if(_outputPaths[0] == [NSNull null]) return; //iBSS
    
    if(!_onlyBootComponents) {
        if(_outputPaths[1] == [NSNull null]) return; //Ramdisk iBEC
        if(_outputPaths[4] == [NSNull null]) return; //Ramdisk
    }
    else {
        if(_outputPaths[2] == [NSNull null]) return; //Boot iBEC
    }
    
    if(_outputPaths[3] == [NSNull null]) return; //KernelCache
    if(_outputPaths[5] == [NSNull null]) return; //DeviceTree
    
    dispatch_async(dispatch_get_main_queue(), ^{
        MainView *view = [Blackb0x ATVKit].mainView;
        [view setProgressColor:[NSColor cyanColor] forSlot:1];
        view.progress1.doubleValue = 0;
        
        view.progress2.hidden = YES;
        view.progress3.hidden = YES;
        view.progress4.hidden = YES;
        view.progress5.hidden = YES;
        
        view.progress_text2.hidden = YES;
        view.progress_text3.hidden = YES;
        view.progress_text4.hidden = YES;
        view.progress_text5.hidden = YES;
        
        [view componentsReady:self.outputPaths];
        
        [self clearComponents];
    });
}

- (void) clearComponents {
    _outputPaths = [[NSMutableArray alloc] initWithObjects:[NSNull null], [NSNull null], [NSNull null], [NSNull null], [NSNull null], [NSNull null], nil];
}

- (void)setIBSSPath:(NSString *)iBSSPath {
    _iBSSPath = iBSSPath;
    if(!_keys) return;
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        [self patchiBSS:iBSSPath];
    });
}

- (void)setIBECPath:(NSString *)iBECPath {
    _iBECPath = iBECPath;
    if(!_keys) return;
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        if(iBECPath) {
            if([iBECPath containsString:@"4."]) [self patchiBEC:iBECPath flags:(char*)"" ticket:0];
            else [self patchiBEC:iBECPath];
        }
    });
}

- (void)setKernelPath:(NSString *)KernelPath {
    _KernelPath = KernelPath;
    if(!_keys) return;

    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        [self patchKernel:KernelPath];
    });
}

- (void)setRamdiskPath:(NSString *)RamdiskPath {
    _RamdiskPath = RamdiskPath;
    if(!_keys) return;
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        [self patchRamdisk:RamdiskPath ssh:NO]; //TODO: Make this use a toggle
    });
}

- (void) setDeviceTreePath:(NSString *)DeviceTreePath {
    _DeviceTreePath = DeviceTreePath;
    
    _outputPaths[5] = _DeviceTreePath;
    [self checkPatching];
}

@end
