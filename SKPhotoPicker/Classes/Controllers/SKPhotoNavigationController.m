//
//  SKPhotoNavigationController.m
//  SKPhotoPicker_Example
//
//  Created by shangkun on 2018/10/9.
//  Copyright © 2018年 Xcoder1011. All rights reserved.
//

#import "SKPhotoNavigationController.h"
#import "SKPhotoHeader.h"
#if __has_include(<Masonry/Masonry.h>)
#import <Masonry/Masonry.h>
#else
#import "Masonry.h"
#endif
@interface SKPhotoNavigationController () <UIGestureRecognizerDelegate>

@property(nonatomic, weak) SKPhotoAlbumListController *albumListController;
@property(nonatomic, strong) UILabel *tipLabel;
@property(nonatomic, assign , readwrite) BOOL allowSelectImage;
@property(nonatomic, assign , readwrite) BOOL allowSelectVideo;
@property(nonatomic, assign , readwrite) NSInteger maxSelectPhotosCount;
@property(nonatomic, strong , readwrite) NSArray<SKAlbumModel *> *albumsList;

@end

@implementation SKPhotoNavigationController

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController navigationBarHidden:(BOOL)hidden {
    
    SKPhotoNavigationController *nav = [[SKPhotoNavigationController alloc] initWithRootViewController:rootViewController];
    [nav setNavigationBarHidden:hidden];
    nav.navigationController.interactivePopGestureRecognizer.delegate = self;
    return nav;
}

- (instancetype)initWithDelegate:(id<SKPhotoNavigationControllerDelegate>)delegate pushPickerVC:(BOOL)pushPickerVC {
   
    return [self initWithDelegate:delegate pushPickerVC:pushPickerVC allowSelectImage:YES allowSelectVideo:YES maxSelectPhotosCount:9];
}

- (instancetype)initWithDelegate:(id<SKPhotoNavigationControllerDelegate>)delegate
                    pushPickerVC:(BOOL)pushPickerVC
                allowSelectImage:(BOOL)allowSelectImage
                allowSelectVideo:(BOOL)allowSelectVideo
            maxSelectPhotosCount:(NSInteger)maxSelectPhotosCount {
    
   SKPhotoAlbumListController *rootController = [[SKPhotoAlbumListController alloc] init];
    self = [super initWithRootViewController:rootController];
    if (self) {
        _albumListController = rootController;
        [self setNavigationBarHidden:NO];
        self.modalPresentationStyle = UIModalPresentationFullScreen;
        self.pickerDelegate = delegate;
        _allowSelectVideo = allowSelectVideo;
        _allowSelectImage = allowSelectImage;
        _maxSelectPhotosCount = maxSelectPhotosCount;
        self.navigationController.interactivePopGestureRecognizer.delegate = self;
        
        PHAuthorizationStatus status = [SKPhotoManager photosAuthorized:nil];
        if (status != PHAuthorizationStatusAuthorized) { // 设备没有授权
            _tipLabel = [UILabel new];
            _tipLabel.textColor = [UIColor lightGrayColor];
            _tipLabel.text =@"设备没有开启相册权限";
            [self.view addSubview:_tipLabel];
            [_tipLabel mas_makeConstraints:^(MASConstraintMaker *make) {
                make.centerY.equalTo(self.view.mas_centerY);
                make.centerX.equalTo(self.view.mas_centerX);
            }];
            __weak typeof(self) weakself = self;
            [SKPhotoManager photosAuthorized:^(PHAuthorizationStatus status) {
                if (status == PHAuthorizationStatusAuthorized) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [weakself.tipLabel removeFromSuperview];
                        weakself.tipLabel = nil;
                        if (pushPickerVC) {
                            [weakself pushToPickerVC];
                        }
                    });
                }
            }];
        } else {
            if (pushPickerVC) {
                [self pushToPickerVC];
            }
        }
    }
    return self;
}

- (void)pushToPickerVC {
    
    [SKPhotoManager sharedInstance].allowSelectVideo = self.allowSelectVideo;
    [SKPhotoManager sharedInstance].allowSelectImage = self.allowSelectImage;
    __weak typeof(self) weakself = self;
    [[SKPhotoManager sharedInstance] fetchAlbumsListComplete:^(NSArray<SKAlbumModel *> *albumsList) {
        weakself.albumsList = albumsList;
        SKPhotoPickerViewController *controller = [[SKPhotoPickerViewController alloc] init];
        controller.items = [[SKPhotoManager sharedInstance].cameraRollAlbum.items mutableCopy];
        controller.title = [SKPhotoManager sharedInstance].cameraRollAlbum.name;
        [weakself pushViewController:controller animated:YES];
    }];
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    _currentSeletedItems = @[].mutableCopy;
    _currentSeletedLocalIdentifier = @[].mutableCopy;
    _allowSelectVideo = YES;
    _allowSelectImage = YES;
    _supportLivePhoto = NO;
    _maxSelectPhotosCount = 9;
    id target = self.interactivePopGestureRecognizer.delegate;
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:target action:@selector(handleNavigationTransition:)];
    pan.delegate = self;
    [self.view addGestureRecognizer:pan];
    self.interactivePopGestureRecognizer.enabled = NO;
    self.navigationBar.barTintColor = [UIColor clearColor];
    self.navigationBar.translucent = YES;
    [self.navigationBar setBackgroundImage:[self getImageWithColor: kBarTintColor] forBarMetrics:UIBarMetricsDefault];
    [self.navigationBar setShadowImage:[UIImage new]];
    self.navigationBar.tintColor = [UIColor whiteColor];
    [self.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor],
                                                 NSFontAttributeName : [UIFont fontWithName:@"Helvetica-Bold" size:17]}];
}

- (void)didSelectDoneEvent {
    
    if (self.pickerDelegate && [self.pickerDelegate respondsToSelector:@selector(imagePickerController:didFinishPickPhotosItems:)]) {
        [self.pickerDelegate imagePickerController:self didFinishPickPhotosItems:[self.currentSeletedItems copy]];
    }
    if (self.pickerDelegate && [self.pickerDelegate respondsToSelector:@selector(imagePickerController:willDismissViewControllerWithItems:)]) {
        [self.pickerDelegate imagePickerController:self willDismissViewControllerWithItems:[self.currentSeletedItems copy]];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)showMaxPhotosCountAlert {
    
    NSString *message = [NSString stringWithFormat:@"你最多只能选择%ld张照片",(long)self.maxSelectPhotosCount];
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"我知道了" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    
    if (self.childViewControllers.count >= 1) {
        viewController.hidesBottomBarWhenPushed = YES;
        UIButton *backButton = [[UIButton alloc] initWithFrame:CGRectMake(20, 12, 24, 40)];
        [backButton setImage:[UIImage imageFromSKBundleWithName:@"arrow_left_white"] forState:UIControlStateNormal];
        [backButton addTarget:self action:@selector(didTapBackButton) forControlEvents:UIControlEventTouchUpInside];
        viewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:backButton];
    }
    [super pushViewController:viewController animated:animated];
}

- (void)didTapBackButton {
    
    [self popViewControllerAnimated:YES];
}

- (UIImage *)getImageWithColor:(UIColor *)color{
    CGSize colorSize= CGSizeMake(1, 1);
    UIGraphicsBeginImageContext(colorSize);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillRect(context, CGRectMake(0, 0, 1, 1));
    UIImage *img=UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

/**
 *  拦截手势触发
 */
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if (self.childViewControllers.count <= 1) {
        return NO;
    }
    
    if ([[self.navigationController valueForKey:@"_isTransitioning"] boolValue]) {
        return NO;
    }
    
    CGPoint translation = [(UIPanGestureRecognizer *)gestureRecognizer translationInView:gestureRecognizer.view];
    if (translation.x <= 0) {
        return NO;
    }
    
    return YES;
}

- (UIViewController *)childViewControllerForStatusBarStyle{
    
    return self.topViewController;
}

- (void)dealloc {
    
#ifdef DEBUG
    
    printf("######## Did released the %s .\n", NSStringFromClass(self.class).UTF8String);
    
#endif
}



@end

