//
//  SWCommentsCell.m
//  Spayce
//
//  Created by Christopher Taylor on 6/19/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SWCommentsCell.h"

// Framework
#import <CoreText/CoreText.h>

// Model
#import "Asset.h"

// View
#import "SPCInitialsImageView.h"

// Category
#import "NSDate+SPCAdditions.h"
#import "NSString+SPCAdditions.h"

// Manager
#import "MeetManager.h"

// Utilities
#import "APIUtils.h"


@interface SWCommentsCell ()

@property (nonatomic, strong) SPCInitialsImageView *customImageView;
@property (nonatomic, strong) UILabel *userIsYouLabel;
@property (nonatomic, assign) CGFloat commentTextWidth;
@property (nonatomic, strong) UIButton *btnActions;
@property (nonatomic, strong) UIImageView *ivDots; // Hosted inside the btnActions view

@end

@implementation SWCommentsCell

#pragma mark - Object lifecycle

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.autoresizesSubviews = YES;
        self.clearsContextBeforeDrawing = YES;
        self.opaque = YES;
        
        [self configureCommentTextWidth];
        
        _customImageView = [[SPCInitialsImageView alloc] initWithFrame:CGRectMake(12, 9, 45, 45)];
        _customImageView.backgroundColor = [UIColor whiteColor];
        _customImageView.contentMode = UIViewContentModeScaleAspectFill;
        _customImageView.layer.cornerRadius = 22.5;
        _customImageView.layer.masksToBounds = YES;
        _customImageView.textLabel.font = [UIFont spc_placeholderFont];
        [self.contentView addSubview:_customImageView];
        
        _imageButton = [[UIButton alloc] initWithFrame:_customImageView.frame];
        _imageButton.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:_imageButton];
        
        _userIsYouLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 36, 15)];
        _userIsYouLabel.center = CGPointMake(_customImageView.center.x, _customImageView.frame.origin.y + 43);
        _userIsYouLabel.backgroundColor = [UIColor colorWithRGBHex:0x998fcc];
        _userIsYouLabel.layer.cornerRadius = 7.5;
        _userIsYouLabel.layer.masksToBounds = YES;
        _userIsYouLabel.layer.borderColor = [UIColor whiteColor].CGColor;
        _userIsYouLabel.layer.borderWidth = 1.5;
        _userIsYouLabel.font = [UIFont spc_boldSystemFontOfSize:8];
        _userIsYouLabel.text = @"You";
        _userIsYouLabel.textAlignment = NSTextAlignmentCenter;
        _userIsYouLabel.textColor = [UIColor whiteColor];
        [self.contentView addSubview:_userIsYouLabel];
        
        
        self.commentLbl = [[STTweetLabel alloc] initWithFrame:CGRectZero];
        self.commentLbl.detectHotWords = NO;  // only manual annotation
        self.commentLbl.detectHashTags = YES;
        __weak SWCommentsCell *weakSelf = self;
        [self.commentLbl setDetectionBlock:^(STTweetHotWord hotWord, NSString * string, NSString * protocol, NSRange range) {
            if (hotWord == STTweetAnnotation) {
                if (weakSelf.taggedUserTappedBlock) {
                    NSLog(@"tap on tagged user, try to exectue block!");
                    weakSelf.taggedUserTappedBlock(string);
                } else {
                    NSLog(@"tap on tagged user with token %@, but no block to execute", string);
                }
            }
            else if (hotWord == STTweetHashtag) {
                if (weakSelf.hashTagTappedBlock) {
                    weakSelf.hashTagTappedBlock(string);
                }
                else {
                    NSLog(@"tapped on hash tag %@, but no blcok to execute",string);
                }
            }
        }];
        self.commentLbl.backgroundColor = [UIColor clearColor];
        self.commentLbl.font = [UIFont spc_regularSystemFontOfSize:14];
        self.commentLbl.textColor = [UIColor colorWithRGBHex:0x14294b];
        self.commentLbl.numberOfLines = 0;
        self.commentLbl.userInteractionEnabled = YES;
        self.commentLbl.lineBreakMode = NSLineBreakByWordWrapping;
        [self.contentView addSubview:self.commentLbl];
        
        self.timeLbl = [[UILabel alloc] initWithFrame:CGRectZero];
        self.timeLbl.font = [UIFont spc_regularSystemFontOfSize:12];
        self.timeLbl.textAlignment = NSTextAlignmentLeft;
        self.timeLbl.backgroundColor = [UIColor clearColor];
        self.timeLbl.textColor = [UIColor colorWithRed:172.0f/255.0f green:182.0f/255.0f blue:198.0f/255.0f alpha:1.0f];
        [self.contentView addSubview:self.timeLbl];
        
        self.commenterNameLbl = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.customImageView.frame)+10.0, 15, CGRectGetWidth(self.contentView.frame)-CGRectGetMaxX(self.customImageView.frame)-CGRectGetWidth(self.timeLbl.frame)-20.0, 15)];
        self.commenterNameLbl.font = [UIFont spc_boldSystemFontOfSize:14];
        self.commenterNameLbl.backgroundColor = [UIColor clearColor];
        self.commenterNameLbl.textColor = [UIColor colorWithRGBHex:0x14294b];
        [self.contentView addSubview:self.commenterNameLbl];
        
        self.separatorLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 1)];
        self.separatorLine.backgroundColor = [UIColor colorWithWhite:243/255.0f alpha:1.0f];
        [self.contentView addSubview:self.separatorLine];
        
        self.separatorLine.frame = CGRectMake(0, self.frame.size.height -(1.0f / [UIScreen mainScreen].scale), self.frame.size.width, (1.0f / [UIScreen mainScreen].scale));
        
        self.starIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"star-lightgray-x-small"]];
        [self.contentView addSubview:self.starIcon];
        
        self.starLbl = [[UILabel alloc] initWithFrame:CGRectZero];
        self.starLbl.backgroundColor = [UIColor clearColor];
        self.starLbl.textColor = [UIColor colorWithRed:172.0f/255.0f green:182.0f/255.0f blue:198.0f/255.0f alpha:1.0f];
        self.starLbl.font = [UIFont spc_regularSystemFontOfSize:12];
        [self.contentView addSubview:self.starLbl];
        
        
        self.starBtn = [[UIButton alloc] initWithFrame:CGRectZero];
        self.starBtn.backgroundColor = [UIColor clearColor];
        [self.starBtn addTarget:self action:@selector(toggleCommentStar:) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:self.starBtn];
        
        self.btnActions = [[UIButton alloc] initWithFrame:CGRectZero];
        self.btnActions.backgroundColor = [UIColor clearColor];
        [self.btnActions addTarget:self action:@selector(tappedActionsButton:) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:self.btnActions];
        // Add the 'dots' image to the button
        self.ivDots = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"comment-cell-dots"]];
        self.ivDots.contentMode = UIViewContentModeCenter;
        [self.btnActions addSubview:self.ivDots];
    }
    return self;
}

-(void)prepareForReuse {
    UIView *view;
    NSArray *subs = [self.commentLbl subviews];
    
    //remove buttons that are used to tap tagged participants in comments
    for (view in subs) {
        if (view.tag >= 2000) {
            [view removeFromSuperview];
        }
    }
    
    // Clear target action
    [self.imageButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
}

- (void)configureWithCleanComment:(Comment *)comment tag:(NSInteger)tag isCurrentUser:(BOOL)isCurrentUser {
    self.currComment = comment;
    self.commenterNameLbl.text = comment.userName;
    self.commentLbl.text = comment.text;
    self.commentId = comment.recordID;
    self.taggedUserNames = comment.taggedUserNames;
    self.taggedUserTokens = comment.taggedUserTokens;
    
    self.userIsYouLabel.hidden = !isCurrentUser;
    
    //if (self.taggedUserNames.count > 0) {
        [self styleTaggedUserNames];
    //}
    
    NSString *timeLblText = [NSDate longFormattedDateStringWithString:comment.dateCreated];
    self.timeLbl.text = [NSString stringWithFormat:@"%@   |   ",timeLblText];
    
    CGFloat height = [SWCommentsCell heightForCommentText:comment.text];
    
    self.commentLbl.frame = CGRectMake(CGRectGetMinX(self.commenterNameLbl.frame), CGRectGetMaxY(self.commenterNameLbl.frame)+1, self.commentTextWidth, height);
    
    self.timeLbl.frame = CGRectMake(CGRectGetMinX(self.commentLbl.frame), CGRectGetMaxY(self.commentLbl.frame)+2, 93, self.timeLbl.font.lineHeight);
    [self.timeLbl sizeToFit];
    self.starIcon.frame = CGRectMake(CGRectGetMaxX(self.timeLbl.frame)-4, CGRectGetMinY(self.timeLbl.frame)-1, self.starIcon.frame.size.width, self.starIcon.frame.size.height);
    
    self.userHasStarred = comment.userHasStarred;
    self.starIcon.image = [UIImage imageNamed:@"star-lightgray-x-small"];
    if (self.userHasStarred) {
        self.starIcon.image = [UIImage imageNamed:@"star-gold-x-small"];
    }
    
    self.starBtn.frame = CGRectMake(CGRectGetMaxX(self.timeLbl.frame)-4, CGRectGetMinY(self.timeLbl.frame)-1, 90, self.starIcon.frame.size.height);
    self.starBtn.userInteractionEnabled = YES;
    
    starCount = (int)comment.starCount;
    
    self.starLbl.text = @"";
    if (starCount > 0){
        self.starLbl.text = [NSString stringWithFormat:@"%i",starCount];
    }
    self.starLbl.frame = CGRectMake(CGRectGetMaxX(self.starIcon.frame)+1, CGRectGetMinY(self.timeLbl.frame), 50, self.starIcon.frame.size.height);
    
    NSURL *url;
    
    if (comment.pic){
        //comments from server
        url = [NSURL URLWithString:[APIUtils imageUrlStringForUrlString:comment.pic.imageUrlHalfSquare size:ImageCacheSizeSquareMedium]];
    }
    else {
        //local comments
        url = [NSURL URLWithString:comment.localPicUrl];
    }
        
    [self configureWithText:comment.userName url:url];
    
    self.btnActions.frame = CGRectMake(CGRectGetWidth(self.contentView.frame) - 40, CGRectGetHeight(self.contentView.frame)/2.0f - 20, 40, 40);
    self.ivDots.frame = CGRectMake(29, 10, 4, 20);
}

- (void)configureWithText:(NSString *)text url:(NSURL *)url {
    [self.customImageView configureWithText:[text.firstLetter capitalizedString] url:url];
}

- (void)configureCommentTextWidth {
    
    self.commentTextWidth = 240	;
    
    if ([UIScreen mainScreen].bounds.size.width == 375) {
        self.commentTextWidth = 295;
    }

    if ([UIScreen mainScreen].bounds.size.width > 375) {
        self.commentTextWidth = 330;
    }
}

-(void)styleTaggedUserNamesLegacy {
    // "Old Style" tags matched the user names against the text of the comment.
    // This lead to some difficult to sort bugs, e.g. broken tags when a user changes
    // their name, tags moving to the earliest example of the appropriate text, etc.
    NSMutableAttributedString *styledText = [[NSMutableAttributedString alloc] initWithString:self.commentLbl.text];
    NSRange fullRange = NSMakeRange(0, styledText.length);
    [styledText addAttribute:NSFontAttributeName value:self.commentLbl.font range:fullRange];
    
    for (int i = 0; i < self.taggedUserNames.count; i++) {
        NSString *nameToFind = [self.taggedUserNames objectAtIndex:i];
        NSRange styleRange = [self.commentLbl.text rangeOfString:nameToFind];
        [styledText addAttribute:@"STTweetAnnotationHotWord" value:[self.taggedUserTokens objectAtIndex:i] range:styleRange];
        [styledText addAttribute:NSFontAttributeName value:self.commentLbl.font range:styleRange];
        [styledText addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:97.0f/255.0f green:166.0f/255.0f blue:244.0f/255.0f alpha:1.0f] range:styleRange];
    }
    self.commentLbl.attributedText = styledText;
}


- (void)styleTaggedUserNames {
    // "New style" comments.  Markup text contains @{<userId>} substrings, which should be
    // replaced by the first name of the indicated user.  Incidences of "@\" are considered
    // escaped versions of "@" and should be replaced with such.
    if (![self.currComment.markupText isEqualToString:self.currComment.text]) {
        @try {
            NSDictionary *attributes = @{ NSFontAttributeName: self.commentLbl.font, NSForegroundColorAttributeName: [UIColor colorWithRGBHex:0x14294b] };
            NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:self.currComment.markupText attributes:attributes];
            
            // Note: it may strike you as more convenient to simply examine our list of tagged user IDs and
            // find-and-replace the strings @{id1}, @{id2}, etc. with their names.
            // Convenient, sure, but also insecure, because we don't have control over usernames and
            // (as of this moment) the string "@{666}" is a perfectly valid username, allowing tag
            // injection by malicious users through name changes.
            
            // Instead, we do a single linear pass through the text to ensure we don't replace
            // the same markup more than once.  As long as the comment itself was posted by
            // a well-behaved client, it should correctly process.
            NSRange atRange = [[attrString string] rangeOfString:@"@"];
            while (atRange.location != NSNotFound && atRange.location < attrString.length - 1) {
                NSInteger nextSearch = atRange.location + 1;
                
                char nextChar = [[attrString string] characterAtIndex:(atRange.location + 1)];
                // escaped @\ ?
                if (nextChar == '\\') {
                    [attrString replaceCharactersInRange:NSMakeRange(atRange.location, 2) withString:@"@"];
                } else if (nextChar == '{') {
                    NSRange endRange = [[attrString string] rangeOfString:@"}" options:0 range:NSMakeRange(atRange.location, attrString.length - atRange.location)];
                    if (endRange.location != NSNotFound) {
                        NSRange replaceRange = NSMakeRange(atRange.location, endRange.location - atRange.location + 1);
                        NSRange idRange = NSMakeRange(atRange.location+2, endRange.location - atRange.location - 2);
                        NSString *idStr = [[attrString string] substringWithRange:idRange];
                        NSString *userName = nil;
                        NSString *userToken = nil;
                        for (int i = 0; i < self.currComment.taggedUserIds.count; i++) {
                            NSObject *taggedId = self.currComment.taggedUserIds[i];
                            NSString *taggedIdStr;
                            if ([taggedId isKindOfClass:[NSString class]]) {
                                taggedIdStr = (NSString *)taggedId;
                            } else {
                                taggedIdStr = [NSString stringWithFormat:@"%d", [((NSNumber *)taggedId) intValue]];
                            }
                            if ([taggedIdStr isEqualToString:idStr]) {
                                userName = self.currComment.taggedUserNames[i];
                                userToken = self.currComment.taggedUserTokens[i];
                            }
                        }
                        if (userName) {
                            NSDictionary *nameAttributes = @{ @"STTweetAnnotationHotWord" : userToken,
                                                              NSFontAttributeName : self.commentLbl.font,
                                                              NSForegroundColorAttributeName : [UIColor colorWithRed:97.0f/255.0f green:166.0f/255.0f blue:244.0f/255.0f alpha:1.0f] };
                            NSAttributedString *styledName = [[NSAttributedString alloc] initWithString:userName attributes:nameAttributes];
                            [attrString replaceCharactersInRange:replaceRange withAttributedString:styledName];
                            nextSearch = atRange.location + styledName.length;
                        }
                    }
                }
                
                atRange = [[attrString string] rangeOfString:@"@" options:0 range:NSMakeRange(nextSearch, attrString.length - nextSearch)];
            }
            
            self.commentLbl.attributedText = attrString;
        }
        @catch (NSException *e) {
            // old style instead
            NSLog(@"Exception %@: using old style instead", e);
            [self styleTaggedUserNamesLegacy];
        }
    } else {
        [self styleTaggedUserNamesLegacy];
    }
}

+ (CGFloat)heightForCommentText:(NSString *)commentText {
    
    
    float commentTextWidth = 240;
    
    if ([UIScreen mainScreen].bounds.size.width == 375) {
        commentTextWidth = 295;
    }
    
    if ([UIScreen mainScreen].bounds.size.width > 375) {
        commentTextWidth = 330;
    }
    
    NSDictionary *attributes = @{ NSFontAttributeName: [UIFont spc_regularSystemFontOfSize:14]};
    NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:commentText attributes:attributes];
    
    //using core text to correctly handle sizing for emoji
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)attrString);
    CGSize targetSize = CGSizeMake(commentTextWidth, CGFLOAT_MAX);
    CGSize fitSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, [attrString length]), NULL, targetSize, NULL);
    CFRelease(framesetter);

    float roundedHeight = ceilf(fitSize.height);
    
    return MAX(18.0, roundedHeight + 2.0);
    
}

+ (CGFloat)cellHeightForCommentText:(NSString *)commentText {
    CGFloat commentHeight = [[self class] heightForCommentText:commentText];
    CGFloat commenterHeight = 15.0;
    CGFloat padding = 12.0;
    CGFloat commentsStarsTimesHeight = 19.0;
    
    
    return commentHeight + commenterHeight + commentsStarsTimesHeight + padding * 2.0 > 80 ? commentHeight + commenterHeight + commentsStarsTimesHeight + padding * 2.0 : 80;

}

-(void)toggleCommentStar:(id)sender {
    self.starBtn.userInteractionEnabled = NO;
    
    if (self.currComment.recordID > 0) {
    
        //unstar commment
        if (self.userHasStarred) {
            
            //update locally immediately
            self.starIcon.image = [UIImage imageNamed:@"star-lightgray-x-small"];
            self.userHasStarred = NO;
            
            starCount = starCount - 1;
            if (starCount > 0) {
                self.starLbl.text = [NSString stringWithFormat:@"%i",starCount];
            }
            else {
                self.starLbl.text = @"";
            }
          
            //update vc data
            self.currComment.starCount = starCount;
            self.currComment.userHasStarred = NO;
            [self.delegate updateComment:self.currComment];
            
            //update on server
            __weak typeof(self) weakSelf = self;
            [MeetManager deleteStarFromComment:self.currComment
                                   resultCallback:^{
                                       NSLog(@"success deleting star on comment!");
                                       __strong typeof(weakSelf) strongSelf = weakSelf;
                                       strongSelf.starBtn.userInteractionEnabled = YES;
                                       
                                   }
                                    faultCallback:^(NSError *error){
                                        NSLog(@"correct local update!");
                                        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Oops"
                                                                                            message:@"There was an error deleting the star on this commment. Please check your connection and try again."
                                                                                           delegate:nil
                                                                                  cancelButtonTitle:@"OK"
                                                                                  otherButtonTitles:nil];
                                        [alertView show];
                                        __strong typeof(weakSelf) strongSelf = weakSelf;
                                        strongSelf.userHasStarred = YES;
                                        strongSelf.starBtn.userInteractionEnabled = YES;
                                        strongSelf.starIcon.image = [UIImage imageNamed:@"star-gold-x-small"];
                                        starCount = starCount + 1;
                                        strongSelf.starLbl.text = [NSString stringWithFormat:@"%i",starCount];
                                       
                                        //update vc data
                                        strongSelf.currComment.starCount = starCount;
                                        strongSelf.currComment.userHasStarred = YES;
                                        [strongSelf.delegate updateComment:strongSelf.currComment];

                                    }];
        }
        //star comment
        else {
            
            //update locally immediately
            self.starIcon.image = [UIImage imageNamed:@"star-gold-x-small"];
            self.userHasStarred = YES;
            
            starCount = starCount + 1;
            self.starLbl.text = [NSString stringWithFormat:@"%i",starCount];
            
            
            //update vc data
            self.currComment.starCount = starCount;
            self.currComment.userHasStarred = YES;
            [self.delegate updateComment:self.currComment];
            
            
            //update on server
            __weak typeof(self) weakSelf = self;
            [MeetManager addStarToComment:self.currComment
                                   resultCallback:^{
                                       NSLog(@"success starring comment!");
                                       __strong typeof(weakSelf) strongSelf = weakSelf;
                                       strongSelf.starBtn.userInteractionEnabled = YES;
                                    }
                                    faultCallback:^(NSError *error){
                                        NSLog(@"error starring comment %@",error);
                                        NSLog(@"correct local update!");
                                        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Oops"
                                                                                            message:@"There was an error adding a star on this commment. Please check your connection and try again."
                                                                                           delegate:nil
                                                                                  cancelButtonTitle:@"OK"
                                                                                  otherButtonTitles:nil];
                                        [alertView show];
                                        
                                        __strong typeof(weakSelf) strongSelf = weakSelf;
                                        strongSelf.userHasStarred = NO;
                                        strongSelf.starIcon.image = [UIImage imageNamed:@"star-lightgray-x-small"];
                                        strongSelf.starBtn.userInteractionEnabled = YES;
                                        starCount = starCount - 1;
                                        if (starCount > 0) {
                                            strongSelf.starLbl.text = [NSString stringWithFormat:@"%i",starCount];
                                        }
                                        else {
                                            strongSelf.starLbl.text = @"";
                                        }
                                        //update vc data
                                        strongSelf.currComment.starCount = starCount;
                                        strongSelf.currComment.userHasStarred = NO;
                                        [strongSelf.delegate updateComment:strongSelf.currComment];
                                    }];
        }
    
    }
}

- (void)tappedActionsButton:(id)sender {
    if ([self isUtilityButtonsHidden]) {
        [self showRightUtilityButtonsAnimated:YES];
    } else {
        [self hideUtilityButtonsAnimated:YES];
    }
}

@end
