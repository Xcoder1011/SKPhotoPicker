//
//  SCPreviewVideoCell.h
//  SuperCoach
//
//  Created by shangkun on 2018/9/13.
//  Copyright © 2018年 Lin Feihong. All rights reserved.
//

#import <UIKit/UIKit.h>
@class SCPhotoModel;

@interface SCPreviewVideoCell : UICollectionViewCell

@property (nonatomic, copy) void (^singleTapGestureBlock)(BOOL hideNav);

@property (nonatomic, strong) SCPhotoModel *model;

- (void)resetSubViewsFrame;

@end
