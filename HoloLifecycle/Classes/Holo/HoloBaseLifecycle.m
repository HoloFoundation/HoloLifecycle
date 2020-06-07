//
//  HoloBaseLifecycle.m
//  HoloLifecycle
//
//  Created by 与佳期 on 2020/6/7.
//

#import "HoloBaseLifecycle.h"
#import "HoloLifecycleManager.h"

@implementation HoloBaseLifecycle

+ (void)registerLifecycle {
    [[HoloLifecycleManager sharedInstance] registerLifecycle:self];
}

+ (HoloLifecyclePriority)priority {
    return HoloLifecyclePriorityBeforeMedium;
}

+ (BOOL)autoRegister {
    return YES;
}

@end
