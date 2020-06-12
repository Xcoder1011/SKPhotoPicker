//
//  SKPhotoCell.h
//  SKPhotoPicker_Example
//
//  Created by shangkun on 2018/10/9.
//  Copyright © 2018年 Xcoder1011. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SKPhotoModel;
@class SKPhotoCell;
@class SKPhotoNavigationController;

@protocol SKPhotoCellDelegate <NSObject>

-(void)pickerPhotoCell:(SKPhotoCell *)cell didSelectItem:(SKPhotoModel *)item indexPath:(NSIndexPath *)indexPath;

-(void)pickerPhotoCell:(SKPhotoCell *)cell didCancelSelectItem:(SKPhotoModel *)item indexPath:(NSIndexPath *)indexPath;

@end

// base cell
@interface SKPhotoBaseCell : UICollectionViewCell

@property (nonatomic, strong) UIImageView *imageView;

@property (nonatomic, strong) UIView *bottomView;

@property (nonatomic, strong) SKPhotoModel *tempModel;

@end


// 照片
@interface SKPhotoCell : SKPhotoBaseCell

@property (nonatomic, weak)  id<SKPhotoCellDelegate> delegate;

@property (nonatomic, weak)  NSIndexPath *indexPath;

@property (nonatomic, strong) SKPhotoModel *model;

@property (nonatomic, weak) UIButton *selectedButton;

@property (nonatomic, weak)  SKPhotoNavigationController *navigation;

- (void)reloadData;

@end


// 视频
@interface SKVideoCell : SKPhotoBaseCell

@property (nonatomic, weak)  NSIndexPath *indexPath;

@property (nonatomic, strong) SKPhotoModel *model;

@property (nonatomic, weak)  SKPhotoNavigationController *navigation;

- (void)reloadData;

@end


// 拍照
@interface SKCameraCell : UICollectionViewCell

@property (nonatomic, strong) UIImageView *imageView;

@property (nonatomic, strong) UIView *bottomView;

@property (nonatomic, strong) UILabel *descLabel;

@end


@interface UIColor (SKUtil)

+ (UIColor *)sk_colorWithHexString:(NSString *)hexStr;

@end

