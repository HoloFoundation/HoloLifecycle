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
#import "HoloLifecycleMacro.h"
#import "HoloLifecycleManager.h"
#import "HoloLifecycleProtocol.h"
#import "HoloLifecycle.h"
#import "ffi.h"
#import "fficonfig.h"
#import "fficonfig_arm64.h"
#import "fficonfig_armv7.h"
#import "fficonfig_i386.h"
#import "fficonfig_x86_64.h"
#import "ffitarget.h"
#import "ffitarget_arm64.h"
#import "ffitarget_armv7.h"
#import "ffitarget_i386.h"
#import "ffitarget_x86_64.h"
#import "ffi_arm64.h"
#import "ffi_armv7.h"
#import "ffi_common.h"
#import "ffi_i386.h"
#import "ffi_x86_64.h"

FOUNDATION_EXPORT double HoloLifecycleVersionNumber;
FOUNDATION_EXPORT const unsigned char HoloLifecycleVersionString[];

