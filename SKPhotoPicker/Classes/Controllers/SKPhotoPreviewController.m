//
//  SKPhotoPreviewController.m
//  SKPhotoPicker_Example
//
//  Created by shangkun on 2018/10/9.
//  Copyright © 2018年 Xcoder1011. All rights reserved.
//

#import "SKPhotoPreviewController.h"
#import "SKPhotoHeader.h"
#import "SKPreviewPhotoCell.h"
#import "SKPreviewVideoCell.h"

#if __has_include(<Masonry/Masonry.h>)
#import <Masonry/Masonry.h>
#else
#import "Masonry.h"
#endif

#if __has_include(<SDWebImage/SDWebImageManager.h>)
#import <SDWebImage/SDWebImageManager.h>
#else
#import "SDWebImageManager.h"
#endif

@interface SKPhotoPreviewController () <UICollectionViewDelegate, UICollectionViewDataSource>
{
    UIView *_naviBar;
    
    UIButton *_backButton;
    UIButton *_selectButton;
    
    UIView *_photoBottomBar;
    UIButton *_doneButton;
    
    UIView *_tipBar;
    UILabel *_tipLabel;
    
    UILabel *_currentIndexLabel;
    BOOL _isShowedAnimated; // 第一次展示动画
}

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, assign) BOOL isHideNavBar;
@property (nonatomic, assign) CGPoint   startLocation;
@property (nonatomic, assign) CGRect    startFrame;
// 照片选择的的nav
@property (nonatomic, weak) SKPhotoNavigationController *photoNavigationController;
@property (nonatomic, strong) UIActivityIndicatorView *indicatorView;
@property (nonatomic, assign) BOOL firstImageLoaded;
@property (nonatomic, assign) BOOL firstImageAnimationEnd;

@end

@implementation SKPhotoPreviewController

#pragma mark -- Life Cycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES];
    [UIApplication sharedApplication].statusBarHidden = YES;
    if (self.currentIndex >= 0) [self.collectionView setContentOffset:CGPointMake((self.view.frame.size.width + kPreviewPadding) * self.currentIndex, 0) animated:NO];
    if (self.fromPhotoPicker) {
        [self refreshTopBottomBarStatus];
    } else {
        [self refreshCurrentIndexLabel];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO];
}

- (void)viewWillLayoutSubviews{
    [super viewWillLayoutSubviews];
    if(!_isShowedAnimated){
        [self photoPreviewFisrtShowWithAnimated];
        _isShowedAnimated = true;
    }
}

- (void)showLoading {
    [self.indicatorView startAnimating];
    [self.view bringSubviewToFront:self.indicatorView];
    self.indicatorView.hidden = NO;
}

- (void)hideLoading {
    [self.indicatorView stopAnimating];
    self.indicatorView.hidden = YES;
}

- (instancetype)init {
    if (self = [super init]) {
        self.automaticallyAdjustsScrollViewInsets = NO;
        self.modalPresentationStyle = UIModalPresentationFullScreen;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initialConfig];
    [self addNavBarButtons];
    [self addTipBarLabels];
    [self addBottomBarButtons];
}

#pragma mark -- Private Method

- (void)initialConfig {
    self.view.backgroundColor = [UIColor whiteColor];
    [self.collectionView reloadData];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)addNavBarButtons {
    
    CGFloat navHeight = 44 + [[UIApplication sharedApplication] statusBarFrame].size.height;
    _naviBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, navHeight)];
    _naviBar.backgroundColor = self.fromPhotoPicker ? kBarTintColor : [UIColor clearColor];

    CGFloat topSpace = [[UIApplication sharedApplication] statusBarFrame].size.height + 2;
    _backButton = [[UIButton alloc] initWithFrame:CGRectMake(10, topSpace, 24, 40)];
    
    [_backButton setImage:[UIImage imageFromSKBundleWithName:@"arrow_left_white"] forState:UIControlStateNormal];
    [_backButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_backButton addTarget:self action:@selector(backButtonClick) forControlEvents:UIControlEventTouchUpInside];
    
    [_naviBar addSubview:_selectButton];
    [_naviBar addSubview:_backButton];
    [self.view addSubview:_naviBar];
    
    if (self.fromPhotoPicker) {
        _selectButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 56/2.0 - 10, [[UIApplication sharedApplication] statusBarFrame].size.height + (44 - 56/2.0)/2.0, 56/2.0, 56/2.0)];
        [_selectButton setBackgroundImage:[UIImage imageFromSKBundleWithName:@"select_white"] forState:UIControlStateNormal];
        [_selectButton setBackgroundImage:[UIImage imageFromSKBundleWithName:@"picture_select_big"] forState:UIControlStateSelected];
        [_selectButton addTarget:self action:@selector(select:) forControlEvents:UIControlEventTouchUpInside];
        [_naviBar addSubview:_selectButton];
        
    } else {
        _currentIndexLabel = [[UILabel alloc] init];
        _currentIndexLabel.textColor = [UIColor whiteColor];
        _currentIndexLabel.font = [UIFont boldSystemFontOfSize:16];
        [_naviBar addSubview:_currentIndexLabel];
        
        [_currentIndexLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(_naviBar.mas_centerX);
            make.top.mas_equalTo(topSpace);
            make.height.mas_equalTo(40);
        }];
    }
    
    [self.view addSubview:_naviBar];
}

- (void)addTipBarLabels {
    
    _tipBar = [[UIView alloc] initWithFrame:CGRectMake(0, 64 , self.view.frame.size.width, 44)];
    _tipBar.backgroundColor = kBarTintColor;
    
    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, SINGLE_LINE_WIDTH)];
    lineView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.7];
    _tipLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 1, self.view.frame.size.width - 20, 43)];
    _tipLabel.text = @"选择照片时不能选择视频";
    [_tipLabel setFont:[UIFont systemFontOfSize:14]];
    [_tipLabel setTextColor:[UIColor whiteColor]];
    _tipBar.hidden = YES;
    
    [_tipBar addSubview:lineView];
    [_tipBar addSubview:_tipLabel];
    [self.view addSubview:_tipBar];
}


- (void)addBottomBarButtons {
    
    CGFloat height = sk_isIPhoneXSeries() ? (44 + kSafeBottomViewPadding) : 44;
    CGFloat offsetY = sk_isIPhoneXSeries() ?  (kSafeBottomViewPadding/2.0) : 0;
    
    _photoBottomBar = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - height, self.view.frame.size.width, height)];
    _photoBottomBar.backgroundColor = kBarTintColor;
    
    _doneButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 70, 6, 60, 32)];
    [_doneButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_doneButton addTarget:self action:@selector(doneButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [_doneButton setTitle:@"完成" forState:UIControlStateNormal];
    [_doneButton setBackgroundColor:kGreenColor];
    [_doneButton.titleLabel setFont:[UIFont systemFontOfSize:14]];
    _doneButton.layer.cornerRadius = 4;
    _doneButton.layer.masksToBounds = YES;
    
    [_photoBottomBar addSubview:_doneButton];
    [self.view addSubview:_photoBottomBar];
    
    [_photoBottomBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.view.mas_right).offset(0);
        make.left.equalTo(self.view.mas_left).offset(0);
        make.bottom.equalTo(self.view.mas_bottom).offset(0);
        make.height.mas_equalTo(height);
    }];
    
    [_doneButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(_photoBottomBar.mas_right).offset(-10);
        make.centerY.equalTo(_photoBottomBar.mas_centerY).offset( -offsetY);;
        make.width.mas_equalTo(@60);
        make.height.mas_equalTo(@30);
    }];
}

- (void)backButtonClick {
     [self dismiss];
}

- (void)popOrDismiss {
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (void)dismiss {
    SKPhotoModel *model = [self.items objectAtIndex:_currentIndex];
    UIImageView *tempImageView = [self tempImageViewFromContainerViewWithCurrentIndex:_currentIndex];
    [self sk_photoBrowserWillDismissWithAnimated:tempImageView photoModel:model];
}

#pragma mark - 手势拖拉动画

/// 手势拖拉动画
- (void)panDidGesture:(UIPanGestureRecognizer *)pan{
    
    // 在第一张图片未加载好之前，不响应手势
    if (self.collectionView.alpha < 1)  return;
       
    SKPhotoModel *model = [self.items objectAtIndex:_currentIndex];
    CGPoint movedPoint       = CGPointZero;
    CGPoint location    = CGPointZero;
    CGPoint velocity    = CGPointZero;
           
    UIView *tempImageView = nil;;
    
    SKPreviewPhotoCell *photoCell;
    SKPreviewVideoCell *videoCell;

    if (model.mediaType == SKAssetMediaTypeVideo) { // 视频cell样式
        SKPreviewVideoCell *cell = (SKPreviewVideoCell *)[_collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:_currentIndex inSection:0]];
        movedPoint       = [pan translationInView:self.view];
        location    = [pan locationInView:cell.bottomView];
        velocity    = [pan velocityInView:self.view];
        tempImageView = cell.imageContainerView;
        videoCell = cell;
        
    }else{
        SKPreviewPhotoCell *cell = (SKPreviewPhotoCell *)[_collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:_currentIndex inSection:0]];
        movedPoint       = [pan translationInView:self.view]; //在视图上移动的位置
        location    = [pan locationInView:cell.bottomView];//在视图上的位置
        velocity    = [pan velocityInView:self.view];
        tempImageView = cell.imageContainerView;
        photoCell = cell;
    }
    
    switch (pan.state) {
        case UIGestureRecognizerStateBegan:{
            _startLocation  = location;
            _startFrame = tempImageView.frame;
        }
            break;
        case UIGestureRecognizerStateChanged:{
            double percent = 1 - fabs(movedPoint.y) / self.view.frame.size.height;
            percent = MAX(percent, 0.3);
            if (CGRectIsEmpty(_startFrame)) {
                return;
            }
            CGFloat width = self.startFrame.size.width * percent;
            CGFloat height = self.startFrame.size.height * percent;
            
            CGFloat x = _startFrame.origin.x + ((1 - percent) * self.startFrame.size.width )/2.0 + movedPoint.x;
            CGFloat y = _startFrame.origin.y + ((1 - percent) * self.startFrame.size.width )/2.0 + movedPoint.y;
            
            if (model.mediaType == SKAssetMediaTypeVideo) { // 视频cell样式
                [videoCell reSetAnimateImageFrame: CGRectMake(x, y, width, height) percent:percent];
            } else {
                [photoCell reSetAnimateImageFrame: CGRectMake(x, y, width, height)];
            }
            self.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:percent];
        }
            break;
            
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled: {
            if (model.mediaType == SKAssetMediaTypeVideo) {
                if(fabs(movedPoint.y) > 150 || fabs(velocity.y) > 550){
                    _startFrame = tempImageView.frame;
                    [self dismiss];
                }else{
                    [UIView animateWithDuration:kPhotoBrowserAnimateTime animations:^{
                        [videoCell reSetAnimateImageFrame:self.startFrame percent:1.0];
                        self.view.backgroundColor = [UIColor blackColor];
                    } completion:^(BOOL finished) {
                        self.view.backgroundColor = [UIColor blackColor];
                    }];
                }
            }else {
                if(fabs(movedPoint.y) > 150 || fabs(velocity.y) > 550){
                    _startFrame = tempImageView.frame;
                    [self dismiss];
                }else{
                    [UIView animateWithDuration:kPhotoBrowserAnimateTime animations:^{
                        [photoCell reSetAnimateImageFrame:self.startFrame];
                        self.view.backgroundColor = [UIColor blackColor];
                    } completion:^(BOOL finished) {
                        self.view.backgroundColor = [UIColor blackColor];
                    }];
                }
            }
        }
            break;
        default:
            break;
    }
}

#pragma mark -- 交互动画

- (void)photoPreviewFisrtShowWithAnimated {
    if (_currentIndex > self.items.count) {
        _currentIndex = 0;  // fix error config currentIndex bug.
    }
    SKPhotoModel *model = [self.items objectAtIndex:_currentIndex];
    _firstImageLoaded = YES;
    UIImageView *tempImageView = [self tempImageViewFromContainerViewWithCurrentIndex:_currentIndex];
    UIView *cotainerView = model.containerView;
    CGRect rect = [cotainerView convertRect:[cotainerView bounds] toView:[UIApplication sharedApplication].delegate.window];
    [tempImageView setFrame:rect];
    [_collectionView setHidden:true];
    [self.view insertSubview:tempImageView atIndex:0];
    if (model.url) {
        UIImage *cacheImage = [[SDImageCache sharedImageCache] imageFromCacheForKey:[model.url absoluteString]];
        if(!cacheImage){
            _firstImageLoaded = NO;
            __weak typeof(self) weakself = self;
            __weak typeof(tempImageView) weaktempImageView = tempImageView;
            [[SDWebImageManager sharedManager] loadImageWithURL:model.url options:SDWebImageRetryFailed progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
            } completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
                [weakself hideLoading];
                weakself.firstImageLoaded = YES;
                weaktempImageView.image = image;
                if (weakself.firstImageAnimationEnd) {
                    [weakself firstShowAnimationWith:tempImageView firstImageLoaded:YES];
                }
            }];
        }
    }
    [self firstShowAnimationWith:tempImageView firstImageLoaded:_firstImageLoaded];
}

- (void)firstShowAnimationWith:(UIImageView *)tempImageView firstImageLoaded:(BOOL)firstImageLoaded{
    
    CGRect lastFrame = [self caculateLastFrameWithTempView:tempImageView firstImageLoaded:firstImageLoaded];
    _firstImageAnimationEnd = NO;
    CGFloat duration = kPhotoBrowserAnimateTime;
    if (!_enableFirstShowAnimation) {
        [tempImageView setFrame:lastFrame];
        duration = 0;
    }
    __weak typeof(self) weakself = self;
    [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [tempImageView setFrame:lastFrame];
        if (firstImageLoaded) {
            [self->_collectionView setAlpha:1];
        }
    } completion:^(BOOL finished) {
        weakself.firstImageAnimationEnd = YES;
        if (firstImageLoaded) {
            [weakself.collectionView setHidden:false];
            [tempImageView removeFromSuperview];
        } else {
            [weakself showLoading];
            if (weakself.firstImageLoaded) {
                [weakself hideLoading];
                [weakself firstShowAnimationWith:tempImageView firstImageLoaded:YES];
            }
        }
    }];
}

- (UIImageView *)tempImageViewFromContainerViewWithCurrentIndex:(NSInteger)currentIndex{
    UIImageView *imageView = [[UIImageView alloc] init];
    SKPhotoModel *model = [self.items objectAtIndex:_currentIndex];
    UIView *containerView = model.containerView;
    imageView.contentMode = containerView ? containerView.contentMode : UIViewContentModeScaleAspectFit;
    imageView.layer.cornerRadius = 0.001;
    imageView.clipsToBounds = true;
    
    UIImage *image = nil;
    if (model.localPhotoPath) {
        image = [UIImage imageWithContentsOfFile:model.localPhotoPath];
    } else if (model.url) {
        UIImage *cacheImage = [[SDImageCache sharedImageCache] imageFromCacheForKey:[model.url absoluteString]];
        if(cacheImage){
            image = cacheImage;
        }
    } else if (model.image) {
        image = model.image;
    }
    if (!image) {
        if([containerView isKindOfClass:[UIImageView class]]){
            image = [(UIImageView *)model.containerView image];
        }
    }
    imageView.image = image;
    if(imageView.image == nil){
        imageView.image = [UIImage sk_imageWithColor:UIColor.clearColor size:CGSizeMake(kScreenWidth, kScreenHeight)];
    }
    return imageView;
}

- (CGRect)caculateLastFrameWithTempView:(UIImageView *)tempImageView firstImageLoaded:(BOOL)firstImageLoaded {
    
    CGFloat width  = tempImageView.image.size.width;
    CGFloat height = tempImageView.image.size.height;
    if (width < 2) width = 10;
    if (height < 2) height = 10;
    CGRect lastFrame = CGRectZero;
    CGFloat imageWidth = self.view.frame.size.width;
    CGFloat imageHeight = floor((height / width) * imageWidth) ;// 向下取整
    if (height / width > self.view.frame.size.height / self.view.frame.size.width) { // 长图
        lastFrame = CGRectMake((self.view.frame.size.width - imageWidth)/2.0, 0 , imageWidth, imageHeight);
    } else {
        // 居中显示
        if (!firstImageLoaded && (width >= height) && (self.view.frame.size.width > width)) {
            imageWidth = width;
            imageHeight = height;
        }
        lastFrame = CGRectMake((self.view.frame.size.width - imageWidth)/2.0, (self.view.frame.size.height - imageHeight)/2.0, imageWidth, imageHeight);
    }
    return lastFrame;
}

- (void)sk_photoBrowserWillDismissWithAnimated:(UIImageView *)tempView photoModel:(SKPhotoModel *)model{
  
    _naviBar.hidden = YES;
    UIView *containerView = model.containerView;
    if(containerView == nil){
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.001 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
                self->_collectionView.alpha = 0.f;
                self.view.alpha = 0.f;
            } completion:^(BOOL finished) {
                self->_startFrame = CGRectZero;
                [self popOrDismiss];
            }];
        });
        return;
    }
    UIWindow *window = [UIApplication sharedApplication].delegate.window;
    __block CGRect rect = [containerView convertRect:[containerView bounds] toView:window];
    [self->_collectionView setHidden:true];
    if([self imageIsOutOfScreen:rect]){
        [UIView animateWithDuration:kPhotoBrowserAnimateTime delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            [tempView setAlpha:0.f];
        } completion:^(BOOL finished) {
            [tempView removeFromSuperview];
            self->_startFrame = CGRectZero;
            [self popOrDismiss];
        }];
    } else {
        CGRect lastFrame = [self caculateLastFrameWithTempView:tempView firstImageLoaded:YES];
        tempView.frame = lastFrame;
        if(!CGRectEqualToRect(self.startFrame, CGRectZero)){
            tempView.frame = self.startFrame;
        }
        [window addSubview:tempView];
        self->_startFrame = CGRectZero;
        [UIView animateWithDuration:kPhotoBrowserAnimateTime delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            [tempView setFrame:rect];
            self.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0];
        } completion:^(BOOL finished) {
            [tempView removeFromSuperview];
            [self popOrDismiss];
        }];
    }
}

- (void)select:(UIButton *)selectButton {
    
    selectButton.selected = !selectButton.isSelected;
    SKPhotoModel *model = [self.items objectAtIndex:_currentIndex];
    model.selected = selectButton.isSelected;
    
    if (selectButton.isSelected) {
        SKPhotoNavigationController *nav = (SKPhotoNavigationController *)self.navigationController;
        if (nav.currentSeletedLocalIdentifier.count >= nav.maxSelectPhotosCount+1) {
            [nav showMaxPhotosCountAlert];
            selectButton.selected = !selectButton.isSelected;
            model.selected = !model.isSelected;
            return;
        }
        if (self.selectItemBlock) {
            self.selectItemBlock(model);
        }
        [self showAnimationWith:selectButton];

    } else {
        if (self.cancelSelectItemBlock) {
            self.cancelSelectItemBlock(model);
        }
    }
    [self refreshTopBottomBarStatus];
}

- (void)showAnimationWith:(UIView *)view {
    
    [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut animations:^{
        [view.layer setValue:@(1.2) forKeyPath:@"transform.scale"];
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut animations:^{
            [view.layer setValue: @(0.90) forKeyPath:@"transform.scale"];
            
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut animations:^{
                [view.layer setValue:@(1.0) forKeyPath:@"transform.scale"];
            } completion:nil];
        }];
    }];
}

- (BOOL)imageIsOutOfScreen:(CGRect)rect{
   if(rect.origin.y > kScreenHeight ||
       rect.origin.y <= - rect.size.height ||
       rect.origin.x > kScreenWidth ||
       rect.origin.x <= - rect.size.width ){
        return true;
    }
    return false;
}

#pragma mark -- 完成选择

- (void)doneButtonClick:(UIButton *)sender {
    
    SKPhotoModel *model = [self.items objectAtIndex:_currentIndex];
    if (model.mediaType == SKAssetMediaTypeVideo) { // 视频
        NSString *filename = [model.asset valueForKey:@"filename"];
        NSLog(@"filename:%@",filename);
        SKPhotoNavigationController *nav = (SKPhotoNavigationController *)self.navigationController;
        [nav dismissViewControllerAnimated:YES completion:^{
            
            if (nav.pickerDelegate && [nav.pickerDelegate respondsToSelector:@selector(imagePickerController:didFinishPickVideo:sourceAssets:)]) {
                [nav.pickerDelegate imagePickerController:nav didFinishPickVideo:model sourceAssets:model.asset];
            }
        }];
        return;
    }
    
    SKPhotoNavigationController *nav = (SKPhotoNavigationController *)self.photoNavigationController;
    if (nav.currentSeletedItems.count == 0) { // 没有勾选的时候，默认选择当前的照片
        SKPhotoModel *model = [self.items objectAtIndex:_currentIndex];
        model.selected = YES;
        if (self.selectItemBlock) {
            self.selectItemBlock(model);
        }
    }
    [self popOrDismiss];
    [nav didSelectDoneEvent];
}

- (void)refreshCurrentIndexLabel {
    _currentIndexLabel.text = [NSString stringWithFormat:@"%zd/%zd",_currentIndex + 1,self.items.count];
}

- (void)refreshTopBottomBarStatus {
    
    SKPhotoModel *model = [self.items objectAtIndex:_currentIndex];
    SKPhotoNavigationController *nav = (SKPhotoNavigationController *)self.photoNavigationController;
    _selectButton.selected = model.isSelected;
    _selectButton.hidden = model.mediaType == SKAssetMediaTypeVideo ? YES : NO;
    if (nav.currentSeletedItems.count > 0) {
        NSString *numstring = [NSString stringWithFormat:@"完成(%tu)",nav.currentSeletedItems.count];
        [_doneButton setTitle:numstring forState:UIControlStateNormal];
        _tipBar.hidden = model.asset.mediaType == PHAssetMediaTypeVideo ? NO : YES;
    } else {
        [_doneButton setTitle:@"完成" forState:UIControlStateNormal];
        _tipBar.hidden = YES;
    }
    
    if (model.isSelected) {
        if (model.selectIndex > 0) {
            [_selectButton setTitle:[NSString stringWithFormat:@"%tu",model.selectIndex] forState:UIControlStateSelected];
        }
    } else {
        [_selectButton setTitle:nil forState:UIControlStateNormal];
    }
}

- (void)presentFromController:(UIViewController *)vc {
    if (vc && [vc isKindOfClass:[SKPhotoNavigationController class]]) {
        self.photoNavigationController = (SKPhotoNavigationController *)vc;
    }
    [vc presentViewController:self animated:NO completion:nil];
}

- (void)present {
   UIWindow *window = [UIApplication sharedApplication].delegate.window;
   [window.rootViewController presentViewController:self animated:NO completion:nil];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    CGFloat offSetWidth = scrollView.contentOffset.x;
    offSetWidth = offSetWidth +  ((self.view.frame.size.width + kPreviewPadding) * 0.5);
    NSInteger currentIndex = offSetWidth / (self.view.frame.size.width + kPreviewPadding);
    if (currentIndex < self.items.count && _currentIndex != currentIndex) {
        _currentIndex = currentIndex;
        if (self.fromPhotoPicker) {
            [self refreshTopBottomBarStatus];
        } else {
            [self refreshCurrentIndexLabel];
        }
    }
}

#pragma mark - UICollectionViewDataSource && UICollectionViewDelegate

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    return self.items.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    SKPhotoModel *model =  [self.items objectAtIndex:indexPath.item];
    if (model.mediaType == SKAssetMediaTypeVideo) { // 视频cell样式
        
        SKPreviewVideoCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([SKPreviewVideoCell class]) forIndexPath:indexPath];
        
        __weak typeof(self) weakself = self;
        cell.singleTapGestureBlock = ^(BOOL hideNav){
            __strong typeof(self) strongself = weakself;
            if (strongself) {
                strongself.isHideNavBar = hideNav;
                strongself->_naviBar.hidden = strongself.isHideNavBar;
                strongself->_photoBottomBar.hidden = strongself.isHideNavBar;
                
                SKPhotoNavigationController *nav = (SKPhotoNavigationController *)strongself.navigationController;
                if (nav.currentSeletedItems.count > 0) {
                    strongself->_tipBar.hidden = strongself.isHideNavBar;
                }
            }
        };
        cell.model = model;
        
        return cell;
    }
    
    // 图片cell
    SKPreviewPhotoCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([SKPreviewPhotoCell class]) forIndexPath:indexPath];
    
    __weak typeof(self) weakself = self;
    cell.singleTapGestureBlock = ^{
        __strong typeof(self) strongself = weakself;
        if (strongself) {
            strongself.isHideNavBar = !strongself.isHideNavBar;
            strongself->_naviBar.hidden = strongself.isHideNavBar;
            strongself->_photoBottomBar.hidden = strongself.isHideNavBar;
        }
    };
    
    SKPhotoNavigationController *nav = (SKPhotoNavigationController *)self.navigationController;
    cell.supportLivePhoto = nav.supportLivePhoto;
    cell.model = model;
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if ([cell isKindOfClass:[SKPreviewPhotoCell class]]) {
        [(SKPreviewPhotoCell *)cell resetSubViewsFrame];
        [(SKPreviewPhotoCell *)cell startPlayAnimationView];
        
    }
    if ([cell isKindOfClass:[SKPreviewVideoCell class]]) {
        [(SKPreviewVideoCell *)cell resetSubViewsFrame];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if ([cell isKindOfClass:[SKPreviewPhotoCell class]]) {
        [(SKPreviewPhotoCell *)cell resetSubViewsFrame];
        [(SKPreviewPhotoCell *)cell stopPlayAnimationView];
        
    }
    if ([cell isKindOfClass:[SKPreviewVideoCell class]]) {
        [(SKPreviewVideoCell *)cell resetSubViewsFrame];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
}

#pragma mark -- Lazy load

- (UICollectionView *)collectionView {
    
    if (!_collectionView) {
        
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc]init];
        layout.itemSize = CGSizeMake(kScreenWidth + kPreviewPadding, kScreenHeight);
        layout.minimumLineSpacing = 0;
        layout.minimumInteritemSpacing = 0;
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        
        UICollectionView *collectionView = [[UICollectionView alloc]initWithFrame:self.view.bounds collectionViewLayout:layout];
        collectionView.backgroundColor = [UIColor blackColor];
        collectionView.showsHorizontalScrollIndicator = YES;
        collectionView.showsVerticalScrollIndicator = NO;
        collectionView.dataSource = self;
        collectionView.delegate = self;
        collectionView.alwaysBounceHorizontal = NO;
        collectionView.bounces = YES;
        collectionView.pagingEnabled = YES;
        collectionView.contentSize = CGSizeMake(self.items.count * (kScreenWidth + kPreviewPadding),0);
        [self.view addSubview:collectionView];
        [self.view insertSubview:collectionView atIndex:0];
        [collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.view).insets(UIEdgeInsetsMake(0 , -kPreviewPadding / 2.0, 0,  - kPreviewPadding / 2.0));
        }];
        
        [collectionView registerClass:[SKPreviewPhotoCell class] forCellWithReuseIdentifier:NSStringFromClass([SKPreviewPhotoCell class])];
        [collectionView registerClass:[SKPreviewVideoCell class] forCellWithReuseIdentifier:NSStringFromClass([SKPreviewVideoCell class])];
        
        _collectionView = collectionView;
    }
    
    return _collectionView;
}

@end
