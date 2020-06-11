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
    
    _doneBtn = quickCreatBtn(kGreenColor, @"完成", YES, [UIFont systemFontOfSize:14], @selector(doneButtonAct:));
    _previewBtn = quickCreatBtn([UIColor clearColor], @"预览", YES, [UIFont systemFontOfSize:17], @selector(previewButtonAct:));
    
    _doneBtn.layer.cornerRadius = 4;
    _doneBtn.layer.masksToBounds = YES;
    
    [_bottomBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.view.mas_right).offset(0);
        make.left.equalTo(self.view.mas_left).offset(0);
        make.bottom.equalTo(self.view.mas_bottom).offset(0);
        make.height.mas_equalTo(height);
    }];
    
    [_doneBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(_bottomBar.mas_right).offset(-10);
        make.centerY.equalTo(_bottomBar.mas_centerY).offset(-offsetY);;
        make.width.mas_equalTo(@60);
        make.height.mas_equalTo(@30);
    }];
    
    [_previewBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_bottomBar.mas_left).offset(5);
        make.centerY.equalTo(_bottomBar.mas_centerY).offset( -offsetY);
        make.width.mas_equalTo(@60);
        make.height.mas_equalTo(@32);
    }];
}

- (void)doneButtonAct:(UIButton *)sender {
    
    SKPhotoNavigationController *nav = (SKPhotoNavigationController *)self.navigationController;
    [nav didSelectDoneEvent];
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
        controller.items = [NSMutableArray arrayWithArray:nav.currentSeletedItems];
    }
    
    [self.navigationController pushViewController:controller animated:YES];
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
    
    [self dismissViewControllerAnimated:YES completion:nil];
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
        
        self.automaticallyAdjustsScrollViewInsets = NO;
        _collectionView = collectionView;
    }
    
    return _collectionView;
}


#pragma mark - UICollectionViewDataSource && UICollectionViewDelegate

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    return self.items.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    SKPhotoModel *model = [self.items objectAtIndex:indexPath.item];
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
    SKPhotoNavigationController *nav = (SKPhotoNavigationController *)self.navigationController;
    cell.navigation = nav;
    cell.delegate = self;
    cell.indexPath = indexPath;
    cell.model = model;
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    SKPhotoPreviewController *controller = [[SKPhotoPreviewController alloc] init];
    __weak typeof(self) weakself = self;
    controller.cancelSelectItemBlock = ^(SKPhotoModel *item) {
        [weakself didCancelSelectItemEvent:item];
    };
    controller.selectItemBlock = ^(SKPhotoModel *item) {
        [weakself selectItemEvent:item];
    };
    controller.currentIndex = indexPath.row;
    controller.fromPhotoPicker = YES;
    controller.items = self.items;
    [self.navigationController pushViewController:controller animated:YES];
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

- (void)refreshBottomBarStatus {
    
    SKPhotoNavigationController *nav = (SKPhotoNavigationController *)self.navigationController;
    
    self.doneBtn.enabled = nav.currentSeletedItems.count > 0 ? YES : NO;
    self.previewBtn.enabled = nav.currentSeletedItems.count > 0 ? YES : NO;
    
    self.doneBtn.alpha = nav.currentSeletedItems.count > 0 ? 1.0 : 0.4;
    self.previewBtn.alpha = nav.currentSeletedItems.count > 0 ? 1.0 : 0.4;
    
    if (nav.currentSeletedItems.count > 0) {
        NSString *numstring = [NSString stringWithFormat:@"完成(%tu)",nav.currentSeletedItems.count];
        [self.doneBtn setTitle:numstring forState:UIControlStateNormal];
    } else {
        [self.doneBtn setTitle:@"完成" forState:UIControlStateNormal];
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
    NSLog(@"item.localIdentifier = %@",item.localIdentifier);
    [self selectItemEvent:item];
}

- (void)pickerPhotoCell:(SKPhotoCell *)cell didCancelSelectItem:(SKPhotoModel *)item indexPath:(NSIndexPath *)indexPath{
    
    NSLog(@"item.localIdentifier = %@",item.localIdentifier);
    
    if ([self.seletedIndexPaths containsObject:indexPath]) {
        [self.seletedIndexPaths removeObject:indexPath];
    }
    
    [self didCancelSelectItemEvent:item];
}


#pragma mark -- PrivateMthod

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
