//
//  SpayceNotificationViewCell.m
//  Spayce
//
//  Created by Joseph Jupin on 10/4/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import "SPCNotificationCell.h"

// Model
#import "User.h"


// Category
#import "NSString+SPCAdditions.h"

// Manager
#import "AuthenticationManager.h"
#import "MeetManager.h"

#import <CoreText/CoreText.h>

#define kTextColor [UIColor blackColor];


@interface SPCNotificationCell() {

}


@property (nonatomic, strong) UIColor *authorHighlightColor;
@property (nonatomic, strong) UIColor *actionHighlightColor;

@end

@implementation SPCNotificationCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        
        
        self.textWidth = 220.0;
        
        //4.7"
        if ([UIScreen mainScreen].bounds.size.width == 375) {
            self.textWidth = 270.0;
        }
        
        //5"
        if ([UIScreen mainScreen].bounds.size.width > 375) {
            self.textWidth = 310.0;
        }
        
        _customImageView = [[SPCInitialsImageView alloc] initWithFrame:CGRectMake(10, 14, 46, 46)];
        _customImageView.backgroundColor = [UIColor whiteColor];
        _customImageView.contentMode = UIViewContentModeScaleAspectFill;
        _customImageView.layer.cornerRadius = 23;
        _customImageView.layer.masksToBounds = YES;
        _customImageView.textLabel.font = [UIFont spc_placeholderFont];
        [self.contentView addSubview:_customImageView];
        
        _imageButton = [[UIButton alloc] initWithFrame:_customImageView.frame];
        _imageButton.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:_imageButton];
        
        self.notificationBodyLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.notificationBodyLabel.backgroundColor = [UIColor clearColor];
        self.notificationBodyLabel.numberOfLines = 0;
        self.notificationBodyLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.notificationBodyLabel.font = [UIFont spc_regularSystemFontOfSize:14];
        self.notificationBodyLabel.textColor = [UIColor colorWithRed:133.0f/255.0f green:141.0f/255.0f blue:154.0f/255.0f alpha:1.0f];
        [self.contentView addSubview:self.notificationBodyLabel];
        
        self.declineBtn = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetMinX(self.notificationBodyLabel.frame), 55, 90, 35)];
        [self.declineBtn setTitle:@"DECLINE" forState:UIControlStateNormal];
        self.declineBtn.titleLabel.font = [UIFont spc_regularSystemFontOfSize:12];
        [self.declineBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.declineBtn setBackgroundColor:[UIColor colorWithRGBHex:0xd0d0d0]];
        self.declineBtn.layer.cornerRadius = 6;
        self.declineBtn.hidden = YES;
        [self.contentView addSubview:self.declineBtn];
        
        self.acceptBtn = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.declineBtn.frame) + 10, 55, 90, 35)];
        [self.acceptBtn setTitle:@"ACCEPT" forState:UIControlStateNormal];
        self.acceptBtn.titleLabel.font = [UIFont spc_regularSystemFontOfSize:12];
        [self.acceptBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.acceptBtn setBackgroundColor:[UIColor colorWithRed:76.0f/255.0f green:176.0f/255.0f blue:251.0f/255.0f alpha:1.0f]];
        self.acceptBtn.layer.cornerRadius = 6;
        self.acceptBtn.hidden = YES;
        [self.contentView addSubview:self.acceptBtn];
        
        
        self.notificationAuthorBtn = [[UIButton alloc] initWithFrame:CGRectZero];
        self.notificationAuthorBtn.backgroundColor =  [UIColor clearColor]; //[UIColor colorWithRed:0 green:0 blue:1 alpha:.2];
        [self.contentView addSubview:self.notificationAuthorBtn];
        
        self.notificationDateAndTimeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.notificationDateAndTimeLabel.backgroundColor = [UIColor clearColor];
        self.notificationDateAndTimeLabel.font = [UIFont spc_regularSystemFontOfSize:11];
        self.notificationDateAndTimeLabel.textColor = [UIColor colorWithRed:172.0f/255.0f green:182.0f/255.0f blue:198.0f/255.0f alpha:1.0f];
        self.notificationDateAndTimeLabel.textAlignment = NSTextAlignmentRight;
        [self.contentView addSubview:self.notificationDateAndTimeLabel];

        self.participant1Btn = [[UIButton alloc] initWithFrame:CGRectZero];
        self.participant1Btn.backgroundColor =  [UIColor clearColor]; //[UIColor colorWithRed:1 green:0 blue:0 alpha:.2];
        [self.participant1Btn addTarget:self action:@selector(showProfileForParticipant:) forControlEvents:UIControlEventTouchDown];
        self.participant1Btn.tag = 0;
        [self.contentView addSubview:self.participant1Btn];
        
        self.participant2Btn = [[UIButton alloc] initWithFrame:CGRectZero];
        self.participant2Btn.backgroundColor =  [UIColor clearColor]; //[UIColor colorWithRed:0 green:1 blue:0 alpha:.2];
        [self.participant2Btn addTarget:self action:@selector(showProfileForParticipant:) forControlEvents:UIControlEventTouchDown];
        self.participant2Btn.tag = 1;
        [self.contentView addSubview:self.participant2Btn];
        
        self.borderLine = [[UIView alloc] initWithFrame:CGRectMake(0,self.frame.size.height-1, self.frame.size.width-20, 1)];
        self.borderLine.backgroundColor = [UIColor lightGrayColor];
        self.borderLine.alpha = 0.25;
        [self.contentView addSubview:self.borderLine];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    // Clear display values
    [self.customImageView prepareForReuse];
    
    self.authorNameWidth = 0;
    self.participant1NameWidth = 0;
    self.participant2NameWidth = 0;
    self.participant1NameXOrigin = 0;
    self.participant1NameYOrigin = 0;
    self.participant2NameXOrigin = 0;
    self.participant2NameYOrigin = 0;
    self.participantTokens = nil;
    self.participantNames = nil;
    self.acceptBtn.hidden = YES;
    self.declineBtn.hidden = YES;
    self.acceptBtn.tag = 0;
    self.declineBtn.tag = 0;
    [self.acceptBtn removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
    [self.declineBtn removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
    
    self.imageButton.tag = 0;
    self.notificationAuthorBtn.tag = 0;
    
    // Clear target action
    [self.imageButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
    [self.notificationAuthorBtn removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
}

-(void) layoutSubviews
{
    //NSLog(@"layout subviews of %@ for notif text %@", self, self.notif.notificationText);
    [super layoutSubviews];
    
    //handle special layout for friend requests
    if ([self.notif.notificationType isEqualToString:@"friendRequest"] || [self.notif.notificationType isEqualToString:@"followRequest"]) {
        self.acceptBtn.hidden = NO;
        self.declineBtn.hidden = NO;
    }
    
    CGFloat textHeight = CGRectGetHeight(self.contentView.frame) - 12.0;
    
    CGSize actualTextSize = [self.notificationBodyLabel.text sizeWithAttributes:@{ NSFontAttributeName: self.notificationBodyLabel.font }];
    float authorY = 25;
    
    if (actualTextSize.width > self.textWidth) {
        authorY = 15;
    }
    
    if (actualTextSize.width > self.textWidth * 2) {
        authorY = 8;
    }
    
    BOOL hasButtons = !self.acceptBtn.hidden;
    
    CGFloat textTop = hasButtons ? CGRectGetMinY(self.customImageView.frame) : CGRectGetMidY(self.contentView.frame) - textHeight / 2.0;
    CGFloat textViewHeight = hasButtons ? CGRectGetHeight(self.contentView.frame) - 65 : textHeight;
    
    self.notificationDateAndTimeLabel.frame = CGRectMake(self.frame.size.width - 53.0, 10.0, 45, self.notificationDateAndTimeLabel.font.lineHeight);
    self.notificationBodyLabel.frame = CGRectMake(CGRectGetMaxX(self.customImageView.frame)+10.0, textTop, self.textWidth, textViewHeight);
    self.notificationAuthorBtn.frame = CGRectMake(CGRectGetMaxX(self.customImageView.frame)+10, authorY, self.authorNameWidth, self.notificationBodyLabel.font.lineHeight);
    self.participant1Btn.frame = CGRectMake(60+self.participant1NameXOrigin, self.participant1NameYOrigin + authorY, self.participant1NameWidth, 20);
    self.participant2Btn.frame = CGRectMake(67+self.participant2NameXOrigin, self.participant2NameYOrigin + authorY, self.participant2NameWidth, 20);
    self.declineBtn.frame = CGRectMake(CGRectGetMinX(self.notificationAuthorBtn.frame), MAX(CGRectGetMaxY(self.customImageView.frame), CGRectGetMaxY(self.notificationBodyLabel.frame))-2, 90, 35);
    self.acceptBtn.frame = CGRectMake(CGRectGetMaxX(self.declineBtn.frame)+10, MAX(CGRectGetMaxY(self.customImageView.frame), CGRectGetMaxY(self.notificationBodyLabel.frame))-2, 90, 35);
    self.borderLine.frame = CGRectMake(0,self.frame.size.height-1, self.frame.size.width, 0.5);
    
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


- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    //[super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(UIColor *)authorHighlightColor {
   return [UIColor colorWithRed:20.0f/255.0f green:41.0f/255.0f blue:75.0f/255.0f alpha:1.0f];
    
}

-(UIColor *)actionHighlightColor {
    return [UIColor colorWithRed:133.0f/255.0f green:141.0f/255.0f blue:154.0f/255.0f alpha:1.0f];
    
}

#pragma mark - Text Building & Styling Methods -- used to handle text composition, parsing and styling for different notification types

- (void)styleNotification:(SpayceNotification *)sn {
    self.notif = sn;
   
    //NSLog(@"sn.type %@",sn.notificationType);
    //NSLog(@"sn.text %@",sn.notificationText);
   
    if ([sn.notificationType isEqualToString:@"memory"]) {
        //update and style mem notification text
        if (sn.memoryAddressName.length > 0) {
            NSString *updatedText = [self updateMemoryNotificationText:sn.notificationText memoryLocation:sn.memoryAddressName participants:sn.memoryParticipants authorId:(int)sn.user.userId];
            [self styleNotificationOfType:sn.notificationType withText:updatedText];
        }
        //handle legacy mem notifications with no memoryAddressName
        else {
            [self styleNotificationOfType:sn.notificationType withText:sn.notificationText];
        }
    }
    else if ([sn.notificationType isEqualToString:@"comment"]) {
        //update and style comment notification text
        if (sn.commentText.length>0){
            //NSLog(@"comment text %@", sn.commentText);
            //NSLog(@"sn  %@",sn);
            NSString *taggedText = [self updateTaggedUsersInCommentText:sn];
            NSString *updatedText = [self updateCommentNotificationText:sn.notificationText commentText:taggedText notification:sn];
            [self styleNotificationOfType:sn.notificationType withText:updatedText];
        }
        //handle legacy comment notifications with no commentText
        else {
            [self styleNotificationOfType:sn.notificationType withText:sn.notificationText];
        }
    }
    else if ([sn.notificationType isEqualToString:@"commentStar"]) {
        [self styleNotificationOfType:@"commentStar" withText:sn.notificationText];
    }
    else if ([sn.notificationType isEqualToString:@"comboStar"]) {
        //update and style combo star notifications
        if (sn.memoryParticipants.count > 0) {
            [self updateComboStarNotificationWithParticipants:sn.memoryParticipants];
        }
        else {
            [self styleNotificationOfType:@"star" withText:sn.notificationText];
        }
    }
    else if ([sn.notificationType isEqualToString:@"friendRequest"]) {
        if (sn.user.userId != [AuthenticationManager sharedInstance].currentUser.userId) {
            NSString *notifText = [NSString stringWithFormat:@"%@\n\n",sn.notificationText];
            [self styleNotificationOfType:sn.notificationType withText:notifText];
        }
        else {
            sn.notificationType = @"sentFriendRequest";
            [self styleNotificationOfType:sn.notificationType withText:sn.notificationText];
        }
    } else if ([sn.notificationType isEqualToString:@"followRequest"]) {
        NSString *notifText = [NSString stringWithFormat:@"%@",sn.notificationText];
        [self styleNotificationOfType:sn.notificationType withText:notifText];
    }
    else {
        [self styleNotificationOfType:sn.notificationType withText:sn.notificationText];
    }
}

- (NSString *)updateTaggedUsersInCommentText:(SpayceNotification *)commentNotif {

    //handle tagged users in comment previews snippets
    
    NSMutableString *text = [[NSMutableString alloc] initWithString:commentNotif.commentText];

    NSArray *taggedUserIds;  //TODO ADD
    NSArray *taggedUserNames;  //TODO ADD
    
    if (commentNotif.commentDict) {
        //NSLog(@"commentDict %@",commentNotif.commentDict);
        Comment *theComment = [[Comment alloc] initWithAttributes:commentNotif.commentDict];
        taggedUserIds = theComment.taggedUserIds;
        taggedUserNames = theComment.taggedUserNames;
    }
    
    NSRange atRange = [text rangeOfString:@"@"];
    while (atRange.location != NSNotFound && atRange.location < text.length - 1) {
        NSInteger nextSearch = atRange.location + 1;
        
        char nextChar = [text characterAtIndex:(atRange.location + 1)];
        // escaped @\ ?
        if (nextChar == '\\') {
            [text replaceCharactersInRange:NSMakeRange(atRange.location, 2) withString:@"@"];
        } else if (nextChar == '{') {
            NSRange endRange = [text rangeOfString:@"}" options:0 range:NSMakeRange(atRange.location, text.length - atRange.location)];
            if (endRange.location != NSNotFound) {
                NSRange replaceRange = NSMakeRange(atRange.location, endRange.location - atRange.location + 1);
                NSRange idRange = NSMakeRange(atRange.location+2, endRange.location - atRange.location - 2);
                NSString *idStr = [text substringWithRange:idRange];
                NSString *userName = nil;
                for (int i = 0; i < taggedUserIds.count; i++) {
                    NSObject *taggedId = taggedUserIds[i];
                    NSString *taggedIdStr;
                    if ([taggedId isKindOfClass:[NSString class]]) {
                        taggedIdStr = (NSString *)taggedId;
                    } else {
                        taggedIdStr = [NSString stringWithFormat:@"%d", [((NSNumber *)taggedId) intValue]];
                    }
                    if ([taggedIdStr isEqualToString:idStr]) {
                        userName = taggedUserNames[i];
                    }
                }
                if (userName) {
                    [text replaceCharactersInRange:replaceRange withString:userName];
                    nextSearch = atRange.location + userName.length;
                }
            }
        }
        
        atRange = [text rangeOfString:@"@" options:0 range:NSMakeRange(nextSearch, text.length - nextSearch)];
    }
    
    NSString *updatedCommentString = [NSString stringWithString:text];
    
    return updatedCommentString;
}

- (NSString *)updateCommentNotificationText:(NSString *)originalText commentText:(NSString *)commentText notification:(SpayceNotification *)sn {
    NSString *updatedText = originalText;
    NSString *lastWord = @"memory";
    NSRange range = [originalText rangeOfString:lastWord];
    
    int adjustedMaxLength = 60;
    if (sn.user.userId == [AuthenticationManager sharedInstance].currentUser.userId) {
        //do nothing
    }
    else {
        adjustedMaxLength = 60 - (int)sn.user.firstName.length + 3;
    }
    
    NSString *trimComment = commentText;
    if (commentText.length > adjustedMaxLength) {
        NSRange truncationRange = NSMakeRange(0,adjustedMaxLength);
        NSString *truncatedComment = [commentText substringWithRange:truncationRange];
        trimComment =  [NSString stringWithFormat:@"%@...",truncatedComment];
        
    }
    
    if (range.length > 0) {
        NSRange truncationRange = NSMakeRange(0,(([originalText rangeOfString:lastWord].location)+lastWord.length));
        NSString *truncatedText = [originalText substringWithRange:truncationRange];
        updatedText = [NSString stringWithFormat:@"%@: \"%@\"",truncatedText,trimComment];
    }

    return updatedText;
}

- (NSString *)updateMemoryNotificationText:(NSString *)originalText
                             memoryLocation:(NSString *)memoryAddressName
                               participants:(NSArray *)participants
                                   authorId:(int)authorId {
    
    NSString *updatedText = originalText;
    NSString *lastWord = @"memory";
    NSRange range = [originalText rangeOfString:lastWord];
    
    NSString *participantsString = @"";
    NSString *youAnd = @"";
    BOOL includesCurrentUser = NO;
  
    int currUserId = (int)[AuthenticationManager sharedInstance].currentUser.userId;
  
    //remove mem author
    NSMutableArray *tempArray = [NSMutableArray arrayWithArray:participants];
    
    for (int i = 0; i < participants.count; i++) {
        NSDictionary *userDict = (NSDictionary *)participants[i];
        NSString *participantIdStr = userDict[@"id"];
        int participantId = [participantIdStr intValue];
        if (authorId == participantId) {
            [tempArray removeObjectAtIndex:i];
            break;
        }
    }
    
    //remove current user
    for (int i = 0; i < tempArray.count; i++) {
        NSDictionary *userDict = (NSDictionary *)tempArray[i];
        NSString *participantIdStr = userDict[@"id"];
        int participantId = [participantIdStr intValue];
        if (currUserId == participantId) {
            youAnd = @"you";
            includesCurrentUser = YES;
            [tempArray removeObjectAtIndex:i];
            break;
        }
    }
    
    if (includesCurrentUser && tempArray.count > 0) {
        youAnd = @"you and";
    }
    
    NSMutableArray *tempNamesArray = [[NSMutableArray alloc] init];
    NSMutableArray *tempTokensArray = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < tempArray.count; i++) {
        NSDictionary *userDict = (NSDictionary *)tempArray[i];
        NSString *participantName = userDict[@"firstname"];
        NSString *participantUserToken = userDict[@"userToken"];
        if (i < 2) {
            [tempNamesArray addObject:participantName];
            [tempTokensArray addObject:participantUserToken];
     
            CGSize participantNameSize = [participantName sizeWithAttributes: @{ NSFontAttributeName: self.notificationBodyLabel.font }];
            
            if (i == 0) {
                self.participant1NameWidth = participantNameSize.width;
            }
            if (i == 1) {
                self.participant2NameWidth = participantNameSize.width;
            }
        }
    }
    
    self.participantNames = [NSArray arrayWithArray:tempNamesArray];
    self.participantTokens = [NSArray arrayWithArray:tempTokensArray];
    
    if (tempNamesArray.count > 1){
        participantsString = [tempNamesArray componentsJoinedByString:@" and "];
    } else {
        if (tempNamesArray.count > 0){
            participantsString = tempNamesArray[0];
        }
    }
    
    if (tempArray.count > 2) {
        int otherCount = (int)tempArray.count - 2;
        if (otherCount == 1) {
            participantsString = [NSString stringWithFormat:@"%@ and %i other",participantsString,otherCount];
        }
        if (otherCount > 1) {
            participantsString = [NSString stringWithFormat:@"%@ and %i others",participantsString,otherCount];
        }

    }
    
    
    
    if (range.length > 0) {
        NSRange truncationRange = NSMakeRange(0,(([originalText rangeOfString:lastWord].location)+lastWord.length));
        NSString *truncatedText = [originalText substringWithRange:truncationRange];
        
        if (includesCurrentUser){
            if (participantsString.length > 0){
                //NSLog(@"includes current user and other participants!");
                updatedText = [NSString stringWithFormat:@"%@ with %@ %@ at %@.",truncatedText,youAnd,participantsString,memoryAddressName];
            }
            else {
                //NSLog(@"includes just current user!");
                updatedText = [NSString stringWithFormat:@"%@ with %@ at %@.",truncatedText,youAnd,memoryAddressName];
            }
        }
        else {
            if (participantsString.length > 0){
                //NSLog(@"does NOT include current user, but does have participants");
                updatedText = [NSString stringWithFormat:@"%@ with %@ at %@.",truncatedText,participantsString,memoryAddressName];
            }
            else {
                updatedText = [NSString stringWithFormat:@"%@ at %@.",truncatedText,memoryAddressName];
            }
        }
    }
    
    return updatedText;
}

- (void)updateComboStarNotificationWithParticipants:(NSArray *)participants {
    
    NSString *firstParticipiant;
    NSString *secondParticipant;
    NSString *particpiantString;
    
    for (int i = 0; i < participants.count; i++) {
        if (i == 0) {
            NSDictionary *userDict = (NSDictionary *)participants[0];
            firstParticipiant = userDict[@"firstname"];
            particpiantString = firstParticipiant;
        }
        if (i == 1) {
            NSDictionary *userDict = (NSDictionary *)participants[1];
            secondParticipant = userDict[@"firstname"];
        }
    }
    
    if (participants.count == 2) {
        particpiantString = [NSString stringWithFormat:@"%@ and %@",firstParticipiant,secondParticipant];
    }
    if (participants.count == 3) {
        int othersCount = (int)participants.count - 2;
        particpiantString = [NSString stringWithFormat:@"%@ and %@ and %i other",firstParticipiant,secondParticipant,othersCount];
    }
    if (participants.count > 3) {
        int othersCount = (int)participants.count - 2;
        particpiantString = [NSString stringWithFormat:@"%@ and %@ and %i others",firstParticipiant,secondParticipant,othersCount];
    }
    
    
    NSMutableArray *tempTokensArray = [[NSMutableArray alloc] init];
    for (int i = 0; i < participants.count; i++) {
        NSDictionary *userDict = (NSDictionary *)participants[i];
        NSString *participantUserToken = userDict[@"userToken"];
        if (i < 2) {
            [tempTokensArray addObject:participantUserToken];
        }
    }
    
    self.participantTokens = [NSArray arrayWithArray:tempTokensArray];
    
    
    NSString *updatedText = [NSString stringWithFormat:@"%@ starred your memory.",particpiantString];
   
    NSString *keyActionString = @"starred";
    NSRange range = [updatedText rangeOfString:keyActionString];
    
    if (range.length > 0) {
        NSMutableAttributedString *styledText = [[NSMutableAttributedString alloc] initWithString:updatedText];
        
        //handle range for a memory notif
        NSRange creator1Range = NSMakeRange(0,firstParticipiant.length);
        NSRange creator2Range = NSMakeRange(firstParticipiant.length + 5,secondParticipant.length);
        
        //style participant names
        [styledText addAttribute:NSForegroundColorAttributeName value:self.authorHighlightColor range:creator1Range];
        [styledText addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"AvenirNext-Bold" size:14] range:creator1Range];
       
        [styledText addAttribute:NSForegroundColorAttributeName value:self.authorHighlightColor range:creator2Range];
        [styledText addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"AvenirNext-Bold" size:14] range:creator2Range];
        
        // Add line spacing
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        [paragraphStyle setLineSpacing:1.7];
        [styledText addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, styledText.length)];
        
        self.notificationBodyLabel.attributedText = styledText;
        
        NSRange leadInRange = NSMakeRange(0, creator2Range.location);
        NSString *leadIn = [updatedText substringWithRange:leadInRange];
        CGSize leadInSize = [leadIn sizeWithAttributes: @{ NSFontAttributeName: self.notificationBodyLabel.font }];

        self.participant2NameXOrigin = leadInSize.width;
        self.participant2NameYOrigin = 0;
        
        CGSize nameSize = [secondParticipant sizeWithAttributes:@{ NSFontAttributeName: self.notificationBodyLabel.font }];
        self.participant2NameWidth = nameSize.width;
    }
}

- (void)styleNotificationOfType:(NSString *)notifType withText:(NSString *)notifText {
    
    self.notif.notificationType = notifType;
    
    NSString *keyActionString = [self getActionStringForType:notifType];
    NSRange range = [notifText rangeOfString:keyActionString];
    
    // Did we find the key action?
    if (range.length > 0) {
        NSMutableAttributedString *styledText = [[NSMutableAttributedString alloc] initWithString:notifText];
        
        NSRange creatorRange = NSMakeRange(0, 0);
        if ([notifType isEqualToString:@"memory"]) {
            creatorRange = NSMakeRange(0,[notifText rangeOfString:keyActionString].location-7);
        } else if ([notifType isEqualToString:@"follow"]) {
            NSInteger strLen = notifText.length;
            NSInteger nameStart = [notifText rangeOfString:keyActionString].location + keyActionString.length + 1;
            creatorRange = NSMakeRange(nameStart, strLen - nameStart - 1);
        } else {
            creatorRange = NSMakeRange(0,[notifText rangeOfString:keyActionString].location);
        }
        
        //style the creator name
        [styledText addAttribute:NSForegroundColorAttributeName value:self.authorHighlightColor range:creatorRange];
        [styledText addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"AvenirNext-Bold" size:14] range:creatorRange];
        
        //style the action
        if ((![notifType isEqualToString:@"friendRequest"]) && (![notifType isEqualToString:@"sentFriendRequest"])) {
            // Do nothing
        }
        if ([notifType isEqualToString:@"memory"]){
            
            //handle participant styling for memories
            BOOL p2adjNeeded = NO;

            
            for (int i = 0; i< self.participantNames.count; i++){
                NSString *taggedName = self.participantNames[i];
                NSRange participantRange = [notifText rangeOfString:taggedName];
                
                if (participantRange.location != NSNotFound) {
                    [styledText addAttribute:NSForegroundColorAttributeName value:self.authorHighlightColor range:participantRange];
                    [styledText addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"AvenirNext-Bold" size:14] range:participantRange];
                    
                    float lineWidth = self.textWidth;
                   
                    //define participant button sizes
                    if (i == 0) {
                        //NSLog(@"lead in length %d, notif text %@", participantRange.location, notifText);
                        NSRange leadIn1 = NSMakeRange(0, participantRange.location);
                        NSString *leadIn = [notifText substringWithRange:leadIn1];
                        CGSize leadInSize = [leadIn sizeWithAttributes: @{ NSFontAttributeName: self.notificationBodyLabel.font }];
                        
                        if (leadInSize.width < lineWidth) {
                            self.participant1NameYOrigin = 0;
                            self.participant1NameXOrigin = leadInSize.width + 5;
                             p2adjNeeded = YES;
                        }
                        else {
                            self.participant1NameYOrigin = 25;
                            
                            if (leadInSize.width < self.textWidth) {
                                 self.participant1NameXOrigin = leadInSize.width - lineWidth;
                            }
                            else {
                                p2adjNeeded = YES;
                                self.participant1NameXOrigin = leadInSize.width - lineWidth + 10;
                            }

                        }
                    }
                    if (i == 1) {
                        
                        NSRange leadIn1 = NSMakeRange(0, participantRange.location);
                        NSString *leadIn = [notifText substringWithRange:leadIn1];
                        CGSize leadInSize = [leadIn sizeWithAttributes:@{ NSFontAttributeName: self.notificationBodyLabel.font }];
                        
                        if (leadInSize.width < lineWidth) {
                            self.participant2NameYOrigin = 0;
                            self.participant2NameXOrigin = leadInSize.width + 5;
                        }
                        else {
                            self.participant2NameYOrigin = 25;
                            self.participant2NameXOrigin = leadInSize.width - lineWidth - 10;
                            if (p2adjNeeded) {
                                self.participant2NameXOrigin = self.participant2NameXOrigin + 10;
                            }
                        }
                    }
                }
                
            }
        }
        
        if ([notifType isEqualToString:@"friendRequest"] || [notifType isEqualToString:@"followRequest"]){
            //handle buttons
            self.acceptBtn.hidden = NO;
            self.declineBtn.hidden = NO;
        }
        
        // Add line spacing
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        [paragraphStyle setLineSpacing:1.7];
        [styledText addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, styledText.length)];
        
        self.notificationBodyLabel.attributedText = styledText;
    }
    else {
        self.notificationBodyLabel.text = notifText;
    }
}

-(NSString *)getActionStringForType:(NSString *)notifType {
    
    NSString *actionString = @"";
    //NSLog(@"notifType %@",notifType);
    
    if ([notifType isEqualToString:@"memory"]) {
        actionString = @"memory";
    }
    if ([notifType isEqualToString:@"comment"]) {
        actionString = @"commented";
    }
    if ([notifType isEqualToString:@"star"]) {
        actionString = @"starred";
    }
    if ([notifType isEqualToString:@"commentStar"]) {
        actionString = @"starred";
    }
    if ([notifType isEqualToString:@"friend"]) {
        actionString = @"added";
    }
    if ([notifType isEqualToString:@"friendRequest"]) {
        actionString = @"sent";
    }
    if ([notifType isEqualToString:@"sentFriendRequest"]) {
        actionString = @"sent";
    }
    if ([notifType isEqualToString:@"followRequest"]) {
        actionString = @"requested";
    }
    if ([notifType isEqualToString:@"followedBy"]) {
        actionString = @"is";
    }
    if ([notifType isEqualToString:@"follow"]) {
        actionString = @"following";
    }
    if ([notifType isEqualToString:@"taggedInComment"]) {
        actionString = @"tagged";
    }
    
    return actionString;
}

#pragma mark - Show Participant Profile call

-(void)showProfileForParticipant:(id)sender {
    UIButton *btn = (UIButton *)sender;
    NSString *userToken = self.participantTokens[btn.tag];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"displayProfileForUserToken" object:userToken];
}

+ (CGFloat)heightForCellWithNotification:(SpayceNotification *)notification {
    // Create a temporary cell
    SPCNotificationCell *cell = [[SPCNotificationCell  alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    [cell styleNotification:notification];
    
    // Calculate it's text height
    NSAttributedString *attributedString = cell.notificationBodyLabel.attributedText;
    CGFloat attributedTextHeight = 0;
  
    float textWidth = 220.0;
    CGFloat padding = 10.0;
    
    //4.7"
    if ([UIScreen mainScreen].bounds.size.width == 375) {
        textWidth = 270.0;
        padding = 10.0;
    }
    
    //5"
    if ([UIScreen mainScreen].bounds.size.width > 375) {
        textWidth = 310.0;
        padding = 10.0;
    }
    
    //using core text to correctly handle sizing (for emoji & multiple font types
    if (attributedString) {
        CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)attributedString);
        CGSize targetSize = CGSizeMake(textWidth, CGFLOAT_MAX);
        CGSize fitSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, [attributedString length]), NULL, targetSize, NULL);
        attributedTextHeight = fitSize.height;
        CFRelease(framesetter);
    }
    
    //NSLog(@"notification text %@",notification.notificationText);
    //NSLog(@"att height %f",attributedTextHeight);
    
    CGFloat strHeight = ceilf(attributedTextHeight);
    CGFloat height = MAX(45.0, strHeight);
    if (([UIScreen mainScreen].bounds.size.width <= 375) && (attributedTextHeight > 35)) {
        ///NSLog(@"padding adj!");
        padding = 15;
    }
    
    if ([SpayceNotification retrieveNotificationType:notification] == NOTIFICATION_TYPE_FOLLOW_REQUEST) {
        return 0;
        //return MAX(105.0, strHeight + 60);
    }
  
    //NSLog(@"news cell height?? %f",height + padding * 2.0);
    
    return height + padding * 2.0;
}

- (void)configureWithText:(NSString *)text url:(NSURL *)url {
    [self.customImageView configureWithText:[text.firstLetter capitalizedString] url:url];
}

@end
