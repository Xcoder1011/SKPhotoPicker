//
//  SKPhotoPickerViewController.h
//  SKPhotoPicker_Example
//
//  Created by shangkun on 2018/10/9.
//  Copyright © 2018年 Xcoder1011. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SKPhotoPickerViewController : UIViewController

@property (nonatomic, assign) NSInteger columnNumber;

@property (nonatomic, assign) BOOL shouldScrollToBottom;

@property (nonatomic, strong) NSMutableArray *items;

@end
