//
//  SKPhotoHeader.h
//  SKPhotoPicker_Example
//
//  Created by shangkun on 2018/10/9.
//  Copyright © 2018年 Xcoder1011. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <sys/time.h>
#import <pthread.h>

#import "SKPhotoManager.h"
#import "SKPhotoNavigationController.h"
#import "SKPhotoPickerViewController.h"
#import "SKPhotoPreviewController.h"
#import "SKPhotoAlbumListController.h"
#import "SKPhotoModel.h"
// #import "UIDevice+SKPhotoPicker.h"

#ifndef SKPhotoHeader_h
#define SKPhotoHeader_h

#define kScreenWidth  [UIScreen mainScreen].bounds.size.width
#define kScreenHeight  [UIScreen mainScreen].bounds.size.height

#define kBarTintColor  [UIColor colorWithRed:(34/255.0) green:(34/255.0)  blue:(34/255.0) alpha:0.8]
#define kGreenColor  [UIColor colorWithRed:82/255.0 green:170/255.0 blue:56/255.0 alpha:1]

#define kBottomBarColor  [UIColor colorWithRed:41/255.0 green:46/255.0 blue:52/255.0 alpha:1]

#define SINGLE_LINE_WIDTH           (1 / [UIScreen mainScreen].scale)
#define SINGLE_LINE_ADJUST_OFFSET   ((1 / [UIScreen mainScreen].scale) / 2)

#define kPreviewPadding  20

#define kSKWeakObj(obj)   __weak typeof(obj) weak##obj = obj;
#define kSKStrongObj(obj)    __strong typeof(obj) obj = weak##obj;

typedef NS_ENUM(NSInteger, SKPhotoAuthorizationStatus) {
    
    SKPhotoAuthorizationStatusNotDetermined = 0, // 用户从未进行过授权等处理，首次访问相应内容会提示用户进行授权
    SKPhotoAuthorizationStatusRestricted    = 1, // 应用没有相关权限，且当前用户无法改变这个权限，比如:家长控制
    SKPhotoAuthorizationStatusDenied        = 2, // 拒绝
    SKPhotoAuthorizationStatusAuthorized    = 3, // 已授权
    SKPhotoAuthorizationStatusNotSupport    = 4, // 硬件等不支持
    
};


static inline bool dispatch_is_main_queue() {
    return pthread_main_np() != 0;
}

static inline void dispatch_async_on_main_queue(void(^block)(void)) {
    if (pthread_main_np()) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

static inline void dispatch_sync_on_main_queue(void(^block)(void)) {
    if (pthread_main_np()) {
        block();
    } else {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}


static inline void dispatch_async_on_global_queue(void(^block)(void)) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block);
}

static inline void dispatch_async_on_globalqueue_then_on_mainqueue(void(^globalblock)(void),void(^mainblock)(void)){
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        globalblock();
        dispatch_async_on_main_queue(mainblock);
    });
    
}

static inline BOOL isIPhoneXDevice() {
    
#ifdef __IPHONE_11_0
    if (@available(iOS 11.0, *)) {
        NSString *modelName = [UIDevice currentDevice].name;
        if ([modelName hasPrefix:@"iPhone X"]) {
            return YES;
        } else {
            return [UIApplication sharedApplication].keyWindow.safeAreaInsets.bottom > 0.f;
        }
    } else {
        return NO;
    }
#else
    return NO;
#endif
    
}

#endif /* SKPhotoHeader_h */
