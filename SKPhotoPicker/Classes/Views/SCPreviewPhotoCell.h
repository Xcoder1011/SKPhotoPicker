//
//  SCPreviewPhotoCell.h
//  SuperCoach
//
//  Created by shangkun on 2018/9/6.
//  Copyright © 2018年 Lin Feihong. All rights reserved.
//

#import <UIKit/UIKit.h>


@class SCPhotoModel;

@interface SCPreviewPhotoCell : UICollectionViewCell

@property (nonatomic, assign) BOOL supportLivePhoto;

@property (nonatomic, strong) SCPhotoModel *model;

@property (nonatomic, copy) void (^singleTapGestureBlock)();

- (void)resetSubViewsFrame;

- (void)startPlayAnimationView;
- (void)stopPlayAnimationView;


@end


@class SCAlbumModel;
@interface SCAlbumListPhotoCell : UITableViewCell

@property (nonatomic, strong) SCAlbumModel *model;

@end

