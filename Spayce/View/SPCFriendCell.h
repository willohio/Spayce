//
//  SPCFriendCell.h
//  Spayce
//
//  Created by Pavel Dusatko on 5/5/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SPCFriendCell : UICollectionViewCell

- (void)configureWithName:(NSString *)name isCeleb:(BOOL)isCeleb url:(NSURL *)url;

@end
