//
//  SKPhotoAlbumListController.m
//  SKPhotoPicker_Example
//
//  Created by shangkun on 2018/10/9.
//  Copyright © 2018年 Xcoder1011. All rights reserved.
//

#import "SKPhotoAlbumListController.h"
#import "SKPhotoNavigationController.h"
#import "SKPhotoPickerViewController.h"
#import "SKPhotoManager.h"
#import "SKPreviewPhotoCell.h"
#if __has_include(<Masonry/Masonry.h>)
#import <Masonry/Masonry.h>
#else
#import "Masonry.h"
#endif

static CGFloat const cellHeight = 70.f;

@interface SKPhotoAlbumListController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableview;
@property (nonatomic, strong) NSMutableArray<SKAlbumModel *> *albumsList;
@end

@implementation SKPhotoAlbumListController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"相册";
    self.view.backgroundColor = [UIColor whiteColor];
    [self addNavBarButtons];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self preparedData];
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (void)preparedData {
    SKPhotoNavigationController *nav = (SKPhotoNavigationController *)self.navigationController;
    if (!_albumsList && nav.albumsList && nav.albumsList > 0) {
        _albumsList = [[NSMutableArray alloc] initWithArray:nav.albumsList];
        [self.tableview reloadData];
    }
    if (_albumsList.count > 0) {
        SKPhotoNavigationController *nav = (SKPhotoNavigationController *)self.navigationController;
        if (nav.currentSeletedLocalIdentifier && nav.currentSeletedLocalIdentifier > 0) {
            [_albumsList enumerateObjectsUsingBlock:^(SKAlbumModel * _Nonnull albumModel, NSUInteger idx, BOOL * _Nonnull stop) {
                [albumModel.items enumerateObjectsUsingBlock:^(SKPhotoModel * _Nonnull photoModel, NSUInteger idx, BOOL * _Nonnull stop) {
                    if ([nav.currentSeletedLocalIdentifier containsObject:photoModel.localIdentifier]) {
                        NSUInteger index = [nav.currentSeletedLocalIdentifier indexOfObject:photoModel.localIdentifier];
                        SKPhotoModel * tempModel = [nav.currentSeletedItems objectAtIndex:index];
                        photoModel.selected = tempModel.isSelected;
                        photoModel.selectIndex = tempModel.selectIndex;
                        [nav.currentSeletedItems replaceObjectAtIndex:index withObject:photoModel];
                    } else {
                        photoModel.selected = NO;
                        photoModel.selectIndex = 0;
                    }
                }];
            }];
        }
        [self.tableview reloadData];
    }
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

#pragma mark - UITableViewDataSource & UITableViewDelegate

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    SKAlbumListPhotoCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([SKAlbumListPhotoCell class])];
    SKAlbumModel * model = [_albumsList objectAtIndex:indexPath.row];
    cell.model = model;
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _albumsList.count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    SKAlbumModel * model = [_albumsList objectAtIndex:indexPath.row];
    SKPhotoPickerViewController *controller = [[SKPhotoPickerViewController alloc] init];
    controller.title = model.name;
    controller.items = [model.items mutableCopy];
    [self.navigationController pushViewController:controller animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return cellHeight;
}

- (UITableView *)tableview {
    if (!_tableview) {
        _tableview = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        _tableview.delegate = self;
        _tableview.dataSource = self;
        [self.view addSubview:_tableview];
        [_tableview mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.view).insets(UIEdgeInsetsZero);
        }];
        if (@available(iOS 11.0, *)) {
            _tableview.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        } else {
            self.automaticallyAdjustsScrollViewInsets = NO;
        }
        CGFloat navAndStatusHeight = (44 + [[UIApplication sharedApplication] statusBarFrame].size.height);
        _tableview.contentInset = UIEdgeInsetsMake(navAndStatusHeight, 0, 0, 0);
        _tableview.scrollIndicatorInsets = _tableview.contentInset;
        _tableview.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        [_tableview registerClass:[SKAlbumListPhotoCell class] forCellReuseIdentifier:NSStringFromClass([SKAlbumListPhotoCell class])];
    }
    return _tableview;
}


@end

