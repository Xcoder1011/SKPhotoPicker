//
//  SKPhotoModel.m
//  SKPhotoPicker_Example
//
//  Created by shangkun on 2018/10/9.
//  Copyright © 2018年 Xcoder1011. All rights reserved.
//

#import "SKPhotoModel.h"

@implementation SKPhotoModel

- (instancetype)init {
    
    if (self = [super init]) {
        _selectIndex = 0;
    }
    return self;
}

- (SKAssetMediaType)mediaType {
    
    if (self.asset) {
        switch (self.asset.mediaType) {
            case PHAssetMediaTypeVideo:
                return SKAssetMediaTypeVideo;
                break;
            case PHAssetMediaTypeImage:
            {
                if ([[self.asset valueForKey:@"filename"] hasSuffix:@"GIF"]) {
                    return SKAssetMediaTypeGIF;
                    
                }else if (self.asset.mediaSubtypes == PHAssetMediaSubtypePhotoLive) {
                    if (@available(iOS 9.0, *)) {
                        return SKAssetMediaTypeLivePhoto;
                    }
                }
                return SKAssetMediaTypeImage;
            }
                break;
            case PHAssetMediaTypeUnknown:
                return SKAssetMediaTypeUnknown;
                break;
            case PHAssetMediaTypeAudio:
                return SKAssetMediaTypeAudio;
                break;
                
            default:
                break;
        }
    }
    return _mediaType;
}

@end

@implementation SKAlbumModel

- (NSArray<SKPhotoModel *> *)selectedItems {
    
    if (self.items && self.items.count > 0) {
        NSMutableArray * temArray = @[].mutableCopy;
        [self.items enumerateObjectsUsingBlock:^(SKPhotoModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.isSelected) {
                [temArray addObject:obj];
            }
        }];
        _selectedCount = temArray.count;
        return [temArray copy];
    }
    return @[];
}

@end
