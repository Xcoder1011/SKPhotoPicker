//
//  SCPhotoModel.m
//  SuperCoach
//
//  Created by shangkun on 2018/9/5.
//  Copyright © 2018年 Lin Feihong. All rights reserved.
//

#import "SCPhotoModel.h"

@implementation SCPhotoModel

- (instancetype)init {
    
    if (self = [super init]) {
        _selectIndex = 0;
    }
    return self;
}

- (SCAssetMediaType)mediaType {
    
    if (self.asset) {
        switch (self.asset.mediaType) {
            case PHAssetMediaTypeVideo:
                return SCAssetMediaTypeVideo;
                break;
            case PHAssetMediaTypeImage:
            {
                if ([[self.asset valueForKey:@"filename"] hasSuffix:@"GIF"]) {
                    return SCAssetMediaTypeGIF;
                    
                }else if (self.asset.mediaSubtypes == PHAssetMediaSubtypePhotoLive) {
                    if (@available(iOS 9.0, *)) {
                        return SCAssetMediaTypeLivePhoto;
                    }
                }
                return SCAssetMediaTypeImage;
            }
                break;
            case PHAssetMediaTypeUnknown:
                return SCAssetMediaTypeUnknown;
                break;
            case PHAssetMediaTypeAudio:
                return SCAssetMediaTypeAudio;
                break;
                
            default:
                break;
        }
    }
    return _mediaType;
}

@end

@implementation SCAlbumModel

- (NSArray<SCPhotoModel *> *)selectedItems {
    
    if (self.items && self.items.count > 0) {
        NSMutableArray * temArray = @[].mutableCopy;
        [self.items enumerateObjectsUsingBlock:^(SCPhotoModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
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
