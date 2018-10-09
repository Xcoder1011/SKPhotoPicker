//
//  SCPhotoNavigationController.h
//  SuperCoach
//
//  Created by shangkun on 2018/9/6.
//  Copyright © 2018年 Lin Feihong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>
#import "SCPhotoModel.h"

@protocol SCPhotoNavigationControllerDelegate;

@interface SCPhotoNavigationController : UINavigationController
// default YES
@property(nonatomic, assign , readonly) BOOL allowSelectImage;
// default YES
@property(nonatomic, assign , readonly) BOOL allowSelectVideo;
// default NO
@property(nonatomic, assign) BOOL supportLivePhoto;
// default 9
@property(nonatomic, assign , readonly) NSInteger maxSelectPhotosCount;

@property(nonatomic, strong , readonly) NSArray<SCAlbumModel *> *albumsList;

@property(nonatomic, strong) NSMutableArray <SCPhotoModel *> *currentSeletedItems;

@property(nonatomic, strong) NSMutableArray <NSString *> *currentSeletedLocalIdentifier;

@property(nonatomic, weak) id <SCPhotoNavigationControllerDelegate> pickerDelegate;

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController navigationBarHidden:(BOOL)hidden;

- (instancetype)initWithDelegate:(id<SCPhotoNavigationControllerDelegate>)delegate pushPickerVC:(BOOL)pushPickerVC;

- (instancetype)initWithDelegate:(id<SCPhotoNavigationControllerDelegate>)delegate
                    pushPickerVC:(BOOL)pushPickerVC
                allowSelectImage:(BOOL)allowSelectImage
                allowSelectVideo:(BOOL)allowSelectVideo
            maxSelectPhotosCount:(NSInteger)maxSelectPhotosCount;

- (void)didSelectDoneEvent;
- (void)showMaxPhotosCountAlert;
@end


@protocol SCPhotoNavigationControllerDelegate <NSObject>

@optional
// 照片
- (void)imagePickerController:(SCPhotoNavigationController *)picker didFinishPickPhotosItems:(NSArray <SCPhotoModel *> *)currentSeletedItems;
// 视频 （只能选择一个视频）
- (void)imagePickerController:(SCPhotoNavigationController *)picker didFinishPickVideo:(SCPhotoModel *)videoItem sourceAssets:(PHAsset *)asset;

@end
