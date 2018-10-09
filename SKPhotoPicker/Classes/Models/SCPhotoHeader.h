//
//  SCPhotoHeader.h
//  SuperCoach
//
//  Created by shangkun on 2018/9/7.
//  Copyright © 2018年 Lin Feihong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <sys/time.h>
#import <pthread.h>

#import "SCPhotoManager.h"
#import "SCPhotoNavigationController.h"
#import "SCPhotoPickerViewController.h"
#import "SCPhotoPreviewController.h"
#import "SCPhotoAlbumListController.h"
#import "SCPhotoModel.h"

#ifndef SCPhotoHeader_h
#define SCPhotoHeader_h

#define kScreenWidth  [UIScreen mainScreen].bounds.size.width
#define kScreenHeight  [UIScreen mainScreen].bounds.size.height

#define kBarTintColor  [UIColor colorWithRed:(34/255.0) green:(34/255.0)  blue:(34/255.0) alpha:0.8]
#define kGreenColor  [UIColor colorWithRed:82/255.0 green:170/255.0 blue:56/255.0 alpha:1]

#define kBottomBarColor  [UIColor colorWithRed:41/255.0 green:46/255.0 blue:52/255.0 alpha:1]

#define SINGLE_LINE_WIDTH           (1 / [UIScreen mainScreen].scale)
#define SINGLE_LINE_ADJUST_OFFSET   ((1 / [UIScreen mainScreen].scale) / 2)

#define kPreviewPadding  20

#define kSCWeakObj(obj)   __weak typeof(obj) weak##obj = obj;
#define kSCStrongObj(obj)    __strong typeof(obj) obj = weak##obj;

typedef NS_ENUM(NSInteger, SCPhotoAuthorizationStatus) {
    
    SCPhotoAuthorizationStatusNotDetermined = 0, // 用户从未进行过授权等处理，首次访问相应内容会提示用户进行授权
    SCPhotoAuthorizationStatusRestricted    = 1, // 应用没有相关权限，且当前用户无法改变这个权限，比如:家长控制
    SCPhotoAuthorizationStatusDenied        = 2, // 拒绝
    SCPhotoAuthorizationStatusAuthorized    = 3, // 已授权
    SCPhotoAuthorizationStatusNotSupport    = 4, // 硬件等不支持
    
} PHOTOS_AVAILABLE_IOS_TVOS(8_0, 10_0);


static inline bool dispatch_is_main_queue() {
    return pthread_main_np() != 0;
}

static inline void dispatch_async_on_main_queue(void(^block)()) {
    if (pthread_main_np()) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

static inline void dispatch_sync_on_main_queue(void(^block)()) {
    if (pthread_main_np()) {
        block();
    } else {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}


static inline void dispatch_async_on_global_queue(void(^block)()) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block);
}

static inline void dispatch_async_on_globalqueue_then_on_mainqueue(void(^globalblock)(),void(^mainblock)()){
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        globalblock();
        dispatch_async_on_main_queue(mainblock);
    });
    
}

#endif /* SCPhotoHeader_h */
