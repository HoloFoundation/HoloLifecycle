//
//  HoloLifecycleMacro.h
//  HoloLifecycle
//
//  Created by Honglou Gong on 2020/7/9.
//

#ifndef HoloLifecycleMacro_h
#define HoloLifecycleMacro_h

#ifdef DEBUG
#define HoloLog(...) NSLog(__VA_ARGS__)
#else
#define HoloLog(...)
#endif

#ifndef HOLO_LOCK
#define HOLO_LOCK(lock) dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
#endif

#ifndef HOLO_UNLOCK
#define HOLO_UNLOCK(lock) dispatch_semaphore_signal(lock);
#endif

#endif /* HoloLifecycleMacro_h */
