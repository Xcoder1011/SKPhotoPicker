//
//  SKPhotoPreviewController.h
//  SKPhotoPicker_Example
//
//  Created by shangkun on 2018/10/9.
//  Copyright © 2018年 Xcoder1011. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SKPhotoModel;
@interface SKPhotoPreviewController : UIViewController

@property (nonatomic, strong) NSMutableArray <SKPhotoModel *> *items;
@property (nonatomic, assign) NSInteger currentIndex;

@property (nonatomic, copy) void (^selectItemBlock) (SKPhotoModel *item);
@property (nonatomic, copy) void (^cancelSelectItemBlock) (SKPhotoModel *item);

// 图片浏览器 support
@property (nonatomic, assign) BOOL  supportPanGesture;
// 图片选择展示预览界面 不一样， default NO
@property (nonatomic, assign) BOOL  fromPhotoPicker;
// default YES, 保存、分享 等操作
@property (nonatomic, assign) BOOL  showActionSheet;
// default NO, 顶部返回按钮等nav
@property (nonatomic, assign) BOOL hideToolBar;
// default YES
@property (nonatomic, assign) BOOL enableFirstShowAnimation;
// default YES
@property (nonatomic, assign) BOOL supportSingleTapGesture;

// 展示界面
- (void)presentFromController:(UIViewController *)vc;
- (void)present;

@end

@interface UIView (SCPhotoPreviewController)

@property (nonatomic, strong) id sk_Item;

@end
