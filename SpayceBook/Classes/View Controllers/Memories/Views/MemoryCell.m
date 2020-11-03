//
//  MemoryCell.m
//  Spayce
//
//  Created by Jake Rosin on 5/1/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "MemoryCell.h"

// Framework
#import <GoogleMaps/GoogleMaps.h>
#import "AuthenticationManager.h"
#import "User.h"

// Model
#import "Comment.h"
#import "Location.h"
#import "Person.h"
#import "SPCMapDataSource.h"
#import "Asset.h"

// View
#import "MemoryActionButton.h"

// Utils
#import "UIImageView+WebCache.h"
#import "SPCTerritory.h"


#define kDEFAULT_ACTION_BUTTON_WIDTH 36
#define kDEFAULT_ACTION_BUTTON_HEIGHT 35
#define kDEFAULT_ACTION_BUTTON_VERTICAL_OFFSET_UP 65
#define kMAX_ACTION_TEXT_WIDTH 50
#define kDEFAULT_EMPTY_HEIGHT 149
#define kDEFAULT_IMAGE_HEIGHT 104
#define kDEFAULT_VIDEO_HEIGHT 104
#define kDEFAULT_MAP_HEIGHT 254
#define kDEFAULT_FRIENDS_HEIGHT 249

#define kMAP_HEIGHT 150
#define kMAP_HEIGHT_EXTENSION 25
#define kFRIENDS_HEIGHT 145

#define kFRIENDS_TAG_AUTHOR_IMAGEVIEW 1001
#define kFRIENDS_TAG_OTHER_IMAGEVIEW 1002
#define kFRIENDS_TAG_AUTHOR_BUTTON 1003
#define kFRIENDS_TAG_OTHER_BUTTON 1004
#define kFRIENDS_TAG_AUTHOR_INITIAL_LBL 1005
#define kFRIENDS_TAG_OTHER_INITIAL_LBL 1006


@interface MemoryCell ()

@property (assign, nonatomic) MemoryType memoryType;

@property (strong, nonatomic) UIView *bgView;
@property (strong, nonatomic) UIView *bgViewInner;
@property (strong, nonatomic) UIView *bgViewInnerBg;
@property (strong, nonatomic) UIImageView *detailImageView;

@property (strong, nonatomic) UIView * memoryContentView;
@property (strong, nonatomic) UIButton *memoryContentButton;

@property (strong, nonatomic) UIImageView *profilePhotoView;
@property (strong, nonatomic) UILabel *profilePhotoPlaceholder;

@property (strong, nonatomic) STTweetLabel *authorLabel;
@property (strong, nonatomic) UILabel *dateLabel;
@property (strong, nonatomic) UILabel *anonLabel;


@property (strong, nonatomic) Memory *memory;
@property (strong, nonatomic) NSAttributedString *memoryText;

@property (strong, nonatomic) UIImageView *userToStarAsyncImageLoaderView;

@property (strong, nonatomic) UIView *starAnimationBg;
@property (strong, nonatomic) UIImageView *starAnimationStar;

@property (strong, nonatomic) UIView * memoryCommentPreview;
@property (strong, nonatomic) UIImageView *checkMark;
@property (nonatomic, assign) BOOL hasShownAnonAlert;

@end

@implementation MemoryCell {
    float textHeight;

    CGFloat commentPreviewHeight;
}

- (void)dealloc
{
    [self cancelFetchingImage];
}

- (id)initWithMemoryType:(MemoryType)type style:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.memoryType = type;
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.contentView.backgroundColor = [UIColor colorWithRed:230.0f/255.0f green:231.0f/255.0f blue:231.0f/255.0f alpha:1.0f];
        
        self.textLabel.hidden = YES;
        self.textLabel.frame = CGRectZero;
        
        self.memoryTextLabel = [[STTweetLabel alloc] initWithFrame:CGRectZero];
        self.memoryTextLabel.font = [UIFont spc_memory_textFont];
        self.memoryTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.memoryTextLabel.numberOfLines = 0;
        self.memoryTextLabel.detectHotWords = NO;  // only manual annotation
        self.memoryTextLabel.detectHashTags = YES;
        self.memoryTextLabel.backgroundColor = [UIColor clearColor];
        __weak MemoryCell *weakSelf = self;
        [self.memoryTextLabel setDetectionBlock:^(STTweetHotWord hotWord, NSString * string, NSString * protocol, NSRange range) {
            if (hotWord == STTweetAnnotation) {
                if (weakSelf.taggedUserTappedBlock) {
                    weakSelf.taggedUserTappedBlock(string);
                } else {
                    NSLog(@"tap on tagged user with token %@, but no block to execute", string);
                }
            }
            else if (hotWord == STTweetHashtag) {
                if (weakSelf.hashTagTappedBlock) {
                    weakSelf.hashTagTappedBlock(string, weakSelf.memory);
                }
                else {
                    NSLog(@"tapped on hash tag %@, but no blcok to execute",string);
                }
            }
        }];
        [self.contentView addSubview:self.memoryTextLabel];
        
        self.locationLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.locationLabel.backgroundColor = [UIColor clearColor];
        self.locationLabel.font = [UIFont spc_memory_locationFont];
        self.locationLabel.textColor = [UIColor colorWithRed:172.0f/255.0f green:182.0f/255.0f blue:198.0f/255.0f alpha:1.0f];
        [self.locationLabel addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(locationTapped:)]];
        self.locationLabel.userInteractionEnabled = YES;
        
        self.bgView = [[UIView alloc] initWithFrame:CGRectZero];
        self.bgView.backgroundColor = [UIColor  clearColor];
        [self.bgView.layer setCornerRadius:0.0f];
        [self.contentView addSubview:self.bgView];
        
        self.bgViewInner = [[UIView alloc] initWithFrame:CGRectZero];
        self.bgViewInner.clipsToBounds = YES;
        self.bgViewInner.backgroundColor = [UIColor whiteColor];
        [self.bgViewInner.layer setCornerRadius:0.0f];
        [self.contentView addSubview:self.bgViewInner];
        
        self.bgViewInnerBg = [[UIView alloc] initWithFrame:CGRectZero];
        self.bgViewInnerBg.backgroundColor = [UIColor whiteColor];
        [self.bgViewInnerBg.layer setCornerRadius:0.0f];
        [self.bgViewInner addSubview:self.bgViewInnerBg];
        
        _detailImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"pin-gray-x-small"]];
        [self.contentView addSubview:_detailImageView];
        
        if (self.memoryType == MemoryTypeText) {
            // Nothing special.  We have no additional content to display.
            self.memoryContentView = [[UIView alloc] initWithFrame:CGRectZero];
        } else if (self.memoryType == MemoryTypeImage) {
            // An image scroller
            self.memoryContentView = [[SPCFeedPhotoScroller alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.bounds), CGRectGetWidth(self.bounds))];
            self.memoryContentView.backgroundColor = [UIColor colorWithWhite:.2 alpha:1];
            self.memoryContentView.clipsToBounds = NO;
            self.bgViewInner.clipsToBounds = NO;
        } else if (self.memoryType == MemoryTypeVideo) {
            // An image scroller (we add video play buttons as well)
            self.memoryContentView = [[SPCFeedVideoScroller alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.bounds), CGRectGetWidth(self.bounds))];
            self.memoryContentView.backgroundColor = [UIColor colorWithWhite:.2 alpha:1];
            self.memoryContentView.clipsToBounds = NO;
            self.bgViewInner.clipsToBounds = NO;
        } else if (self.memoryType == MemoryTypeMap) {
            // A GMSMapView that does not allow user interaction.
            GMSMapView * mapView = [[GMSMapView alloc] initWithFrame:CGRectMake(0, -kMAP_HEIGHT_EXTENSION, CGRectGetWidth(self.contentView.frame)-10, kMAP_HEIGHT + kMAP_HEIGHT_EXTENSION*2)];
            mapView.clipsToBounds = YES;
            self.memoryContentView = [[UIView alloc] initWithFrame:CGRectMake(10, 10, CGRectGetWidth(self.contentView.frame)-10, kMAP_HEIGHT)];
            self.memoryContentView.clipsToBounds = YES;
            [self.memoryContentView addSubview:mapView];
            mapView.userInteractionEnabled = NO;
            self.memoryContentButton = [[UIButton alloc] initWithFrame:CGRectMake(10, 10, CGRectGetWidth(self.contentView.frame)-10, kMAP_HEIGHT)];
            [self.memoryContentButton addTarget:self action:@selector(locationTapped:) forControlEvents:UIControlEventTouchUpInside];
        } else if (self.memoryType == MemoryTypeFriends) {
            // An empty view containing two image views (overlapping in a Venn diagram
            // formation, tagged with kFRIENDS_TAG_AUTHOR_IMAGEVIEW and kFRIENDS_TAG_OTHER_IMAGEVIEW).
            self.memoryContentView = [[UIView alloc] initWithFrame:CGRectMake(10, 10, CGRectGetWidth(self.contentView.frame)-10, kFRIENDS_HEIGHT)];
            
            UIImageView *authorImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 85, 85)];
            authorImageView.layer.cornerRadius = 42.5;
            authorImageView.clipsToBounds = YES;
            authorImageView.tag = kFRIENDS_TAG_AUTHOR_IMAGEVIEW;
            authorImageView.backgroundColor = [UIColor clearColor];
            
            UIButton *authorButton = [[UIButton alloc] initWithFrame:authorImageView.frame];
            authorButton.layer.cornerRadius = 42.5;
            authorButton.clipsToBounds = YES;
            authorButton.tag = kFRIENDS_TAG_AUTHOR_BUTTON;
            authorButton.backgroundColor = [UIColor clearColor];
            [authorButton addTarget:self action:@selector(addFriendButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
            
            UILabel *initialLbl = [[UILabel alloc] initWithFrame:authorButton.frame];
            initialLbl.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1];
            initialLbl.tag = kFRIENDS_TAG_AUTHOR_INITIAL_LBL;
            initialLbl.textColor = [UIColor whiteColor];
            initialLbl.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:28];
            initialLbl.layer.cornerRadius = 42.5;
            initialLbl.textAlignment = NSTextAlignmentCenter;
            initialLbl.clipsToBounds = YES;
            
            UIImageView *otherImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 85, 85)];
            otherImageView.layer.cornerRadius = 42.5;
            otherImageView.clipsToBounds = YES;
            otherImageView.tag = kFRIENDS_TAG_OTHER_IMAGEVIEW;
            otherImageView.backgroundColor = [UIColor clearColor];
            
            UIButton *otherButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 85, 85)];
            otherButton.layer.cornerRadius = 42.5;
            otherButton.clipsToBounds = YES;
            otherButton.tag = kFRIENDS_TAG_OTHER_BUTTON;
            otherButton.backgroundColor = [UIColor clearColor];
            [otherButton addTarget:self action:@selector(addFriendButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
            
            UILabel *otherInitialLbl = [[UILabel alloc] initWithFrame:otherButton.frame];
            otherInitialLbl.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1];
            otherInitialLbl.tag = kFRIENDS_TAG_OTHER_INITIAL_LBL;
            otherInitialLbl.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:28];
            otherInitialLbl.layer.cornerRadius = 42.5;
            otherInitialLbl.textAlignment = NSTextAlignmentCenter;
            otherInitialLbl.clipsToBounds = YES;
            
            [self.memoryContentView addSubview:initialLbl];
            [self.memoryContentView addSubview:otherInitialLbl];
            
            [self.memoryContentView addSubview:authorImageView];
            [self.memoryContentView addSubview:otherImageView];
            
            [self.memoryContentView addSubview:authorButton];
            [self.memoryContentView addSubview:otherButton];
        }
        
        [self.bgViewInner addSubview:self.memoryContentView];
        if (self.memoryContentButton) {
            [self.bgViewInner addSubview:self.memoryContentButton];
        }
        [self.contentView sendSubviewToBack:self.bgViewInner];
        [self.contentView sendSubviewToBack:self.bgView];
        
        
        self.authorLabel = [[STTweetLabel alloc] initWithFrame:CGRectZero];
        self.authorLabel.font = [UIFont spc_memory_authorFont];
        self.authorLabel.backgroundColor = [UIColor clearColor];
        self.authorLabel.textColor = [UIColor colorWithRed:1.0f/255.0f green:24.0f/255.0f blue:38.0f/255.0f alpha:1.0f];
        self.authorLabel.detectHotWords = NO;  // only manual annotation
   
        [self.authorLabel setDetectionBlock:^(STTweetHotWord hotWord, NSString * string, NSString * protocol, NSRange range) {
            if (weakSelf.memory.isAnonMem) {
                NSLog(@"tapped anon block??");
                if (!weakSelf.hasShownAnonAlert) {
                    weakSelf.hasShownAnonAlert = YES;
                    [[[UIAlertView alloc] initWithTitle:nil message:@"Anonymous memories don't have a profile." delegate:weakSelf cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] show];
                }
            }
            else if (hotWord == STTweetAnnotation) {
                if (weakSelf.taggedUserTappedBlock) {
                    weakSelf.taggedUserTappedBlock(string);
                }
                else {
                    NSLog(@"tap on tagged user with token %@, but no block to execute", string);
                }
            }
        }];
        
        [self.contentView addSubview:self.locationLabel];
        [self.contentView addSubview:self.authorLabel];
        
        self.dateLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.dateLabel.backgroundColor = [UIColor whiteColor];
        self.dateLabel.font = [UIFont spc_regularSystemFontOfSize:14];
        self.dateLabel.textColor = [UIColor colorWithRed:172.0f/255.0f green:182.0f/255.0f blue:198.0f/255.0f alpha:1.0f];
        [self.contentView addSubview:self.dateLabel];
        
        self.anonLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.anonLabel.backgroundColor = [UIColor whiteColor];
        self.anonLabel.font = [UIFont spc_mediumSystemFontOfSize:14];
        self.anonLabel.textColor = [UIColor colorWithRGBHex:0xacb6c6];
        [self.contentView addSubview:self.anonLabel];
        
        _profilePhotoPlaceholder = [[UILabel alloc] initWithFrame:CGRectZero];
        _profilePhotoPlaceholder.backgroundColor = [UIColor colorWithRed:154.0/255.0 green:166.0/255.0 blue:171.0/255.0 alpha:1.0];
        _profilePhotoPlaceholder.textAlignment = NSTextAlignmentCenter;
        _profilePhotoPlaceholder.textColor = [UIColor whiteColor];
        _profilePhotoPlaceholder.font = [UIFont spc_memory_placeholderFont];
        [self.contentView addSubview:_profilePhotoPlaceholder];
        
        _profilePhotoView  = [[UIImageView alloc] initWithFrame:CGRectZero];
        _profilePhotoView.backgroundColor = [UIColor colorWithRed:154.0/255.0 green:166.0/255.0 blue:171.0/255.0 alpha:1.0];
        [self.contentView addSubview:_profilePhotoView];
        
        _commentsButton = [[MemoryActionButton alloc] initWithFrame:CGRectZero];
        [self.contentView addSubview:_commentsButton];
        
        _usersToStarButton = [[MemoryActionButton alloc] initWithFrame:CGRectZero];
        [self.contentView addSubview:_usersToStarButton];
        
        _starsButton = [[MemoryActionButton alloc] initWithFrame:CGRectZero];
        [_starsButton addTarget:self action:@selector(animateStar:) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:_starsButton];
        
        _authorButton = [[UIButton alloc] initWithFrame:CGRectZero];
        _authorButton.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:_authorButton];
        
        _actionButton = [[UIButton alloc] init];
        [_actionButton setImage:[UIImage imageNamed:@"memory-action"] forState:UIControlStateNormal];
        [self.contentView addSubview:_actionButton];
        
        
        _followButton = [[UIButton alloc] init];
        [_followButton setImage:[UIImage imageNamed:@"friendship-follow"] forState:UIControlStateNormal];
        _followButton.hidden = YES;
        [self.contentView addSubview:_followButton];
        
        _memoryCommentPreview = [[UIView alloc] initWithFrame:CGRectZero];
        _memoryCommentPreview.userInteractionEnabled = YES;
        _memoryCommentPreview.backgroundColor = [UIColor colorWithWhite:250.0f/255.0f alpha:1.0f];
        [_memoryCommentPreview.layer setCornerRadius:1.5f];
        [self.contentView addSubview:_memoryCommentPreview];
        
        for (int i = 0; i < 3; i++)  {
            
            UILabel *tempLabel = [[UILabel alloc] initWithFrame:CGRectZero];
            tempLabel.numberOfLines = 0;
            tempLabel.lineBreakMode = NSLineBreakByWordWrapping;
            tempLabel.font = [UIFont spc_memory_textFont];
            tempLabel.userInteractionEnabled = NO;
            tempLabel.tag = i + 100; //used to update the comment for each mem
            tempLabel.textColor = [UIColor colorWithWhite:157.0f/255.0f alpha:1.0f];
            [self.memoryCommentPreview addSubview:tempLabel];
        }
        
        self.checkMark = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkmark-celeb"]];
        [self.contentView addSubview:self.checkMark];
        self.checkMark.hidden = YES;
        
        _starAnimationBg = [[UIView alloc] initWithFrame:CGRectZero];
        _starAnimationBg.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.4];
        _starAnimationBg.hidden = YES;
        [_starAnimationBg.layer setCornerRadius:1.5f];
        _starAnimationBg.userInteractionEnabled = NO;
        [self.contentView addSubview:_starAnimationBg];
        
        _starAnimationStar = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"star-white"]];
        _starAnimationStar.hidden = YES;
        _starAnimationStar.userInteractionEnabled = NO;
        [self.contentView addSubview:_starAnimationStar];
        
        _doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap)];
        _doubleTap.numberOfTapsRequired = 2;
        [self.contentView addGestureRecognizer:_doubleTap];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.profilePhotoView.frame = CGRectMake(15.0, 10.0, 50.0, 50.0);
    self.profilePhotoView.layer.cornerRadius = self.profilePhotoView.frame.size.height/2;
    self.profilePhotoView.clipsToBounds = YES;
    
    self.profilePhotoPlaceholder.frame = self.profilePhotoView.frame;
    self.profilePhotoPlaceholder.layer.cornerRadius = self.profilePhotoPlaceholder.frame.size.height/2;
    self.profilePhotoPlaceholder.clipsToBounds = YES;
    
    self.authorButton.frame = self.profilePhotoView.frame;
    self.actionButton.frame = CGRectMake(CGRectGetMaxX(self.contentView.frame) - 44, 0, 44, 44);
    self.followButton.frame = CGRectMake(CGRectGetMaxX(self.contentView.frame) - 100, 20, 90, 25);
    
    
    
    [self.detailImageView sizeToFit];
    
    self.bgView.frame = CGRectMake(0, 0, CGRectGetWidth(self.contentView.frame), self.contentView.frame.size.height-19);
    self.bgViewInner.frame = CGRectMake(0, 0, CGRectGetWidth(self.contentView.frame), self.contentView.frame.size.height-20);
    
    float commentIndent = 0;
    ((MemoryActionButton *)self.usersToStarButton).color = [UIColor colorWithWhite:0 alpha:.3];
    ((MemoryActionButton *)self.usersToStarButton).clearBg = YES;
    
    if (self.memoryType == MemoryTypeText || (self.memoryType == MemoryTypeMap && ![MemoryCell memoryHasLocation:self.memory])) {
        // Nothing special.  We have no additional content to display.
        if (self.memoryType != MemoryTypeText) {
            ((MemoryActionButton *)self.usersToStarButton).color = [UIColor whiteColor];
            ((MemoryActionButton *)self.usersToStarButton).clearBg = NO;
        } else {
            ((MemoryActionButton *)self.usersToStarButton).color = [UIColor colorWithWhite:0.0f alpha:0.3f];
            ((MemoryActionButton *)self.usersToStarButton).clearBg = YES;
        }
        
        self.bgViewInnerBg.frame = self.bgViewInner.bounds;
        self.memoryContentView.hidden = YES;
        if (self.memoryContentButton) {
            self.memoryContentButton.hidden = YES;
        }
        
        self.memoryCommentPreview.frame = CGRectMake(commentIndent,
                                                     CGRectGetMaxY(self.bgView.frame)-commentPreviewHeight-1,
                                                     CGRectGetWidth(self.bgViewInnerBg.frame),
                                                     commentPreviewHeight);
        
    }
    else if (self.memoryType == MemoryTypeImage) {
        
        
       // Layout the image scroller.
        self.bgViewInnerBg.frame = CGRectMake(0, 0, CGRectGetWidth(self.bgView.frame),
                                              CGRectGetHeight(self.bgViewInner.frame)-self.memoryContentView.frame.size.height);
        self.memoryContentView.frame =
            CGRectMake(0,
                       CGRectGetMaxY(self.bgViewInner.frame)-self.bounds.size.width-commentPreviewHeight,
                       self.bounds.size.width,
                       self.bounds.size.width);
        
        
        self.memoryCommentPreview.frame = CGRectMake(commentIndent,
                                                     CGRectGetMaxY(self.bgView.frame)-commentPreviewHeight-1,
                                                     CGRectGetWidth(self.bgViewInner.frame),
                                                     commentPreviewHeight);
        
    } else if (self.memoryType == MemoryTypeVideo) {
        
        
        // Layout the image scroller.
        self.bgViewInnerBg.frame = CGRectMake(0, 0, CGRectGetWidth(self.bgView.frame),
                                              CGRectGetHeight(self.bgViewInner.frame)-self.memoryContentView.frame.size.height);
        self.memoryContentView.frame =
        CGRectMake(0,
                   CGRectGetMaxY(self.bgViewInner.frame)-self.bounds.size.width-commentPreviewHeight,
                   self.bounds.size.width,
                   self.bounds.size.width);
        
        self.memoryCommentPreview.frame = CGRectMake(commentIndent,
                                                     CGRectGetMaxY(self.bgView.frame)-commentPreviewHeight-1,
                                                     CGRectGetWidth(self.bgViewInner.frame),
                                                     commentPreviewHeight);
        
        
        
    } else if (self.memoryType == MemoryTypeMap) {
        // Layout the map view.
        self.bgViewInnerBg.frame = CGRectMake(0, 0, CGRectGetWidth(self.bgViewInner.frame),
                                              CGRectGetHeight(self.bgViewInner.frame)-kMAP_HEIGHT);
        self.memoryContentView.frame =
        CGRectMake(0,
                   CGRectGetMaxY(self.bgViewInner.bounds)-kMAP_HEIGHT-commentPreviewHeight,
                   CGRectGetWidth(self.bgViewInner.frame),
                   kMAP_HEIGHT);
        self.memoryContentView.hidden = NO;
        ((UIView *)self.memoryContentView.subviews[0]).frame =
        CGRectMake(0,
                   -kMAP_HEIGHT_EXTENSION,
                   CGRectGetWidth(self.bgViewInner.frame),
                   kMAP_HEIGHT + kMAP_HEIGHT_EXTENSION*2);
        self.memoryContentButton.frame =
        CGRectMake(0,
                   CGRectGetMaxY(self.bgViewInner.bounds)-kMAP_HEIGHT,
                   CGRectGetWidth(self.bgViewInner.bounds),
                   kMAP_HEIGHT);
        self.memoryContentButton.hidden = NO;
        
        self.memoryCommentPreview.frame = CGRectMake(commentIndent,
                                                     CGRectGetMaxY(self.bgView.frame)-commentPreviewHeight-1,
                                                     CGRectGetWidth(self.bgViewInner.frame),
                                                     commentPreviewHeight);

    } else if (self.memoryType == MemoryTypeFriends) {
        // Basically the only thing we do is position the friend circles in a reasonable way
        // (slightly overlapping)
        self.bgViewInnerBg.frame = self.bgViewInner.bounds;
        
        self.memoryContentView.frame =
        CGRectMake(0,
                   CGRectGetMaxY(self.bgViewInner.bounds)-self.memoryContentView.frame.size.height-commentPreviewHeight,
                   CGRectGetWidth(self.bgViewInner.frame),
                   self.memoryContentView.frame.size.height);
        
        UIButton *aButton = (UIButton *)[self.memoryContentView viewWithTag:kFRIENDS_TAG_AUTHOR_BUTTON];
        UIButton *oButton = (UIButton *)[self.memoryContentView viewWithTag:kFRIENDS_TAG_OTHER_BUTTON];
        UIImageView *aImageView = (UIImageView *)[self.memoryContentView viewWithTag:kFRIENDS_TAG_AUTHOR_IMAGEVIEW];
        UIImageView *oImageView = (UIImageView *)[self.memoryContentView viewWithTag:kFRIENDS_TAG_OTHER_IMAGEVIEW];
        aImageView.center = aButton.center = CGPointMake(CGRectGetWidth(self.memoryContentView.frame)/2 - 37, CGRectGetHeight(aButton.frame)/2);
        oImageView.center = oButton.center = CGPointMake(CGRectGetWidth(self.memoryContentView.frame)/2 + 37, CGRectGetHeight(oButton.frame)/2);
        UILabel *aLbl = (UILabel *)[self.memoryContentView viewWithTag:kFRIENDS_TAG_AUTHOR_INITIAL_LBL];
        UILabel *oLbl = (UILabel *)[self.memoryContentView viewWithTag:kFRIENDS_TAG_OTHER_INITIAL_LBL];
        aLbl.frame = aButton.frame;
        oLbl.frame = oButton.frame;
        
        
        self.memoryCommentPreview.frame = CGRectMake(commentIndent,
                                                     CGRectGetMaxY(self.bgView.frame)-commentPreviewHeight-1,
                                                     CGRectGetWidth(self.bgViewInner.frame),
                                                     commentPreviewHeight);
    }
    
    self.starAnimationBg.frame = self.bgView.frame;
    self.starAnimationStar.center = self.bgView.center;
    
    CGFloat authorWidth = [self.authorLabel.text sizeWithAttributes:@{ NSFontAttributeName: self.authorLabel.font }].width;
    
    self.authorLabel.frame = CGRectIntegral(CGRectMake(75, 17, authorWidth,self.authorLabel.font.lineHeight));
   
    self.locationLabel.frame = CGRectMake(75+12, CGRectGetMaxY(self.authorLabel.frame)-2,
                                            CGRectGetWidth(self.bgView.frame)-20-75, self.locationLabel.font.lineHeight+2);
    
    if (!self.followButton.hidden) {
        NSLog(@"follow button visible!");
        float locXOrigin = 75+12;
        self.locationLabel.frame = CGRectMake(locXOrigin, CGRectGetMaxY(self.authorLabel.frame)-2,
                                               CGRectGetMinX(self.followButton.frame) - locXOrigin - 5, self.locationLabel.font.lineHeight+2);
    }
    
    [self.dateLabel sizeToFit];
    self.dateLabel.frame = CGRectMake(CGRectGetMaxX(self.authorLabel.frame), CGRectGetMinY(self.authorLabel.frame), CGRectGetWidth(self.dateLabel.frame), self.authorLabel.font.lineHeight);
    
    [self.anonLabel sizeToFit];
    self.anonLabel.frame = CGRectMake(CGRectGetMaxX(self.dateLabel.frame) + 4.0f, CGRectGetMinY(self.authorLabel.frame), CGRectGetWidth(self.anonLabel.frame), self.anonLabel.font.lineHeight);
    
    
   if (self.memory.author.isCeleb) {
        self.checkMark.hidden = NO;
        self.checkMark.center = CGPointMake(CGRectGetMaxX(self.authorLabel.frame) + 3 + self.checkMark.frame.size.width/2, self.authorLabel.center.y+1);
        self.dateLabel.frame = CGRectMake(CGRectGetMaxX(self.checkMark.frame), CGRectGetMinY(self.authorLabel.frame), 100, self.authorLabel.font.lineHeight);
   }
    
    self.memoryTextLabel.frame = CGRectMake(20, self.bgViewInner.frame.origin.y+70, CGRectGetWidth(self.bgViewInner.frame)-40, textHeight);
    self.detailImageView.frame = CGRectMake(69, -2+CGRectGetMinY(self.locationLabel.frame), CGRectGetWidth(self.detailImageView.frame), CGRectGetHeight(self.detailImageView.frame));
    
    CGFloat commentsButtonPadding = 8;
    CGFloat starButtonPadding = 10;
    
    CGRect starFrame = CGRectMake(15,
                                  CGRectGetHeight(self.contentView.frame)-kDEFAULT_ACTION_BUTTON_VERTICAL_OFFSET_UP - commentPreviewHeight,
                                  kDEFAULT_ACTION_BUTTON_WIDTH+self.memory.starsCountTextWidth+starButtonPadding,
                                  kDEFAULT_ACTION_BUTTON_HEIGHT);
    
    CGRect usersToStarFrame;
    CGRect commentsFrame;
    if (self.memory.userToStarMostRecently) {
        // we inset our buttons by 4 pixels horizontally.  Compensate by shifting the usersToStar button leftwards
        // by 8, then rightward by 1 to produce a slight divider.
        CGFloat usersToStarX = CGRectGetMaxX(starFrame) - 8;
        if (self.lighterBg) {
             usersToStarX = CGRectGetMaxX(starFrame) - 7;
        }
        
        usersToStarFrame = CGRectMake(usersToStarX, starFrame.origin.y, 44, kDEFAULT_ACTION_BUTTON_HEIGHT);
    } else {
        usersToStarFrame = CGRectZero;
        
    }
  
    CGFloat commentsButtonWidth = self.memory.commentsCountTextWidth + kDEFAULT_ACTION_BUTTON_WIDTH + commentsButtonPadding;
    commentsFrame = CGRectMake(self.contentView.frame.size.width - 15 - commentsButtonWidth,
                               CGRectGetMinY(starFrame),
                               commentsButtonWidth,
                               kDEFAULT_ACTION_BUTTON_HEIGHT);
    
    self.starsButton.frame = starFrame;
    self.usersToStarButton.frame = usersToStarFrame;
    self.commentsButton.frame = commentsFrame;
}

#pragma mark - accessors

- (CGRect)mediaContentScreenRect {
    NSLog(@"mediaContentScreenRect");
    return [self.memoryContentView convertRect:self.memoryContentView.bounds toView:nil];
}

- (UIImage *)mediaContentImage {
    if (self.memoryType == MemoryTypeImage) {
        return ((SPCFeedPhotoScroller *)self.memoryContentView).currentImage;
    }
    return nil;
}

- (UIImageView *)userToStarAsyncImageLoaderView {
    if (!_userToStarAsyncImageLoaderView) {
        _userToStarAsyncImageLoaderView = [[UIImageView alloc] init];
    }
    return _userToStarAsyncImageLoaderView;
}

#pragma mark - Actions

- (void)cancelFetchingImage
{
    [self.profilePhotoView sd_cancelCurrentImageLoad];
    self.profilePhotoView.image = nil;
    [self.userToStarAsyncImageLoaderView sd_cancelCurrentImageLoad];
    self.userToStarAsyncImageLoaderView.image = nil;
}

- (void)prepareForReuse
{
    [self cancelFetchingImage];
    [self clearContent];
    self.memoryCommentPreview.hidden = YES;
    
    self.lastIndexShown = 0;
    self.checkMark.hidden = YES;

    UILabel *view;
    NSArray *subs = [self.memoryCommentPreview subviews];
    
    for (view in subs) {
       ((UILabel *)view).text = @"";
    }
    
    if (self.memoryType == MemoryTypeFriends) {
        UIImageView *aImageView = (UIImageView *)[self.memoryContentView viewWithTag:kFRIENDS_TAG_AUTHOR_IMAGEVIEW];
        UIImageView *oImageView = (UIImageView *)[self.memoryContentView viewWithTag:kFRIENDS_TAG_OTHER_IMAGEVIEW];
        UILabel *aLbl = (UILabel *)[self.memoryContentView viewWithTag:kFRIENDS_TAG_AUTHOR_INITIAL_LBL];
        UILabel *oLbl = (UILabel *)[self.memoryContentView viewWithTag:kFRIENDS_TAG_OTHER_INITIAL_LBL];
        
        [aImageView sd_cancelCurrentImageLoad];
        aImageView.image = nil;
        [oImageView sd_cancelCurrentImageLoad];
        oImageView.image = nil;
        aLbl.text = @"";
        oLbl.text = @"";
    }
}

- (void)clearContent {
    if (self.memoryType == MemoryTypeVideo) {
        [((SPCFeedVideoScroller *)self.memoryContentView) clearVids];
    }
}

#pragma mark - Configuration

- (void)configureWithMemory:(Memory *)memory tag:(NSInteger)tag dateFormatter:(NSDateFormatter *)dateFormatter {
    [self configureWithMemory:memory tag:tag dateFormatter:dateFormatter placeholder:nil canShowAnonLabel:NO];
}

- (void)configureWithMemory:(Memory *)memory tag:(NSInteger)tag dateFormatter:(NSDateFormatter *)dateFormatter canShowAnonLabel:(BOOL)canShowAnonLabel {
    [self configureWithMemory:memory tag:tag dateFormatter:dateFormatter placeholder:nil canShowAnonLabel:canShowAnonLabel];
}

- (void)configureWithMemory:(Memory *)memory tag:(NSInteger)tag dateFormatter:(NSDateFormatter *)dateFormatter placeholder:(UIImage *)placeholder {
    [self configureWithMemory:memory tag:tag dateFormatter:dateFormatter placeholder:placeholder canShowAnonLabel:NO];
}

- (void)configureWithMemory:(Memory *)memory tag:(NSInteger)tag dateFormatter:(NSDateFormatter *)dateFormatter placeholder:(UIImage *)placeholder canShowAnonLabel:(BOOL)canShowAnonLabel {
    BOOL newMemory = self.memory.recordID != memory.recordID;
    
    if (newMemory) {
        self.starAnimationBg.hidden = YES;
        self.starAnimationStar.hidden = YES;
    }
    
    self.lighterBg = YES;
  
    // TODO Only update areas that could plausibly change.
    // Note that this requires revisions to prepareForReuse...
    
    self.memory = memory;
    textHeight = self.memory.heightForMemoryText;
    
    self.dateLabel.text = [NSString stringWithFormat:@" - %@", memory.timeElapsed];
    self.anonLabel.text = self.memory.isAnonMem && canShowAnonLabel ? @"(Only You)" : @"";

    self.commentsButton.tag = tag;
    self.starsButton.tag = tag;
    self.usersToStarButton.tag = tag;
    self.authorButton.tag = tag;
    self.actionButton.tag = tag;

    [self configureDetailedTextWithMemory:memory];
    if (self.memoryType == MemoryTypeText) {
        // nothing else to do
    } else if (self.memoryType == MemoryTypeImage) {
        [((SPCFeedPhotoScroller *)self.memoryContentView) viewingFromComments:self.viewingInComments];
        if (self.lastIndexShown > ((ImageMemory *)memory).images.count) {
            self.lastIndexShown = 0;
        }

        self.memoryContentView.clipsToBounds = NO;
        self.bgViewInner.clipsToBounds = NO;
        
        [((SPCFeedPhotoScroller *)self.memoryContentView) setMemoryImages:((ImageMemory *)memory).images withCurrentImage:(int)self.lastIndexShown placeholder:placeholder];
        ((SPCFeedPhotoScroller *)self.memoryContentView).delegate = self;
    } else if (self.memoryType == MemoryTypeVideo) {
        
        self.memoryContentView.clipsToBounds = YES;
        self.bgViewInner.clipsToBounds = YES;
        if (((VideoMemory *)memory).videoURLs.count > 1) {
            self.memoryContentView.clipsToBounds = NO;
            self.bgViewInner.clipsToBounds = NO;
        }
        [((SPCFeedVideoScroller *)self.memoryContentView) setMemoryImages:((VideoMemory *)memory).previewImages];
        [((SPCFeedVideoScroller *)self.memoryContentView) addVidURLs:((VideoMemory *)memory).videoURLs];
        ((SPCFeedVideoScroller *)self.memoryContentView).delegate = self;
    } else if (self.memoryType == MemoryTypeMap) {
        if ([MemoryCell memoryHasLocation:memory]) {
            [self configureGMSMapView:(GMSMapView *)self.memoryContentView.subviews[0] withMemory:memory];
        }
    } else if (self.memoryType == MemoryTypeFriends) {
        UIImageView *aImageView = (UIImageView *)[self.memoryContentView viewWithTag:kFRIENDS_TAG_AUTHOR_IMAGEVIEW];
        UIImageView *oImageView = (UIImageView *)[self.memoryContentView viewWithTag:kFRIENDS_TAG_OTHER_IMAGEVIEW];
        [self configureFriendImageViewsForAuthor:aImageView other:oImageView withMemory:memory];
    }
    [self configureMemoryAuthorLabelWithMemory:memory];
    [self configureMemoryTextWithMemory:memory attributedText:self.memoryText];
    [self configureCommentsWithMemory:memory];
    [self configureThumbnailWithMemory:memory];
    
    [self configureStarsWithMemory:memory];
    [self configureUsersToStarWithMemory:memory];
    [self configureCommentsPreview];
    
    [self setNeedsLayout];

}

- (void)configureMemoryAuthorLabelWithMemory:(Memory *)memory {
    self.authorLabel.attributedText = memory.authorAttributedString;
}

- (void)configureMemoryTextWithMemory:(Memory *)memory attributedText:(NSAttributedString *)attributedText {
    self.memoryTextLabel.attributedText = attributedText;
}

- (void)setMemory:(Memory *)memory {
    _memory = memory;
    _memoryText = nil;
}

- (NSAttributedString *)memoryText {
    if (!_memoryText) {
        _memoryText = [MemoryCell getMemoryTextWithMemory:self.memory];
    }
    return _memoryText;
}

+ (NSAttributedString *)getMemoryTextWithMemory:(Memory *)memory {
    NSString *memoryText = memory.text;
    NSDictionary *attributes = @{ NSForegroundColorAttributeName: [UIColor blackColor], NSFontAttributeName: [UIFont spc_memory_textFont] };
    //NSLog(@"memory text %@, attributes %@", memoryText, attributes);
    NSMutableAttributedString *cellText = [[NSMutableAttributedString alloc] initWithString:memoryText attributes:attributes];
    
    if (memory.taggedUsers.count > 0 && ![memory isKindOfClass:[FriendsMemory class]]) {
        if (cellText.length > 0) {
            [cellText appendAttributedString:[[NSAttributedString alloc] initWithString:@" - " attributes:@{ NSForegroundColorAttributeName: [UIColor colorWithRGBHex:0xa4a5a6], NSFontAttributeName: [UIFont spc_memory_textFont] }]];
        }
        [cellText appendAttributedString:[[NSAttributedString alloc] initWithString:@"with" attributes:@{ NSForegroundColorAttributeName: [UIColor colorWithRGBHex:0xa4a5a6], NSFontAttributeName: [UIFont spc_memory_textFont] }]];
        
        NSString * strAnd = memory.taggedUsers.count == 2 ? @" and" : @" &";
        NSString * strSep = @",";
        UIColor *appendedTextColor = [UIColor colorWithRed:172.0f/255.0f green:182.0f/255.0f blue:198.0f/255.0f alpha:1.0f];
        
        for (int i = 0; i < memory.taggedUsers.count; i++) {
            Person * person = memory.taggedUsers[i];
            // separator?
            if (i > 0) {
                if (i + 1 == memory.taggedUsers.count) {
                    [cellText appendAttributedString:[[NSAttributedString alloc] initWithString:strAnd attributes:@{ NSForegroundColorAttributeName: appendedTextColor, NSFontAttributeName: [UIFont spc_memory_textFont] }]];
                } else {
                    [cellText appendAttributedString:[[NSAttributedString alloc] initWithString:strSep attributes:@{ NSForegroundColorAttributeName: appendedTextColor, NSFontAttributeName: [UIFont spc_memory_textFont] }]];
                }
            }
            
            UIColor *nameColor = [UIColor colorWithRed:118.0f/255.0f green:158.0f/255.0f blue:222.0f/255.0f alpha:1.0f];
            
            
            [cellText appendAttributedString:[[NSAttributedString alloc] initWithString:@" "]];
            [cellText appendAttributedString:[[NSAttributedString alloc]
                                              initWithString:person.firstname
                                              attributes:@{ STTweetAnnotationHotWord: person.userToken,
                                                            NSForegroundColorAttributeName: nameColor,
                                                            NSFontAttributeName: [UIFont spc_memory_textFont] }]];
        }
        [cellText appendAttributedString:[[NSAttributedString alloc] initWithString:@"." attributes:@{ NSForegroundColorAttributeName: appendedTextColor, NSFontAttributeName: [UIFont spc_memory_textFont] }]];
    }
    
    // Add line spacing
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineSpacing:1.7];
    [cellText addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, cellText.length)];
    
    return [[NSAttributedString alloc] initWithAttributedString:cellText];
}

- (void)configureDetailedTextWithMemory:(Memory *)memory {
    if (memory.venue.specificity == SPCVenueIsReal) {
        self.locationLabel.text = memory.locationName;
    }
    if (memory.venue.specificity == SPCVenueIsFuzzedToNeighhborhood) {
        self.locationLabel.text = [NSString stringWithFormat:@"%@, %@",memory.venue.neighborhood,[SPCTerritory fixCityName:memory.venue.city stateCode:memory.venue.state countryCode:memory.venue.country]];
    }
    if (memory.venue.specificity == SPCVenueIsFuzzedToCity) {
        self.locationLabel.text = [NSString stringWithFormat:@"%@, %@",[SPCTerritory fixCityName:memory.venue.city stateCode:memory.venue.state countryCode:memory.venue.country],memory.venue.country];
    }
}

- (void)configureCommentsWithMemory:(Memory *)memory {
    NSInteger commentsCount = memory.commentsCount;

    UIImage *iconImg = [UIImage imageNamed:(memory.userHasCommented ? @"memory-chat-blue" : @"memory-chat-empty")];
  
    [(MemoryActionButton *)self.commentsButton configureWithIconImage:iconImg count:commentsCount clearBG:self.lighterBg];
}

- (void)configureStarsWithMemory:(Memory *)memory {
    NSInteger starsCount = memory.starsCount;

    UIImage *iconImg = [UIImage imageNamed:(memory.userHasStarred ? @"memory-star-gold" : @"memory-star-empty")];
  
    [(MemoryActionButton *)self.starsButton configureWithIconImage:iconImg count:starsCount clearBG:self.lighterBg];
    ((MemoryActionButton *)self.starsButton).roundedCorners = memory.userToStarMostRecently ? UIRectCornerTopLeft | UIRectCornerBottomLeft : UIRectCornerAllCorners;
}

- (void)configureUsersToStarWithMemory:(Memory *)memory {
    if (memory.userToStarMostRecently) {
        // configure with the profile asset id of this user
        __weak typeof(self) weakSelf = self;
        
        // TODO: instead of loading the image asynchronously here, modify the MemoryButton
        // so it is capable of loading its own images.
        [self.userToStarAsyncImageLoaderView sd_setImageWithURL:[NSURL URLWithString:memory.userToStarMostRecently.imageAsset.imageUrlThumbnail] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (image && memory.recordID == strongSelf.memory.recordID) {
                [(MemoryActionButton *)strongSelf.usersToStarButton configureWithIconImage:image rounded:YES clearBG:self.lighterBg];
            }
        }];

        ((MemoryActionButton *)self.usersToStarButton).roundedCorners = UIRectCornerTopRight | UIRectCornerBottomRight;
        ((MemoryActionButton *)self.usersToStarButton).imageSize = 18;
        
        self.usersToStarButton.hidden = NO;
        self.usersToStarButton.enabled = YES;
    } else {
        self.usersToStarButton.hidden = YES;
        self.usersToStarButton.enabled = NO;
    }
}

- (void)configureThumbnailWithImage:(UIImage *)image {
    dispatch_async(dispatch_get_main_queue(), ^(void){
        self.profilePhotoView.image = image;
        self.profilePhotoView.hidden = NO;
        self.profilePhotoPlaceholder.hidden = YES;
    });
}

- (void)configureThumbnailWithName:(NSString *)name {
    dispatch_async(dispatch_get_main_queue(), ^(void){
        self.profilePhotoPlaceholder.text = [name substringToIndex:1];
        self.profilePhotoView.hidden = YES;
        self.profilePhotoPlaceholder.hidden = NO;
    });
}

- (void)configureThumbnailWithMemory:(Memory *)memory {
    [self configureThumbnailWithName:memory.author.firstname];
    [self.profilePhotoView sd_setImageWithURL:[NSURL URLWithString:memory.author.imageAsset.imageUrlThumbnail] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        if (image) {
            [self configureThumbnailWithImage:image];
        }
    }];
}

- (void)configureCommentsPreview {
    float totalHeight = 8;

    for (int i = 0; i < self.memory.recentComments.count; i++)  {
        self.memoryCommentPreview.hidden = NO;        
        Comment *comment = (Comment *)self.memory.recentComments[i];

        UILabel *tempLabel = (UILabel *)[self.memoryCommentPreview viewWithTag:i+100];
        tempLabel.frame = CGRectMake(18, totalHeight, [UIScreen mainScreen].bounds.size.width-36, comment.attributedTextHeight + 1);
        tempLabel.attributedText = comment.attributedText;
        totalHeight = totalHeight + comment.attributedTextHeight + 3;
    }

    commentPreviewHeight = self.memory.heightForCommentText;
    //NSLog(@"commentPreviewHeight %f",commentPreviewHeight);
}

- (void)configureGMSMapView:(GMSMapView *)mapView withMemory:(Memory *)memory {
    // zoom the map view to the lat / long for this memory.
    CLLocationCoordinate2D center = { [memory.location.latitude floatValue], [memory.location.longitude floatValue] };
    
    GMSCameraPosition *camera;
    camera = [GMSCameraPosition cameraWithLatitude:center.latitude
                                         longitude:center.longitude zoom:17
                                           bearing:0 viewingAngle:5];
    
    mapView.camera = camera;
    
    // adjust map center to position the blue anchor (current position) in the apparent center
    // of the visible area of the map (e.g., when not in the foreground, only the top portion
    // of the map is visible, and we want to center the map well below the user's location).
    
    // adjust map center to position the blue anchor (memory position) near the right edge
    // of the map.
    CGPoint centerViewAt;
    centerViewAt = CGPointMake(CGRectGetWidth(mapView.frame)/2 - 70, CGRectGetHeight(mapView.frame)/2);
    CLLocationCoordinate2D mapCenter = [mapView.projection coordinateForPoint:centerViewAt];
    [mapView moveCamera:[GMSCameraUpdate setTarget:mapCenter]];
    
    // Add a marker at the memory's position.
    [mapView clear];
    SPCMarker * marker = [SPCMarkerVenueData markerWithMemory:self.memory];
    marker.map = mapView;
}


- (void)configureFriendImageViewsForAuthor:(UIImageView *)aImageView other:(UIImageView *)oImageView withMemory:(Memory *)memory {
    
    UILabel *aLbl = (UILabel *)[self.memoryContentView viewWithTag:kFRIENDS_TAG_AUTHOR_INITIAL_LBL];
    UILabel *oLbl = (UILabel *)[self.memoryContentView viewWithTag:kFRIENDS_TAG_OTHER_INITIAL_LBL];
    
    [aImageView sd_setImageWithURL:[NSURL URLWithString:memory.author.imageAsset.imageUrlHalfSquare]];
    
    aLbl.text = [memory.author.firstname substringToIndex:1];
    if (memory.taggedUsers.count > 0) {
        Person *otherPerson = memory.taggedUsers[0];
        [oImageView sd_setImageWithURL:[NSURL URLWithString:otherPerson.imageAsset.imageUrlHalfSquare]];
        oLbl.text = [otherPerson.firstname substringToIndex:1];
        
    } else {
        [oImageView sd_cancelCurrentImageLoad];
        oImageView.image = nil;
    }
}


- (void)updateForCommentDisplay  {
    self.backgroundColor = [UIColor clearColor];
    self.contentView.backgroundColor = [UIColor clearColor];
    self.memoryContentView.backgroundColor = [UIColor clearColor];
    self.bgView.backgroundColor = [UIColor clearColor];
    self.bgViewInner.backgroundColor = [UIColor clearColor];
    self.bgViewInnerBg.backgroundColor = [UIColor whiteColor];
    self.locationLabel.hidden = NO;
    self.commentsButton.hidden = YES;
    
    commentPreviewHeight = 0;
    self.memoryCommentPreview.hidden = YES;
    
    self.actionButton.hidden = YES;
    self.actionButton.userInteractionEnabled = NO;
    
    if ([self.memory.author.userToken isEqualToString:[AuthenticationManager sharedInstance].currentUser.userToken]) {
        self.followButton.hidden = YES;
    }
    else {
        self.followButton.hidden = NO;
        self.followButton.userInteractionEnabled = YES;
        
        NSLog(@"self.memory.author.followingStatus %li",self.memory.author.followingStatus);
        
        if (self.memory.author.followingStatus == FollowingStatusFollowing) {
            [self.followButton setImage:[UIImage imageNamed:@"friendship-following"] forState:UIControlStateNormal];
        }
        if (self.memory.author.followingStatus == FollowingStatusNotFollowing) {
            [self.followButton setImage:[UIImage imageNamed:@"friendship-follow"] forState:UIControlStateNormal];
            
        }
        if (self.memory.author.followingStatus == FollowingStatusBlocked) {
            self.followButton.hidden = YES;
        }
        if (self.memory.author.followingStatus == FollowingStatusRequested) {
            self.followButton.userInteractionEnabled = NO;
            [self.followButton setImage:[UIImage imageNamed:@"following-requested"] forState:UIControlStateNormal];
        }
        if (self.memory.author.followingStatus == FollowingStatusUnknown) {
            [self.followButton setImage:[UIImage imageNamed:@"friendship-follow"] forState:UIControlStateNormal];
        }
    }
    
    if (self.memory.isAnonMem) {
        self.followButton.hidden = YES;
    }
    

}

- (void)updateTimestamp {
    if (self.memory) {
        self.dateLabel.text = [NSString stringWithFormat:@" - %@", self.memory.timeElapsed];
    }
}

#pragma mark - Actions

- (void)handleDoubleTap {
    if (!self.memory.userHasStarred) {
        [self.starsButton sendActionsForControlEvents: UIControlEventTouchUpInside];
    }
}

- (void)updateToPublic {
    self.memory.accessType = MemoryAccessTypePublic;
}

- (void)updateToPrivate {
    self.memory.accessType = MemoryAccessTypePrivate;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    
    UITouch *touch = [touches anyObject];
    
    if (touch.view == self.memoryCommentPreview) {
        [self.commentsButton sendActionsForControlEvents: UIControlEventTouchUpInside];
    }
}


- (void)addFriendButtonTapped:(id)sender {
    UIView *view = (UIView *)sender;
    if (view.tag == kFRIENDS_TAG_AUTHOR_BUTTON) {
        [self.authorButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    } else if (view.tag == kFRIENDS_TAG_OTHER_BUTTON && self.memory.taggedUsers.count > 0) {
        // the other tagged user...
        Person * person = self.memory.taggedUsers[0];
        NSString *userToken = person.userToken;
        if (self.taggedUserTappedBlock) {
            self.taggedUserTappedBlock(userToken);
        }
    }
}


#pragma mark - SPCFeedScroller delegates

- (void)spcFeedPhotoScroller:(SPCFeedPhotoScroller *)feedScroller onAssetTappedWithIndex:(int)index {
    if (self.memoryType == MemoryTypeImage) {
        if (self.imageTappedBlock) {
            self.imageTappedBlock(self.memory, ((ImageMemory *)self.memory).images, index);
        }
    }
}

- (void)spcFeedVideoScroller:(SPCFeedVideoScroller *)feedScroller onAssetTappedWithIndex:(int)index videoUrl:(NSString *)url {
    if (self.memoryType == MemoryTypeVideo) {
        if (self.videoTappedBlock) {
            self.videoTappedBlock(self.memory, ((VideoMemory *)self.memory).previewImages, ((VideoMemory *)self.memory).videoURLs, index);
        }
    }
}

- (void)locationTapped:(id)sender {
    // Old Add Friend memories will still provide location, and, bizarely, a Venue with an
    // address id even though those memories no longer have geocoordinates associated.  However,
    // the self.memory.addressID field will be 0.
    if (self.locationTappedBlock && self.memory.location && self.memory.venue.addressId) {
        if ([self.memory.venue.latitude floatValue] != 0 || [self.memory.venue.longitude floatValue] != 0) {
            self.locationTappedBlock(self.memory);
        }
    }
}

- (void)animateStar:(id)sender {
    if (!self.memory.userHasStarred) {
        NSLog(@"animateStar!");
        self.starAnimationBg.alpha = 0.0;
        self.starAnimationBg.hidden = NO;
        [UIView animateWithDuration:0.4
                              delay:0.1
                            options: 0
                         animations:^{
                             self.starAnimationBg.alpha = 1.0;
                         }
                         completion:^(BOOL finished) {
                             // fade back out!
                             [UIView animateWithDuration:0.4 delay:1.0 options:0 animations:^{
                                 self.starAnimationBg.alpha = 0.0;
                             }completion:^(BOOL finished) {
                                 if (finished) {
                                     self.starAnimationBg.hidden = YES;
                                 }
                                 }
                              ];
                         }];
        self.starAnimationStar.alpha = 0.0;
        CGRect starFrame = CGRectMake(0, 0, self.starAnimationStar.image.size.width, self.starAnimationStar.image.size.height);
        starFrame = CGRectOffset(starFrame, self.starAnimationBg.center.x - starFrame.size.width/2, self.starAnimationBg.center.y - starFrame.size.height/2);
        self.starAnimationStar.frame = CGRectInset(starFrame, 30, 30);
        self.starAnimationStar.hidden = NO;
        [UIView animateWithDuration:0.4 delay:0.1 options:0 animations:^{
            self.starAnimationStar.alpha = 1.0;
            self.starAnimationStar.frame = starFrame;
        }completion:^(BOOL finished) {
            // yay!  fade out!
            
            [UIView animateWithDuration:0.4 delay:0.9 options:0 animations:^{
                self.starAnimationStar.alpha = 0.0;
                self.starAnimationStar.frame = CGRectInset(starFrame, -40, -40);
            } completion:^(BOOL finished) {
                self.starAnimationStar.hidden = YES;
            }];
            
        }];
    }
}

+ (BOOL)memoryHasLocation:(Memory *)memory {
    return memory.location && (memory.location.latitude || memory.location.longitude);
}

+ (CGFloat)measureMainContentOffsetWithMemory:(Memory *)memory constrainedToSize:(CGSize)constraint {
    // determine the full height, omitting shadow and spacing and text for comments.
    CGFloat fullHeight = [MemoryCell measureHeightWithMemory:memory constrainedToSize:constraint] - 20;
    CGFloat noCommentsHeight = fullHeight - memory.heightForCommentText;
    
    // this is the bottom of the memory cell proper.  Move up above our content to
    // get the main offset.  For example, the main offset for an image memory
    // is the first pixel of the image.
    if (memory.type == MemoryTypeText || (memory.type == MemoryTypeMap && ![MemoryCell memoryHasLocation:memory])) {
        return 0;
    } else if (memory.type == MemoryTypeImage) {
        return noCommentsHeight - [UIScreen mainScreen].bounds.size.width;
    } else if (memory.type == MemoryTypeVideo) {
        return noCommentsHeight - [UIScreen mainScreen].bounds.size.width;
    } else if (memory.type == MemoryTypeAudio) {
        // no support for audio memories: hide them.
        return 0;
    } else if (memory.type == MemoryTypeMap) {
        return noCommentsHeight - kMAP_HEIGHT;
    } else if (memory.type == MemoryTypeFriends) {
        return 0;
    }
    
    return noCommentsHeight;
}

+ (CGFloat)measureHeightWithMemory:(Memory *)memory constrainedToSize:(CGSize)constraint {

    CGFloat textHeight = memory.heightForMemoryText;
    CGFloat commentHeight = memory.heightForCommentText;
    CGFloat imageHeight = [[UIScreen mainScreen] bounds].size.width;

    if (memory.type == MemoryTypeText || (memory.type == MemoryTypeMap && ![MemoryCell memoryHasLocation:memory])) {
        return textHeight + kDEFAULT_EMPTY_HEIGHT + commentHeight;
    } else if (memory.type == MemoryTypeImage) {
        return textHeight + kDEFAULT_IMAGE_HEIGHT + commentHeight + imageHeight;
    } else if (memory.type == MemoryTypeVideo) {
        return textHeight + kDEFAULT_VIDEO_HEIGHT + commentHeight + imageHeight;
    } else if (memory.type == MemoryTypeAudio) {
        // no support for audio memories: hide them.
        return 0;
    } else if (memory.type == MemoryTypeMap) {
        return textHeight + kDEFAULT_MAP_HEIGHT + commentHeight;
    } else if (memory.type == MemoryTypeFriends) {
        return textHeight + kDEFAULT_FRIENDS_HEIGHT + commentHeight;
    }

    return kDEFAULT_EMPTY_HEIGHT;
}

#pragma mark - UIAlertViewDelegate

//WTF?  WHy is this getting called twice?  Either way, we're going to lock it down.

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == alertView.cancelButtonIndex) {
        self.hasShownAnonAlert = NO;
    }
}

@end
