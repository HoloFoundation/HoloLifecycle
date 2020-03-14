//
//  HoloLifecycleManager.m
//  HoloLifecycle
//
//  Created by 与佳期 on 2020/3/8.
//

#import "HoloLifecycleManager.h"
#import <objc/runtime.h>
#import <JRSwizzle/JRSwizzle.h>
#import <Aspects/Aspects.h>
#import "HoloLifecycle.h"

#ifdef DEBUG
#define HoloLog(...) NSLog(__VA_ARGS__)
#else
#define HoloLog(...)
#endif

static NSString * const kHoloLifecycleClass = @"_holo_lifecycle_class_";

@interface HoloLifecycleManager ()

@property (nonatomic, copy) NSArray<HoloLifecycle *> *beforeInstances;

@property (nonatomic, copy) NSArray<HoloLifecycle *> *afterInstances;

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
        NSArray *classArray = [self _findAllSubClass:[HoloLifecycle class]];
        [[NSUserDefaults standardUserDefaults] setObject:classArray forKey:kHoloLifecycleClass];
#else
        NSArray *classArray = [[NSUserDefaults standardUserDefaults] objectForKey:kHoloLifecycleClass];
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
        if (cls && [cls priority] >= 300) {
            [beforeArray addObject:[cls new]];
        } else if (cls) {
            [afterArray addObject:[cls new]];
        }
    }];
    self.beforeInstances = [beforeArray copy];
    self.afterInstances = [afterArray copy];
}

- (NSArray<NSString *> *)_findAllSubClass:(Class)class {
    // 注册类的总数
    int count = objc_getClassList(NULL, 0);
    NSMutableArray *array = [NSMutableArray new];
    // 获取所有已注册的类
    Class *classes = (Class *)malloc(sizeof(Class) * count);
    objc_getClassList(classes, count);
    
    for (int i = 0; i < count; i++) {
        if (class == class_getSuperclass(classes[i])) {
            [array addObject:[NSString stringWithFormat:@"%@", classes[i]]];
        }
    }
    free(classes);
    
    return [array sortedArrayUsingComparator:^NSComparisonResult(NSString * _Nonnull obj1, NSString * _Nonnull obj2) {
        return [NSClassFromString(obj1) priority] < [NSClassFromString(obj2) priority];
    }];
}

// 打印所有 HoloLifecycle 子类执行方法及耗时
- (void)logSelectorsAndPerformTime {
    self.hasLog = YES;
}

@end


@implementation UIApplication (HoloLifecycle)

+ (void)load {
    [HoloLifecycleManager sharedInstance].hasLog = YES;
    [self jr_swizzleMethod:@selector(setDelegate:) withMethod:@selector(_lb_setDelegate:) error:nil];
}

- (void)_lb_setDelegate:(id <UIApplicationDelegate>)delegate {
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
    
    [self _lb_setDelegate:delegate];
}

- (void)_aspect_hookSelectorWithDelegate:(id <UIApplicationDelegate>)delegate sel:(SEL)sel {
    [(NSObject *)delegate aspect_hookSelector:sel withOptions:AspectPositionBefore usingBlock:^(id<AspectInfo> info) {
        [self _invokeWithLifecycles:[HoloLifecycleManager sharedInstance].beforeInstances sel:sel info:info];
    } error:nil];
    [(NSObject *)delegate aspect_hookSelector:sel withOptions:AspectPositionAfter usingBlock:^(id<AspectInfo> info) {
        [self _invokeWithLifecycles:[HoloLifecycleManager sharedInstance].afterInstances sel:sel info:info];
    } error:nil];
}

- (void)_invokeWithLifecycles:(NSArray<HoloLifecycle *> *)lifecycles sel:(SEL)sel info:(id<AspectInfo>)info {
    for (HoloLifecycle *lifecycle in lifecycles) {
        if ([lifecycle respondsToSelector:sel]) {
#ifdef DEBUG
            NSTimeInterval startTime = 0.0;
            if ([HoloLifecycleManager sharedInstance].hasLog) {
                startTime = [[NSDate date] timeIntervalSince1970]*1000;
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
                NSTimeInterval endTime = [[NSDate date] timeIntervalSince1970]*1000;
                NSTimeInterval time = endTime - startTime;
                HoloLog(@"lifecycle: %@, selector: %@, performTime: %f milliseconds", NSStringFromClass([lifecycle class]), NSStringFromSelector(sel), time);
            }
#endif
        }
    }
}

@end
