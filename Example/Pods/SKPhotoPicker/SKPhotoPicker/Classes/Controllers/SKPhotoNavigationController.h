//
//  SKPhotoNavigationController.h
//  SKPhotoPicker_Example
//
//  Created by shangkun on 2018/10/9.
//  Copyright © 2018年 Xcoder1011. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>
#import "SKPhotoModel.h"

typedef NS_ENUM(NSUInteger, SKChoosePhotoMode) {
    SKChoosePhotoModeNormal = 0,   // 默认模式
    SKChoosePhotoModePublishPost,  // 支持拍照
};

@protocol SKPhotoNavigationControllerDelegate;

@interface SKPhotoNavigationController : UINavigationController
// default YES
@property(nonatomic, assign , readonly) BOOL allowSelectImage;
// default YES
@property(nonatomic, assign , readonly) BOOL allowSelectVideo;
// default NO
@property(nonatomic, assign) BOOL supportLivePhoto;
// default 9
@property(nonatomic, assign , readonly) NSInteger maxSelectPhotosCount;
// 业务场景
@property(nonatomic, assign) SKChoosePhotoMode chooseMode;

@property(nonatomic, strong , readonly) NSArray<SKAlbumModel *> *albumsList;

@property(nonatomic, strong) NSMutableArray <SKPhotoModel *> *currentSeletedItems;

@property(nonatomic, strong) NSMutableArray <NSString *> *currentSeletedLocalIdentifier;

@property(nonatomic, weak) id <SKPhotoNavigationControllerDelegate> pickerDelegate;

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController navigationBarHidden:(BOOL)hidden;

- (instancetype)initWithDelegate:(id<SKPhotoNavigationControllerDelegate>)delegate pushPickerVC:(BOOL)pushPickerVC;

- (instancetype)initWithDelegate:(id<SKPhotoNavigationControllerDelegate>)delegate
                    pushPickerVC:(BOOL)pushPickerVC
                allowSelectImage:(BOOL)allowSelectImage
                allowSelectVideo:(BOOL)allowSelectVideo
            maxSelectPhotosCount:(NSInteger)maxSelectPhotosCount;

- (void)didSelectDoneEvent;
- (void)showMaxPhotosCountAlert;
@end


@protocol SKPhotoNavigationControllerDelegate <NSObject>

@optional
// 照片
- (void)imagePickerController:(SKPhotoNavigationController *)picker didFinishPickPhotosItems:(NSArray <SKPhotoModel *> *)currentSeletedItems;
// 视频 （只能选择一个视频）
- (void)imagePickerController:(SKPhotoNavigationController *)picker didFinishPickVideo:(SKPhotoModel *)videoItem sourceAssets:(PHAsset *)asset;
// 去拍照
- (void)imagePickerController:(SKPhotoNavigationController *)picker takeCameraWithItems:(NSArray <SKPhotoModel *> *)currentSeletedItems;
// 即将消失
- (void)imagePickerController:(SKPhotoNavigationController *)picker willDismissViewControllerWithItems:(NSArray <SKPhotoModel *> *)currentSeletedItems;
// 完全消失
- (void)imagePickerController:(SKPhotoNavigationController *)picker didDismissViewControllerWithItems:(NSArray <SKPhotoModel *> *)currentSeletedItems fromCancel:(BOOL)cancel;

@end
