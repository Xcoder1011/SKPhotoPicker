//
//  SCSCotoModel.h
//  SuperCoach
//
//  Created by shangkun on 2018/9/5.
//  Copyright © 2018年 Lin Feihong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>


typedef NS_ENUM(NSInteger, SCAssetMediaType) {
    SCAssetMediaTypeUnknown = 0,
    SCAssetMediaTypeImage   = 1,
    SCAssetMediaTypeVideo   = 2,
    SCAssetMediaTypeAudio   = 3,
    SCAssetMediaTypeGIF   = 4,
    SCAssetMediaTypeLivePhoto   = 5,
};

// 照片 model

@interface SCPhotoModel : NSObject

@property (nonatomic, strong) PHAsset *asset;

@property (nonatomic, copy) NSString *duration;

@property (nonatomic, assign, getter=isSelected) BOOL selected;
// 默认为 0, 不显示； 显示 1，2，....9
@property (nonatomic, assign) NSUInteger selectIndex;

@property (nonatomic, strong) NSURL *url ;

// @property (nonatomic, strong) UIImage *image;

@property (nonatomic, copy) NSString *localIdentifier;


@property (nonatomic, copy) NSString *localPhotoPath;
@property (nonatomic, copy) NSString *localThumbPath;

@property (nonatomic, copy) NSString *localVideoPath;

@property (nonatomic, copy) NSString *fileName;

@property (nonatomic, assign) SCAssetMediaType mediaType;

@end


// 相册 model

@class SCPhotoModel;
@interface SCAlbumModel : NSObject

// 相册名字
@property (nonatomic, copy) NSString *name;
// 张数
@property (nonatomic, assign) NSUInteger count;

// 封面图
@property (nonatomic, strong) UIImage *coverImage;
// 已经选择的照片数量
@property (nonatomic, assign) NSInteger selectedCount;
// 照片资源
@property (nonatomic, strong) NSArray <SCPhotoModel *> *items;

@property (nonatomic, strong) NSArray <SCPhotoModel *> *selectedItems;

@property (nonatomic, copy) NSString *localIdentifier;

@end
