//
//  HoloLifecycle.m
//  HoloLifecycle
//
//  Created by 与佳期 on 2020/3/8.
//

#import "HoloLifecycle.h"

@implementation HoloLifecycle

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
