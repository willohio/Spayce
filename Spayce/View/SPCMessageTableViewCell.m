//
//  SPCMessageTableViewCell.m
//  Spayce
//
//  Created by Christopher Taylor on 3/19/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import "SPCMessageTableViewCell.h"


#import "SPCInitialsImageView.h"

// Category
#import "NSString+SPCAdditions.h"

// Utilities
#import "APIUtils.h"

// Model
#import "Person.h"
#import "SPCMessage.h"
#import "Asset.h"


@interface SPCMessageTableViewCell()

@property (nonatomic, strong) Person *person;

@property (nonatomic, strong) SPCInitialsImageView *customImageView;
@property (nonatomic, assign) CGFloat profilePicWidth;

@property (nonatomic, strong) UILabel *messageLabel;
@property (nonatomic, strong) UIView *messageBg;
@property (nonatomic, strong) UIImageView *chatTailImgView;

@property (nonatomic, strong) UIColor *currUserMsgBgColor;
@property (nonatomic, strong) UIColor *otherUsersMsgBgColor;

@property (nonatomic, strong) UIColor *currUserMsgTextColor;
@property (nonatomic, strong) UIColor *otherUsersMsgTextColor;

@property (nonatomic, assign) CGFloat messageHeight;
@property (nonatomic, assign) CGFloat messageWidth;

@property (nonatomic, assign) BOOL currUserIsAuthor;

@property (nonatomic, assign) CGFloat msgXOrigin;

@end

@implementation SPCMessageTableViewCell

#pragma mark - Object lifecycle

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.contentView.backgroundColor = [UIColor clearColor];
        self.backgroundColor = [UIColor clearColor];
        
        self.profilePicWidth = 40;
        
        self.currUserMsgBgColor = [UIColor colorWithRed:42.0f/255.0f green:159.0f/255.0f blue:253.0f/255.0f alpha:1.0f];
        self.currUserMsgTextColor = [UIColor whiteColor];

        self.otherUsersMsgBgColor = [UIColor colorWithRed:229.0f/255.0f green:229.0f/255.0f blue:234.0f/255.0f alpha:1.0f];
        self.otherUsersMsgTextColor = [UIColor blackColor];

        self.messageBg = [[UIView alloc] initWithFrame:CGRectZero];
        self.messageBg.layer.cornerRadius = 20;
        self.messageBg.clipsToBounds = YES;
        
        self.customImageView = [[SPCInitialsImageView alloc] initWithFrame:CGRectZero];
        self.customImageView.layer.cornerRadius = self.profilePicWidth/2;
        self.customImageView.clipsToBounds = YES;
        [self.contentView addSubview:self.customImageView];

        self.authorBtn = [[UIButton alloc] initWithFrame:CGRectZero];
        self.authorBtn.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:self.authorBtn];
        
        self.messageLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.messageLabel.backgroundColor = [UIColor clearColor];
        self.messageLabel.textAlignment = NSTextAlignmentLeft;
        self.messageLabel.font = [UIFont fontWithName:@"OpenSans" size:17];
        self.messageLabel.numberOfLines = 0;
        self.messageLabel.lineBreakMode = NSLineBreakByWordWrapping;
        
        self.chatTailImgView = [[UIImageView alloc] initWithFrame:CGRectZero];

        [self.contentView addSubview:self.messageBg];
        [self.contentView addSubview:self.messageLabel];
        [self.contentView addSubview:self.chatTailImgView];
        
    }
    return self;
}


- (void)prepareForReuse {
    [super prepareForReuse];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.messageBg.frame = CGRectMake(self.msgXOrigin, 0, self.messageWidth, self.messageHeight);

    if (self.currUserIsAuthor) {
        self.chatTailImgView.frame = CGRectMake(self.msgXOrigin + self.messageWidth - 8, self.messageBg.frame.size.height - 15, 15, 13);
    }
    else {
        self.chatTailImgView.frame = CGRectMake(self.msgXOrigin - 7, self.messageBg.frame.size.height - 15, 15, 13);
    }
    
    if (self.messageHeight > 40) {
        self.messageLabel.frame = CGRectMake(self.msgXOrigin + 13, 13, self.messageWidth - 26, self.messageHeight - 26);
    }
    else {
        self.messageLabel.frame = CGRectMake(self.msgXOrigin + 13, 8, self.messageWidth - 26, self.messageHeight - 16);
    }
    
    self.customImageView.frame = CGRectMake(10, CGRectGetMaxY(self.messageBg.frame) - self.profilePicWidth, self.profilePicWidth, self.profilePicWidth);
    self.authorBtn.frame = self.customImageView.frame;
}

#pragma mark - Configuration

- (void)configureWitMessage:(SPCMessage *)message {
    
    self.messageLabel.text = message.messageText;
    self.messageHeight = message.messageHeight;
    self.messageWidth = message.messageWidth;
    
    self.currUserIsAuthor = message.currUserIsAuthor;
    
    if (self.currUserIsAuthor) {
        self.messageBg.backgroundColor = self.currUserMsgBgColor;
        self.messageLabel.textColor = self.currUserMsgTextColor;
        self.msgXOrigin = self.bounds.size.width - self.messageWidth - 10;
        self.customImageView.hidden = YES;
        self.chatTailImgView.image = [UIImage imageNamed:@"chatTailYou"];
    }
    
    else {
        self.messageBg.backgroundColor = self.otherUsersMsgBgColor;
        self.messageLabel.textColor = self.otherUsersMsgTextColor;
        self.msgXOrigin = self.profilePicWidth + 20;
        self.customImageView.hidden = NO;
        self.chatTailImgView.image = [UIImage imageNamed:@"chatTail"];
    }
    
    NSURL *url = [NSURL URLWithString:[APIUtils imageUrlStringForUrlString:message.author.imageAsset.imageUrlThumbnail size:ImageCacheSizeThumbnailSmall]];
    [self.customImageView configureWithText:[message.author.firstname.firstLetter capitalizedString] url:url];
  
    [self setNeedsLayout];
    
}

@end