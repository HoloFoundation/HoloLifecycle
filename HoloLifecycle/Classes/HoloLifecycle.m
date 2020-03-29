//
//  HoloLifecycle.m
//  HoloLifecycle
//
//  Created by 与佳期 on 2020/3/8.
//

#import "HoloLifecycle.h"
#import "HoloLifecycleManager.h"

@implementation HoloLifecycle

+ (HoloLifecyclePriority)priority {
    return HoloLifecyclePriorityBeforeMedium;
}

+ (BOOL)autoRegister {
    return YES;
}

+ (void)registerLifecycle {
    [[HoloLifecycleManager sharedInstance] registerLifecycle:self];
}

@end
