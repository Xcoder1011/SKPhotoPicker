//
//  SKPhotoPickerViewController.m
//  SKPhotoPicker_Example
//
//  Created by shangkun on 2018/10/9.
//  Copyright © 2018年 Xcoder1011. All rights reserved.
//

#import "SKPhotoPickerViewController.h"
#import "SKPhotoHeader.h"
#import "SKPhotoCell.h"
#if __has_include(<Masonry/Masonry.h>)
#import <Masonry/Masonry.h>
#else
#import "Masonry.h"
#endif

@interface SKPhotoPickerViewController () <UICollectionViewDelegate, UICollectionViewDataSource,SKPhotoCellDelegate>

@property (nonatomic, strong) UIView *bottomBar;
@property (nonatomic, strong) UIButton *doneBtn;
@property (nonatomic, strong) UIButton *previewBtn;
@property (nonatomic, strong) NSMutableArray <NSIndexPath *> *seletedIndexPaths;
@property (nonatomic, strong) UICollectionView *collectionView;

@end

@implementation SKPhotoPickerViewController

- (void)viewDidLoad {
   
    [super viewDidLoad];
    
    [self addNavBarButtons];
    
    [self addBottomBar];
    
    [self initialConfig];
    
    [self preparedPhotos];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refreshBottomBarStatus];
}

- (void)initialConfig {
    self.view.backgroundColor = [UIColor whiteColor];
    _columnNumber = 4;
    _shouldScrollToBottom = NO;
}

- (void)preparedPhotos {
    
    [self.collectionView performBatchUpdates:^{
        [self.collectionView reloadData];
    } completion:^(BOOL finished) {
        [self scrollToBottom];
    }];
}

- (void)scrollToBottom {
    
    if (self.items && self.items.count > 0 && self.shouldScrollToBottom) {
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem: self.items.count - 1 inSection:0] atScrollPosition:UICollectionViewScrollPositionBottom animated:NO];
    }
}

- (void)addBottomBar {
    
    CGFloat height = sk_isIPhoneXSeries() ? (44 + kSafeBottomViewPadding) : 44;
    CGFloat offsetY = sk_isIPhoneXSeries() ?  (kSafeBottomViewPadding/2.0) : 0;
    _bottomBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, height)];
    _bottomBar.backgroundColor = kBottomBarColor;
    [self.view addSubview:_bottomBar];
    __weak typeof(self) weakself = self;
    UIButton * (^quickCreatBtn)(UIColor *backgroundColor, NSString *title, BOOL enabled, UIFont *font, SEL sel) = ^(UIColor *backgroundColor, NSString *title, BOOL enabled, UIFont *font, SEL sel) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn setBackgroundColor:backgroundColor];
        [btn.titleLabel setFont:font];
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [btn setTitle:title forState:UIControlStateNormal];
        btn.enabled = enabled;
        btn.frame = CGRectMake(0, 0, 60, 32);
        [btn addTarget:self action:sel forControlEvents:UIControlEventTouchUpInside];
        [weakself.bottomBar addSubview:btn];
        return btn;
    };
    
    SKPhotoNavigationController *nav = (SKPhotoNavigationController *)self.navigationController;
    if (nav.chooseMode == SKChoosePhotoModeSupportCamera) { // 拍照模式
        _doneBtn = quickCreatBtn(kGreenColor, @"下一步", YES, [UIFont systemFontOfSize:14], @selector(previewButtonAct:)); // nextBtnAct
    } else {
        _doneBtn = quickCreatBtn(kGreenColor, @"完成", YES, [UIFont systemFontOfSize:14], @selector(doneButtonAct:));
    }
    _doneBtn.layer.cornerRadius = 4;
    _doneBtn.layer.masksToBounds = YES;
    
    _previewBtn = quickCreatBtn([UIColor clearColor], @"预览", YES, [UIFont systemFontOfSize:17], @selector(previewButtonAct:));
 
    [_bottomBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.view.mas_right).offset(0);
        make.left.equalTo(self.view.mas_left).offset(0);
        make.bottom.equalTo(self.view.mas_bottom).offset(0);
        make.height.mas_equalTo(height);
    }];
    
    [_doneBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(_bottomBar.mas_right).offset(-10);
        make.centerY.equalTo(_bottomBar.mas_centerY).offset(-offsetY);
        // 拍照模式
        if (nav.chooseMode == SKChoosePhotoModeSupportCamera) {
            make.width.mas_equalTo(@80);
        } else {
            make.width.mas_equalTo(@60);
        }
        make.height.mas_equalTo(@30);
    }];
    
    [_previewBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_bottomBar.mas_left).offset(5);
        make.centerY.equalTo(_bottomBar.mas_centerY).offset(-offsetY);
        make.width.mas_equalTo(@60);
        make.height.mas_equalTo(@32);
    }];
}

- (void)doneButtonAct:(UIButton *)sender {
    
    SKPhotoNavigationController *nav = (SKPhotoNavigationController *)self.navigationController;
    if (nav.chooseMode == SKChoosePhotoModeSupportCamera) { // 拍照模式
        [self previewButtonAct:nil];
    } else {
        [nav didSelectDoneEvent];
    }
}

- (void)previewButtonAct:(UIButton *)sender {
    
    SKPhotoPreviewController *controller = [[SKPhotoPreviewController alloc] init];
    __weak typeof(self) weakself = self;
    controller.cancelSelectItemBlock = ^(SKPhotoModel *item) {
        [weakself didCancelSelectItemEvent:item];
    };
    controller.selectItemBlock = ^(SKPhotoModel *item) {
        [weakself selectItemEvent:item];
    };
    controller.currentIndex = 0;
    controller.fromPhotoPicker = YES;
    
    SKPhotoNavigationController *nav = (SKPhotoNavigationController *)self.navigationController;
    if (nav.currentSeletedItems && nav.currentSeletedItems > 0) {
        NSArray *visibleCells = self.collectionView.visibleCells;
        for (NSInteger i = 0; i < nav.currentSeletedItems.count; i++) {
            SKPhotoModel *model = nav.currentSeletedItems[i];
            model.containerView = nil;
            for (NSInteger j = 0; j < visibleCells.count; j++) {
                UICollectionViewCell *cell = visibleCells[j];
                if ([cell isKindOfClass:[SKPhotoBaseCell class]]) {
                     SKPhotoBaseCell *bcell = (SKPhotoBaseCell *)cell;
                    if(model == bcell.tempModel){
                        model.containerView = bcell.imageView;
                        break;
                    }
                }
            }
        }
        controller.items = [NSMutableArray arrayWithArray:nav.currentSeletedItems];
    }
    [controller presentFromController:nav];
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (void)addNavBarButtons {
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btn setTitle:@"取消" forState:UIControlStateNormal];
    [btn.titleLabel setFont:[UIFont systemFontOfSize:16]];
    NSMutableDictionary *attrDict = [NSMutableDictionary dictionary];
    attrDict[NSFontAttributeName] = [UIFont systemFontOfSize:16];
    CGFloat width = [btn.titleLabel.text sizeWithAttributes:attrDict].width + 10;
    btn.frame = CGRectMake(0, 0, width, 44);
    [btn addTarget:self action:@selector(cancelBtnTouched) forControlEvents:UIControlEventTouchUpInside];
    btn.exclusiveTouch = YES;
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:btn];
    self.navigationItem.rightBarButtonItem = item;
}

- (void)cancelBtnTouched {
    SKPhotoNavigationController *nav = (SKPhotoNavigationController *)self.navigationController;
    if (nav.pickerDelegate && [nav.pickerDelegate respondsToSelector:@selector(imagePickerController:willDismissViewControllerWithItems:)]) {
        [nav.pickerDelegate imagePickerController:nav willDismissViewControllerWithItems:[nav.currentSeletedItems copy]];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UICollectionViewDataSource && UICollectionViewDelegate

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    SKPhotoNavigationController *nav = (SKPhotoNavigationController *)self.navigationController;
    if (nav.chooseMode == SKChoosePhotoModeSupportCamera) { // 拍照模式
        return self.items.count + 1;
    }
    return self.items.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    SKPhotoNavigationController *nav = (SKPhotoNavigationController *)self.navigationController;
    SKPhotoModel *model = [self.items objectAtIndex:indexPath.item];
    if (nav.chooseMode == SKChoosePhotoModeSupportCamera) { // 拍照模式
        if (indexPath.item == 0) { // 第一个
            SKCameraCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([SKCameraCell class]) forIndexPath:indexPath];
            return cell;
        }
        model = [self.items objectAtIndex:indexPath.item - 1];
    }
    
    if (model.mediaType == SKAssetMediaTypeVideo) { // 视频cell
        SKPhotoNavigationController *nav = (SKPhotoNavigationController *)self.navigationController;
        SKVideoCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([SKVideoCell class]) forIndexPath:indexPath];
        cell.indexPath = indexPath;
        cell.navigation = nav;
        cell.model = model;
        return cell;
    }
    
    // 照片cell
    SKPhotoCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([SKPhotoCell class]) forIndexPath:indexPath];
    cell.navigation = nav;
    cell.delegate = self;
    cell.indexPath = indexPath;
    cell.model = model;
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    BOOL isNormal = YES;
    SKPhotoNavigationController *nav = (SKPhotoNavigationController *)self.navigationController;
    if (nav.chooseMode == SKChoosePhotoModeSupportCamera) { // 拍照模式
        isNormal = NO;
        if (indexPath.item == 0) { // 第一个
            NSLog(@"第一个 拍照模式");
            NSInteger maxSelectPhotosCount = nav.maxSelectPhotosCount;
            maxSelectPhotosCount = maxSelectPhotosCount - nav.currentSeletedItems.count;
            if (maxSelectPhotosCount <= 0) {
                [nav showMaxPhotosCountAlert];
                return;
            }
            NSLog(@"拍照");
            return;
        }
    }
    
    NSArray *visibleCells = self.collectionView.visibleCells;
    for (NSInteger i = 0; i < self.items.count; i++) {
        SKPhotoModel *model = self.items[i];
        model.containerView = nil;
        for (NSInteger j = 0; j < visibleCells.count; j++) {
            UICollectionViewCell *cell = visibleCells[j];
            if ([cell isKindOfClass:[SKPhotoBaseCell class]]) {
                SKPhotoBaseCell *bcell = (SKPhotoBaseCell *)cell;
                if(model == bcell.tempModel){
                    model.containerView = bcell.imageView;
                    break;
                }
            }
        }
    }
    
    SKPhotoPreviewController *controller = [[SKPhotoPreviewController alloc] init];
    __weak typeof(self) weakself = self;
    controller.cancelSelectItemBlock = ^(SKPhotoModel *item) {
        [weakself didCancelSelectItemEvent:item];
    };
    controller.selectItemBlock = ^(SKPhotoModel *item) {
        [weakself selectItemEvent:item];
    };
    controller.fromPhotoPicker = YES;
    controller.currentIndex = isNormal ? indexPath.item : indexPath.item-1;
    controller.items = self.items;
    [controller presentFromController:nav];
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if ([cell isKindOfClass:[SKVideoCell class]]) {
        SKVideoCell *cell1 = (SKVideoCell *)cell;
        [cell1 reloadData];
    }
    
    if ([cell isKindOfClass:[SKPhotoCell class]]) {
        SKPhotoCell *cell1 = (SKPhotoCell *)cell;
        [cell1 reloadData];
    }
}

#pragma mark - SKPhotoCellDelegate

- (void)pickerPhotoCell:(SKPhotoCell *)cell didSelectItem:(SKPhotoModel *)item indexPath:(NSIndexPath *)indexPath {
    
    SKPhotoNavigationController *nav = (SKPhotoNavigationController *)self.navigationController;
    if ([nav.currentSeletedLocalIdentifier containsObject:item.localIdentifier]) {
        NSLog(@"发生错误了");
        return;
    }
    [self.seletedIndexPaths addObject:indexPath];
    [self selectItemEvent:item];
}

- (void)pickerPhotoCell:(SKPhotoCell *)cell didCancelSelectItem:(SKPhotoModel *)item indexPath:(NSIndexPath *)indexPath{
    
    if ([self.seletedIndexPaths containsObject:indexPath]) {
        [self.seletedIndexPaths removeObject:indexPath];
    }
    [self didCancelSelectItemEvent:item];
}

#pragma mark -- Private Method

- (void)refreshBottomBarStatus {
    
    SKPhotoNavigationController *nav = (SKPhotoNavigationController *)self.navigationController;
    self.doneBtn.enabled = nav.currentSeletedItems.count > 0 ? YES : NO;
    self.previewBtn.enabled = nav.currentSeletedItems.count > 0 ? YES : NO;
    self.doneBtn.alpha = nav.currentSeletedItems.count > 0 ? 1.0 : 0.4;
    self.previewBtn.alpha = nav.currentSeletedItems.count > 0 ? 1.0 : 0.4;
    
    if (nav.chooseMode == SKChoosePhotoModeSupportCamera) { // 拍照模式
        if (nav.currentSeletedItems.count > 0) {
            NSString *numstring = [NSString stringWithFormat:@"下一步(%tu)",nav.currentSeletedItems.count];
            [self.doneBtn setTitle:numstring forState:UIControlStateNormal];
        } else {
            [self.doneBtn setTitle:@"下一步" forState:UIControlStateNormal];
        }
    } else {
        if (nav.currentSeletedItems.count > 0) {
            NSString *numstring = [NSString stringWithFormat:@"完成(%tu)",nav.currentSeletedItems.count];
            [self.doneBtn setTitle:numstring forState:UIControlStateNormal];
        } else {
            [self.doneBtn setTitle:@"完成" forState:UIControlStateNormal];
        }
    }
}

- (void)selectItemEvent:(SKPhotoModel *)item {
    
    SKPhotoNavigationController *nav = (SKPhotoNavigationController *)self.navigationController;
    if ([nav.currentSeletedLocalIdentifier containsObject:item.localIdentifier]) {
        return;
    }
    [nav.currentSeletedLocalIdentifier addObject:item.localIdentifier];
    [nav.currentSeletedItems addObject:item];
    
    [nav.currentSeletedItems enumerateObjectsUsingBlock:^(SKPhotoModel * _Nonnull  obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.selectIndex = idx + 1;
    }];
    
    [self.collectionView.visibleCells enumerateObjectsUsingBlock:^(__kindof UICollectionViewCell * _Nonnull cell, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([cell isKindOfClass:[SKPhotoCell class]])  [(SKPhotoCell *)cell reloadData];
        if ([cell isKindOfClass:[SKVideoCell class]])  [(SKVideoCell *)cell reloadData];
    }];
    
    [self refreshBottomBarStatus];
}

- (void)didCancelSelectItemEvent:(SKPhotoModel *)item {
    
    SKPhotoNavigationController *nav = (SKPhotoNavigationController *)self.navigationController;
    if ([nav.currentSeletedLocalIdentifier containsObject:item.localIdentifier]) {
        __block NSUInteger tempIndex = 0;
        [nav.currentSeletedItems enumerateObjectsUsingBlock:^(SKPhotoModel * _Nonnull  obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj.localIdentifier isEqualToString:item.localIdentifier]) {
                tempIndex = idx;
                *stop = YES;
            }
        }];
        [nav.currentSeletedItems removeObjectAtIndex:tempIndex];
        [nav.currentSeletedLocalIdentifier removeObject:item.localIdentifier];
    }
    
    if ([nav.currentSeletedItems containsObject:item]) {
        [nav.currentSeletedItems removeObject:item];
    }
    [nav.currentSeletedItems enumerateObjectsUsingBlock:^(SKPhotoModel * _Nonnull  obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.selectIndex = idx + 1;
    }];
    
    [self.collectionView.visibleCells enumerateObjectsUsingBlock:^(__kindof UICollectionViewCell * _Nonnull cell, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([cell isKindOfClass:[SKPhotoCell class]])  [(SKPhotoCell *)cell reloadData];
        if ([cell isKindOfClass:[SKVideoCell class]])  [(SKVideoCell *)cell reloadData];
    }];
    // 不记录当前选中的indexPaths 会导致在屏幕外的cell 角标数字不能实时刷新
    [self.collectionView reloadItemsAtIndexPaths:[self.seletedIndexPaths copy]];
    [self refreshBottomBarStatus];
}

- (UICollectionView *)collectionView {
    
    if (!_collectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc]init];
        CGFloat margin = 5;
        CGFloat width = (kScreenWidth - (self.columnNumber + 1) * margin) / self.columnNumber;
        CGFloat height = width;
        layout.itemSize = CGSizeMake(width, height);
        layout.minimumLineSpacing = margin;
        layout.minimumInteritemSpacing = margin;
        layout.sectionInset = UIEdgeInsetsMake(5, 5, 5, 5);
        
        UICollectionView *collectionView = [[UICollectionView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) collectionViewLayout:layout];
        collectionView.backgroundColor = [UIColor whiteColor];
        collectionView.dataSource = self;
        collectionView.delegate = self;
        collectionView.alwaysBounceHorizontal = NO;
        [self.view addSubview:collectionView];
        CGFloat padding = sk_isIPhoneXSeries() ? (44 + kSafeBottomViewPadding) : 44;
        [collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.left.right.equalTo(self.view).offset(0);
            make.bottom.equalTo(self.view.mas_bottom).offset(-padding);
        }];
        
        [collectionView registerClass:[SKPhotoCell class] forCellWithReuseIdentifier:NSStringFromClass([SKPhotoCell class])];
        [collectionView registerClass:[SKVideoCell class] forCellWithReuseIdentifier:NSStringFromClass([SKVideoCell class])];
        [collectionView registerClass:[SKCameraCell class] forCellWithReuseIdentifier:NSStringFromClass([SKCameraCell class])];

        if (@available(iOS 11.0, *)) {
            collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        } else {
            self.automaticallyAdjustsScrollViewInsets = NO;
        }
        CGFloat navAndStatusHeight = (44 + [[UIApplication sharedApplication] statusBarFrame].size.height);
        collectionView.contentInset = UIEdgeInsetsMake(navAndStatusHeight, 0, 0, 0);
        collectionView.scrollIndicatorInsets = collectionView.contentInset;
        _collectionView = collectionView;
    }
    return _collectionView;
}

- (NSMutableArray *)items {
    
    if (!_items) {
        _items = @[].mutableCopy;
    }
    return _items;
}

- (NSMutableArray<NSIndexPath *> *)seletedIndexPaths {
    
    if (!_seletedIndexPaths) {
        _seletedIndexPaths = @[].mutableCopy;
    }
    return _seletedIndexPaths;
}

@end
