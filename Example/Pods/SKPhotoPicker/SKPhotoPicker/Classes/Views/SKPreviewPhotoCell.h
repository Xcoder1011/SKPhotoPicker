//
//  SKPreviewPhotoCell.h
//  SKPhotoPicker_Example
//
//  Created by shangkun on 2018/10/9.
//  Copyright © 2018年 Xcoder1011. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SKPhotoModel;

@interface SKPreviewPhotoCell : UICollectionViewCell

@property (nonatomic, assign) BOOL supportLivePhoto;

@property (nonatomic, strong) SKPhotoModel *model;

@property (nonatomic, copy) void (^singleTapGestureBlock)();

- (void)resetSubViewsFrame;

- (void)startPlayAnimationView;
- (void)stopPlayAnimationView;


@end


@class SKAlbumModel;
@interface SKAlbumListPhotoCell : UITableViewCell

@property (nonatomic, strong) SKAlbumModel *model;

@end
