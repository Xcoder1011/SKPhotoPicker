//
//  SKPublishPostTestCell.m
//  SKPhotoPicker_Example
//
//  Created by shangkun on 2018/10/10.
//  Copyright © 2018年 Xcoder1011. All rights reserved.
//

#import "SKPublishPostTestCell.h"

@implementation SKPublishPostTestCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupView];
    }
    return self;
    
}

- (void)setItem:(SKPhotoModel *)item {
    _item = item;
    
    kWeakObj(self)
    if (item.mediaType == SKAssetMediaTypeGIF) {
        dispatch_async_on_global_queue(^{
            NSData *imageData = [NSData dataWithContentsOfFile:item.localPhotoPath];
            UIImage *image = [UIImage sd_animatedGIFWithData:imageData];
            if (image) {
                dispatch_async_on_main_queue(^{
                    weakself.picImgeView.image = image;
                });
            }
        });
        
    } else {
        self.picImgeView.image = [UIImage imageWithContentsOfFile:item.localPhotoPath];
    }
    
    self.deleteBtn.hidden = NO;
    self.addBtnView.hidden = YES;
    self.playBtnView.hidden = item.mediaType == SKAssetMediaTypeVideo ? NO : YES;
    self.timeLabel.hidden = item.mediaType == SKAssetMediaTypeVideo ? NO : YES;
    self.timeLabel.text = item.duration;
}

- (void)setupView
{
    
    UIImageView * (^createImageView)(NSString *, CGSize) = ^(NSString *imageName, CGSize size){
        UIImageView *imageV = [[UIImageView alloc]init];
        [imageV setImage:[UIImage imageNamedFromSKBundle:imageName]];
        CGRect frame = imageV.frame;
        frame.size = size;
        imageV.frame = frame;
        imageV.center = self.contentView.center;
        imageV.contentMode =  UIViewContentModeScaleAspectFill;
        imageV.clipsToBounds = YES;
        imageV.hidden = YES;
        return imageV;
    };
    
    self.backgroundColor =  [UIColor colorWithHexString:@"F2F2F2"];
    
    UIImageView *imageView = [[UIImageView alloc]init];
    [self.contentView addSubview:imageView];
    imageView.frame = self.contentView.bounds;
    imageView.contentMode =  UIViewContentModeScaleAspectFill;
    imageView.clipsToBounds = YES;
    _picImgeView = imageView;
    
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    CGRect frame = self.contentView.bounds;
    btn.frame = CGRectMake(CGRectGetMaxX(frame)-25, 5, 20, 20);
    btn.layer.cornerRadius = 10;
    btn.clipsToBounds = YES;
    [btn setBackgroundImage:[UIImage imageNamed:@"sc_close_icon"] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(clickToDeletePicture:) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:btn];
    _deleteBtn = btn;
    
    
    UIImageView *addBtnView = createImageView(@"sc_add_icon",CGSizeMake(32, 32));
    _addBtnView = addBtnView;
    [self.contentView addSubview:addBtnView];
    
    UIImageView *playBtnView = createImageView(@"play_small_icon",CGSizeMake(32, 32));
    _playBtnView = playBtnView;
    [self.contentView addSubview:playBtnView];
    
    [self.contentView addSubview:self.timeLabel];
    [self.contentView bringSubviewToFront:self.timeLabel];
}

- (void)clickToDeletePicture:(UIButton*)sender
{
    self.deleteBtnClickBlock(self.index);
}

- (UILabel *)timeLabel {
    
    if (!_timeLabel) {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(5, self.contentView.frame.size.height - 20, self.contentView.frame.size.width - 10, 17)];
        [label setFont:[UIFont systemFontOfSize:14]];
        [label setTextColor:[UIColor whiteColor]];
        label.textAlignment = NSTextAlignmentRight;
        _timeLabel = label;
    }
    return _timeLabel;
}

- (void)dealloc {
    self.picImgeView.image = nil;
    self.picImgeView = nil;
}


@end
