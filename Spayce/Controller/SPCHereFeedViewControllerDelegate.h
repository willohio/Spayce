//
//  SPCHereFeedViewControllerDelegate.h
//  Spayce
//
//  Created by Pavel Dusatko on 4/23/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
@class Venue;

@protocol SPCHereFeedViewControllerDelegate <NSObject>

@optional
- (void)feedViewController:(UIViewController *)controller didSelectVenue:(Venue *)venue;
// Used to dismiss feed view controller
- (void)dismissFeedViewController:(UIViewController *)controller animated:(BOOL)animated;
// The # of transparent pixels at the top of the screen changed.
- (void)feedViewController:(UIViewController *)controller didChangeTransparentPixelsAtTop:(CGFloat)transparentPixelsAtTop;
// Used when the user presses the "refresh location" button
- (void)userRefreshedLocation;

- (void)updateStatusBarForOYL;

- (void)updateStatusBarAfterRefresh;
@end
