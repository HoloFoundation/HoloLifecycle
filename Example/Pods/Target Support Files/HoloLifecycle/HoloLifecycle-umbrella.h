#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "HoloBaseLifecycle.h"
#import "HoloLifecycleManager.h"
#import "HoloLifecycleProtocol.h"
#import "HoloLifecycle.h"

FOUNDATION_EXPORT double HoloLifecycleVersionNumber;
FOUNDATION_EXPORT const unsigned char HoloLifecycleVersionString[];

