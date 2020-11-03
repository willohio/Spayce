//
//  SPCPeopleFinderCollectionReusableView.h
//  Spayce
//
//  Created by Jordan Perry on 3/26/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SPCPeopleFinderCollectionReusableViewDelegate;

@interface SPCPeopleFinderCollectionReusableView : UICollectionReusableView

@property (nonatomic, weak) id<SPCPeopleFinderCollectionReusableViewDelegate> delegate;

@property (nonatomic, copy) NSString *text;
@property (nonatomic, assign) BOOL showXButton;

@end

@protocol SPCPeopleFinderCollectionReusableViewDelegate <NSObject>
@optional

- (void)didSelectXButtonForPeopleFinderReusableView:(SPCPeopleFinderCollectionReusableView *)reusableView;

@end
