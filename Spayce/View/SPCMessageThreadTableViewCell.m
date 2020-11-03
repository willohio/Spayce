//
//  SPCMessageThreadTableViewCell.m
//  Spayce
//
//  Created by Christopher Taylor on 3/23/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import "SPCMessageThreadTableViewCell.h"

#import "SPCInitialsImageView.h"

// Category
#import "NSString+SPCAdditions.h"

// Utilities
#import "APIUtils.h"

// Model
#import "Person.h"
#import "SPCMessage.h"
#import "Asset.h"


@interface SPCMessageThreadTableViewCell()

@property (nonatomic, strong) SPCMessageThread *messageThread;

@property (nonatomic, strong) SPCInitialsImageView *customImageView1;
@property (nonatomic, strong) SPCInitialsImageView *customImageView2;
@property (nonatomic, strong) UIView *borderLine;

@property (nonatomic, assign) CGFloat profilePicWidth;

@property (nonatomic, strong) UILabel *participantsLabel;
@property (nonatomic, strong) UILabel *handleLabel;
@property (nonatomic, strong) UILabel *messageLabel;
@property (nonatomic, strong) UILabel *dateLabel;

@property (nonatomic, strong) UIView *unreadMarkerView;

@end

@implementation SPCMessageThreadTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.contentView.backgroundColor = [UIColor clearColor];
        self.backgroundColor = [UIColor clearColor];
        
        self.customImageView1 = [[SPCInitialsImageView alloc] initWithFrame:CGRectZero];
        self.customImageView1.layer.cornerRadius = self.profilePicWidth/2;
        self.customImageView1.clipsToBounds = YES;
        [self.contentView addSubview:self.customImageView1];
        
        self.customImageView2 = [[SPCInitialsImageView alloc] initWithFrame:CGRectZero];
        self.customImageView2.layer.cornerRadius = self.profilePicWidth/2;
        self.customImageView2.clipsToBounds = YES;
        self.customImageView2.layer.borderColor = [UIColor whiteColor].CGColor;
        self.customImageView2.layer.borderWidth = 2;
        [self.contentView addSubview:self.customImageView2];
        
        self.participantsLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.participantsLabel.backgroundColor = [UIColor clearColor];
        self.participantsLabel.textAlignment = NSTextAlignmentLeft;
        self.participantsLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:13];
        self.participantsLabel.numberOfLines = 1;
        self.participantsLabel.textColor = [UIColor colorWithWhite:61.0f/255.0f alpha:1.0f];

        self.handleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.handleLabel.backgroundColor = [UIColor clearColor];
        self.handleLabel.textAlignment = NSTextAlignmentLeft;
        self.handleLabel.font = [UIFont fontWithName:@"OpenSans" size:13];
        self.handleLabel.numberOfLines = 1;
        self.handleLabel.textColor = [UIColor colorWithRed:187.0f/255.0f green:189.0f/255.0f blue:193.0f/255.0f alpha:1.0f];

        
        self.messageLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.messageLabel.backgroundColor = [UIColor clearColor];
        self.messageLabel.textAlignment = NSTextAlignmentLeft;
        self.messageLabel.font = [UIFont fontWithName:@"OpenSans" size:13];
        self.messageLabel.numberOfLines = 0;
        self.messageLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.messageLabel.clipsToBounds = YES;
        self.messageLabel.textColor = [UIColor colorWithRed:187.0f/255.0f green:189.0f/255.0f blue:193.0f/255.0f alpha:1.0f];
        
        self.dateLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.dateLabel.backgroundColor = [UIColor clearColor];
        self.dateLabel.textAlignment = NSTextAlignmentRight;
        self.dateLabel.font = [UIFont fontWithName:@"OpenSans" size:13];
        self.dateLabel.numberOfLines = 1;
        self.dateLabel.textColor = [UIColor colorWithRed:187.0f/255.0f green:189.0f/255.0f blue:193.0f/255.0f alpha:1.0f];

        
        self.borderLine = [[UIView alloc] initWithFrame:CGRectZero];
        self.borderLine.backgroundColor = [UIColor lightGrayColor];
        self.borderLine.alpha = 0.25;
        
        self.unreadMarkerView = [[UIView alloc] initWithFrame:CGRectZero];
        self.unreadMarkerView.backgroundColor = [UIColor colorWithRed:76.0f/255.0f green:176.0f/255.0f blue:251.0f/255.0f alpha:1.0f];
      
     
        
        [self.contentView addSubview:self.customImageView1];
        [self.contentView addSubview:self.customImageView2];
        [self.contentView addSubview:self.participantsLabel];
        [self.contentView addSubview:self.handleLabel];
        [self.contentView addSubview:self.messageLabel];
        [self.contentView addSubview:self.dateLabel];
        [self.contentView addSubview:self.borderLine];
        [self.contentView addSubview:self.unreadMarkerView];

        
    }
    return self;
}


- (void)prepareForReuse {
    [super prepareForReuse];
    self.unreadMarkerView.hidden = YES;
}

- (void)layoutSubviews {
    [super layoutSubviews];
 
    //Update image view frames
    self.customImageView1.frame = CGRectMake(20, 12, self.profilePicWidth, self.profilePicWidth);
    self.customImageView2.frame = CGRectMake(35, 22, self.profilePicWidth, self.profilePicWidth);
    self.customImageView1.layer.cornerRadius = self.profilePicWidth/2;
    self.customImageView2.layer.cornerRadius = self.profilePicWidth/2;
    
    
    self.participantsLabel.frame = CGRectMake(75, 8, 200, 20);
    [self.participantsLabel sizeToFit];
    
    self.handleLabel.frame = CGRectMake(CGRectGetMaxX(self.participantsLabel.frame)+5, 8, 100, 20);
    [self.handleLabel sizeToFit];
    
    float maxWidth = 160;
    
    //4.7"
    if ([UIScreen mainScreen].bounds.size.width >= 375) {
        maxWidth = 210;
    }
    
    //5.5"
    if ([UIScreen mainScreen].bounds.size.width >= 414) {
        maxWidth = 240;
    }
    
    
    self.messageLabel.frame = CGRectMake(75, CGRectGetMaxY(self.participantsLabel.frame), maxWidth, 40);
    self.messageLabel.backgroundColor = [UIColor clearColor];
    self.messageLabel.numberOfLines = 0;
    [self.messageLabel sizeToFit];
    if (self.messageLabel.frame.size.height >= 40) {
        self.messageLabel.numberOfLines = 2;
        self.messageLabel.frame = CGRectMake(75, CGRectGetMaxY(self.participantsLabel.frame), maxWidth, 40);
    }
    
    self.dateLabel.frame = CGRectMake(self.bounds.size.width - 85, 24, 75, 20);
    self.dateLabel.backgroundColor = [UIColor clearColor];
    
    self.borderLine.frame = CGRectMake(0,self.contentView.frame.size.height-1, self.bounds.size.width, 1);
   
    float markerSize = 8;
    self.unreadMarkerView.frame = CGRectMake(5, (self.contentView.frame.size.height - markerSize)/2, markerSize, markerSize);
    self.unreadMarkerView.layer.cornerRadius = self.unreadMarkerView.frame.size.width/2;
    self.unreadMarkerView.clipsToBounds = YES;

    self.unreadMarkerView.hidden = !self.messageThread.hasUnreadMessages;
    
}

#pragma mark - Configuration

- (void)configureWitMessageThread:(SPCMessageThread *)thread {
    
    self.messageThread = thread;
    
    //Handle cell styling for a thread with one other user
    if (thread.participants.count == 1) {
       
        //Display 1 large profile pic
        self.profilePicWidth = 45;
        self.customImageView2.hidden = YES;
       
        Person *participant = thread.participants[0];
        NSURL *url = [NSURL URLWithString:[APIUtils imageUrlStringForUrlString:participant.imageAsset.imageUrlThumbnail size:ImageCacheSizeThumbnailMedium]];
        [self.customImageView1 configureWithText:[participant.firstname.firstLetter capitalizedString] url:url];

        self.participantsLabel.text = [NSString stringWithFormat:@"%@", participant.displayName];
        self.handleLabel.text = [NSString stringWithFormat:@"@%@",participant.handle];

        
    }
    
    //Handle cell styling for a thread with multiple users
    else {
        
        if (thread.participants.count > 1) {
            
            //Display 2 smaller profile pics
            self.profilePicWidth = 30;
            self.customImageView2.hidden = NO;
        
            Person *participant = thread.participants[0];
            NSURL *url = [NSURL URLWithString:[APIUtils imageUrlStringForUrlString:participant.imageAsset.imageUrlThumbnail size:ImageCacheSizeThumbnailMedium]];
            [self.customImageView1 configureWithText:[participant.firstname.firstLetter capitalizedString] url:url];

            Person *participant1 = thread.participants[1];
            NSURL *url1 = [NSURL URLWithString:[APIUtils imageUrlStringForUrlString:participant1.imageAsset.imageUrlThumbnail size:ImageCacheSizeThumbnailMedium]];
            [self.customImageView2 configureWithText:[participant1.firstname.firstLetter capitalizedString] url:url1];

            
            self.participantsLabel.text = [NSString stringWithFormat:@"%@ & %@",participant.firstname,participant1.firstname];
            self.handleLabel.text = @"";
            
            if (thread.participants.count > 2) {
                Person *participant2 = thread.participants[2];
                self.participantsLabel.text = [NSString stringWithFormat:@"%@, %@ & %@",participant.firstname,participant1.firstname,participant2.firstname];
                
            }
            
        }
    }
    
    //Update most recent message text! 
    [thread configureDates];
    SPCMessage *mostRecentMsg = thread.messages[thread.messages.count - 1];
    thread.dateOfMostRecentThreadActivity = mostRecentMsg.createdDate;
    
    self.messageLabel.text = mostRecentMsg.messageText;
    
    //Update dislay date
    self.dateLabel.text = [thread generateUpdatedDisplayDate];
    
    [self setNeedsLayout];
    
}


@end
