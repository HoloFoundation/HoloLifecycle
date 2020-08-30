//
//  HoloLifecycleManager.m
//  HoloLifecycle
//
//  Created by 与佳期 on 2020/3/8.
//

#import "HoloLifecycleManager.h"
#import <objc/runtime.h>
#import <Aspects/Aspects.h>
#import "HoloBaseLifecycle.h"
#import "HoloLifecycleMacro.h"
#import "HoloLifecycleHookInfo.h"

static NSString * const kHoloBaseLifecycleCacheInfoKey      = @"holo_base_lifecycle_cache_info_key";
static NSString * const kHoloBaseLifecycleCacheAppVersion   = @"holo_base_lifecycle_cache_app_version";
static NSString * const kHoloBaseLifecycleCacheSubClasses   = @"holo_base_lifecycle_cache_sub_classes";
static NSInteger const kAppDelegatePriority = 300;

@interface HoloLifecycleManager ()

@property (nonatomic, copy) NSArray<HoloBaseLifecycle *> *beforeInstances;

@property (nonatomic, copy) NSArray<HoloBaseLifecycle *> *afterInstances;

@property (nonatomic, strong) dispatch_semaphore_t lock;

@property (nonatomic, assign) BOOL hasLog;

@end

@implementation HoloLifecycleManager

+ (instancetype)sharedInstance {
    static HoloLifecycleManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
#if DEBUG
        NSArray *classArray = [self _findAllHoloBaseLifecycleSubClass];
#else
        NSDictionary *cacheInfo = [[NSUserDefaults standardUserDefaults] objectForKey:kHoloBaseLifecycleCacheInfoKey];
        NSString *cacheAppVersion = cacheInfo[kHoloBaseLifecycleCacheAppVersion];
        NSString *appVersion = [NSBundle.mainBundle.infoDictionary objectForKey:@"CFBundleShortVersionString"];
        
        NSArray *classArray = nil;
        if ([cacheAppVersion isEqualToString:appVersion]) {
            classArray = cacheInfo[kHoloBaseLifecycleCacheSubClasses];
        } else {
            classArray = [self _findAllHoloBaseLifecycleSubClass];
            cacheInfo = @{
                kHoloBaseLifecycleCacheAppVersion : appVersion,
                kHoloBaseLifecycleCacheSubClasses : classArray
            };
            [[NSUserDefaults standardUserDefaults] setObject:cacheInfo forKey:kHoloBaseLifecycleCacheInfoKey];
        }
#endif
        [self _createInstancesWithClassArray:classArray];
    }
    return self;
}

- (void)_createInstancesWithClassArray:(NSArray<NSString *> *)classArray {
    NSMutableArray *beforeArray = [NSMutableArray new];
    NSMutableArray *afterArray = [NSMutableArray new];
    [classArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        Class cls = NSClassFromString(obj);
        if (cls && [cls priority] >= kAppDelegatePriority) {
            [beforeArray addObject:[cls new]];
        } else if (cls) {
            [afterArray addObject:[cls new]];
        }
    }];
    self.beforeInstances = [beforeArray copy];
    self.afterInstances = [afterArray copy];
}

- (NSArray<NSString *> *)_findAllHoloBaseLifecycleSubClass {
    // 注册类的总数
    int count = objc_getClassList(NULL, 0);
    NSMutableArray *array = [NSMutableArray new];
    // 获取所有已注册的类
    Class *class = (Class *)malloc(sizeof(Class) * count);
    objc_getClassList(class, count);
    
    for (int i = 0; i < count; i++) {
        Class cls = class[i];
        if (class_getSuperclass(cls) == [HoloBaseLifecycle class] && [cls autoRegister]) {
            [array addObject:NSStringFromClass(cls)];
        }
    }
    free(class);
    
    return [array sortedArrayUsingComparator:^NSComparisonResult(NSString * _Nonnull obj1, NSString * _Nonnull obj2) {
        return [NSClassFromString(obj1) priority] < [NSClassFromString(obj2) priority];
    }];
}


// 手动注册生命周期类
- (void)registerLifecycle:(Class)lifecycle {
    HOLO_LOCK(self.lock);
    NSArray<HoloBaseLifecycle *> *instances;
    
    NSInteger priority = HoloLifecyclePriorityBeforeMedium;
    if ([lifecycle respondsToSelector:@selector(priority)]) {
        priority = [lifecycle priority];
    }
    
    if (priority >= kAppDelegatePriority) {
        instances = self.beforeInstances;
    } else {
        instances = self.afterInstances;
    }

    id lifecycleInstance = [lifecycle new];
    NSMutableArray *mutableArray = [NSMutableArray arrayWithArray:instances];
    [instances enumerateObjectsUsingBlock:^(HoloBaseLifecycle * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        NSInteger objPriority = HoloLifecyclePriorityBeforeMedium;
        if ([[obj class] respondsToSelector:@selector(priority)]) {
            objPriority = [[obj class] priority];
        }
        
        if (objPriority < priority) {
            [mutableArray insertObject:lifecycleInstance atIndex:idx];
            *stop = YES;
        }
    }];
    
    if (![mutableArray containsObject:lifecycleInstance]) {
        [mutableArray addObject:lifecycleInstance];
    }
    
    if (priority >= kAppDelegatePriority) {
        self.beforeInstances = [mutableArray copy];
    } else {
        self.afterInstances = [mutableArray copy];
    }
    HOLO_UNLOCK(self.lock);
}

// 打印所有 HoloBaseLifecycle 子类执行方法及耗时
- (void)logSelectorsAndPerformTime {
    self.hasLog = YES;
}

#pragma mark - getter
- (dispatch_semaphore_t)lock {
    if (!_lock) {
        _lock = dispatch_semaphore_create(1);
    }
    return _lock;
}

@end


@implementation UIApplication (HoloLifecycle)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        
        SEL originalSelector = @selector(setDelegate:);
        SEL swizzledSelector = @selector(_holo_setDelegate:);
        
        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
        
        BOOL success = class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
        if (success) {
            class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
}

- (void)_holo_setDelegate:(id <UIApplicationDelegate>)delegate {
    unsigned count = 0;
    Method *methods = class_copyMethodList([delegate class], &count);
    for (int i = 0; i < count; i++) {
        Method method = methods[i];
        SEL sel = method_getName(method);
        struct objc_method_description methodDesc = protocol_getMethodDescription(@protocol(UIApplicationDelegate), sel, NO, YES);
        if (methodDesc.name != NULL && methodDesc.types != NULL) {
            [self _aspect_hookSelectorWithDelegate:delegate sel:sel];
        }
    }
    
    [self _holo_setDelegate:delegate];
}

- (void)_aspect_hookSelectorWithDelegate:(id <UIApplicationDelegate>)delegate sel:(SEL)sel {
    holo_hook_func(delegate, sel);
    
//    [(NSObject *)delegate aspect_hookSelector:sel withOptions:AspectPositionBefore usingBlock:^(id<AspectInfo> info) {
//        [self _invokeWithLifecycles:[HoloLifecycleManager sharedInstance].beforeInstances sel:sel info:info];
//    } error:nil];
//    [(NSObject *)delegate aspect_hookSelector:sel withOptions:AspectPositionAfter usingBlock:^(id<AspectInfo> info) {
//        [self _invokeWithLifecycles:[HoloLifecycleManager sharedInstance].afterInstances sel:sel info:info];
//    } error:nil];
}

- (void)_invokeWithLifecycles:(NSArray<HoloBaseLifecycle *> *)lifecycles sel:(SEL)sel info:(id<AspectInfo>)info {
    for (HoloBaseLifecycle *lifecycle in lifecycles) {
        if ([lifecycle respondsToSelector:sel]) {
#ifdef DEBUG
            NSDate *startTime = nil;
            if ([HoloLifecycleManager sharedInstance].hasLog) {
                startTime = [NSDate date];
            }
#endif
            
            NSMethodSignature *signature = [lifecycle methodSignatureForSelector:sel];
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
            invocation.target = lifecycle;
            invocation.selector = sel;
            
            NSUInteger numberOfArguments = signature.numberOfArguments;
            if (numberOfArguments > info.originalInvocation.methodSignature.numberOfArguments) {
                HoloLog(@"lifecycle has too many arguments. Not calling %@", info);
                continue;
            }
            
            void *argBuf = NULL;
            for (NSUInteger idx = 2; idx < numberOfArguments; idx++) {
                const char *type = [info.originalInvocation.methodSignature getArgumentTypeAtIndex:idx];
                NSUInteger argSize;
                NSGetSizeAndAlignment(type, &argSize, NULL);
                
                if (!(argBuf = reallocf(argBuf, argSize))) {
                    HoloLog(@"Failed to allocate memory for lifecycle invocation.");
                    break;
                }
                
                [info.originalInvocation getArgument:argBuf atIndex:idx];
                [invocation setArgument:argBuf atIndex:idx];
            }
            
            [invocation invoke];
            
            if (argBuf != NULL) {
                free(argBuf);
            }
            
#ifdef DEBUG
            if ([HoloLifecycleManager sharedInstance].hasLog) {
                NSTimeInterval time = -[startTime timeIntervalSinceNow]*1000;
                HoloLog(@"\nlifecycle: %@\nselector: %@\nperformTime: %f milliseconds", NSStringFromClass([lifecycle class]), NSStringFromSelector(sel), time);
            }
#endif
        }
    }
}


static void holo_ffi_closure_func(ffi_cif *cif, void *ret, void **args, void *userdata) {
    
    HoloLifecycleHookInfo *info = (__bridge HoloLifecycleHookInfo *)userdata;
        
    for (HoloBaseLifecycle *lifecycle in [HoloLifecycleManager sharedInstance].beforeInstances) {

        if (![lifecycle respondsToSelector:info.sel]) {
            continue;
        }
        
        SEL selector = info.sel;
        NSMethodSignature *signature = [lifecycle methodSignatureForSelector:selector];

        ffi_cif cif;
        // 构造参数类型列表
        NSUInteger argsCount = signature.numberOfArguments;
        ffi_type **argTypes = calloc(argsCount, sizeof(ffi_type *));
        for (int i = 0; i < argsCount; ++i) {
            const char *argType = [signature getArgumentTypeAtIndex:i];
            ffi_type *arg_ffi_type = holo_ffiTypeWithTypeEncoding(argType);
            NSCAssert(arg_ffi_type, @"can't find a ffi_type ==> %s", argType);
            argTypes[i] = arg_ffi_type;
        }
        // 返回值类型
        ffi_type *retType = holo_ffiTypeWithTypeEncoding(signature.methodReturnType);
        ffi_prep_cif(&cif, FFI_DEFAULT_ABI, (uint32_t)signature.numberOfArguments, retType, argTypes);
        
        // 构造参数
        void **callbackArgs = calloc(argsCount, sizeof(void *));
        callbackArgs[0] = (void *)&lifecycle;
        callbackArgs[1] = &selector;
        memcpy(callbackArgs + 2, args + 2, sizeof(*args)*(argsCount - 2));
        
        __unsafe_unretained id ret = nil;
        IMP func = [lifecycle methodForSelector:selector];
        ffi_call(&cif, func, &ret, callbackArgs);
    }
    
    ffi_call(cif, info->_originalIMP, ret, args);
    
    
//    for (HoloBaseLifecycle *lifecycle in [HoloLifecycleManager sharedInstance].afterInstances) {
//        NSLog(@"-------------after");
//    }
}



void holo_hook_func(id obj, SEL sel) {
    
    Method method = class_getInstanceMethod([obj class], sel);
    
    if (!obj || !method) {
        NSCAssert(NO, @"参数错误");
        return;
    }
    
    const SEL key = holo_associatedKey(method_getName(method));
    if (objc_getAssociatedObject(obj, key)) {
        return;
    }
    
    HoloLifecycleHookInfo *info = [HoloLifecycleHookInfo infoWithObject:obj method:method];
    info.cls = [obj class];
    info.sel = sel;
    
    // info需要被强引用，否则会出现内存 crash
    objc_setAssociatedObject(obj, key, info, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    const unsigned int argsCount = method_getNumberOfArguments(method);
    // 构造参数类型列表
    ffi_type **argTypes = calloc(argsCount, sizeof(ffi_type *));
    for (int i = 0; i < argsCount; ++i) {
        const char *argType = [info.signature getArgumentTypeAtIndex:i];
        ffi_type *arg_ffi_type = holo_ffiTypeWithTypeEncoding(argType);
        NSCAssert(arg_ffi_type, @"can't find a ffi_type ==> %s", argType);
        argTypes[i] = arg_ffi_type;
    }
    // 返回值类型
    ffi_type *retType = holo_ffiTypeWithTypeEncoding(info.signature.methodReturnType);
    
    // 需要在堆上开辟内存，否则会出现内存问题(HoloLifecycleHookInfo 释放时会 free 掉)
    ffi_cif *cif = calloc(1, sizeof(ffi_cif));
    // 生成 ffi_cfi 模版对象，保存函数参数个数、类型等信息，相当于一个函数原型
    ffi_status prepCifStatus = ffi_prep_cif(cif, FFI_DEFAULT_ABI, argsCount, retType, argTypes);
    if (prepCifStatus != FFI_OK) {
        NSCAssert1(NO, @"ffi_prep_cif failed = %d", prepCifStatus);
        return;
    }
    
    // 生成新的 IMP
    void *newIMP = NULL;
    ffi_closure *cloure = ffi_closure_alloc(sizeof(ffi_closure), (void **)&newIMP);
    {
        info->_cif = cif;
        info->_argTypes = argTypes;
        info->_closure = cloure;
        info->_newIMP = newIMP;
    };
    ffi_status prepClosureStatus = ffi_prep_closure_loc(cloure, cif, holo_ffi_closure_func, (__bridge void *)info, newIMP);
    if (prepClosureStatus != FFI_OK) {
        NSCAssert1(NO, @"ffi_prep_closure_loc failed = %d", prepClosureStatus);
        return;
    }

    // 替换 IMP 实现
    Class hookClass = [obj class];
    SEL aSelector = method_getName(method);
    const char *typeEncoding = method_getTypeEncoding(method);
    if (!class_addMethod(hookClass, aSelector, newIMP, typeEncoding)) {
        // IMP originIMP = class_replaceMethod(hookClass, aSelector, newIMP, typeEncoding);
        IMP originIMP = method_setImplementation(method, newIMP);
        if (info->_originalIMP != originIMP) {
            info->_originalIMP = originIMP;
        }
    }
}


static const SEL holo_associatedKey(SEL selector) {
    NSCAssert(selector != NULL, @"selector不能为NULL");
    NSString *selectorString = [@"holo_aop_" stringByAppendingString:NSStringFromSelector(selector)];
    const SEL key = NSSelectorFromString(selectorString);
    return key;
}

ffi_type *holo_ffiTypeWithTypeEncoding(const char *type) {
    if (strcmp(type, "@?") == 0) { // block
        return &ffi_type_pointer;
    }
    const char *c = type;
    switch (c[0]) {
        case 'v':
            return &ffi_type_void;
        case 'c':
            return &ffi_type_schar;
        case 'C':
            return &ffi_type_uchar;
        case 's':
            return &ffi_type_sshort;
        case 'S':
            return &ffi_type_ushort;
        case 'i':
            return &ffi_type_sint;
        case 'I':
            return &ffi_type_uint;
        case 'l':
            return &ffi_type_slong;
        case 'L':
            return &ffi_type_ulong;
        case 'q':
            return &ffi_type_sint64;
        case 'Q':
            return &ffi_type_uint64;
        case 'f':
            return &ffi_type_float;
        case 'd':
            return &ffi_type_double;
        case 'F':
#if CGFLOAT_IS_DOUBLE
            return &ffi_type_double;
#else
            return &ffi_type_float;
#endif
        case 'B':
            return &ffi_type_uint8;
        case '^':
            return &ffi_type_pointer;
        case '@':
            return &ffi_type_pointer;
        case '#':
            return &ffi_type_pointer;
        case ':':
            return &ffi_type_pointer;
        case '*':
            return &ffi_type_pointer;
        case '{':
        default: {
            printf("not support the type: %s", c);
        } break;
    }
    
    NSCAssert(NO, @"can't match a ffi_type of %s", type);
    return NULL;
}


id holo_ArgumentAtIndex(NSMethodSignature *methodSignature, void **args, NSUInteger index) {
#define WRAP_AND_RETURN(type) \
do { \
type val = *((type *)args[index]);\
return @(val); \
} while (0)
    
    const char *originArgType = [methodSignature getArgumentTypeAtIndex:index];
//    NSString *argTypeString = ZD_ReduceBlockSignatureCodingType(originArgType);
//    const char *argType = argTypeString.UTF8String;
    const char *argType = originArgType;
    
    // Skip const type qualifier.
    if (argType[0] == 'r') {
        argType++;
    }
    
    if (strcmp(argType, @encode(id)) == 0 || strcmp(argType, @encode(Class)) == 0) {
        id argValue = (__bridge id)(*((void **)args[index]));
        return argValue;
    } else if (strcmp(argType, @encode(char)) == 0) {
        WRAP_AND_RETURN(char);
    } else if (strcmp(argType, @encode(int)) == 0) {
        WRAP_AND_RETURN(int);
    } else if (strcmp(argType, @encode(short)) == 0) {
        WRAP_AND_RETURN(short);
    } else if (strcmp(argType, @encode(long)) == 0) {
        WRAP_AND_RETURN(long);
    } else if (strcmp(argType, @encode(long long)) == 0) {
        WRAP_AND_RETURN(long long);
    } else if (strcmp(argType, @encode(unsigned char)) == 0) {
        WRAP_AND_RETURN(unsigned char);
    } else if (strcmp(argType, @encode(unsigned int)) == 0) {
        WRAP_AND_RETURN(unsigned int);
    } else if (strcmp(argType, @encode(unsigned short)) == 0) {
        WRAP_AND_RETURN(unsigned short);
    } else if (strcmp(argType, @encode(unsigned long)) == 0) {
        WRAP_AND_RETURN(unsigned long);
    } else if (strcmp(argType, @encode(unsigned long long)) == 0) {
        WRAP_AND_RETURN(unsigned long long);
    } else if (strcmp(argType, @encode(float)) == 0) {
        WRAP_AND_RETURN(float);
    } else if (strcmp(argType, @encode(double)) == 0) {
        WRAP_AND_RETURN(double);
    } else if (strcmp(argType, @encode(BOOL)) == 0) {
        WRAP_AND_RETURN(BOOL);
    } else if (strcmp(argType, @encode(char *)) == 0) {
        WRAP_AND_RETURN(const char *);
    } else if (strcmp(argType, @encode(void (^)(void))) == 0) {
        __unsafe_unretained id block = nil;
        block = (__bridge id)(*((void **)args[index]));
        return [block copy];
    }
    else {
        NSCAssert(NO, @"不支持的类型");
    }
    
    return nil;
#undef WRAP_AND_RETURN
}


@end
