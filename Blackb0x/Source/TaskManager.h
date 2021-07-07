//
//  TaskManager.h
//  Blackb0x
//
//  Created by spiral on 16/12/20.
//  Copyright © 2020 spiral. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum TaskTypes
{
    TaskTypeDownload,
    TaskTypePatch,
    TaskTypeUpload,
    TaskTypeOther
} TaskType;

@interface Task : NSObject

@property (strong) NSString *taskName;
@property (nonatomic) TaskType type;
@property (strong) NSProgressIndicator *progressIndicator;
@property (strong) NSTextField *progressText;
@end

@interface TaskManager : NSObject

+ (TaskManager *) manager;

@property (strong) NSMutableArray *progressBars;
@property (strong) NSMutableArray *tasks;

@end

NS_ASSUME_NONNULL_END
