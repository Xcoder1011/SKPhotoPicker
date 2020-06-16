//
//  SKPreviewVideoCell.h
//  SKPhotoPicker_Example
//
//  Created by shangkun on 2018/10/9.
//  Copyright © 2018年 Xcoder1011. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SKPhotoModel;
@interface SKPreviewVideoCell : UICollectionViewCell

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIView *bottomView;
@property (nonatomic, strong) UIView *imageContainerView;

@property (nonatomic, copy) void (^singleTapGestureBlock)(BOOL hideNav);
@property (nonatomic, strong) SKPhotoModel *model;

- (void)resetSubViewsFrame;
- (void)reSetAnimateImageFrame:(CGRect)frame percent:(double)percent;

@end
