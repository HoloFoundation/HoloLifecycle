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
        NSArray *classArray = [self _findAllHoloBaseLifecycleSubClass];
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
    [(NSObject *)delegate aspect_hookSelector:sel withOptions:AspectPositionBefore usingBlock:^(id<AspectInfo> info) {
        [self _invokeWithLifecycles:[HoloLifecycleManager sharedInstance].beforeInstances sel:sel info:info];
    } error:nil];
    [(NSObject *)delegate aspect_hookSelector:sel withOptions:AspectPositionAfter usingBlock:^(id<AspectInfo> info) {
        [self _invokeWithLifecycles:[HoloLifecycleManager sharedInstance].afterInstances sel:sel info:info];
    } error:nil];
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

@end
