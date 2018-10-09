//
//  SCPhotoNavigationController.m
//  SuperCoach
//
//  Created by shangkun on 2018/9/6.
//  Copyright © 2018年 Lin Feihong. All rights reserved.
//

#import "SCPhotoNavigationController.h"
#import "SCPhotoHeader.h"

@interface SCPhotoNavigationController () <UIGestureRecognizerDelegate>

@property(nonatomic, weak) SCPhotoAlbumListController *albumListController;
@property(nonatomic, strong) UILabel *tipLabel;
@property(nonatomic, assign , readwrite) BOOL allowSelectImage;
@property(nonatomic, assign , readwrite) BOOL allowSelectVideo;
@property(nonatomic, assign , readwrite) NSInteger maxSelectPhotosCount;
@property(nonatomic, strong , readwrite) NSArray<SCAlbumModel *> *albumsList;

@end

@implementation SCPhotoNavigationController

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController navigationBarHidden:(BOOL)hidden {
    
    SCPhotoNavigationController *nav = [[SCPhotoNavigationController alloc] initWithRootViewController:rootViewController];
    [nav setNavigationBarHidden:hidden];
    nav.navigationController.interactivePopGestureRecognizer.delegate = self;
    return nav;
}

- (instancetype)initWithDelegate:(id<SCPhotoNavigationControllerDelegate>)delegate pushPickerVC:(BOOL)pushPickerVC {
    
    return [self initWithDelegate:delegate pushPickerVC:pushPickerVC allowSelectImage:YES allowSelectVideo:YES maxSelectPhotosCount:9];
}

- (instancetype)initWithDelegate:(id<SCPhotoNavigationControllerDelegate>)delegate
                    pushPickerVC:(BOOL)pushPickerVC
                allowSelectImage:(BOOL)allowSelectImage
                allowSelectVideo:(BOOL)allowSelectVideo
            maxSelectPhotosCount:(NSInteger)maxSelectPhotosCount {
    
    SCPhotoAlbumListController *rootController = [[SCPhotoAlbumListController alloc] init];
    _albumListController = rootController;
    self = [super initWithRootViewController:rootController];
    
    if (self) {
        [self setNavigationBarHidden:NO];
        self.pickerDelegate = delegate;
        _allowSelectVideo = allowSelectVideo;
        _allowSelectImage = allowSelectImage;
        _maxSelectPhotosCount = maxSelectPhotosCount;
        self.navigationController.interactivePopGestureRecognizer.delegate = self;
        
        PHAuthorizationStatus status = [SCPhotoManager photosAuthorized:nil];
        if (status != PHAuthorizationStatusAuthorized) { // 设备没有授权
            _tipLabel = [UILabel new];
            _tipLabel.textColor = [UIColor lightGrayColor];
            _tipLabel.text =@"设备没有开启相册权限";
            [self.view addSubview:_tipLabel];
            [_tipLabel mas_makeConstraints:^(MASConstraintMaker *make) {
                make.centerY.equalTo(self.view.mas_centerY);
                make.centerX.equalTo(self.view.mas_centerX);
            }];
            [SCPhotoManager photosAuthorized:^(PHAuthorizationStatus status) {
                if (status == PHAuthorizationStatusAuthorized) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [_tipLabel removeFromSuperview];
                        _tipLabel = nil;
                        if (pushPickerVC) {
                            [self pushToPickerVC];
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
    
    __weak typeof(self) weakself = self;
    [SCPhotoManager sharedInstance].allowSelectVideo = self.allowSelectVideo;
    [SCPhotoManager sharedInstance].allowSelectImage = self.allowSelectImage;
    
    [[SCPhotoManager sharedInstance] fetchAlbumsListComplete:^(NSArray<SCAlbumModel *> *albumsList) {
        weakself.albumsList = albumsList;
        SCPhotoPickerViewController *controller = [[SCPhotoPickerViewController alloc] init];
        controller.items = [[SCPhotoManager sharedInstance].cameraRollAlbum.items mutableCopy];
        controller.title = [SCPhotoManager sharedInstance].cameraRollAlbum.name;
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
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    self.navigationBar.translucent = YES;
    self.navigationBar.barTintColor = kBarTintColor;
    self.navigationBar.tintColor = [UIColor whiteColor];
    [self.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor],
                                                NSFontAttributeName : [UIFont fontWithName:@"Helvetica-Bold" size:17]}];
}


- (void)didSelectDoneEvent {
    
    if (self.pickerDelegate && [self.pickerDelegate respondsToSelector:@selector(imagePickerController:didFinishPickPhotosItems:)]) {
        [self.pickerDelegate imagePickerController:self didFinishPickPhotosItems:[self.currentSeletedItems copy]];
    }
    [self dismissViewControllerAnimated:YES completion:^{
    }];
}


- (void)showMaxPhotosCountAlert {
    
    NSString *message = [NSString stringWithFormat:@"你最多只能选择%ld张照片",(long)self.maxSelectPhotosCount];
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"我知道了" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        //
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}


- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    
    if (self.childViewControllers.count >= 1) {
        viewController.hidesBottomBarWhenPushed = YES; // 隐藏底部的工具条
        UIButton *backButton = [[UIButton alloc] initWithFrame:CGRectMake(20, 12, 24, 40)];
        [backButton setImage:[UIImage imageNamedFromSCBundle:@"arrow_left_white"] forState:UIControlStateNormal];
        [backButton addTarget:self action:@selector(didTapBackButton) forControlEvents:UIControlEventTouchUpInside];
        viewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:backButton];
    }
    [super pushViewController:viewController animated:animated];
}

- (void)didTapBackButton {
    
    [self popViewControllerAnimated:YES];
}

/**
 *  拦截手势触发
 */
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if (self.childViewControllers.count <= 1) {
        return NO;
    }
    
    // 导航控制器当前处于转换状态时忽略平移手势。
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
