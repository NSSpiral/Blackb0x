//
//  TaskManager.m
//  Blackb0x
//
//  Created by spiral on 16/12/20.
//  Copyright © 2020 spiral. All rights reserved.
//

#import "TaskManager.h"

@implementation Task

- (instancetype) init {
    self = [super init];
    _type = TaskTypeDownload;
    
    return self;
}

- (void) updateProgress:(int) percent {
    if(!_progressIndicator) return;
    
    
}

@end

@implementation TaskManager

- (instancetype) init {
    self = [super init];
    _tasks = [[NSMutableArray alloc] init];
    
    
    return self;
}

+ (TaskManager *) manager {
    static TaskManager *taskManager = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        taskManager = [[self alloc] init];
    });
    
    return taskManager;
            
}

+ (Task *) taskWithName:(NSString *) taskName {
    TaskManager *manager = [TaskManager manager];
    
    for(Task *t in manager.tasks) {
        if([t.taskName isEqualTo:taskName]) {
            return t;
        }
    }
    
    Task *task = [[Task alloc] init];
    task.taskName = taskName;
    
    return task;
    
}

                  
@end
