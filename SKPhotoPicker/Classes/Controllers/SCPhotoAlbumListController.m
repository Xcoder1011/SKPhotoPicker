//
//  SCPhotoAlbumListController.m
//  SuperCoach
//
//  Created by shangkun on 2018/9/7.
//  Copyright © 2018年 Lin Feihong. All rights reserved.
//

#import "SCPhotoAlbumListController.h"
#import "SCPhotoNavigationController.h"
#import "SCPhotoPickerViewController.h"
#import "SCPhotoManager.h"
#import "SCPreviewPhotoCell.h"

static CGFloat const cellHeight = 70.f;

@interface SCPhotoAlbumListController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableview;
@property (nonatomic, strong) NSMutableArray<SCAlbumModel *> *albumsList;
@end

@implementation SCPhotoAlbumListController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"相册";
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = [UIColor whiteColor];
    [self addNavBarButtons];
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    [self preparedData];
}

- (void)preparedData {
    
    SCPhotoNavigationController *nav = (SCPhotoNavigationController *)self.navigationController;
    if (!_albumsList && nav.albumsList && nav.albumsList > 0) {
        _albumsList = [[NSMutableArray alloc] initWithArray:nav.albumsList];
        [self.tableview reloadData];
    }
    if (_albumsList.count > 0) {
        
        SCPhotoNavigationController *nav = (SCPhotoNavigationController *)self.navigationController;
        
        if (nav.currentSeletedLocalIdentifier && nav.currentSeletedLocalIdentifier > 0) {
            
            [_albumsList enumerateObjectsUsingBlock:^(SCAlbumModel * _Nonnull albumModel, NSUInteger idx, BOOL * _Nonnull stop) {
                
                [albumModel.items enumerateObjectsUsingBlock:^(SCPhotoModel * _Nonnull photoModel, NSUInteger idx, BOOL * _Nonnull stop) {
                    
                    if ([nav.currentSeletedLocalIdentifier containsObject:photoModel.localIdentifier]) {
                        NSUInteger index = [nav.currentSeletedLocalIdentifier indexOfObject:photoModel.localIdentifier];
                        SCPhotoModel * tempModel = [nav.currentSeletedItems objectAtIndex:index];
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
    btn.frame = CGRectMake(0, 0, 44, 44);
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btn setTitle:@"取消" forState:UIControlStateNormal];
    [btn.titleLabel setFont:[UIFont systemFontOfSize:16]];
    btn.width = [btn.titleLabel.text sizeWithFont:[UIFont systemFontOfSize:16]].width + 10;
    [btn addTarget:self action:@selector(cancelBtnTouched) forControlEvents:UIControlEventTouchUpInside];
    btn.exclusiveTouch = YES;
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:btn];
    self.navigationItem.rightBarButtonItem = item;
}

- (void)cancelBtnTouched {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITableViewDataSource & UITableViewDelegate

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  
    SCAlbumListPhotoCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([SCAlbumListPhotoCell class])];
    SCAlbumModel * model = [_albumsList objectAtIndex:indexPath.row];
    cell.model = model;
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return _albumsList.count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    SCAlbumModel * model = [_albumsList objectAtIndex:indexPath.row];
    SCPhotoPickerViewController *controller = [[SCPhotoPickerViewController alloc] init];
    controller.title = model.name;
    controller.items = [model.items mutableCopy];
    //controller.seletedItems = [model.selectedItems mutableCopy];
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
        self.automaticallyAdjustsScrollViewInsets = NO;
        _tableview.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        [_tableview registerClass:[SCAlbumListPhotoCell class] forCellReuseIdentifier:NSStringFromClass([SCAlbumListPhotoCell class])];
    }
    return _tableview;
}


@end
