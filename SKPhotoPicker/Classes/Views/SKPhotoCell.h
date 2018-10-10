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

// 照片
@interface SKPhotoCell : UICollectionViewCell

@property (nonatomic, weak)  id<SKPhotoCellDelegate> delegate;

@property (nonatomic, weak)  NSIndexPath *indexPath;

@property (nonatomic, strong) SKPhotoModel *model;

@property (nonatomic, weak) UIButton *selectedButton;

@property (nonatomic, weak)  SKPhotoNavigationController *navigation;

- (void)reloadData;

@end



// 视频
@interface SKVideoCell : UICollectionViewCell

@property (nonatomic, weak)  NSIndexPath *indexPath;

@property (nonatomic, strong) SKPhotoModel *model;

@property (nonatomic, weak)  SKPhotoNavigationController *navigation;

- (void)reloadData;

@end
