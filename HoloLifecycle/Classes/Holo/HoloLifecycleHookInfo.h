//
//  HoloLifecycleHookInfo.h
//  HoloLifecycle
//
//  Created by 与佳期 on 2020/8/30.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HoloLifecycleHookInfo : NSObject {
    @public
    
    void *_originalIMP;
}

@property (nonatomic, strong) Class cls;
@property (nonatomic, assign) SEL sel;

@end

NS_ASSUME_NONNULL_END
