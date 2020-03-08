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

static NSString * const kHoloLifecycleClass = @"_holo_lifecycle_class_";

@interface HoloLifecycleManager ()

@property (nonatomic, copy) NSArray *subClasses;

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
        NSArray *stringArray = [self _findAllSubClass:[HoloLifecycle class]];
        self.subClasses = [self _classArrayWithStringArray:stringArray];
        [[NSUserDefaults standardUserDefaults] setObject:stringArray forKey:kHoloLifecycleClass];
#else
        NSArray *stringArray = [[NSUserDefaults standardUserDefaults] objectForKey:kHoloLifecycleClass];
        self.subCalsses = [self _classArrayWithStringArray:stringArray];
#endif
    }
    return self;
}

- (NSArray *)_classArrayWithStringArray:(NSArray *)stringArray {
    NSMutableArray *classArray = [NSMutableArray new];
    [stringArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        Class cls = NSClassFromString(obj);
        if (cls) [classArray addObject:[cls new]];
    }];
    return [classArray copy];
}

- (NSArray *)_findAllSubClass:(Class)class {
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
    return array;
}

@end


@implementation UIApplication (HoloLifecycle)

+ (void)load {
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
        
        HoloLifecycleManager *lifecycleManager = [HoloLifecycleManager sharedInstance];
        for (HoloLifecycle *lifecycle in lifecycleManager.subClasses) {
            if ([lifecycle respondsToSelector:sel]) {
                NSMethodSignature *signature = [lifecycle methodSignatureForSelector:sel];
                NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
                invocation.target = lifecycle;
                invocation.selector = sel;
                
                NSUInteger numberOfArguments = signature.numberOfArguments;
                if (numberOfArguments > info.originalInvocation.methodSignature.numberOfArguments) {
                    NSLog(@"lifecycle has too many arguments. Not calling %@", info);
                    continue;
                }
                
                void *argBuf = NULL;
                for (NSUInteger idx = 2; idx < numberOfArguments; idx++) {
                    const char *type = [info.originalInvocation.methodSignature getArgumentTypeAtIndex:idx];
                    NSUInteger argSize;
                    NSGetSizeAndAlignment(type, &argSize, NULL);
                    
                    if (!(argBuf = reallocf(argBuf, argSize))) {
                        NSLog(@"Failed to allocate memory for lifecycle invocation.");
                        break;
                    }
                    
                    [info.originalInvocation getArgument:argBuf atIndex:idx];
                    [invocation setArgument:argBuf atIndex:idx];
                }
                
                [invocation invoke];
                
                if (argBuf != NULL) {
                    free(argBuf);
                }
            }
        }
    } error:nil];
}

@end
