//
//  SPCTableView.h
//  Spayce
//
//  Created by Jake Rosin on 5/6/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//
//  A general-purpose UITableView extension that allows completely
//  non-interative regions.  Touches on these regions will be ignored
//  by the table view (if the cell/header/footer itself does not capture them)
//  and passed up the view hierarchy.
//
//  Use case: 'Spayce' displays a memory feed (table) over a map.  We want
//  the map to accept touch events that occur in the visually empty areas
//  of the feed (a transparent header view).  Using SPCTableView allows that
//  area to be set as untouchable.

#import <UIKit/UIKit.h>

@interface SPCTableView : UITableView

@property (nonatomic, assign) BOOL clipsHitsToBounds;
@property (nonatomic, strong) NSMutableArray *untouchableContentRegions;

- (void)addUntouchableContentRegion:(CGRect)rect;

@end
