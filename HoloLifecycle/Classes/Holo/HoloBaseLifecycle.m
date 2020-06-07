//
//  HoloBaseLifecycle.m
//  HoloLifecycle
//
//  Created by 与佳期 on 2020/6/7.
//

#import "HoloBaseLifecycle.h"
#import "HoloLifecycleManager.h"

@implementation HoloBaseLifecycle

+ (HoloLifecyclePriority)priority {
    return HoloLifecyclePriorityBeforeMedium;
}

+ (void)registerLifecycle {
    [[HoloLifecycleManager sharedInstance] registerLifecycle:self];
}

+ (BOOL)autoRegister {
    return YES;
}

@end
