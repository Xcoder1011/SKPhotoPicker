//
//  SKPreviewPhotoCell.m
//  SKPhotoPicker_Example
//
//  Created by shangkun on 2018/10/9.
//  Copyright © 2018年 Xcoder1011. All rights reserved.
//

#import "SKPreviewPhotoCell.h"
#import "SKPhotoModel.h"
#import "SKPhotoManager.h"
#import "SKPhotoHeader.h"
#import <PhotosUI/PhotosUI.h>

#if __has_include(<SDWebImage/UIImage+GIF.h>)
#import <SDWebImage/UIImage+GIF.h>
#else
#import "UIImage+GIF.h"
#endif

#if __has_include(<SDWebImage/NSData+ImageContentType.h>)
#import <SDWebImage/NSData+ImageContentType.h>
#else
#import "NSData+ImageContentType.h"
#endif

#if __has_include(<SDWebImage/SDWebImageManager.h>)
#import <SDWebImage/SDWebImageManager.h>
#else
#import "SDWebImageManager.h"
#endif

#if __has_include(<Masonry/Masonry.h>)
#import <Masonry/Masonry.h>
#else
#import "Masonry.h"
#endif

@interface SKPreviewPhotoCell () <UIScrollViewDelegate
#ifdef __IPHONE_9_0
,PHLivePhotoViewDelegate
#endif
>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, copy)   NSString *identifier;
@property (nonatomic, assign) PHImageRequestID imageRequestID;
@property (nonatomic, assign) PHImageRequestID livePhotoRequestID;

#ifdef __IPHONE_9_0
@property (nonatomic, strong) PHLivePhotoView *livePhotoView;
#endif
@property (nonatomic, strong) UIImage *gifImage;
@property (nonatomic, strong) UIActivityIndicatorView *indicatorView;

@end

@implementation SKPreviewPhotoCell

- (instancetype)initWithFrame:(CGRect)frame {
    
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor blackColor];
        [self setupSubViews];
        _supportLivePhoto = NO;
        UITapGestureRecognizer *singleTapGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTap:)];
        [self addGestureRecognizer:singleTapGes];
        UITapGestureRecognizer *doubleTapGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
        doubleTapGes.numberOfTapsRequired = 2;
        [singleTapGes requireGestureRecognizerToFail:doubleTapGes];
        [self addGestureRecognizer:doubleTapGes];
        UILongPressGestureRecognizer *longTapGes = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGes:)];
        [self addGestureRecognizer:longTapGes];
    }
    return self;
}

- (void)setModel:(SKPhotoModel *)model {
    
    _model = model;
    [self.scrollView setZoomScale:1.0 animated:NO];
    self.identifier = model.asset.localIdentifier;
    self.imageView.image = nil;
    __weak typeof(self) weakself = self;
    if (model.mediaType == SKAssetMediaTypeImage || model.mediaType == SKAssetMediaTypeGIF
#ifdef __IPHONE_9_0
        || ((model.mediaType == SKAssetMediaTypeLivePhoto) && (!_supportLivePhoto))
#endif
        ) { // 图片
        
        if (model.localPhotoPath) {
            [self.imageView setImage:[UIImage imageWithContentsOfFile:model.localPhotoPath]];
            [self resetSubViewsFrame];
        } else if (model.url) {
            [self configWithUrl:model.url];
        } else {
            [self showLoading];
            PHImageRequestID imageRequestID = [[SKPhotoManager sharedInstance] requestOriginalImageForAsset:model.asset completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
                if ([weakself.identifier isEqualToString:model.asset.localIdentifier]) {
                    weakself.imageView.image = photo;
                    [weakself resetSubViewsFrame];
                } else {
                    [[PHImageManager defaultManager] cancelImageRequest:weakself.imageRequestID];
                }
                if (!isDegraded) { // 不是低质量图像
                    self.imageRequestID = 0;
                }
                [weakself hideLoading];
            }];
            
            if (imageRequestID && self.imageRequestID && imageRequestID != self.imageRequestID) {
                [[PHImageManager defaultManager] cancelImageRequest:self.imageRequestID];
            }
            self.imageRequestID = imageRequestID;
        }
    }
    
#ifdef __IPHONE_9_0
    if (_supportLivePhoto) {
        self.imageView.hidden = (model.mediaType == SKAssetMediaTypeImage || model.mediaType == SKAssetMediaTypeGIF) ? NO : YES;
        self.livePhotoView.hidden = model.mediaType == SKAssetMediaTypeLivePhoto ? NO : YES;
    }
#endif
}

- (void)setupSubViews {
    
    [self.bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.contentView).insets(UIEdgeInsetsZero);
    }];
}

- (void)startPlayAnimationView {
    __weak typeof(self) weakself = self;
    if (self.model && self.model.mediaType == SKAssetMediaTypeGIF) {  // GIF
        if (self.model.asset) {
            [self showLoading];
            PHImageRequestID imageRequestID = [[SKPhotoManager sharedInstance] requestGIFForAsset:self.model.asset completion:^(NSData *imageData, UIImageOrientation orientation) {
                if ([weakself.identifier isEqualToString:weakself.model.asset.localIdentifier]) {
                    dispatch_async_on_global_queue(^{
                        UIImage *image;
                        if ([UIImage respondsToSelector:@selector(sd_animatedGIFWithData:)]) {
                            image = [UIImage sd_animatedGIFWithData:imageData];
                        } else {
                            image = [UIImage sk_animatedGIFWithData:imageData];
                        }
                        if (image) {
                            dispatch_async_on_main_queue(^{
                                weakself.imageView.image = image;
                                [weakself resetSubViewsFrame];
                            });
                        }
                    });
                } else {
                    [[PHImageManager defaultManager] cancelImageRequest:weakself.imageRequestID];
                }
                self.imageRequestID = 0;
                
            } progressHandler:nil failed:^{
            } needNetworkAccess:YES];
            
            if (imageRequestID && self.imageRequestID && imageRequestID != self.imageRequestID) {
                [[PHImageManager defaultManager] cancelImageRequest:self.imageRequestID];
            }
            self.imageRequestID = imageRequestID;
        } else if (self.model.url) {
            [self configWithUrl:self.model.url];
        }
        return;
    }
    
#ifdef __IPHONE_9_0
    
    if (self.model && self.supportLivePhoto) {
        SKPhotoModel *model = self.model;
        PHAsset *phAsset = model.asset;
        CGFloat aspectRatio = phAsset.pixelWidth / (CGFloat)phAsset.pixelHeight;
        CGSize size;
        CGFloat pixelWidth = kScreenWidth * 1.7;
        CGFloat pixelHeight = pixelWidth / aspectRatio;
        size = CGSizeMake(pixelWidth, pixelHeight);
        self.livePhotoView.hidden = model.mediaType == SKAssetMediaTypeLivePhoto ? NO : YES;
        if (self.model.mediaType == SKAssetMediaTypeLivePhoto) { // LivePhoto
            if (_livePhotoView.livePhoto) {
                [self.livePhotoView stopPlayback];
                self.livePhotoView.livePhoto = nil;
            }
            __weak typeof(self) weakself = self;
            PHImageRequestID livePhotoRequestID = [[SKPhotoManager sharedInstance] requestLivePhotoForAsset:model.asset imageSize:size completion:^(PHLivePhoto *livePhoto) {
                if ([weakself.identifier isEqualToString:model.asset.localIdentifier]) {
                    weakself.livePhotoView.livePhoto = livePhoto;
                    [weakself.livePhotoView startPlaybackWithStyle:PHLivePhotoViewPlaybackStyleFull];
                } else {
                    [[PHImageManager defaultManager] cancelImageRequest:weakself.livePhotoRequestID];
                }
                weakself.livePhotoRequestID = 0;
                [weakself hideLoading];
            } progressHandler:^(double progress) {
            } failed:^{
                [weakself hideLoading];
            } needNetworkAccess:NO];
            if (livePhotoRequestID && self.livePhotoRequestID && livePhotoRequestID != self.livePhotoRequestID) {
                [[PHImageManager defaultManager] cancelImageRequest:self.livePhotoRequestID];
            }
            self.livePhotoRequestID = livePhotoRequestID;
        }
        return;
    }
    
#endif
}

- (void)configWithUrl:(NSURL *)url {
    __weak typeof(self) weakself = self;
    [[SDWebImageManager sharedManager] cachedImageExistsForURL:url completion:^(BOOL isInCache) {
        if (isInCache) {
            __block NSURL *imageURL = url;
            [[SDImageCache sharedImageCache] queryCacheOperationForKey:url.absoluteString done:^(UIImage * _Nullable image, NSData * _Nullable data, SDImageCacheType cacheType) {
                [self configWithData:data imageURL:imageURL image:image];
            }];
        } else {
            [weakself showLoading];
            [[SDWebImageManager sharedManager] loadImageWithURL:url options:SDWebImageRetryFailed progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
            } completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
                [weakself hideLoading];
                if (data) {
                    [weakself configWithData:data imageURL:imageURL image:image];
                }
            }];
        }
    }];
}

- (void)configWithData:(NSData *)data imageURL:(NSURL *)imageURL image:(UIImage *)image {
    if (data) {
        if ([NSData sd_imageFormatForImageData:data] == SDImageFormatGIF) { // GIF
            dispatch_async_on_global_queue(^{
                UIImage *animatedImg = [UIImage sd_animatedGIFWithData:data];
                if (animatedImg) {
                    dispatch_async_on_main_queue(^{
                        self.imageView.image = animatedImg;
                        [self resetSubViewsFrame];
                        [self hideLoading];
                    });
                }
            });
        } else {
            [self.imageView setImage:image];
            [self resetSubViewsFrame];
        }
    }
}

- (void)stopPlayAnimationView {
    if (self.model && self.model.asset && self.model.mediaType == SKAssetMediaTypeGIF) {  // GIF
        self.imageView.image = nil;
    }
}

- (void)resetSubViewsFrame {
    
    [self.scrollView setZoomScale:1.0 animated:NO];
    self.imageContainerView.frame = CGRectMake(0, 0, self.scrollView.frame.size.width, self.scrollView.frame.size.height);
    UIImage *image = self.imageView.image;
    if (image) {
        if (image.size.height / image.size.width > self.frame.size.height / self.scrollView.frame.size.width) { // 长图
            CGFloat imageContainerViewHeight = floor((image.size.height / image.size.width) * self.scrollView.frame.size.width) ;// 向下取整
            self.imageContainerView.frame = CGRectMake(0, 0, self.scrollView.frame.size.width, imageContainerViewHeight);
        } else {
            // 居中显示
            CGFloat imageContainerViewHeight = floor((image.size.height / image.size.width) * self.scrollView.frame.size.width);
            self.imageContainerView.bounds = CGRectMake(0, 0, self.scrollView.frame.size.width, imageContainerViewHeight);
            self.imageContainerView.center = CGPointMake(self.scrollView.frame.size.width / 2.0, self.frame.size.height / 2.0);
        }
    }
    self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width, MAX(self.imageContainerView.frame.size.height, self.frame.size.height));
    [self.scrollView scrollRectToVisible:self.bounds animated:NO];
    self.scrollView.alwaysBounceVertical = self.imageContainerView.frame.size.height <= self.bounds.size.height ? NO : YES;
    self.imageView.frame = self.imageContainerView.bounds;
#ifdef __IPHONE_9_0
    self.livePhotoView.frame = self.imageContainerView.bounds;
#endif
    [self refreshImageContainerViewCenter];
}

- (void)stopLivePhoto {
    [self.livePhotoView stopPlayback];
}

- (void)showLoading {
    [self.indicatorView startAnimating];
    self.indicatorView.hidden = NO;
}

- (void)hideLoading {
    [self.indicatorView stopAnimating];
    self.indicatorView.hidden = YES;
}

- (void)reSetAnimateImageFrame:(CGRect)frame {
    [UIView animateWithDuration:0 animations:^{
        self.imageContainerView.frame = frame;
        self.imageView.frame = self.imageContainerView.bounds;
        [UIView animateWithDuration:kPhotoBrowserAnimateTime animations:^{
            [self layoutIfNeeded];
        }];
    }];
}


#pragma mark - UIScrollViewDelegate

- (nullable UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.imageContainerView;
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view {
    scrollView.contentInset = UIEdgeInsetsZero;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    [self refreshImageContainerViewCenter];
}

#pragma mark -  PHLivePhotoViewDelegate

- (void)livePhotoView:(PHLivePhotoView *)livePhotoView willBeginPlaybackWithStyle:(PHLivePhotoViewPlaybackStyle)playbackStyle {
}
- (void)livePhotoView:(PHLivePhotoView *)livePhotoView didEndPlaybackWithStyle:(PHLivePhotoViewPlaybackStyle)playbackStyle {
    [self stopLivePhoto];
}

#pragma mark - UITapGestureRecognizer Event

- (void)doubleTap:(UITapGestureRecognizer *)tap {
    
    if (_scrollView.zoomScale > 1.0) {
        _scrollView.contentInset = UIEdgeInsetsZero;
        [_scrollView setZoomScale:1.0 animated:YES];
    } else {
        CGPoint touchPoint = [tap locationInView:self.imageView];
        CGFloat newZoomScale = _scrollView.maximumZoomScale;
        CGFloat xsize = self.frame.size.width / newZoomScale;
        CGFloat ysize = self.frame.size.height / newZoomScale;
        [_scrollView zoomToRect:CGRectMake(touchPoint.x - xsize/2, touchPoint.y - ysize/2, xsize, ysize) animated:YES];
    }
}

- (void)singleTap:(UITapGestureRecognizer *)tap {
    if (self.singleTapGestureBlock) {
        self.singleTapGestureBlock();
    }
}

- (void)longPressGes:(UILongPressGestureRecognizer *)ges {
     if (ges.state==UIGestureRecognizerStateBegan) {
         if (self.longProgressGestureBlock) {
             self.longProgressGestureBlock();
         }
     }
}

#pragma mark - Private

- (void)refreshImageContainerViewCenter {
    CGFloat offsetX = (_scrollView.frame.size.width > _scrollView.contentSize.width) ? ((_scrollView.frame.size.width - _scrollView.contentSize.width) * 0.5) : 0.0;
    CGFloat offsetY = (_scrollView.frame.size.height > _scrollView.contentSize.height) ? ((_scrollView.frame.size.height - _scrollView.contentSize.height) * 0.5) : 0.0;
    self.imageContainerView.center = CGPointMake(_scrollView.contentSize.width * 0.5 + offsetX, _scrollView.contentSize.height * 0.5 + offsetY);
}


- (UIView *)bottomView {
    if (!_bottomView) {
        UIView *bottomView = [[UIView alloc] initWithFrame:self.contentView.bounds];
        bottomView.backgroundColor = [UIColor blackColor];
        [self.contentView addSubview:bottomView];
        _bottomView = bottomView;
    }
    return _bottomView;
}


- (UIImageView *)imageView {
    if (!_imageView ) {
        UIImageView *imageV = [[UIImageView alloc] initWithFrame:self.imageContainerView.bounds];
        imageV.contentMode = UIViewContentModeScaleAspectFill;
        imageV.clipsToBounds = YES;
        [self.imageContainerView addSubview:imageV];
        [self.imageContainerView insertSubview:imageV atIndex:0];
        _imageView = imageV;
    }
    return _imageView;
}

- (UIScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] init];
        _scrollView.frame = CGRectMake(kPreviewPadding / 2.0, 0, self.frame.size.width - kPreviewPadding,  self.frame.size.height);
        _scrollView.bouncesZoom = YES;
        _scrollView.maximumZoomScale = 2.5;
        _scrollView.minimumZoomScale = 1.0;
        _scrollView.multipleTouchEnabled = YES;
        _scrollView.delegate = self;
        _scrollView.scrollsToTop = NO;
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _scrollView.delaysContentTouches = NO;
        _scrollView.canCancelContentTouches = YES;
        _scrollView.alwaysBounceVertical = NO;
        [self.bottomView addSubview:_scrollView];
    }
    return _scrollView;
}

- (UIView *)imageContainerView {
    if (!_imageContainerView) {
        _imageContainerView = [[UIView alloc] initWithFrame:self.scrollView.bounds];
        _imageContainerView.clipsToBounds = YES;
        _imageContainerView.contentMode = UIViewContentModeScaleAspectFill;
        [self.scrollView addSubview:_imageContainerView];
    }
    return _imageContainerView;
}

- (PHLivePhotoView *)livePhotoView {
    if (!_livePhotoView) {
        _livePhotoView = [[PHLivePhotoView alloc] init];
        _livePhotoView.clipsToBounds = YES;
        _livePhotoView.contentMode = UIViewContentModeScaleAspectFill;
        _livePhotoView.delegate = self;
        [self.imageContainerView addSubview:_livePhotoView];
    }
    return _livePhotoView;
}

@end



@interface SKAlbumListPhotoCell ()

@property (nonatomic, strong) UIImageView *photoView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, assign) PHImageRequestID imageRequestID;
@end

@implementation SKAlbumListPhotoCell

static CGFloat const cellHeight = 70.f;

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        [self setupSubViews];
    }
    return self;
}


- (void)setModel:(SKAlbumModel *)model {
    
    _model = model;
    NSMutableAttributedString *titleStr = [[NSMutableAttributedString alloc] initWithString:model.name attributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:16],NSForegroundColorAttributeName:[UIColor blackColor]}];
    NSAttributedString *countStr = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"  (%zd)",model.count] attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:16],NSForegroundColorAttributeName:[UIColor lightGrayColor]}];
    [titleStr appendAttributedString:countStr];
    self.nameLabel.attributedText = titleStr;
    
    self.identifier = [model.items lastObject].asset.localIdentifier;
    self.photoView.image = nil;
    
    CGSize size;
    size.width = cellHeight * 1.7;
    size.height = cellHeight * 1.7;
    __weak typeof(self) weakself = self;
    
    PHImageRequestID imageRequestID = [[SKPhotoManager sharedInstance] requestImageForAsset:[model.items lastObject].asset imageSize:size completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
        
        if ([weakself.identifier isEqualToString:[model.items lastObject].asset.localIdentifier]) {
            weakself.photoView.image = photo;
        } else {
            [[PHImageManager defaultManager] cancelImageRequest:weakself.imageRequestID];
        }
        if (!isDegraded) { //不是低质量图像
            self.imageRequestID = 0;
        }
        
    } progressHandler:nil needNetworkAccess:NO];
    
    if (imageRequestID && self.imageRequestID && imageRequestID != self.imageRequestID) {
        [[PHImageManager defaultManager] cancelImageRequest:self.imageRequestID];
    }
    self.imageRequestID = imageRequestID;
}

- (void)setupSubViews {
    
    [self.photoView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView.mas_left).offset(0);
        make.width.height.mas_equalTo(cellHeight);
        make.centerY.equalTo(self.contentView.mas_centerY).offset(0);
    }];
    
    [self.nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.contentView.mas_right).offset(-50);
        make.left.equalTo(self.photoView.mas_right).offset(10);
        make.centerY.equalTo(self.contentView.mas_centerY).offset(0);
    }];
}

- (UILabel *)nameLabel {
    
    if (!_nameLabel) {
        _nameLabel = [UILabel new];
        [self.contentView addSubview:_nameLabel];
    }
    return _nameLabel;
}

- (UIImageView *)photoView {
    
    if (!_photoView ) {
        UIImageView *imageV = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.width)];
        imageV.contentMode = UIViewContentModeScaleAspectFill;
        imageV.layer.masksToBounds = YES;
        imageV.clipsToBounds = YES;
        [self.contentView addSubview:imageV];
        _photoView = imageV;
    }
    return _photoView;
}



@end
