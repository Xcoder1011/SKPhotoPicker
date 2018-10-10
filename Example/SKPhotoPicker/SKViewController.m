//
//  SKViewController.m
//  SKPhotoPicker
//
//  Created by Xcoder1011 on 10/09/2018.
//  Copyright (c) 2018 Xcoder1011. All rights reserved.
//

#import "SKViewController.h"
#import <SKPhotoPicker/SKPhotoHeader.h>
#import "SKPublishPostTestCell.h"

@interface SKViewController () <UIScrollViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UITextViewDelegate, SKPhotoNavigationControllerDelegate> {
    CGFloat _keyboardHeight;
    BOOL _currentSelectVideo; // 当前选择了视频
    CGFloat _contentTextVieHeight;
}

@property (nonatomic, strong) UIScrollView *bgScrollView;
@property (nonatomic, strong) UITextView *contentTextView;
@property (nonatomic, strong) UICollectionView *picCollectionView;
@property (nonatomic, strong) NSMutableArray *photoLocalPaths;
@property (nonatomic, strong) NSMutableArray *currentSelectPhotoItems;

@end

#define contentVieHeight 60
#define maxPicsNum 9
#define leftPadding 20
#define photoCellPadding 5
#define photoCellWidth  ((kDeviceWidth - 2*leftPadding) - photoCellPadding * 2) / 3.0
#define getRectNavAndStatusHeight  self.navigationController.navigationBar.frame.size.height+[[UIApplication sharedApplication] statusBarFrame].size.height


@implementation SKViewController

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self initialConfig];

    [self setupSubViews];

    [self.picCollectionView reloadData];
    
    [self.contentTextView becomeFirstResponder];
}


- (void)initialConfig {
    self.title = @"朋友圈";
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationController.navigationBar.translucent = NO;
    [self addNavBarButtons];
}

- (void)addNavBarButtons {
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setTitleColor:[UIColor colorWithRed:82/255.0 green:170/255.0 blue:56/255.0 alpha:1] forState:UIControlStateNormal];
    [btn setTitle:@"发表" forState:UIControlStateNormal];
    [btn.titleLabel setFont:[UIFont systemFontOfSize:16]];
    NSMutableDictionary *attrDict = [NSMutableDictionary dictionary];
    attrDict[NSFontAttributeName] = [UIFont systemFontOfSize:16];
    CGFloat width = [btn.titleLabel.text sizeWithAttributes:attrDict].width + 10;
    btn.frame = CGRectMake(0, 0, width, 44);
    [btn addTarget:self action:@selector(submitAction) forControlEvents:UIControlEventTouchUpInside];
    btn.exclusiveTouch = YES;
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:btn];
    self.navigationItem.rightBarButtonItem = item;
}

- (void)submitAction {
    
}

-(void)setupSubViews {
    
    [self.view addSubview:self.bgScrollView];
    
    [self.bgScrollView addSubview:self.contentTextView];
    
    [self.bgScrollView addSubview:self.picCollectionView];
    
    [self.bgScrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view).insets(UIEdgeInsetsMake(0, leftPadding,  0, leftPadding));
    }];
    
    [self.contentTextView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.bgScrollView.mas_top).offset(25);
        make.left.equalTo(self.bgScrollView.mas_left).offset(0);
        make.width.mas_equalTo(kDeviceWidth - 2*leftPadding);
        make.height.mas_equalTo(contentVieHeight);
    }];
    
    CGFloat collectionHeight = photoCellWidth * 3 + photoCellPadding * 2;
    [self.picCollectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentTextView.mas_bottom).offset(25);
        make.left.equalTo(self.bgScrollView.mas_left).offset(0);
        make.width.mas_equalTo(kDeviceWidth - 2*leftPadding);
        make.height.mas_equalTo(collectionHeight);
    }];
    
}

#pragma mark -- Private Method

/**
 去相册选择
 */
- (void)selectPhotosFromAlbums {
    
    if (_currentSelectVideo) {
        return;
    }
    
    __block BOOL allowSelectVideo = YES;
    if (self.currentSelectPhotoItems.count != 0) {
        [self.currentSelectPhotoItems enumerateObjectsUsingBlock:^(SKPhotoModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            BOOL isImageType = (obj.mediaType == SKAssetMediaTypeImage || obj.mediaType == SKAssetMediaTypeGIF || obj.mediaType == SKAssetMediaTypeLivePhoto) ? YES : NO;
            if (isImageType) {
                allowSelectVideo = NO;
                *stop = YES;
            }
        }];
    }
    
    NSInteger maxSelectPhotosCount = maxPicsNum;
    maxSelectPhotosCount = maxSelectPhotosCount - self.currentSelectPhotoItems.count;
    
    SKPhotoNavigationController *controller = [[SKPhotoNavigationController alloc] initWithDelegate:self pushPickerVC:YES allowSelectImage:YES allowSelectVideo:allowSelectVideo maxSelectPhotosCount:maxSelectPhotosCount];
    controller.supportLivePhoto = NO;
    [self presentViewController:controller animated:YES completion:nil];
}


- (void) longPressPics:(UILongPressGestureRecognizer *)longPressGes
{
    // 禁止拖动加号:
    NSIndexPath *indexPath = [self.picCollectionView indexPathForItemAtPoint:[longPressGes locationInView:self.picCollectionView]];
    
    switch (longPressGes.state) {
        case UIGestureRecognizerStateBegan: {
            // 如果点击的位置不是cell,break
            if (indexPath.row == self.currentSelectPhotoItems.count) {
                return;
            }
            if (nil == indexPath) {
                break;
            }
            [self.picCollectionView beginInteractiveMovementForItemAtIndexPath:indexPath];
        }
            break;
            
        case UIGestureRecognizerStateChanged:
            [self.picCollectionView updateInteractiveMovementTargetPosition:[longPressGes locationInView:self.picCollectionView]];
            break;
            
        case UIGestureRecognizerStateEnded:
            if (indexPath.row == self.currentSelectPhotoItems.count) {
                [self.picCollectionView cancelInteractiveMovement];
                return;
            }
            [self.picCollectionView endInteractiveMovement];
            break;
            
        default:
            [self.picCollectionView cancelInteractiveMovement];
            break;
    }
}


- (void)adjustContentTextViewHeight
{
    
    CGSize newSize  = [_contentTextView sizeThatFits:CGSizeMake(kDeviceWidth - 2*leftPadding ,MAXFLOAT)];
    if (newSize.height > contentVieHeight) {
        if (_contentTextVieHeight == newSize.height) {
            return;
        }
        
    } else {
        if (_contentTextVieHeight == contentVieHeight) {
            return;
        }
    }
    
    NSLog(@"改变了高度");
    
    [UIView animateWithDuration:0.5 animations:^{
        
        if (newSize.height > contentVieHeight) {
            
            CGFloat contensizeHeight = kDeviceHeight - getRectNavAndStatusHeight + 1;
            
            if (self.picCollectionView.frame.size.height + newSize.height + 50 > self.view.frame.size.height ) {
                
                CGFloat addHeight = self.picCollectionView.frame.size.height + newSize.height + 50 - self.view.frame.size.height;
                self.bgScrollView.contentSize = CGSizeMake(kDeviceWidth - 2 * leftPadding, contensizeHeight +  addHeight );
                //self.bgScrollView.contentSize = CGSizeMake(kDeviceWidth - 2 * leftPadding, contensizeHeight +  (newSize.height - contentVieHeight) );
            }
            
            [_contentTextView mas_updateConstraints:^(MASConstraintMaker *make){
                make.height.mas_equalTo(newSize.height);
            }];
            
            _contentTextVieHeight = newSize.height;
            
        } else {
            
            CGFloat contensizeHeight = kDeviceHeight - getRectNavAndStatusHeight + 1;
            self.bgScrollView.contentSize = CGSizeMake(kDeviceWidth - 2 * leftPadding,contensizeHeight +  0 );
            [_contentTextView mas_updateConstraints:^(MASConstraintMaker *make){
                make.height.mas_equalTo(contentVieHeight);
            }];
            
            _contentTextVieHeight = contentVieHeight;
        }
        
        CGFloat padding = 95;
        CGFloat rangeValue = (self.view.frame.size.height - _keyboardHeight) - newSize.height;
        if (rangeValue <= padding) {
            self.bgScrollView.contentOffset  = CGPointMake(0, padding - rangeValue);
            
            NSLog(@"rangeValue1111 = %f",padding - rangeValue);
            NSLog(@"txtheight = %f, _keyboardHeight = %f,  range = %f",newSize.height ,_keyboardHeight, self.view.frame.size.height - _keyboardHeight);
            
        } else {
            self.bgScrollView.contentOffset  = CGPointMake(0, 0);
        }
    }];
    
}

#pragma mark -- SCPhotoNavigationControllerDelegate

- (void)imagePickerController:(SKPhotoNavigationController *)picker didFinishPickPhotosItems:(NSArray<SKPhotoModel *> *)currentSeletedItems {
    _currentSelectVideo = NO;
    
    if (currentSeletedItems.count > 0) {
        
        dispatch_queue_t  concurrentQueue = dispatch_queue_create("com.skphotopickerdelegate.queue", DISPATCH_QUEUE_CONCURRENT);
        dispatch_group_t group = dispatch_group_create();
        for (NSInteger index = 0; index < currentSeletedItems.count; index ++ ) {
            
            dispatch_group_enter(group);
            dispatch_group_async(group, concurrentQueue, ^{
                
                __block SKPhotoModel *model = [currentSeletedItems objectAtIndex:index];
                NSString *filename = [model.asset valueForKey:@"filename"];
                model.fileName = filename;
                
                @autoreleasepool {
                    
                    if (model.mediaType == SKAssetMediaTypeGIF) { // gif
                        
                        [[SKPhotoManager sharedInstance] requestGIFForAsset:model.asset completion:^(NSData *imageData, UIImageOrientation orientation) {
                            
                            NSString* randomTokenKey = model.asset.localIdentifier;
                            NSString* photoLocalPath = [self cachePhotoPathWithFileName:[NSString stringWithFormat:@"%@.gif",randomTokenKey]];
                            
                            if (![[NSFileManager defaultManager] fileExistsAtPath:photoLocalPath]) {
                                BOOL success = [imageData writeToFile:photoLocalPath atomically:YES];
                                if (success) {
                                    NSLog(@"保存GIF成功 photoLocalPath = %@",photoLocalPath);
                                    model.localPhotoPath = photoLocalPath;
                                }
                            } else {
                                NSLog(@"本地已经存在GIF = %@",photoLocalPath);
                                model.localPhotoPath = photoLocalPath;
                            }
                            dispatch_group_leave(group);
                            
                        } progressHandler:nil failed:^{
                            
                        } needNetworkAccess:YES];
                        
                    } else {  // image 或者 LivePhoto
                        
                        [[SKPhotoManager sharedInstance] requestOriginalImageForAsset:model.asset completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
                            if (isDegraded) { // 低质量图像
                                return ;
                            }
                            NSString* randomTokenKey = model.asset.localIdentifier;
                            NSString* photoLocalPath = [self cachePhotoPathWithFileName:[NSString stringWithFormat:@"%@.jpg",randomTokenKey]];
                            
                            if (![[NSFileManager defaultManager] fileExistsAtPath:photoLocalPath]) {
                                BOOL success = [UIImageJPEGRepresentation(photo, 0.6f) writeToFile:photoLocalPath atomically:YES];
                                if (success) {
                                    NSLog(@"保存图片成功 photoLocalPath = %@",photoLocalPath);
                                    model.localPhotoPath = photoLocalPath;
                                }
                            } else {
                                NSLog(@"本地已经存在图片 = %@",photoLocalPath);
                                model.localPhotoPath = photoLocalPath;
                            }
                            dispatch_group_leave(group);
                        }];
                    }
                }
            });
        }
        
        dispatch_group_notify(group, concurrentQueue, ^{
            dispatch_async_on_main_queue(^{
                [self.currentSelectPhotoItems addObjectsFromArray:currentSeletedItems];
                [self.picCollectionView reloadData];
            });
        });
    }
}

- (NSString *)cachePhotoPathWithFileName:(NSString *)fileName{
    
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *namePath = [NSString stringWithFormat:@"skphotopicker/cache_photos/%@", fileName];
    NSString *fullPath = [path stringByAppendingFormat:@"/%@", namePath];
    NSString *fullDir = [fullPath stringByDeletingLastPathComponent];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:fullDir]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:fullDir
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:NULL];
    }
    return fullPath;
}

- (void)imagePickerController:(SKPhotoNavigationController *)picker didFinishPickVideo:(SKPhotoModel *)videoItem sourceAssets:(PHAsset *)asset {
    
    _currentSelectVideo = YES;
    [self.currentSelectPhotoItems removeAllObjects];
    [self.currentSelectPhotoItems addObject:videoItem];
    [self.picCollectionView reloadData];
    
    __block UIImage *image ;
    
    __block SKPhotoModel * videoModel = videoItem;
    
    kWeakObj(self)
    [[SKPhotoManager sharedInstance] requestOriginalImageForAsset:asset completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
        
        if (isDegraded) { // 缩略图
            return ;
        }
        
        image = photo;
        NSString* randomTokenKey = asset.localIdentifier;
        NSString* localThumbPath = [self cachePhotoPathWithFileName:[NSString stringWithFormat:@"%@_thumb.jpg",randomTokenKey]];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:localThumbPath]) {
            
            BOOL success = [UIImageJPEGRepresentation(photo, 0.6f) writeToFile:localThumbPath atomically:YES];
            if (success) {
                NSLog(@"保存缩略图图片成功 localThumbPath = %@",localThumbPath);
                videoModel.localThumbPath = localThumbPath;
                videoModel.localPhotoPath = localThumbPath;
                dispatch_async_on_main_queue(^{
                    [weakself.picCollectionView reloadData];
                });
            }
            
        } else {
            NSLog(@"本地已经有缩略图图片 localThumbPath = %@",localThumbPath);
            videoModel.localThumbPath = localThumbPath;
            videoModel.localPhotoPath = localThumbPath;
            dispatch_async_on_main_queue(^{
                [weakself.picCollectionView reloadData];
            });
        }
    }];
    
    
    [[SKPhotoManager sharedInstance] getVideoOutputPathWithAsset:asset completion:^(NSString *outputPath) {
        NSLog(@"outputPath = %@",outputPath);
        videoModel.localVideoPath = outputPath;
    }];
}


#pragma mark  -- UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView
{
    [self adjustContentTextViewHeight];
    if (textView.markedTextRange==nil) {
        if (textView.text.length > 300) {
            textView.text = [textView.text substringWithRange:NSMakeRange(0, 300)];
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提醒" message:@"内容限定在300字以内，已自动为您截取" delegate:self cancelButtonTitle:@"知道了" otherButtonTitles:nil, nil];
            alertView.tag = 121;
            [alertView show];
        }
    }
}



#pragma mark - UIKeyboardNotifications

- (void)keyboardWillShow:(NSNotification *)notification
{
    CGRect keyboardBounds;
    [[notification.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue: &keyboardBounds];
    NSNumber *duration = [notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSNumber *curve = [notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey];
    keyboardBounds = [[[UIApplication sharedApplication].delegate window] convertRect:keyboardBounds toView:self.view];
    
    _keyboardHeight = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;
   
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:[duration doubleValue]];
    [UIView setAnimationCurve:[curve intValue]];
    
    [self textViewDidChange:_contentTextView];
    
    [UIView commitAnimations];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    NSNumber *duration = [notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSNumber *curve = [notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey];
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:[duration doubleValue]];
    [UIView setAnimationCurve:[curve intValue]];
    
    [UIView commitAnimations];
    
    self.bgScrollView.contentOffset  = CGPointMake(0, 0);
    
}


#pragma mark -- UICollectionViewDelegate

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (self.currentSelectPhotoItems.count == maxPicsNum && !_currentSelectVideo) {
        return self.currentSelectPhotoItems.count;
    }
    
    if (_currentSelectVideo) {
        return self.currentSelectPhotoItems.count;
    }
    return self.currentSelectPhotoItems.count + 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    SKPublishPostTestCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([SKPublishPostTestCell class]) forIndexPath:indexPath];
    cell.index = indexPath.row;
    
    if (indexPath.row == self.currentSelectPhotoItems.count && !_currentSelectVideo) {
        cell.picImgeView.image = nil;
        cell.deleteBtn.hidden = YES;
        cell.addBtnView.hidden = NO;
        cell.playBtnView.hidden = YES;
        cell.timeLabel.hidden = YES;
    } else{
        
        cell.item = [self.currentSelectPhotoItems objectAtIndex:indexPath.row];
        kWeakObj(self)
        cell.deleteBtnClickBlock = ^(NSInteger index){
            kStrongObj(self)
            [self.currentSelectPhotoItems removeObjectAtIndex:index];
            if (self.currentSelectPhotoItems.count == 0) {
                self->_currentSelectVideo = NO;
            }
            [self.picCollectionView reloadData];
        };
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == self.currentSelectPhotoItems.count) {
        [self.view endEditing:YES];
        [self selectPhotosFromAlbums];
        return;
    }
    
    SKPhotoModel *item = [self.currentSelectPhotoItems objectAtIndex:indexPath.row];
    if (item.mediaType == SKAssetMediaTypeVideo) { // 预览视频
        SKPhotoPreviewController *controller = [[SKPhotoPreviewController alloc] init];
        controller.items = [NSMutableArray arrayWithArray:self.currentSelectPhotoItems];
        controller.currentIndex = 0;
        SKPhotoNavigationController *nav = [[SKPhotoNavigationController alloc] initWithRootViewController:controller navigationBarHidden:NO];
        [self presentViewController:nav animated:YES completion:nil];
        return;
    }
    
    // 预览图片

}

- (void)collectionView:(UICollectionView *)collectionView moveItemAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    //如果移到添加按钮后面，就退出，不能移动
    NSInteger destinationRow = destinationIndexPath.row;
    if (destinationRow == self.currentSelectPhotoItems.count) {
        return;
    }
    
    SKPhotoModel *model = self.currentSelectPhotoItems[sourceIndexPath.item];
    [self.currentSelectPhotoItems removeObjectAtIndex:sourceIndexPath.row];
    [self.currentSelectPhotoItems insertObject:model atIndex:destinationIndexPath.row];
}

#pragma mark -- lazyload

- (UITextView*)contentTextView
{
    if (!_contentTextView) {
        UITextView *contentTextView = [[UITextView alloc]init];
        contentTextView.scrollEnabled = NO;
        contentTextView.delegate = self;
        contentTextView.font = [UIFont systemFontOfSize:16];
        contentTextView.placeholder = @"这一刻的想法...";
        contentTextView.textColor = [UIColor blackColor];
        contentTextView.textContainerInset = UIEdgeInsetsMake(0, 0, 0, 0);
        NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
        paragraphStyle.lineSpacing = 4;
        NSDictionary *attributes = @{NSFontAttributeName:[UIFont systemFontOfSize:16],NSParagraphStyleAttributeName:paragraphStyle};
        contentTextView.typingAttributes = attributes;
        contentTextView.backgroundColor = [UIColor whiteColor];
        _contentTextView = contentTextView;
    }
    return _contentTextView;
}


- (UIScrollView*)bgScrollView
{
    if (!_bgScrollView) {
        _bgScrollView = [[UIScrollView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
        _bgScrollView.backgroundColor = [UIColor whiteColor];
        _bgScrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
        _bgScrollView.delegate = self;
        CGFloat contensizeHeight = kDeviceHeight - getRectNavAndStatusHeight + 1;
        _bgScrollView.contentSize = CGSizeMake(kDeviceWidth - 2 * leftPadding, contensizeHeight);
        _bgScrollView.showsVerticalScrollIndicator = NO;
        if (@available (iOS 11.0 , *)) {
            _bgScrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        _bgScrollView.backgroundColor = [UIColor whiteColor];
    }
    return _bgScrollView;
}

- (UICollectionView*)picCollectionView
{
    if (!_picCollectionView) {
        
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc]init];
        layout.scrollDirection = UICollectionViewScrollDirectionVertical;
        layout.minimumInteritemSpacing = 0;
        layout.minimumLineSpacing = 5;
        CGFloat cellWidth = photoCellWidth;
        layout.itemSize = CGSizeMake( cellWidth, cellWidth);
        _picCollectionView = [[UICollectionView alloc]initWithFrame:CGRectZero collectionViewLayout:layout];
        _picCollectionView.delegate = self;
        _picCollectionView.dataSource = self;
        _picCollectionView.backgroundColor = [UIColor whiteColor];
        [_picCollectionView registerClass:[SKPublishPostTestCell class] forCellWithReuseIdentifier:NSStringFromClass([SKPublishPostTestCell class])];
        UILongPressGestureRecognizer *longPresssGes = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressPics:)];
        [_picCollectionView addGestureRecognizer:longPresssGes];
        _picCollectionView.scrollEnabled = NO;
    }
    return _picCollectionView;
}

- (NSMutableArray *)photoLocalPaths {
    
    if (!_photoLocalPaths) {
        _photoLocalPaths = [NSMutableArray arrayWithCapacity:0];
    }
    return _photoLocalPaths;
}

- (NSMutableArray *)currentSelectPhotoItems {
    
    if (!_currentSelectPhotoItems) {
        _currentSelectPhotoItems = [NSMutableArray arrayWithCapacity:0];
    }
    return _currentSelectPhotoItems;
}

@end
