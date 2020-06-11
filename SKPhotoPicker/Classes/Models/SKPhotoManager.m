//
//  SKPhotoManager.m
//  SKPhotoPicker_Example
//
//  Created by shangkun on 2018/10/9.
//  Copyright © 2018年 Xcoder1011. All rights reserved.
//

#import "SKPhotoManager.h"
#import "SKPhotoModel.h"
#import "SKPhotoHeader.h"
#import <ImageIO/ImageIO.h>

@implementation SKPhotoManager

+ (SKPhotoManager *)sharedInstance {
    
    static SKPhotoManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[SKPhotoManager alloc] init];
        manager.sortAscending = NO;
        manager.photoPreviewMaxWidth = 600;
        manager.allowSelectVideo = YES;
        manager.allowSelectImage = YES;
    });
    return manager;
}


- (PHImageRequestID)requestOriginalImageForAsset:(PHAsset *)asset
                                      completion:(void (^)(UIImage *photo,NSDictionary *info,BOOL isDegraded))completion {
    
    CGSize imageSize;
    PHAsset *phAsset = (PHAsset *)asset;
    CGFloat kSKreenSKale = 1.7;
    CGFloat aspectRatio = phAsset.pixelWidth / (CGFloat)phAsset.pixelHeight;
    CGFloat pixelWidth = kScreenWidth * kSKreenSKale;
    CGFloat pixelHeight = pixelWidth / aspectRatio;
    imageSize = CGSizeMake(pixelWidth, pixelHeight);
    
    return [self requestImageForAsset:asset imageSize:imageSize completion:completion progressHandler:nil needNetworkAccess:YES];
}

- (PHImageRequestID)requestCoverImageForAsset:(PHAsset *)asset
                                   photoWidth:(CGFloat)photoWidth
                                   completion:(void (^)(UIImage *photo,NSDictionary *info,BOOL isDegraded))completion {
    
    CGSize imageSize;
    if (photoWidth < kScreenWidth && photoWidth < _photoPreviewMaxWidth) {
        imageSize = CGSizeMake(photoWidth, photoWidth);
    } else {
        PHAsset *phAsset = (PHAsset *)asset;
        CGFloat kSKreenSKale = 1.7;
        CGFloat aspectRatio = phAsset.pixelWidth / (CGFloat)phAsset.pixelHeight;
        CGFloat pixelWidth = photoWidth * kSKreenSKale;
        CGFloat pixelHeight = pixelWidth / aspectRatio;
        imageSize = CGSizeMake(pixelWidth, pixelHeight);
    }
    
    return [self requestImageForAsset:asset imageSize:imageSize completion:completion progressHandler:nil needNetworkAccess:YES];
}


- (PHImageRequestID)requestImageForAsset:(PHAsset *)asset imageSize:(CGSize)imageSize completion:(void (^)(UIImage *photo,NSDictionary *info,BOOL isDegraded))completion progressHandler:(void (^)(double progress, NSError *error, BOOL *stop, NSDictionary *info))progressHandler needNetworkAccess:(BOOL)needNetworkAccess {
    if ([asset isKindOfClass:[PHAsset class]]) {
        
        PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
        option.resizeMode = PHImageRequestOptionsResizeModeFast;
        option.networkAccessAllowed = NO;
        option.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;//控制照片质量
        
        PHImageRequestID imageRequestID = [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:imageSize contentMode:PHImageContentModeAspectFill options:option resultHandler:^(UIImage *
                                                                                                                                                                                                   _Nullable result, NSDictionary * _Nullable info) {
            BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey]);
            if (downloadFinined && result) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    // 可能需要修正 图片方向
                    // PHImageResultIsDegradedKey : 当前递送的 UIImage 是否是最终结果的低质量格式。当高质量图像正在下载时，这个可以让你给用户先展示一个预览图像 。
                    if (completion) completion(result,info,[[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
                });
                return ;
            }
            
            // 从iCloud下载图片
            if ([info objectForKey:PHImageResultIsInCloudKey] && !result && needNetworkAccess && ![[info objectForKey:PHImageCancelledKey] boolValue]) {
                PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
                options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
                options.resizeMode = PHImageRequestOptionsResizeModeFast;
                options.networkAccessAllowed = YES;
                options.progressHandler = ^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (progressHandler) {
                            progressHandler(progress, error, stop, info);
                        }
                    });
                };
                PHImageRequestID cloudRequestId = 0;
                cloudRequestId = [[PHImageManager defaultManager] requestImageDataForAsset:asset options:options resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
                    
                    //BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey] && ![[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
                    UIImage *resultImage = [UIImage imageWithData:imageData scale:0.1];
                    resultImage = [self SKaleImage:resultImage toSize:imageSize];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (resultImage) {
                            if (completion) completion(resultImage,info,[[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
                        }
                    });
                }];
            }
        }];
        return imageRequestID;
    }
    return 0;
}

// 获取asset对应的LivePhoto
- (PHImageRequestID)requestLivePhotoForAsset:(PHAsset *)asset
                                   imageSize:(CGSize)imageSize
                                  completion:(void (^)(PHLivePhoto *livePhoto))completion
                             progressHandler:(void (^)(double progress))progressHandler
                                      failed:(void(^)(void))failed
                           needNetworkAccess:(BOOL)needNetworkAccess {
    
    if ([asset isKindOfClass:[PHAsset class]]) {
        
        PHLivePhotoRequestOptions *option = [[PHLivePhotoRequestOptions alloc] init];
        option.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        option.networkAccessAllowed = NO;
        
        PHImageRequestID imageRequestID = [[PHImageManager defaultManager] requestLivePhotoForAsset:asset targetSize:imageSize contentMode:PHImageContentModeAspectFill options:option resultHandler:^(PHLivePhoto * _Nullable livePhoto, NSDictionary * _Nullable info) {
            
            BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey] && ![[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
            if (downloadFinined && livePhoto) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (completion) completion(livePhoto);
                });
                return ;
            }
            
            // 从iCloud下载图片
            if ([info objectForKey:PHImageResultIsInCloudKey] && needNetworkAccess && ![[info objectForKey:PHImageCancelledKey] boolValue]) {
                PHLivePhotoRequestOptions *options = [[PHLivePhotoRequestOptions alloc] init];
                options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
                options.networkAccessAllowed = YES;
                options.progressHandler = ^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (progressHandler) {
                            progressHandler(progress);
                        }
                    });
                };
                
                PHImageRequestID cloudRequestId = 0;
                cloudRequestId = [[PHImageManager defaultManager] requestLivePhotoForAsset:asset targetSize:imageSize contentMode:PHImageContentModeAspectFill options:options resultHandler:^(PHLivePhoto * _Nullable livePhoto, NSDictionary * _Nullable info) {
                    
                    BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey] && ![[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
                    if (downloadFinined && livePhoto) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (completion) {
                                completion(livePhoto);
                            }
                        });
                    }else {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (failed) {
                                failed();
                            }
                        });
                    }
                }];
            }
        }];
        
        return imageRequestID;
    }
    return 0;
}


// 获取asset对应的Gif
- (PHImageRequestID)requestGIFForAsset:(PHAsset *)asset
                            completion:(void (^)(NSData *imageData, UIImageOrientation orientation))completion
                       progressHandler:(void (^)(double progress))progressHandler
                                failed:(void(^)(void))failed
                     needNetworkAccess:(BOOL)needNetworkAccess {
    
    if ([asset isKindOfClass:[PHAsset class]]) {
        
        PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
        option.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        option.networkAccessAllowed = NO;
        option.resizeMode = PHImageRequestOptionsResizeModeFast;
        option.synchronous = NO;
        option.version = PHImageRequestOptionsVersionOriginal;
        
        PHImageRequestID imageRequestID = [[PHImageManager defaultManager] requestImageDataForAsset:asset options:option resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
            
            BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey] && ![[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
            if (downloadFinined && imageData) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (completion) completion(imageData, orientation);
                });
                return ;
            }
            
            if ([info objectForKey:PHImageResultIsInCloudKey] && needNetworkAccess && ![[info objectForKey:PHImageCancelledKey] boolValue]) {
                PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
                options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
                options.networkAccessAllowed = YES;
                options.progressHandler = ^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (progressHandler) {
                            progressHandler(progress);
                        }
                    });
                };
                
                PHImageRequestID cloudRequestId = 0;
                cloudRequestId = [[PHImageManager defaultManager] requestImageDataForAsset:asset options:options resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
                    
                    BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey] && ![[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
                    if (downloadFinined && imageData) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (completion) {
                                if (completion) completion(imageData, orientation);
                            }
                        });
                    }else {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (failed) {
                                failed();
                            }
                        });
                    }
                }];
            }
        }];
        
        return imageRequestID;
    }
    return 0;
    
}

// 获取视频数据
- (void)requestPlayerItemForVideo:(PHAsset *)asset
                       completion:(void (^)(AVPlayerItem *playerItem, NSDictionary *info))completion {
    PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
    option.resizeMode = PHImageRequestOptionsResizeModeFast;
    
    [[PHImageManager defaultManager] requestPlayerItemForVideo:asset options:nil resultHandler:^(AVPlayerItem * _Nullable playerItem, NSDictionary * _Nullable info) {
        if (completion)  completion(playerItem, info);
    }];
}

// 导出视频 沙盒路径
- (void)getVideoOutputPathWithAsset:(PHAsset *)asset completion:(void (^)(NSString *outputPath))completion  {
    
    if (NO) {  // @available(iOS 9.0 , *)
        
        NSArray *assetResources = [PHAssetResource assetResourcesForAsset:asset];
        PHAssetResource *resource;
        for (PHAssetResource *assetRes in assetResources) {
            if (assetRes.type == PHAssetResourceTypePairedVideo ||
                assetRes.type == PHAssetResourceTypeVideo) {
                resource = assetRes;
            }
        }
        
        NSString * fileName = @"";
        if (resource.originalFilename) {
            fileName = resource.originalFilename;
        }
        
        if (asset.mediaType == PHAssetMediaTypeVideo || asset.mediaSubtypes == PHAssetMediaSubtypePhotoLive)
        {
            PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
            options.version = PHImageRequestOptionsVersionCurrent;
            options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
            
            NSDateFormatter *formater = [[NSDateFormatter alloc] init];
            [formater setDateFormat:@"yyyy-MM-dd-HH:mm:ss"];
            __block NSString *outputPath = [NSTemporaryDirectory() stringByAppendingFormat:@"output-%@.mp4", [formater stringFromDate:[NSDate date]]];
            NSLog(@"video outputPath = %@",outputPath);
            
            [[PHAssetResourceManager defaultManager] writeDataForAssetResource:resource toFile:[NSURL fileURLWithPath:outputPath] options:nil completionHandler:^(NSError * _Nullable error) {
                
                if (error) {
                    NSLog(@"error = %@",error);
                } else {
                    if (completion) {
                        completion(outputPath);
                    }
                }
            }];
        }
        
    } else { // iOS 9.0以下方法
        
        PHVideoRequestOptions* options = [[PHVideoRequestOptions alloc] init];
        options.version = PHVideoRequestOptionsVersionOriginal;
        options.deliveryMode = PHVideoRequestOptionsDeliveryModeAutomatic;
        options.networkAccessAllowed = YES;
        [[PHImageManager defaultManager] requestAVAssetForVideo:asset options:options resultHandler:^(AVAsset* avasset, AVAudioMix* audioMix, NSDictionary* info){
            NSLog(@"Info:\n%@",info);
            AVURLAsset *videoAsset = (AVURLAsset*)avasset;
            NSLog(@"AVAsset URL: %@",videoAsset.URL);
            [self startExportVideoWithVideoAsset:videoAsset completion:completion];
        }];
    }
    
}

- (void)startExportVideoWithVideoAsset:(AVURLAsset *)videoAsset completion:(void (^)(NSString *outputPath))completion {
    
    NSArray *presets = [AVAssetExportSession exportPresetsCompatibleWithAsset:videoAsset];
    
    if ([presets containsObject:AVAssetExportPreset640x480]) {
        AVAssetExportSession *session = [[AVAssetExportSession alloc]initWithAsset:videoAsset presetName:AVAssetExportPreset640x480];
        
        NSDateFormatter *formater = [[NSDateFormatter alloc] init];
        [formater setDateFormat:@"yyyy-MM-dd-HH:mm:ss"];
        __block NSString *outputPath = [NSTemporaryDirectory() stringByAppendingFormat:@"output-%@.mp4", [formater stringFromDate:[NSDate date]]];
        //__block NSString *outputPath = [NSHomeDirectory() stringByAppendingFormat:@"/Documents/output-%@.mp4", [formater stringFromDate:[NSDate date]]];
        
        NSLog(@"video outputPath = %@",outputPath);
        session.outputURL = [NSURL fileURLWithPath:outputPath];
        
        session.shouldOptimizeForNetworkUse = true;
        
        NSArray *supportedTypeArray = session.supportedFileTypes;
        if ([supportedTypeArray containsObject:AVFileTypeMPEG4]) {
            session.outputFileType = AVFileTypeMPEG4;
        } else if (supportedTypeArray.count == 0) {
            NSLog(@"No supported file types 视频类型暂不支持导出");
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion(outputPath);
                }
            });
            return;
        } else {
            session.outputFileType = [supportedTypeArray objectAtIndex:0];
        }
        
        AVMutableVideoComposition *videoComposition = [self fixedCompositionWithAsset:videoAsset];
        if (videoComposition.renderSize.width) {
            // 修正视频转向
            session.videoComposition = videoComposition;
        }
        
        [session exportAsynchronouslyWithCompletionHandler:^(void) {
            switch (session.status) {
                case AVAssetExportSessionStatusUnknown:
                    NSLog(@"AVAssetExportSessionStatusUnknown"); break;
                case AVAssetExportSessionStatusWaiting:
                    NSLog(@"AVAssetExportSessionStatusWaiting"); break;
                case AVAssetExportSessionStatusExporting:
                    NSLog(@"AVAssetExportSessionStatusExporting"); break;
                case AVAssetExportSessionStatusCompleted: {
                    NSLog(@"AVAssetExportSessionStatusCompleted");
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (completion) {
                            completion(outputPath);
                        }
                    });
                }  break;
                case AVAssetExportSessionStatusFailed:
                    NSLog(@"AVAssetExportSessionStatusFailed"); break;
                default: break;
            }
        }];
    }
}

/// 获取优化后的视频转向信息
- (AVMutableVideoComposition *)fixedCompositionWithAsset:(AVAsset *)videoAsset {
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
    // 视频转向
    int degrees = [self degressFromVideoFileWithAsset:videoAsset];
    if (degrees != 0) {
        CGAffineTransform translateToCenter;
        CGAffineTransform mixedTransform;
        videoComposition.frameDuration = CMTimeMake(1, 30);
        
        NSArray *tracks = [videoAsset tracksWithMediaType:AVMediaTypeVideo];
        AVAssetTrack *videoTrack = [tracks objectAtIndex:0];
        
        if (degrees == 90) {
            // 顺时针旋转90°
            translateToCenter = CGAffineTransformMakeTranslation(videoTrack.naturalSize.height, 0.0);
            mixedTransform = CGAffineTransformRotate(translateToCenter,M_PI_2);
            videoComposition.renderSize = CGSizeMake(videoTrack.naturalSize.height,videoTrack.naturalSize.width);
        } else if(degrees == 180){
            // 顺时针旋转180°
            translateToCenter = CGAffineTransformMakeTranslation(videoTrack.naturalSize.width, videoTrack.naturalSize.height);
            mixedTransform = CGAffineTransformRotate(translateToCenter,M_PI);
            videoComposition.renderSize = CGSizeMake(videoTrack.naturalSize.width,videoTrack.naturalSize.height);
            
        } else {
            // 顺时针旋转270°
            translateToCenter = CGAffineTransformMakeTranslation(0.0, videoTrack.naturalSize.width);
            mixedTransform = CGAffineTransformRotate(translateToCenter,M_PI_2*3.0);
            videoComposition.renderSize = CGSizeMake(videoTrack.naturalSize.height,videoTrack.naturalSize.width);
        }
        
        AVMutableVideoCompositionInstruction *roateInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        roateInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, [videoAsset duration]);
        AVMutableVideoCompositionLayerInstruction *roateLayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
        
        [roateLayerInstruction setTransform:mixedTransform atTime:kCMTimeZero];
        
        roateInstruction.layerInstructions = @[roateLayerInstruction];
        // 加入视频方向信息
        videoComposition.instructions = @[roateInstruction];
    }
    return videoComposition;
}

/// 获取视频角度
- (int)degressFromVideoFileWithAsset:(AVAsset *)asset {
    int degress = 0;
    NSArray *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    if([tracks count] > 0) {
        AVAssetTrack *videoTrack = [tracks objectAtIndex:0];
        CGAffineTransform t = videoTrack.preferredTransform;
        if(t.a == 0 && t.b == 1.0 && t.c == -1.0 && t.d == 0){
            // Portrait
            degress = 90;
        } else if(t.a == 0 && t.b == -1.0 && t.c == 1.0 && t.d == 0){
            // PortraitUpsideDown
            degress = 270;
        } else if(t.a == 1.0 && t.b == 0 && t.c == 0 && t.d == 1.0){
            // LandSKapeRight
            degress = 0;
        } else if(t.a == -1.0 && t.b == 0 && t.c == 0 && t.d == -1.0){
            // LandSKapeLeft
            degress = 180;
        }
    }
    return degress;
}

-(SKAlbumModel *)albumModelWith:(PHAssetCollection *)collection assetResult:(PHFetchResult<PHAsset *> *) assetResult{
    
    SKAlbumModel * model = [[SKAlbumModel alloc] init];
    model.name = collection.localizedTitle;
    model.localIdentifier = collection.localIdentifier;
    NSLog(@"SKAlbumModel localIdentifier = %@",collection.localIdentifier);
    if ([assetResult isKindOfClass:[PHFetchResult class]]) {
        model.count = assetResult.count;
        NSLog(@"localizedTitle = %@ , %tu张",collection.localizedTitle, assetResult.count);
    }
    NSMutableArray<SKPhotoModel *> *items = [NSMutableArray array];
    [assetResult enumerateObjectsUsingBlock:^(PHAsset * _Nonnull asset, NSUInteger idx, BOOL * _Nonnull stop) {
        
        SKPhotoModel *model = [[SKPhotoModel alloc] init];
        model.asset = asset;
        model.duration = [self getVideoDuration:asset];
        model.localIdentifier = asset.localIdentifier;
        // NSLog(@"localIdentifier = %@",obj.localIdentifier); // localIdentifier = B4792D6B-9D40-4028-A11C-A78A5AC05C8D/L0/001
        [items addObject:model];
    }];
    model.items = [items copy];
    return model;
    
}

// 获取 相册列表数据
- (void)fetchAlbumsListComplete:(void (^)(NSArray< SKAlbumModel *> *))complete {
    
    PHFetchOptions *option = [[PHFetchOptions alloc] init];
    
    if (!self.allowSelectVideo) option.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeImage];
    if (!self.allowSelectImage) option.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld",PHAssetMediaTypeVideo];
    
    if (!self.sortAscending) option.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:self.sortAscending]];
    
    PHFetchResult <PHAssetCollection *> *myPhotoStreamAlbum = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumMyPhotoStream options:nil]; // 我的照片流
    PHFetchResult <PHAssetCollection *> *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    PHFetchResult <PHCollection *> *userCustomAlbums = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];
    //    PHFetchResult <PHAssetCollection *> *userCustomAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil]; // 用户自己创建的相册 “测试相册3”
    PHFetchResult <PHAssetCollection *> *syncedAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumSyncedAlbum options:nil];
    PHFetchResult <PHAssetCollection *> *sharedAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumCloudShared options:nil];
    NSArray *allAlbums = @[myPhotoStreamAlbum,smartAlbums,userCustomAlbums,syncedAlbums,sharedAlbums];
    
    NSMutableArray<SKAlbumModel *> *allAlbumsArray = [NSMutableArray array];
    
    for (PHFetchResult *result in allAlbums) {
        for (PHAssetCollection *collection in result) {
            // 过滤PHCollectionList对象, 实际应该不会出现
            if (![collection isKindOfClass:PHAssetCollection.class]) continue;
            // 过滤最近删除和已隐藏
            if (collection.assetCollectionSubtype > 215 ||
                collection.assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumAllHidden) continue;
            if ([collection.localizedTitle containsString:@"Deleted"] || [collection.localizedTitle isEqualToString:@"最近删除"]) continue;
            // 获取相册内asset result
            PHFetchResult<PHAsset *> *assetResult = [PHAsset fetchAssetsInAssetCollection:collection options:option];
            if (assetResult.count < 1) continue;
            if ([self iSKameraRollAlbum:collection.localizedTitle]) {
                SKAlbumModel *cameraRollAlbum = [self albumModelWith:collection assetResult:assetResult] ;
                _cameraRollAlbum = cameraRollAlbum;
                [allAlbumsArray insertObject:cameraRollAlbum atIndex:0];
            } else {
                [allAlbumsArray addObject:[self albumModelWith:collection assetResult:assetResult]];
            }
        }
    }
    
    if (complete) {
        complete(allAlbumsArray);
    }
}

// 判断是否是相机胶卷数据
- (BOOL)iSKameraRollAlbum:(NSString *)albumName {
    NSString *versionStr = [[UIDevice currentDevice].systemVersion stringByReplacingOccurrencesOfString:@"." withString:@""];
    if (versionStr.length <= 1) {
        versionStr = [versionStr stringByAppendingString:@"00"];
    } else if (versionStr.length <= 2) {
        versionStr = [versionStr stringByAppendingString:@"0"];
    }
    CGFloat version = versionStr.floatValue;
    if (version >= 800 && version <= 802) {
        return [albumName isEqualToString:@"最近添加"] || [albumName isEqualToString:@"Recently Added"];
    } else {
        return [albumName isEqualToString:@"Camera Roll"] || [albumName isEqualToString:@"相机胶卷"] || [albumName isEqualToString:@"所有照片"] || [albumName isEqualToString:@"All Photos"] || [albumName isEqualToString:@"Recents"];
    }
}

- (void)fetchcameraRollAlbumAssetComplete:(void (^)(NSArray<SKPhotoModel *> *))complete {
    
    [self fetchAlbumsAllowSelectVideo:self.allowSelectVideo allowSelectImage:self.allowSelectImage complete:complete];
}

- (void)fetchAlbumsAllowSelectVideo:(BOOL)allowSelectVideo allowSelectImage:(BOOL)allowSelectImage complete:(void (^)(NSArray<SKPhotoModel *> *))complete {
    
    PHFetchOptions *option = [[PHFetchOptions alloc] init];
    if (!allowSelectVideo) option.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeImage];
    if (!allowSelectImage) option.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld",PHAssetMediaTypeVideo];
    if (!self.sortAscending) option.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:self.sortAscending]];
    
    
    PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil];
    
    //PHFetchResult *userCustomAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil]; // 用户自己创建的相册 “测试相册3”
    
    [smartAlbums enumerateObjectsUsingBlock:^(PHAssetCollection *  _Nonnull collection, NSUInteger idx, BOOL * _Nonnull stop) {
        
        NSLog(@"collection = %@",collection); // collection = <PHAssetCollection: 0x1193e8b50> A506EB6E-BCFC-4E4E-B4DB-162B473014F5/L0/040, title:"所有照片", subtitle:"(null)" assetCollectionType=2/209
        
        // 过滤PHCollectionList对象
        if (![collection isKindOfClass:PHAssetCollection.class]) return ;
        // 过滤最近删除和已隐藏
        if (collection.assetCollectionSubtype > 215 ||
            collection.assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumAllHidden) return ;
        // 获取相册内asset result
        PHFetchResult<PHAsset *> *result = [PHAsset fetchAssetsInAssetCollection:collection options:option];
        
        NSMutableArray<SKPhotoModel *> *userLibraryPhotos = [NSMutableArray array];
        if (!result.count) {
            if (complete) complete(userLibraryPhotos);
            return;
        }
        
        if (collection.assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumUserLibrary) { //所有照片
            NSMutableArray<SKPhotoModel *> *userLibraryPhotos = [NSMutableArray array];
            [result enumerateObjectsUsingBlock:^(PHAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                SKPhotoModel *model = [[SKPhotoModel alloc] init];
                model.asset = obj;
                model.duration = [self getVideoDuration:obj];
                //NSLog(@"localIdentifier = %@",obj.localIdentifier); // localIdentifier = B4792D6B-9D40-4028-A11C-A78A5AC05C8D/L0/001
                [userLibraryPhotos addObject:model];
            }];
            
            if (complete) complete(userLibraryPhotos);
            return;
        }
    }];
    
    
}

+ (PHAuthorizationStatus)photosAuthorized:(void(^)(PHAuthorizationStatus))handler
{
    __block  PHAuthorizationStatus status = PHAuthorizationStatusDenied;
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        
        // 在8.0系统以后，新加入Photos.framework框架
        if (@available(iOS 8,*))
        {
            
            PHAuthorizationStatus authorizationStatus = [PHPhotoLibrary authorizationStatus];
            NSLog(@"photosAuthorized  status = %zd", authorizationStatus);
            status = authorizationStatus;
            // 在iOS11 之后， 相册权限如果是“仅添加图片”，对应的status 为PHAuthorizationStatusDenied
            // 在iOS11 之后， 相册权限如果是“永不”，对应的status 为PHAuthorizationStatusDenied
            // 在iOS11 之后， 相册权限如果是“读取和写入”，对应的status 为PHAuthorizationStatusAuthorized
            
            switch (authorizationStatus) {
                case PHAuthorizationStatusNotDetermined:
                    break;
                case PHAuthorizationStatusRestricted:
                    break;
                case PHAuthorizationStatusAuthorized:
                    break;
                case PHAuthorizationStatusDenied:
                    break;
                    
                default:
                    break;
            }
            
            // iOS11之前：访问相册和存储照片到相册（读写权限），需要用户授权，需要添加NSPhotoLibraryUsageDeSKription。
            // iOS11之后：默认开启访问相册权限（读权限），无需用户授权，无需添加NSPhotoLibraryUsageDeSKription，适配iOS11之前的还是需要加的。
            // 在iOS11之后，添加图片到相册（写权限），需要用户授权，需要添加NSPhotoLibraryAddUsageDeSKription。
            
            
            if (handler && authorizationStatus == PHAuthorizationStatusNotDetermined) {
                
                [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status1) {
                    
                    NSLog(@"PHPhotoLibrary requestAuthorization status = %zd",status1); // status = 2
                    status = status1;
                    switch (status1) {
                        case PHAuthorizationStatusNotDetermined:
                            break;
                        case PHAuthorizationStatusRestricted:
                            break;
                        case PHAuthorizationStatusAuthorized:
                            break;
                        case PHAuthorizationStatusDenied:
                            break;
                            
                        default:
                            break;
                    }
                    if (handler) handler(status);
                }];
                
            } else {
                if (handler) handler(status);
            }
            
        }
        else
        {
            // 8.0之前用ALAuthorizationStatus判断, 这里 不做适配了
        }
    }
    
    return status;
}


- (NSString *)getVideoDuration:(PHAsset *)asset
{
    if (asset.mediaType != PHAssetMediaTypeVideo) return nil;
    
    NSInteger duration = (NSInteger)round(asset.duration);
    
    if (duration < 60) {
        return [NSString stringWithFormat:@"00:%02ld", (long)duration];
    } else if (duration < 3600) {
        NSInteger m = duration / 60;
        NSInteger s = duration % 60;
        return [NSString stringWithFormat:@"%02ld:%02ld", (long)m, (long)s];
    } else {
        NSInteger h = duration / 3600;
        NSInteger m = (duration % 3600) / 60;
        NSInteger s = duration % 60;
        return [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)h, (long)m, (long)s];
    }
}

- (UIImage *)SKaleImage:(UIImage *)image toSize:(CGSize)size {
    if (image.size.width > size.width) {
        UIGraphicsBeginImageContext(size);
        [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
        UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return newImage;
    } else {
        return image;
    }
}

@end



@implementation UIImage (SKPhotoManager)

+ (UIImage *)imageNamedFromSKBundle:(NSString *)name {
    Class class = NSClassFromString(@"SKPhotoManager");
    NSBundle *currentBundle = [NSBundle bundleForClass:class];
    NSString *bundlePath = [currentBundle pathForResource:@"SKPhotoPicker" ofType:@"bundle"];
    NSString *imageName = [bundlePath stringByAppendingPathComponent:name];
    UIImage *image = [UIImage imageWithContentsOfFile:imageName];
    if (!image)  image = [UIImage imageNamed:name];
    return image;
}

+ (UIImage *)animatedGIFWithSKData:(NSData *)data {
    if (!data) {
        return nil;
    }
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
    size_t count = CGImageSourceGetCount(source);
    UIImage *animatedImage;
    if (count <= 1) {
        animatedImage = [[UIImage alloc] initWithData:data];
    }
    else {
        NSMutableArray *images = [NSMutableArray array];
        NSTimeInterval duration = 0.0f;
        for (size_t i = 0; i < count; i++) {
            CGImageRef image = CGImageSourceCreateImageAtIndex(source, i, NULL);
            if (!image) {
                continue;
            }
            duration += [self frameDurationAtIndex:i source:source];
            [images addObject:[UIImage imageWithCGImage:image scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp]];
            CGImageRelease(image);
        }
        if (!duration) {
            duration = (1.0f / 10.0f) * count;
        }
        animatedImage = [UIImage animatedImageWithImages:images duration:duration];
    }
    CFRelease(source);
    return animatedImage;
}

+ (float)frameDurationAtIndex:(NSUInteger)index source:(CGImageSourceRef)source {
    float frameDuration = 0.1f;
    CFDictionaryRef cfFrameProperties = CGImageSourceCopyPropertiesAtIndex(source, index, nil);
    NSDictionary *frameProperties = (__bridge NSDictionary *)cfFrameProperties;
    NSDictionary *gifProperties = frameProperties[(NSString *)kCGImagePropertyGIFDictionary];
    NSNumber *delayTimeUnclampedProp = gifProperties[(NSString *)kCGImagePropertyGIFUnclampedDelayTime];
    if (delayTimeUnclampedProp) {
        frameDuration = [delayTimeUnclampedProp floatValue];
    }
    else {
        NSNumber *delayTimeProp = gifProperties[(NSString *)kCGImagePropertyGIFDelayTime];
        if (delayTimeProp) {
            frameDuration = [delayTimeProp floatValue];
        }
    }
    if (frameDuration < 0.011f) {
        frameDuration = 0.100f;
    }
    CFRelease(cfFrameProperties);
    return frameDuration;
}


@end
