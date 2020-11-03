//
//  SPCHighSpeedMemCell.m
//  Spayce
//
//  Created by Christopher Taylor on 9/5/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCHighSpeedMemCell.h"
#import "SPCMemoryAsset.h"
#import "Asset.h"
#import "UIImageView+WebCache.h"

@interface SPCHighSpeedMemCell ()

@property (nonatomic,strong) UIImageView *imageView1;
@property (nonatomic,strong) UIImageView *imageView2;
@property (nonatomic,strong) UIImageView *imageView3;
@property (nonatomic,strong) UIImageView *imageView4;

@property (nonatomic, strong) UIButton *btn1;
@property (nonatomic, strong) UIButton *btn2;
@property (nonatomic, strong) UIButton *btn3;
@property (nonatomic, strong) UIButton *btn4;

@property (nonatomic, strong) NSArray *memIDsArray;

@end

@implementation SPCHighSpeedMemCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.imageView1 = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 75,75)];
        self.imageView1.backgroundColor = [UIColor colorWithWhite:255.0f/255.0f alpha:1.0f];
        [self addSubview:self.imageView1];

        self.imageView2 = [[UIImageView alloc] initWithFrame:CGRectMake(0, 79, 75,75)];
        self.imageView2.backgroundColor = [UIColor colorWithWhite:255.0f/255.0f alpha:1.0f];
        [self addSubview:self.imageView2];
        
        self.imageView3 = [[UIImageView alloc] initWithFrame:CGRectMake(79, 0, 75,75)];
        self.imageView3.backgroundColor = [UIColor colorWithWhite:255.0f/255.0f alpha:1.0f];
        [self addSubview:self.imageView3];
        
        self.imageView4 = [[UIImageView alloc] initWithFrame:CGRectMake(79, 79, 75,75)];
        self.imageView4.backgroundColor = [UIColor colorWithWhite:255.0f/255.0f alpha:1.0f];
        [self addSubview:self.imageView4];
        
        self.btn1 = [[UIButton alloc] initWithFrame:self.imageView1.frame];
        self.btn1.tag = 0;
        [self.btn1 addTarget:self action:@selector(showMem:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.btn1];

        self.btn2 = [[UIButton alloc] initWithFrame:self.imageView2.frame];
        self.btn2.tag = 1;
        [self.btn2 addTarget:self action:@selector(showMem:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.btn2];

        self.btn3 = [[UIButton alloc] initWithFrame:self.imageView3.frame];
        self.btn3.tag = 2;
        
        [self.btn3 addTarget:self action:@selector(showMem:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.btn3];

        self.btn4 = [[UIButton alloc] initWithFrame:self.imageView4.frame];
        self.btn4.tag = 1;
        
        [self.btn4 addTarget:self action:@selector(showMem:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.btn4];
    }
    return self;
}

-(void)configureWithAssetsArray:(NSArray *)assets {
    
    NSMutableArray *tempMemIDsArray = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < assets.count; i ++) {
        SPCMemoryAsset *tempAsset = assets[i];
        
        NSString *imageUrlStr = [tempAsset.asset imageUrlThumbnail];
        
        NSInteger memID = [tempAsset memoryID];
        [tempMemIDsArray addObject:@(memID)];
        
        if (i == 0) {
            self.imageView1.backgroundColor = [UIColor colorWithWhite:235.0f/255.0f alpha:1.0f];
            
            [self.imageView1 sd_setImageWithURL:[NSURL URLWithString:imageUrlStr]
                              placeholderImage:[UIImage imageNamed:@"placeholder-gray"]
                                     completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                         self.imageView1.image = image;
                                     }];
        }
        
        if (i == 1) {
            
            self.imageView2.backgroundColor = [UIColor colorWithWhite:235.0f/255.0f alpha:1.0f];
            
            [self.imageView2 sd_setImageWithURL:[NSURL URLWithString:imageUrlStr]
                               placeholderImage:[UIImage imageNamed:@"placeholder-gray"]
                                      completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                          self.imageView2.image = image;
                                      }];
        }
        
        if (i == 2) {
            self.imageView3.backgroundColor = [UIColor colorWithWhite:235.0f/255.0f alpha:1.0f];
            
            
            [self.imageView3 sd_setImageWithURL:[NSURL URLWithString:imageUrlStr]
                               placeholderImage:[UIImage imageNamed:@"placeholder-gray"]
                                      completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                          self.imageView3.image = image;
                                      }];
        }
        
        if (i == 3) {
            
            self.imageView4.backgroundColor = [UIColor colorWithWhite:235.0f/255.0f alpha:1.0f];
            
            
            [self.imageView4 sd_setImageWithURL:[NSURL URLWithString:imageUrlStr]
                               placeholderImage:[UIImage imageNamed:@"placeholder-gray"]
                                      completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                          self.imageView4.image = image;
                                      }];
        }
    }
    
    self.memIDsArray = [NSArray arrayWithArray:tempMemIDsArray];
}

-(void)showMem:(id)sender {
    
    UIButton *tempBtn = (UIButton *)sender;
    NSInteger tag = tempBtn.tag;
    
    NSNumber *tempNum = self.memIDsArray[tag];
    NSInteger memId =  [tempNum integerValue];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(fetchMemForComments:)]) {
        [self.delegate fetchMemForComments:memId];
    }
}


@end
