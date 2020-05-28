//
//  SKPreviewVideoCell.m
//  SKPhotoPicker_Example
//
//  Created by shangkun on 2018/10/9.
//  Copyright © 2018年 Xcoder1011. All rights reserved.
//


#import "SKPreviewVideoCell.h"
#import "SKPhotoModel.h"
#import "SKPhotoManager.h"
#import "SKPhotoHeader.h"
#if __has_include(<Masonry/Masonry.h>)
#import <Masonry/Masonry.h>
#else
#import "Masonry.h"
#endif
@interface SKPreviewVideoCell () <UIScrollViewDelegate>

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIView *bottomView;

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *imageContainerView;

@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, assign) PHImageRequestID imageRequestID;

@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;

@property (nonatomic, strong) UIButton *playBtn;

@end


@implementation SKPreviewVideoCell

- (instancetype)initWithFrame:(CGRect)frame {
    
    if (self = [super initWithFrame:frame]) {
        
        self.backgroundColor = [UIColor blackColor];
        
        [self setupSubViews];
        
        UITapGestureRecognizer *singleTapGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTap:)];
        [self addGestureRecognizer:singleTapGes];
    }
    return self;
}


- (void)setModel:(SKPhotoModel *)model {
    
    _model = model;
    [self.SKrollView setZoomScale:1.0 animated:NO];
    
    self.playBtn.hidden = model.mediaType == SKAssetMediaTypeVideo ? NO : YES;
    
    self.identifier = model.asset.localIdentifier;
    self.imageView.image = nil;
    CGSize size;
    
    if (model.localPhotoPath) {
        self.imageView.image = [UIImage imageWithContentsOfFile:model.localPhotoPath];
        return;
    }
    
    PHAsset *phAsset = model.asset;
    CGFloat aspectRatio = phAsset.pixelWidth / (CGFloat)phAsset.pixelHeight;
    CGFloat pixelWidth = kScreenWidth * 1.7;
    CGFloat pixelHeight = pixelWidth / aspectRatio;
    size = CGSizeMake(pixelWidth, pixelHeight);
    
    __weak typeof(self) weakself = self;
    PHImageRequestID imageRequestID = [[SKPhotoManager sharedInstance] requestImageForAsset:model.asset imageSize:size completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
        
        if ([weakself.identifier isEqualToString:model.asset.localIdentifier]) {
            weakself.imageView.image = photo;
            [weakself resetSubViewsFrame];
            
        } else {
            [[PHImageManager defaultManager] cancelImageRequest:weakself.imageRequestID];
        }
        
        if (!isDegraded) { // 不是低质量图像
            weakself.imageRequestID = 0;
        }
        
    } progressHandler:nil needNetworkAccess:NO];
    
    if (imageRequestID && self.imageRequestID && imageRequestID != self.imageRequestID) {
        [[PHImageManager defaultManager] cancelImageRequest:self.imageRequestID];
    }
    self.imageRequestID = imageRequestID;
}

- (void)setupSubViews {
    
    [self.bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.contentView).insets(UIEdgeInsetsZero);
    }];
}

- (void)configPlayerButton {
    
}

- (void)playVideo:(UIButton *)sender {
    
    if (self.player) {
        [self.player play];
        return;
    }
    
    if (_model.localVideoPath) {
        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:[NSURL fileURLWithPath:_model.localVideoPath]];
        [self dealPlayerItem:playerItem info:nil];
        return;
    }
    
    __weak typeof(self) weakself = self;
    [[SKPhotoManager sharedInstance] requestPlayerItemForVideo:_model.asset completion:^(AVPlayerItem *playerItem, NSDictionary *info) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakself dealPlayerItem:playerItem info:info];
        });
    }];
}

- (void)dealPlayerItem:(AVPlayerItem *)playerItem info:(NSDictionary *)info {
    
    self.player = [AVPlayer playerWithPlayerItem:playerItem];
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    playerLayer.frame = self.imageContainerView.bounds;
    self.playerLayer = playerLayer;
    
    if (![self.imageContainerView.layer.sublayers containsObject:self.playerLayer]) {
        [self.imageContainerView.layer addSublayer:playerLayer];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidPlayToEndTime) name:AVPlayerItemDidPlayToEndTimeNotification object: self.player.currentItem];
    [self.player play];
}


#pragma mark - Notification Method

- (void)playerItemDidPlayToEndTime {
    [self.player pause];
    
    if (self.singleTapGestureBlock) {
        self.singleTapGestureBlock(NO);
    }
    self.playBtn.hidden =  NO;
    [self clearPlayer];
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
    [self refreshImageContainerViewCenter];
    self.playBtn.hidden =  NO;
    [self clearPlayer];
}


#pragma mark - UIScrollViewDelegate

- (nullable UIView *)viewForZoomingInScrollView:(UIScrollView *)SKrollView {
    return self.imageContainerView;
}

- (void)SKrollViewWillBeginZooming:(UIScrollView *)SKrollView withView:(UIView *)view {
    SKrollView.contentInset = UIEdgeInsetsZero;
}

- (void)SKrollViewDidZoom:(UIScrollView *)SKrollView {
    [self refreshImageContainerViewCenter];
}

- (void)SKrollViewDidEndZooming:(UIScrollView *)SKrollView withView:(UIView *)view atScale:(CGFloat)SKale {
}

#pragma mark - UITapGestureRecognizer Event

- (void)singleTap:(UITapGestureRecognizer *)tap {
    
    BOOL hideNav = NO;
    if ([self isPlaying]) {
        [self.player pause];
        self.playBtn.hidden = NO;
    } else {
        [self playVideo:nil];
        hideNav = YES;
        self.playBtn.hidden = YES;
    }
    
    if (self.singleTapGestureBlock) {
        self.singleTapGestureBlock(hideNav);
    }
}

- (BOOL)isPlaying {
    
    if (@available(iOS 10.0, *)) {
        
        if (self.player && self.player.timeControlStatus == AVPlayerTimeControlStatusPlaying) {
            return YES;
        } else {
            return NO;
        }
    }
    
    if (self.player && self.player.rate != 0) {
        return YES;
    } else {
        return NO;
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

- (UIScrollView *)SKrollView {
    
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
        _imageContainerView = [[UIView alloc] initWithFrame:self.SKrollView.bounds];
        _imageContainerView.clipsToBounds = YES;
        _imageContainerView.contentMode = UIViewContentModeScaleAspectFill;
        [self.SKrollView addSubview:_imageContainerView];
    }
    return _imageContainerView;
}

- (UIButton *)playBtn {
    
    if (!_playBtn) {
        _playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_playBtn setImage:[UIImage imageNamedFromSKBundle:@"play_big_icon"] forState:UIControlStateNormal];
        [_playBtn addTarget:self action:@selector(playVideo:) forControlEvents:UIControlEventTouchUpInside];
        _playBtn.userInteractionEnabled = NO;
        [self.bottomView addSubview:_playBtn];
        [self.bottomView bringSubviewToFront:_playBtn];
        
        [_playBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.imageContainerView.mas_centerX);
            make.centerY.equalTo(self.imageContainerView.mas_centerY);
            make.width.height.mas_equalTo(80);
        }];
    }
    return _playBtn;
}

- (void)clearPlayer {
    
    if (self.player) {
        [self.player pause];
        [self.player pause];
        [self.player setRate:0];
        [self.player replaceCurrentItemWithPlayerItem:nil];
        self.player = nil;
        [self.playerLayer removeFromSuperlayer];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
