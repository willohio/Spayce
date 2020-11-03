//
//  SPCProfileFriendCell.h
//  Spayce
//
//  Created by Pavel Dusatko on 8/23/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SPCProfileFriendCell : UICollectionViewCell

- (void)configureWithName:(NSString *)name url:(NSURL *)url;

@end
