//
//  MainViewController.h
//  SpayceBook
//
//  Created by Dmitry Miller on 5/14/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SPCMainViewController : UIViewController {
    BOOL justLoggedIn;
    BOOL animationExists;
}

- (UITabBarController *)customTabBarController;

@end
