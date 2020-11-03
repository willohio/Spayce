//
//  SpayceNotificationViewCell.h
//  Spayce
//
//  Created by Joseph Jupin on 10/4/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SpayceNotification.h"

// View
#import "SPCInitialsImageView.h"

@interface SPCNotificationCell : UITableViewCell


@property (nonatomic, strong) SpayceNotification *notif;
@property (nonatomic, strong) SPCInitialsImageView *customImageView;
@property (nonatomic, strong) UIView *borderLine;
@property (nonatomic, strong) UILabel * notificationBodyLabel;
@property (nonatomic, strong) UILabel * notificationDateAndTimeLabel;
@property (nonatomic, strong) UIButton *notificationAuthorBtn;
@property (nonatomic, strong) UIButton *participant1Btn;
@property (nonatomic, strong) UIButton *participant2Btn;


@property (nonatomic, assign) CGFloat authorNameWidth;
@property (nonatomic, strong) NSArray *participantNames;
@property (nonatomic, strong) NSArray *participantTokens;

@property (nonatomic, assign) CGFloat  participant1NameWidth;
@property (nonatomic, assign) CGFloat  participant1NameXOrigin;
@property (nonatomic, assign) CGFloat  participant1NameYOrigin;

@property (nonatomic, assign) CGFloat  participant2NameWidth;
@property (nonatomic, assign) CGFloat  participant2NameXOrigin;
@property (nonatomic, assign) CGFloat  participant2NameYOrigin;

@property (nonatomic, strong) UIButton *acceptBtn;
@property (nonatomic, strong) UIButton *declineBtn;

@property (nonatomic, strong) UIButton *imageButton;
@property (nonatomic, assign) CGFloat textWidth;

- (void)styleNotification:(SpayceNotification *)sn;

+ (CGFloat)heightForCellWithNotification:(SpayceNotification *)notification;

- (void)configureWithText:(NSString *)text url:(NSURL *)url;

@end
