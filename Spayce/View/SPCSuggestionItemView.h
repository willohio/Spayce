//
//  SPCSuggestionItemView.h
//  Spayce
//
//  Created by Christopher Taylor on 10/7/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Venue.h"

@interface SPCSuggestionItemView : UIButton {
    
}

@property (nonatomic, strong) Venue *venue;

@property (nonatomic, strong) UIImageView *picImageView;
@property (nonatomic, strong) UILabel *cityLabel;

- (id)initWithVenue:(Venue *)v andFrame:(CGRect)frame;

@end
