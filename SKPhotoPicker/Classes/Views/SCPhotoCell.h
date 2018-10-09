//
//  SCPhotoCell.h
//  SuperCoach
//
//  Created by shangkun on 2018/9/6.
//  Copyright © 2018年 Lin Feihong. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SCPhotoModel;
@class SCPhotoCell;
@class SCPhotoNavigationController;

@protocol SCPhotoCellDelegate <NSObject>

-(void)pickerPhotoCell:(SCPhotoCell *)cell didSelectItem:(SCPhotoModel *)item indexPath:(NSIndexPath *)indexPath;

-(void)pickerPhotoCell:(SCPhotoCell *)cell didCancelSelectItem:(SCPhotoModel *)item indexPath:(NSIndexPath *)indexPath;

@end

// 照片
@interface SCPhotoCell : UICollectionViewCell

@property (nonatomic, weak)  id<SCPhotoCellDelegate> delegate;

@property (nonatomic, weak)  NSIndexPath *indexPath;

@property (nonatomic, strong) SCPhotoModel *model;

@property (nonatomic, weak) UIButton *selectedButton;

@property (nonatomic, weak)  SCPhotoNavigationController *navigation;

- (void)reloadData;

@end



// 视频
@interface SCVideoCell : UICollectionViewCell

@property (nonatomic, weak)  NSIndexPath *indexPath;

@property (nonatomic, strong) SCPhotoModel *model;

@property (nonatomic, weak)  SCPhotoNavigationController *navigation;

- (void)reloadData;

@end
