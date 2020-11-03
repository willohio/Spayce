//
//  SPCMapFilterCollectionViewCell.m
//  Spayce
//
//  Created by Christopher Taylor on 12/3/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCMapFilterCollectionViewCell.h"

@interface SPCMapFilterCollectionViewCell ()

@property (nonatomic, strong) UILabel *filterLabel;
@property (nonatomic, strong) UIImageView *filterIcon;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UILabel *allLabel;


@end

@implementation SPCMapFilterCollectionViewCell


#pragma mark - Object lifecycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.contentView.backgroundColor = [UIColor clearColor];
       
        self.containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width - 10, 45)];
        self.containerView.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:self.containerView];
        
        self.filterIcon = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 24, 24)];
        [self.containerView addSubview:self.filterIcon];
        
        self.filterLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.containerView.frame.size.height - 20, self.containerView.frame.size.width, 20)];
        self.filterLabel.font = [UIFont spc_boldSystemFontOfSize:8];
        self.filterLabel.textColor = [UIColor colorWithRed:139.0f/255.0f green:153.0f/255.0f blue:175.0f/255.0f alpha:1.0f];
        self.filterLabel.textAlignment = NSTextAlignmentCenter;
        [self.containerView addSubview:self.filterLabel];
        
        self.allLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.containerView.frame.size.height - 20, self.containerView.frame.size.width, 20)];
        self.allLabel.font = [UIFont spc_boldSystemFontOfSize:18];
        self.allLabel.textColor = [UIColor colorWithRed:139.0f/255.0f green:153.0f/255.0f blue:175.0f/255.0f alpha:1.0f];
        self.allLabel.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:self.allLabel];
    
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.filterSelected = NO;
    self.allLabel.text = @"";
    self.filterLabel.text = @"";
    self.filterIcon.image = nil;
    self.backgroundColor = [UIColor whiteColor];
}


- (void)configureWithFilter:(NSString *)filter {
 
    self.filterName = filter;
    
    if ([filter isEqualToString:@"All"]) {
        self.allLabel.center = CGPointMake(self.contentView.frame.size.width/2, self.contentView.frame.size.height/2);
        self.allLabel.text = @"All";
    }
    else {
        self.filterLabel.text = [filter uppercaseString];
        self.filterIcon.image = [self getImageForFilter:filter];
        self.filterIcon.center = CGPointMake(self.containerView.frame.size.width/2, self.filterIcon.center.y);
        self.containerView.center = CGPointMake(self.contentView.frame.size.width/2, self.contentView.frame.size.height/2);
    }
}

-(void)toggleFilter {
    if (self.filterSelected) {
        self.filterSelected = NO;
        self.backgroundColor = [UIColor whiteColor];
    }
    else {
        self.filterSelected = YES;
        self.backgroundColor = [UIColor colorWithRed:244.0f/255.0f green:241.0f/255.0f blue:241.0f/255.0f alpha:1.0f];
    }
}

-(UIImage *)getImageForFilter:(NSString *)filter {
    
    //TODO - update images when final ones are available
    
    if ([filter isEqualToString:@"Cafes"]) {
        return [UIImage imageNamed:@"lg-icon-pin-cafe"];
    }
    if ([filter isEqualToString:@"Restaurants"]) {
        return [UIImage imageNamed:@"lg-icon-pin-restaurant"];
    }
    if ([filter isEqualToString:@"Homes"]) {
        return [UIImage imageNamed:@"lg-icon-pin-residential"];
    }
    if ([filter isEqualToString:@"Travel"]) {
        return [UIImage imageNamed:@"lg-icon-pin-airport"];
    }
    if ([filter isEqualToString:@"Sports"]) {
        return [UIImage imageNamed:@"lg-icon-pin-stadium"];
    }
    if ([filter isEqualToString:@"Bars"]) {
        return [UIImage imageNamed:@"lg-icon-pin-bar"];
    }
    if ([filter isEqualToString:@"Schools"]) {
        return [UIImage imageNamed:@"lg-icon-pin-school"];
    }
    if ([filter isEqualToString:@"Fun"]) {
        return [UIImage imageNamed:@"lg-icon-pin-amusement"];
    }
    if ([filter isEqualToString:@"Stores"]) {
        return [UIImage imageNamed:@"lg-icon-pin-store"];
    }
    if ([filter isEqualToString:@"Offices"]) {
        return [UIImage imageNamed:@"lg-icon-pin-real-estate"];
    }
    if ([filter isEqualToString:@"Favorites"]) {
        return [UIImage imageNamed:@"heart-selected"];
    }
    if ([filter isEqualToString:@"Popular"]) {
        return [UIImage imageNamed:@"big-gold-star"];
    }
    return nil;
}

@end
