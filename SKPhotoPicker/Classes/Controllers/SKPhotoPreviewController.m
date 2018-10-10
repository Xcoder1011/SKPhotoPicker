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
@interface SKPhotoPreviewController () <UICollectionViewDelegate, UICollectionViewDataSource>
{
    UIView *_naviBar;
    
    UIButton *_backButton;
    UIButton *_selectButton;
    
    UIView *_photoBottomBar;
    UIButton *_doneButton;
    
    UIView *_tipBar;
    UILabel *_tipLabel;
}

@property (nonatomic, strong) UICollectionView *collectionView;

@property (nonatomic, assign) BOOL isHideNavBar;

@end

@implementation SKPhotoPreviewController

#pragma mark -- Life Cycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES];
    [UIApplication sharedApplication].statusBarHidden = YES;
    if (self.currentIndex >= 0) [self.collectionView setContentOffset:CGPointMake((self.view.frame.size.width + kPreviewPadding) * self.currentIndex, 0) animated:NO];
    [self refreshTopBottomBarStatus];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO];
    [UIApplication sharedApplication].statusBarHidden = NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
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
    
    _naviBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 64)];
    _naviBar.backgroundColor = kBarTintColor;
    
    _backButton = [[UIButton alloc] initWithFrame:CGRectMake(10, 12, 24, 40)];
    [_backButton setImage:[UIImage imageNamedFromSKBundle:@"arrow_left_white"] forState:UIControlStateNormal];
    [_backButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_backButton addTarget:self action:@selector(backButtonClick) forControlEvents:UIControlEventTouchUpInside];
    
    _selectButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 56/2.0 - 10, 18, 56/2.0, 56/2.0)];
    [_selectButton setBackgroundImage:[UIImage imageNamedFromSKBundle:@"select_white"] forState:UIControlStateNormal];
    [_selectButton setBackgroundImage:[UIImage imageNamedFromSKBundle:@"picture_select_big"] forState:UIControlStateSelected];
    [_selectButton addTarget:self action:@selector(select:) forControlEvents:UIControlEventTouchUpInside];
    
    _selectButton.hidden = NO;
    
    [_naviBar addSubview:_selectButton];
    [_naviBar addSubview:_backButton];
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
    
    _photoBottomBar = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 44, self.view.frame.size.width, 44)];
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
    [_naviBar addSubview:_backButton];
    [self.view addSubview:_photoBottomBar];
}

- (void)backButtonClick {
    if (self.navigationController.childViewControllers.count < 2) {
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)select:(UIButton *)selectButton {
    
    selectButton.selected = !selectButton.isSelected;
    SKPhotoModel *model = [self.items objectAtIndex:_currentIndex];
    model.selected = selectButton.isSelected;
    
    if (selectButton.isSelected) {
        
        SKPhotoNavigationController *nav = (SKPhotoNavigationController *)self.navigationController;
        if (nav.currentSeletedLocalIdentifier.count == nav.maxSelectPhotosCount) {
            [nav showMaxPhotosCountAlert];
            selectButton.selected = !selectButton.isSelected;
            model.selected = model.isSelected;
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
        [view.layer setValue:@(1.2) forKeyPath:@"transform.SKale"];
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut animations:^{
            [view.layer setValue: @(0.90) forKeyPath:@"transform.SKale"];
            
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut animations:^{
                [view.layer setValue:@(1.0) forKeyPath:@"transform.SKale"];
            } completion:nil];
        }];
    }];
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
    
    SKPhotoNavigationController *nav = (SKPhotoNavigationController *)self.navigationController;
    [nav didSelectDoneEvent];
}


- (void)refreshTopBottomBarStatus {
    
    SKPhotoModel *model = [self.items objectAtIndex:_currentIndex];
    
    _selectButton.hidden = model.mediaType == SKAssetMediaTypeVideo ? YES : NO;
    
    _selectButton.selected = model.isSelected;
    
    if (model.isSelected) {
        if (model.selectIndex > 0) {
            [_selectButton setTitle:[NSString stringWithFormat:@"%tu",model.selectIndex] forState:UIControlStateSelected];
        }
    } else {
        [_selectButton setTitle:nil forState:UIControlStateNormal];
    }
    
    SKPhotoNavigationController *nav = (SKPhotoNavigationController *)self.navigationController;
    if (nav.currentSeletedItems.count > 0) {
        NSString *numstring = [NSString stringWithFormat:@"完成(%tu)",nav.currentSeletedItems.count];
        [_doneButton setTitle:numstring forState:UIControlStateNormal];
        _tipBar.hidden = model.asset.mediaType == PHAssetMediaTypeVideo ? NO : YES;
    } else {
        [_doneButton setTitle:@"完成" forState:UIControlStateNormal];
        _tipBar.hidden = YES;
    }
}


#pragma mark - UIScrollViewDelegate

- (void)SKrollViewDidScroll:(UIScrollView *)SKrollView {
    
    CGFloat offSetWidth = SKrollView.contentOffset.x;
    offSetWidth = offSetWidth +  ((self.view.frame.size.width + kPreviewPadding) * 0.5);
    NSInteger currentIndex = offSetWidth / (self.view.frame.size.width + kPreviewPadding);
    if (currentIndex < self.items.count && _currentIndex != currentIndex) {
        _currentIndex = currentIndex;
        [self refreshTopBottomBarStatus];
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
