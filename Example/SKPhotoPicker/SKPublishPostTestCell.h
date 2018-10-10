//
//  SKPublishPostTestCell.h
//  SKPhotoPicker_Example
//
//  Created by shangkun on 2018/10/10.
//  Copyright © 2018年 Xcoder1011. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SKPhotoPicker/SKPhotoHeader.h>

@interface SKPublishPostTestCell : UICollectionViewCell

@property (nonatomic, strong) UIButton *deleteBtn;

@property (nonatomic, assign) NSInteger index;

@property (nonatomic, strong) UIImageView *picImgeView;

@property (nonatomic, strong) UIImageView *addBtnView;

@property (nonatomic, strong) UIImageView *playBtnView;

@property (nonatomic, strong) UILabel *timeLabel;

@property (nonatomic, copy) void(^deleteBtnClickBlock)(NSInteger index);

@property (nonatomic, strong) SKPhotoModel *item;

@end
