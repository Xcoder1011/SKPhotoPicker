//
//  SCPhotoCell.m
//  SuperCoach
//
//  Created by shangkun on 2018/9/6.
//  Copyright © 2018年 Lin Feihong. All rights reserved.
//

#import "SCPhotoCell.h"
#import "SCPhotoModel.h"
#import "SCPhotoManager.h"
#import "SCPhotoNavigationController.h"

@interface SCPhotoCell ()

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIImageView *selectImageView;
@property (nonatomic, strong) UIView *bottomView;

@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, assign) PHImageRequestID imageRequestID;

@end

@implementation SCPhotoCell

- (instancetype)initWithFrame:(CGRect)frame {
    
    if (self = [super initWithFrame:frame]) {
        //
        [self setupSubViews];
    }
    return self;
}

- (void)reloadData {
    
    self.selectedButton.selected = _model.isSelected;
    
    if (_model.isSelected) {
        if (_model.selectIndex > 0) {
            [self.selectedButton setTitle:[NSString stringWithFormat:@"%tu",_model.selectIndex] forState:UIControlStateSelected];
        }
        
    } else {
        [self.selectedButton setTitle:nil forState:UIControlStateNormal];
    }
}


- (void)setModel:(SCPhotoModel *)model {
    
    _model = model;
    self.identifier = model.asset.localIdentifier;
    self.imageView.image = nil;
    
    CGSize size;
    size.width = self.imageView.frame.size.width * 1.7;
    size.height = self.imageView.frame.size.height * 1.7;
    __weak typeof(self) weakself = self;
    PHImageRequestID imageRequestID = [[SCPhotoManager sharedInstance] requestImageForAsset:model.asset imageSize:size completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
        
        if ([weakself.identifier isEqualToString:model.asset.localIdentifier]) {
            weakself.imageView.image = photo;
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
    
    
    self.selectedButton.selected = model.isSelected;
    
    if (model.isSelected) {
        
        if (model.selectIndex > 0) {
            [self.selectedButton setTitle:[NSString stringWithFormat:@"%tu",model.selectIndex] forState:UIControlStateSelected];
        }
        
    } else {
        [self.selectedButton setTitle:@"" forState:UIControlStateNormal];
    }
   
}

- (void)selectButtonClicked:(UIButton *)sender {
    
    sender.selected = !sender.isSelected;
    _model.selected = sender.isSelected;
    
    if (sender.isSelected) {
        
        if (self.navigation.currentSeletedLocalIdentifier.count == self.navigation.maxSelectPhotosCount) {
            [self.navigation showMaxPhotosCountAlert];
            sender.selected = !sender.isSelected;
            _model.selected = sender.isSelected;
            return;
        }
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(pickerPhotoCell:didSelectItem:indexPath:)]) {
            [self.delegate pickerPhotoCell:self didSelectItem:_model indexPath:_indexPath];
        }
        [self showAnimationWith:sender];
        
    } else {
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(pickerPhotoCell:didCancelSelectItem:indexPath:)]) {
            [self.delegate pickerPhotoCell:self didCancelSelectItem:_model indexPath:_indexPath];
        }
    }
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

- (void)setupSubViews {
    
    [self.bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.contentView).insets(UIEdgeInsetsZero);
    }];
    
    [self.imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.bottomView).insets(UIEdgeInsetsZero);
    }];
    
    [self.selectedButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.bottomView.mas_right).offset(-2);
        make.top.equalTo(self.bottomView.mas_top).offset(2);
        make.width.height.mas_equalTo(23);
    }];
}

- (UIButton *)selectedButton {
    if (!_selectedButton) {
        UIButton *selectButton = [UIButton buttonWithType:UIButtonTypeCustom];
        selectButton.frame = CGRectMake(self.frame.size.width - 44, 0, 28, 28);
        [selectButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [selectButton setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        [selectButton setTitleFont:[UIFont systemFontOfSize:14]];
        [selectButton addTarget:self action:@selector(selectButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        [selectButton setBackgroundImage:[UIImage imageNamedFromSCBundle:@"select_white"] forState:UIControlStateNormal];
        [selectButton setBackgroundImage:[UIImage imageNamedFromSCBundle:@"picture_select_small"] forState:UIControlStateSelected];
        [self.bottomView addSubview:selectButton];
        _selectedButton = selectButton;
    }
    return _selectedButton;
}

- (UIView *)bottomView {
    
    if (!_bottomView) {
        UIView *bottomView = [[UIView alloc] initWithFrame:self.bounds];
        bottomView.backgroundColor = [UIColor whiteColor];
        [self.contentView addSubview:bottomView];
        _bottomView = bottomView;
    }
    return _bottomView;
}


- (UIImageView *)imageView {
    
    if (!_imageView ) {
        UIImageView *imageV = [[UIImageView alloc] initWithFrame:self.bottomView.bounds];
        imageV.contentMode = UIViewContentModeScaleAspectFill;
        imageV.clipsToBounds = YES;
        [self.bottomView addSubview:imageV];
        _imageView = imageV;
    }
    return _imageView;
}

@end





@interface SCVideoCell ()

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIView *bottomView;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UIControl *maskView;

@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, assign) PHImageRequestID imageRequestID;

@end

@implementation SCVideoCell

- (instancetype)initWithFrame:(CGRect)frame {
    
    if (self = [super initWithFrame:frame]) {
        //
        [self setupSubViews];
    }
    return self;
}


- (void)setModel:(SCPhotoModel *)model {
    
    _model = model;
    self.identifier = model.asset.localIdentifier;
    self.imageView.image = nil;
    NSString *string = [NSString stringWithFormat:@"  %@",model.duration];
    NSMutableAttributedString *attri = [[NSMutableAttributedString alloc] initWithString:string];
    NSTextAttachment *attch = [[NSTextAttachment alloc] init];
    attch.image = [UIImage imageNamedFromSCBundle:@"video_icon_white"];
    attch.bounds = CGRectMake(0, -0, 37/2.0, 22/2.0);
    NSAttributedString *attachString = [NSAttributedString attributedStringWithAttachment:attch];
    [attri insertAttributedString:attachString atIndex: 0];
    self.timeLabel.attributedText = attri;
    
    CGSize size;
    size.width = self.imageView.frame.size.width * 1.7;
    size.height = self.imageView.frame.size.height * 1.7;
    __weak typeof(self) weakself = self;
    PHImageRequestID imageRequestID = [[SCPhotoManager sharedInstance] requestImageForAsset:model.asset imageSize:size completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
        
        if ([weakself.identifier isEqualToString:model.asset.localIdentifier]) {
            weakself.imageView.image = photo;
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
    
    self.maskView.hidden = self.navigation.currentSeletedLocalIdentifier.count > 0 ? NO : YES;
}

- (void)clickVideoCell {
    
}

- (void)reloadData {
    
    self.maskView.hidden = self.navigation.currentSeletedLocalIdentifier.count > 0 ? NO : YES;
}


- (void)setupSubViews {
    
    [self.bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.contentView).insets(UIEdgeInsetsZero);
    }];
    
    [self.imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.bottomView).insets(UIEdgeInsetsZero);
    }];
    
    [self.maskView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.bottomView).insets(UIEdgeInsetsZero);
    }];
    
    [self.timeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.bottomView.mas_right).offset(0);
        make.left.equalTo(self.bottomView.mas_left).offset(0);
        make.bottom.equalTo(self.bottomView.mas_bottom).offset(- 5);
        make.height.mas_equalTo(17);
    }];
}


- (UIView *)bottomView {
    
    if (!_bottomView) {
        UIView *bottomView = [[UIView alloc] initWithFrame:self.bounds];
        bottomView.backgroundColor = [UIColor whiteColor];
        [self.contentView addSubview:bottomView];
        _bottomView = bottomView;
    }
    return _bottomView;
}


- (UIImageView *)imageView {
    
    if (!_imageView ) {
        UIImageView *imageV = [[UIImageView alloc] initWithFrame:self.bottomView.bounds];
        imageV.contentMode = UIViewContentModeScaleAspectFill;
        imageV.clipsToBounds = YES;
        [self.bottomView addSubview:imageV];
        _imageView = imageV;
    }
    return _imageView;
}

- (UILabel *)timeLabel {
    
    if (!_timeLabel) {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
        [label setFont:[UIFont systemFontOfSize:14]];
        [label setTextColor:[UIColor whiteColor]];
        label.textAlignment = NSTextAlignmentCenter;
        [self.bottomView addSubview:label];
        [self.bottomView bringSubviewToFront:label];
        _timeLabel = label;
    }
    return _timeLabel;
}

- (UIControl *)maskView {
    
    if (!_maskView) {
        UIControl *maskView = [[UIControl alloc] initWithFrame:self.bounds];
        maskView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.8];
        [maskView addTarget:self action:@selector(clickVideoCell) forControlEvents:UIControlEventTouchUpInside];
        maskView.hidden = YES;
        [self.bottomView addSubview:maskView];
        _maskView = maskView;
    }
    return _maskView;
}

@end
