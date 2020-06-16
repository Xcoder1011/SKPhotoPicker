//
//  SKPhotoManager.h
//  SKPhotoPicker_Example
//
//  Created by shangkun on 2018/10/9.
//  Copyright © 2018年 Xcoder1011. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

@class SKPhotoModel;
@class SKAlbumModel;

@interface SKPhotoManager : NSObject

+ (SKPhotoManager *)sharedInstance;

/* 对照片排序，按修改时间升序
 * default NO
 * 如果为NO，最新的照片会显示在最前面
 */
@property (nonatomic, assign) BOOL sortAscending;
@property (nonatomic, assign) CGFloat photoPreviewMaxWidth;

@property(nonatomic, assign) BOOL allowSelectImage;
@property(nonatomic, assign) BOOL allowSelectVideo;

@property (nonatomic, strong) SKAlbumModel *cameraRollAlbum;

// 获取 相册列表数据
- (void)fetchAlbumsListComplete:(void (^)(NSArray< SKAlbumModel *> *))complete;

// 获取 相册胶卷 数据
- (void)fetchcameraRollAlbumAssetComplete:(void (^)(NSArray< SKPhotoModel *> *))complete;


// 获取封面图片
- (PHImageRequestID)requestCoverImageForAsset:(PHAsset *)asset
                                   photoWidth:(CGFloat)photoWidth
                                   completion:(void (^)(UIImage *photo,NSDictionary *info,BOOL isDegraded))completion;

// 获取大图数据
- (PHImageRequestID)requestOriginalImageForAsset:(PHAsset *)asset
                                      completion:(void (^)(UIImage *photo,NSDictionary *info,BOOL isDegraded))completion ;

// 获取asset对应的图片
- (PHImageRequestID)requestImageForAsset:(PHAsset *)asset
                               imageSize:(CGSize)imageSize
                              completion:(void (^)(UIImage *photo,NSDictionary *info,BOOL isDegraded))completion
                         progressHandler:(void (^)(double progress, NSError *error, BOOL *stop, NSDictionary *info))progressHandler
                       needNetworkAccess:(BOOL)needNetworkAccess;

// 获取视频数据
- (void)requestPlayerItemForVideo:(PHAsset *)asset
                       completion:(void (^)(AVPlayerItem *playerItem, NSDictionary *info))completion;

// 获取asset对应的LivePhoto
- (PHImageRequestID)requestLivePhotoForAsset:(PHAsset *)asset
                                   imageSize:(CGSize)imageSize
                                  completion:(void (^)(PHLivePhoto *livePhoto))completion
                             progressHandler:(void (^)(double progress))progressHandler
                                      failed:(void(^)(void))failed
                           needNetworkAccess:(BOOL)needNetworkAccess;

// 获取asset对应的Gif
- (PHImageRequestID)requestGIFForAsset:(PHAsset *)asset
                            completion:(void (^)(NSData *imageData, UIImageOrientation orientation))completion
                       progressHandler:(void (^)(double progress))progressHandler
                                failed:(void(^)(void))failed
                     needNetworkAccess:(BOOL)needNetworkAccess;

// 导出视频 沙盒路径
- (void)getVideoOutputPathWithAsset:(PHAsset *)asset completion:(void (^)(NSString *outputPath))completion ;


// 请求相册权限
+ (PHAuthorizationStatus)photosAuthorized:(void(^)(PHAuthorizationStatus))handler;

@end


@interface UIImage (SKPhotoManager)

+ (UIImage *)imageFromSKBundleWithName:(NSString *)name;
+ (UIImage *)sk_animatedGIFWithData:(NSData *)data;
+ (UIImage *)sk_imageWithColor:(UIColor *)color size:(CGSize)size;
@end
