//
//  SPCTerritoryMemoryCell.h
//  Spayce
//
//  Created by Jake Rosin on 11/14/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Memory;

@interface SPCTerritoryMemoryCell : UITableViewCell

- (instancetype)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier;

- (void)configureWithMemory:(Memory *)memory;

@end
