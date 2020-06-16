//
//  SKPhotoModel.h
//  SKPhotoPicker_Example
//
//  Created by shangkun on 2018/10/9.
//  Copyright © 2018年 Xcoder1011. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

typedef NS_ENUM(NSInteger, SKAssetMediaType) {
    SKAssetMediaTypeUnknown = 0,
    SKAssetMediaTypeImage,
    SKAssetMediaTypeVideo,
    SKAssetMediaTypeAudio,
    SKAssetMediaTypeGIF,
    SKAssetMediaTypeLivePhoto,
};

@interface SKPhotoModel : NSObject

@property (nonatomic, strong) PHAsset *asset;
@property (nonatomic, copy) NSString *duration;
@property (nonatomic, assign, getter=isSelected) BOOL selected;
// 默认为 0, 不显示； 显示 1，2，....9
@property (nonatomic, assign) NSUInteger selectIndex;
@property (nonatomic, strong) NSURL *url ;
@property (nonatomic, copy) NSString *fileName;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, copy) NSString *localIdentifier;
@property (nonatomic, copy) NSString *localPhotoPath;
@property (nonatomic, copy) NSString *localThumbPath;
@property (nonatomic, copy) NSString *localVideoPath;
@property (nonatomic, assign) SKAssetMediaType mediaType;
/// 图片浏览器框架 所用
@property (nonatomic, strong) UIView *containerView;

@end

@class SKPhotoModel;

@interface SKAlbumModel : NSObject

/// 相册名字
@property (nonatomic, copy) NSString *name;
/// 张数
@property (nonatomic, assign) NSUInteger count;
/// 封面图
@property (nonatomic, strong) UIImage *coverImage;
/// 已经选择的照片数量
@property (nonatomic, assign) NSInteger selectedCount;
/// 照片资源
@property (nonatomic, strong) NSArray <SKPhotoModel *> *items;
@property (nonatomic, strong) NSArray <SKPhotoModel *> *selectedItems;
@property (nonatomic, copy) NSString *localIdentifier;

@end
