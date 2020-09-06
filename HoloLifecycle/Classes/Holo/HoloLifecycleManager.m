//
//  HoloLifecycleManager.m
//  HoloLifecycle
//
//  Created by 与佳期 on 2020/3/8.
//

#import "HoloLifecycleManager.h"
#import <objc/runtime.h>
#import "HoloBaseLifecycle.h"
#import "HoloLifecycleMacro.h"
#import "HoloLifecycleHookInfo.h"
#import "ffi.h"

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
                kHoloBaseLifecycleCacheAppVersion : appVersion ?: @"",
                kHoloBaseLifecycleCacheSubClasses : classArray ?: @[]
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
            holo_lifecycle_hook_func(delegate, sel);
        }
    }
    
    [self _holo_setDelegate:delegate];
}

void holo_lifecycle_hook_func(id obj, SEL sel) {
    NSString *selStr = [@"holo_lifecycle_" stringByAppendingString:NSStringFromSelector(sel)];
    const SEL key = NSSelectorFromString(selStr);
    if (objc_getAssociatedObject(obj, key)) {
        return;
    }
    
    HoloLifecycleHookInfo *info = [HoloLifecycleHookInfo new];
    info.cls = [obj class];
    info.sel = sel;
    
    objc_setAssociatedObject(obj, key, info, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    Method method = class_getInstanceMethod([obj class], sel);
    const char *typeEncoding = method_getTypeEncoding(method);
    NSMethodSignature *signature = [NSMethodSignature signatureWithObjCTypes:typeEncoding];
    
    const unsigned int argsCount = method_getNumberOfArguments(method);
    // 构造参数类型列表
    ffi_type **argTypes = calloc(argsCount, sizeof(ffi_type *));
    for (int i = 0; i < argsCount; ++i) {
        const char *argType = [signature getArgumentTypeAtIndex:i];
        ffi_type *arg_ffi_type = holo_lifecycle_ffi_type(argType);
        NSCAssert(arg_ffi_type, @"HoloLifecycle: can't find a ffi_type: %s", argType);
        argTypes[i] = arg_ffi_type;
    }
    // 返回值类型
    ffi_type *retType = holo_lifecycle_ffi_type(signature.methodReturnType);
    
    // 需要在堆上开辟内存，否则会出现内存问题 (HoloLifecycleHookInfo 释放时会 free 掉)
    ffi_cif *cif = calloc(1, sizeof(ffi_cif));
    // 生成 ffi_cfi 模版对象，保存函数参数个数、类型等信息，相当于一个函数原型
    ffi_status prepCifStatus = ffi_prep_cif(cif, FFI_DEFAULT_ABI, argsCount, retType, argTypes);
    if (prepCifStatus != FFI_OK) {
        NSCAssert(NO, @"HoloLifecycle: ffi_prep_cif failed: %d", prepCifStatus);
        return;
    }
    
    // 生成新的 IMP
    void *newIMP = NULL;
    ffi_closure *closure = ffi_closure_alloc(sizeof(ffi_closure), (void **)&newIMP);
    ffi_status prepClosureStatus = ffi_prep_closure_loc(closure, cif, holo_lifecycle_ffi_closure_func, (__bridge void *)info, newIMP);
    if (prepClosureStatus != FFI_OK) {
        NSCAssert(NO, @"HoloLifecycle: ffi_prep_closure_loc failed: %d", prepClosureStatus);
        return;
    }
    
    // 替换 IMP 实现
    Class hookClass = [obj class];
    SEL aSelector = method_getName(method);
    if (!class_addMethod(hookClass, aSelector, newIMP, typeEncoding)) {
        IMP originIMP = method_setImplementation(method, newIMP);
        if (info->_originalIMP != originIMP) {
            info->_originalIMP = originIMP;
        }
    }
}

#define HOLO_LIFECYCLE_START \
CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent(); \

#define HOLO_LIFECYCLE_END_LOG(cls, sel) \
if ([HoloLifecycleManager sharedInstance].hasLog) { \
CFAbsoluteTime endTime = (CFAbsoluteTimeGetCurrent() - startTime); \
HoloLog(@"HoloLifecycle: '%@' perform selector '%@': %f milliseconds", NSStringFromClass(cls), NSStringFromSelector(sel), endTime * 1000.0); \
} \

static void holo_lifecycle_ffi_closure_func(ffi_cif *cif, void *ret, void **args, void *userdata) {
    HoloLifecycleHookInfo *info = (__bridge HoloLifecycleHookInfo *)userdata;
    
    // before
    for (HoloBaseLifecycle *lifecycle in [HoloLifecycleManager sharedInstance].beforeInstances) {
        
#if DEBUG
        HOLO_LIFECYCLE_START
#endif
        
        holo_lifecycle_call_sel(lifecycle, info.sel, cif, args);
        
#if DEBUG
        HOLO_LIFECYCLE_END_LOG(lifecycle.class, info.sel)
#endif
        
    }
    
    
#if DEBUG
    HOLO_LIFECYCLE_START
#endif
    
    // call original IMP
    ffi_call(cif, info->_originalIMP, ret, args);
    
#if DEBUG
    HOLO_LIFECYCLE_END_LOG(info.cls, info.sel)
#endif
    
    
    // after
    for (HoloBaseLifecycle *lifecycle in [HoloLifecycleManager sharedInstance].afterInstances) {
        
#if DEBUG
        HOLO_LIFECYCLE_START
#endif
        
        holo_lifecycle_call_sel(lifecycle, info.sel, cif, args);
        
#if DEBUG
        HOLO_LIFECYCLE_END_LOG(lifecycle.class, info.sel)
#endif
        
    }
}

static void holo_lifecycle_call_sel(HoloBaseLifecycle *lifecycle, SEL sel, ffi_cif *originalCif, void **originalArgs) {
    if (![lifecycle respondsToSelector:sel]) {
        return;
    }
    
    // 复用 cif，构造参数，重置 args[0]、args[1]
    NSMethodSignature *signature = [lifecycle methodSignatureForSelector:sel];
    NSUInteger argsCount = signature.numberOfArguments;
    void **args = calloc(argsCount, sizeof(void *));
    args[0] = &lifecycle;
    args[1] = &sel;
    memcpy(args + 2, originalArgs + 2, sizeof(*originalArgs)*(argsCount - 2));
    
    IMP func = [lifecycle methodForSelector:sel];
    ffi_call(originalCif, func, NULL, args);
}

NS_INLINE ffi_type *holo_lifecycle_ffi_type(const char *c) {
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
        case '{': {
            // http://www.chiark.greenend.org.uk/doc/libffi-dev/html/Type-Example.html
            ffi_type *type = malloc(sizeof(ffi_type));
            type->type = FFI_TYPE_STRUCT;
            NSUInteger size = 0;
            NSUInteger alignment = 0;
            NSGetSizeAndAlignment(c, &size, &alignment);
            type->alignment = alignment;
            type->size = size;
            while (c[0] != '=') ++c; ++c;
            
            NSPointerArray *pointArray = [NSPointerArray pointerArrayWithOptions:NSPointerFunctionsOpaqueMemory];
            while (c[0] != '}') {
                ffi_type *elementType = NULL;
                elementType = holo_lifecycle_ffi_type(c);
                if (elementType) {
                    [pointArray addPointer:elementType];
                    c = NSGetSizeAndAlignment(c, NULL, NULL);
                } else {
                    return NULL;
                }
            }
            NSInteger count = pointArray.count;
            ffi_type **types = malloc(sizeof(ffi_type *) * (count + 1));
            for (NSInteger i = 0; i < count; i++) {
                types[i] = [pointArray pointerAtIndex:i];
            }
            types[count] = NULL; // terminated element is NULL
            
            type->elements = types;
            return type;
        }
    }
    return NULL;
}


@end
