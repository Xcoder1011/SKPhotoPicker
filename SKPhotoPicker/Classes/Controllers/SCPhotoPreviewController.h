//
//  SCPhotoPreviewController.h
//  SuperCoach
//
//  Created by shangkun on 2018/9/6.
//  Copyright © 2018年 Lin Feihong. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SCPhotoModel;
@interface SCPhotoPreviewController : UIViewController

@property (nonatomic, strong) NSMutableArray *items;
@property (nonatomic, assign) NSInteger currentIndex;

@property (nonatomic, copy) void (^selectItemBlock) (SCPhotoModel *item);
@property (nonatomic, copy) void (^cancelSelectItemBlock) (SCPhotoModel *item);


@end
