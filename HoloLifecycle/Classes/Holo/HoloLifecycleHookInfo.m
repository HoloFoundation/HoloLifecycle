//
//  HoloLifecycleHookInfo.m
//  HoloLifecycle
//
//  Created by 与佳期 on 2020/8/30.
//

#import "HoloLifecycleHookInfo.h"

@implementation HoloLifecycleHookInfo

- (void)dealloc {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    if (_cif) {
        free(_cif);
        _cif = NULL;
    }
    if (_closure) {
        ffi_closure_free(_closure);
        _closure = NULL;
    }
    if (_argTypes) {
        free(_argTypes);
        _argTypes = NULL;
    }
}

+ (instancetype)infoWithObject:(id)obj method:(Method)method {
    if (!obj) {
        return nil;
    }
    
    HoloLifecycleHookInfo *model = [HoloLifecycleHookInfo new];
    model.obj = obj;
    model.method = method;
    {
        const char *typeEncoding = method_getTypeEncoding(method);
        NSMethodSignature *signature = [NSMethodSignature signatureWithObjCTypes:typeEncoding];
        model.signature = signature;
        model.typeEncoding = [NSString stringWithUTF8String:typeEncoding];
        
        model->_originalIMP = (void *)method_getImplementation(method);
    }
    
    return model;
}



@end

