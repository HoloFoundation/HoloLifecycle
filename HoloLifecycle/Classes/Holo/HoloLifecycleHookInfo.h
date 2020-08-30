//
//  HoloLifecycleHookInfo.h
//  HoloLifecycle
//
//  Created by 与佳期 on 2020/8/30.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "ffi.h"

NS_ASSUME_NONNULL_BEGIN

@interface HoloLifecycleHookInfo : NSObject {
    @public
    ffi_cif *_cif;
    ffi_type **_argTypes;
    ffi_closure *_closure;

    void *_originalIMP;
    void *_newIMP;
}

@property (nonatomic) Method method;
@property (nonatomic, strong) NSMethodSignature *signature;
@property (nonatomic, copy) NSString *typeEncoding;
@property (nonatomic, weak) id obj;

@property (nonatomic, strong) Class cls;
@property (nonatomic, assign) SEL sel;

+ (instancetype)infoWithObject:(id)obj method:(Method _Nullable)method;

@end

NS_ASSUME_NONNULL_END
