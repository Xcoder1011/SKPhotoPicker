//
//  SCPhotoPickerViewController.h
//  SuperCoach
//
//  Created by shangkun on 2018/9/5.
//  Copyright © 2018年 Lin Feihong. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SCPhotoPickerViewController : UIViewController

@property (nonatomic, assign) NSInteger columnNumber;
@property (nonatomic, assign) BOOL shouldScrollToBottom;
// 数据源
@property (nonatomic, strong) NSMutableArray *items;

@end
