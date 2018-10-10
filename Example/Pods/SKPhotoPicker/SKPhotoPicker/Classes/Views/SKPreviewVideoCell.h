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

@property (nonatomic, copy) void (^singleTapGestureBlock)(BOOL hideNav);

@property (nonatomic, strong) SKPhotoModel *model;

- (void)resetSubViewsFrame;

@end
