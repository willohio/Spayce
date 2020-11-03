//
//  SPCNewsLogCell.m
//  Spayce
//
//  Created by Christopher Taylor on 10/22/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCNewsLogCell.h"

//model
#import "User.h"
#import "UserProfile.h"
#import "ProfileDetail.h"
#import "Asset.h"

//utils
#import "APIUtils.h"

//category
#import "NSDate+SPCAdditions.h"

//manager
#import "PNSManager.h"
#import "ContactAndProfileManager.h"
#import "AuthenticationManager.h"

@interface SPCNewsLogCell ()

@property (nonatomic, strong) UIView *contentFrame;
@property (nonatomic, assign) CGFloat textHeight;
@property (nonatomic, strong) UILabel *unreadBadgeCount;
@property (nonatomic, assign) NSInteger unreadCount;
@property (nonatomic, strong) UILabel *newsLogLbl;

@end

@implementation SPCNewsLogCell 

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    @try {
        [[PNSManager sharedInstance] removeObserver:self forKeyPath:@"totalCount"];
    }
    @catch (NSException *exception) {}
}


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        
        self.backgroundColor = [UIColor clearColor];
        
        self.contentFrame = [[UIView alloc] initWithFrame:CGRectZero];
        self.contentFrame.backgroundColor = [UIColor clearColor];
        self.contentFrame.layer.cornerRadius = 2;
        self.contentFrame.layer.masksToBounds = YES;
        self.contentFrame.clipsToBounds = YES;
        [self addSubview:self.contentFrame];
        
        self.customImageView = [[SPCInitialsImageView alloc] initWithFrame:CGRectMake(10, 14, 46, 46)];
        self.customImageView.backgroundColor = [UIColor whiteColor];
        self.customImageView.contentMode = UIViewContentModeScaleAspectFill;
        self.customImageView.layer.cornerRadius = 23;
        self.customImageView.layer.masksToBounds = YES;
        self.customImageView.textLabel.font = [UIFont spc_placeholderFont];
        [self.contentFrame addSubview:self.customImageView];
        
        self.imageButton = [[UIButton alloc] initWithFrame:self.customImageView.frame];
        self.imageButton.backgroundColor = [UIColor clearColor];
        [self.contentFrame addSubview:self.imageButton];
        
        self.notificationBodyLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.notificationBodyLabel.backgroundColor = [UIColor clearColor];
        self.notificationBodyLabel.numberOfLines = 0;
        self.notificationBodyLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.notificationBodyLabel.font = [UIFont spc_mediumSystemFontOfSize:14];
        self.notificationBodyLabel.textColor = [UIColor colorWithRGBHex:0x14294b];
        [self.contentFrame addSubview:self.notificationBodyLabel];
        
        self.notificationAuthorBtn = [[UIButton alloc] initWithFrame:CGRectZero];
        self.notificationAuthorBtn.backgroundColor = [UIColor clearColor];
        [self.contentFrame addSubview:self.notificationAuthorBtn];
        
        self.notificationDateAndTimeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.notificationDateAndTimeLabel.backgroundColor = [UIColor clearColor];
        self.notificationDateAndTimeLabel.font = [UIFont spc_mediumSystemFontOfSize:10];
        self.notificationDateAndTimeLabel.textColor = [UIColor colorWithRGBHex:0xacb6c6];
        self.notificationDateAndTimeLabel.textAlignment = NSTextAlignmentRight;
        [self.contentFrame addSubview:self.notificationDateAndTimeLabel];
        
        self.participant1Btn = [[UIButton alloc] initWithFrame:CGRectZero];
        self.participant1Btn.backgroundColor = [UIColor clearColor];
        [self.participant1Btn addTarget:self action:@selector(showProfileForParticipant:) forControlEvents:UIControlEventTouchDown];
        self.participant1Btn.tag = 0;
        [self.contentFrame addSubview:self.participant1Btn];
        
        self.participant2Btn = [[UIButton alloc] initWithFrame:CGRectZero];
        self.participant2Btn.backgroundColor =  [UIColor clearColor];
        [self.participant2Btn addTarget:self action:@selector(showProfileForParticipant:) forControlEvents:UIControlEventTouchDown];
        self.participant2Btn.tag = 1;
        [self.contentFrame addSubview:self.participant2Btn];
        
        self.newsLogLbl = [[UILabel alloc] initWithFrame:CGRectZero];
        self.newsLogLbl.text = NSLocalizedString(@"NEWS LOG", nil);
        self.newsLogLbl.font = [UIFont spc_mediumSystemFontOfSize:10];
        self.newsLogLbl.textColor = [UIColor colorWithRGBHex:0x8b99af];
        [self.contentFrame addSubview:self.newsLogLbl];
        
        self.unreadBadgeCount = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 50, 25)];
        self.unreadBadgeCount.font = [UIFont spc_regularSystemFontOfSize:14];
        self.unreadBadgeCount.layer.borderColor = [UIColor colorWithRGBHex:0x6ab1fb].CGColor;
        self.unreadBadgeCount.layer.cornerRadius = 12;
        self.unreadBadgeCount.textAlignment = NSTextAlignmentCenter;
        self.unreadBadgeCount.clipsToBounds = YES;
        [self.contentFrame addSubview:self.unreadBadgeCount];
        
        [[PNSManager sharedInstance] addObserver:self forKeyPath:@"totalCount" options:NSKeyValueObservingOptionInitial context:nil];
    }
    return self;
}


-(void) layoutSubviews
{
    [super layoutSubviews];
    
    CGSize actualTextSize = [self.notificationBodyLabel.text sizeWithAttributes:@{ NSFontAttributeName: self.notificationBodyLabel.font }];
    float authorY = 25;
    
    if (actualTextSize.width > self.textWidth) {
        authorY = 15;
    }
    
    if (actualTextSize.width > self.textWidth * 2) {
        authorY = 8;
    }
    self.borderLine.alpha = 0;

    self.contentFrame.frame = self.bounds;
    
    [self.notificationDateAndTimeLabel sizeToFit];
    self.notificationDateAndTimeLabel.frame = CGRectMake(self.contentFrame.frame.size.width - 10 - self.notificationDateAndTimeLabel.bounds.size.width, 10.0, self.notificationDateAndTimeLabel.bounds.size.width, self.notificationDateAndTimeLabel.font.lineHeight);
    self.notificationBodyLabel.frame = CGRectMake(CGRectGetMaxX(self.customImageView.frame)+10.0, CGRectGetMidY(self.customImageView.frame) - self.textHeight / 2.0, self.textWidth, self.textHeight);
    self.notificationAuthorBtn.frame = CGRectMake(CGRectGetMaxX(self.customImageView.frame)+10, authorY, self.authorNameWidth, self.notificationBodyLabel.font.lineHeight);
    self.participant1Btn.frame = CGRectMake(60+self.participant1NameXOrigin, self.participant1NameYOrigin + authorY, self.participant1NameWidth, 20);
    self.participant2Btn.frame = CGRectMake(67+self.participant2NameXOrigin, self.participant2NameYOrigin + authorY, self.participant2NameWidth, 20);
    
    self.newsLogLbl.frame = CGRectMake(CGRectGetMinX(self.notificationBodyLabel.frame) + 5, CGRectGetMaxY(self.contentFrame.frame) - 32, 80, 15);

    self.unreadBadgeCount.center = CGPointMake(self.contentFrame.frame.size.width - 35, 77.5);
    
    //hide author btn on system notifications
    if ([self.notif.notificationType isEqualToString:@"locationBasedNotificationFriend"]) {
        self.notificationAuthorBtn.frame = CGRectZero;
    }
    if ([self.notif.notificationType isEqualToString:@"locationBasedNotificationPublic"]) {
        self.notificationAuthorBtn.frame = CGRectZero;
    }
    if ([self.notif.notificationType isEqualToString:@"locationBasedNotificationOld"]) {
        self.notificationAuthorBtn.frame = CGRectZero;
    }
    if ([self.notif.notificationType isEqualToString:@"locationBasedNotificationNone"]) {
        self.notificationAuthorBtn.frame = CGRectZero;
    }
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
  
    // Do nothing
}

-(void)configureWithNotification:(SpayceNotification *)mostRecentNotification count:(NSInteger)unreadCount {
    
    self.unreadCount = [PNSManager sharedInstance].unreadNews;
    self.unreadBadgeCount.text = [NSString stringWithFormat:@"%i",(int)self.unreadCount];
    
    
    if ([PNSManager sharedInstance].unreadNews > 0 ) {
        self.unreadBadgeCount.textColor = [UIColor whiteColor];
        self.unreadBadgeCount.backgroundColor = [UIColor colorWithRGBHex:0x6ab1fb];
        self.unreadBadgeCount.layer.borderWidth = 0;
        
        if ([PNSManager sharedInstance].unreadNews > 50) {
            self.unreadBadgeCount.text = [NSString stringWithFormat:@"50+"];
        }
    }
    else {
        self.unreadBadgeCount.backgroundColor = [UIColor clearColor];
        self.unreadBadgeCount.textColor = [UIColor colorWithRGBHex:0x6ab1fb];
        self.unreadBadgeCount.layer.borderWidth = 1;
    }
    

    [self styleNotification:mostRecentNotification];
    self.notificationDateAndTimeLabel.text = [NSDate formattedDateStringWithString:mostRecentNotification.createdTime];
    
    Asset *asset = mostRecentNotification.user.imageAsset;

    // we might want to override this -- new users may not have their profile asset
    // in place at the time this notification was cached.  Also, changes in profile asset
    // over time may not be reflected in our cached notifications.
    if ([mostRecentNotification.user.userToken isEqualToString:[AuthenticationManager sharedInstance].currentUser.userToken]) {
        if ([ContactAndProfileManager sharedInstance].profile.profileDetail.imageAsset != nil) {
            asset = [ContactAndProfileManager sharedInstance].profile.profileDetail.imageAsset;
        }
    }
    
    NSURL *url = [NSURL URLWithString:[APIUtils imageUrlStringForUrlString:asset.imageUrlThumbnail size:ImageCacheSizeThumbnailMedium]];
    [self configureWithText:mostRecentNotification.user.firstName url:url];
    
    // Update tags, so we can reference the proper notification on a tap event
    [self.imageButton setTag:mostRecentNotification.notificationId];
    [self.notificationAuthorBtn setTag:mostRecentNotification.notificationId];
    
    self.textHeight = [SPCNewsLogCell heightForCellWithNotification:mostRecentNotification];
    
    [self setNeedsLayout];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == [PNSManager sharedInstance]) {
        if ([keyPath isEqualToString:@"totalCount"])  {
            NSArray *recentNotifs = [[PNSManager sharedInstance] getNotificationsForSection:0];
            if (recentNotifs.count > 0) {
                SpayceNotification *mostRecentNotification = [recentNotifs objectAtIndex:0];
                [self configureWithNotification:mostRecentNotification count:[PNSManager sharedInstance].unreadNews];
            }
        }
    }
}

@end
