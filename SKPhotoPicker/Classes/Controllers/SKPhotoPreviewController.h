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

@property (nonatomic, strong) NSMutableArray *items;
@property (nonatomic, assign) NSInteger currentIndex;

@property (nonatomic, copy) void (^selectItemBlock) (SKPhotoModel *item);
@property (nonatomic, copy) void (^cancelSelectItemBlock) (SKPhotoModel *item);

// 图片浏览器 support
@property (nonatomic, assign) BOOL  supportPanGesture;
// 图片选择展示预览界面 不一样， default NO
@property (nonatomic, assign) BOOL  fromPhotoPicker;

@end
