//
//  SPCFriendingActivityHeaderView.m
//  Spayce
//
//  Created by Arria P. Owlia on 2/13/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import "SPCFriendingActivityHeaderView.h"

// View
#import "SPCInitialsImageView.h"

// Model
#import "Memory.h"
#import "Person.h"
#import "Asset.h"

@interface SPCFriendingActivityHeaderView()

// Top-left Friending Activity Label
@property (strong, nonatomic) UILabel *lblFriendingActivity;

// Internal background view
@property (strong, nonatomic) UIView *bgView;

// Internal array of friending memories - filtered from what was passed in
@property (strong, nonatomic) NSArray *memories;

// Internal array of friend images and their associated buttons
@property (strong, nonatomic) NSMutableArray *arrayImageViews;
@property (strong, nonatomic) NSMutableArray *arrayImageButtons;
@property (strong, nonatomic) NSMutableArray *arrayPairButtons; // e.g. 'PersonX & PersonY'

// Tag lookups
@property (strong, nonatomic) NSMutableDictionary *dicPairButtonTagToMemory;
@property (strong, nonatomic) NSMutableDictionary *dicImageButtonTagToPerson;

@end

@implementation SPCFriendingActivityHeaderView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        UIView *dropShadowView = [[UIView alloc] initWithFrame:CGRectMake(5, 5, self.frame.size.width-10, self.frame.size.height - 10)];
        dropShadowView.layer.shadowColor = [UIColor blackColor].CGColor;
        dropShadowView.layer.shadowOffset = CGSizeMake(0, 0);
        dropShadowView.layer.shadowRadius = 0.5f;
        dropShadowView.layer.shadowOpacity = 0.3f;
        dropShadowView.layer.masksToBounds = NO;
        dropShadowView.clipsToBounds = NO;
        [self addSubview:dropShadowView];
        
        _bgView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width-10, self.frame.size.height - 5)];
        _bgView.backgroundColor = [UIColor whiteColor];
        _bgView.layer.cornerRadius = 2;
        _bgView.layer.masksToBounds = YES;
        _bgView.clipsToBounds = YES;
        [dropShadowView addSubview:self.bgView];
        
        // Friending Activity Label
        _lblFriendingActivity = [[UILabel alloc] init];
        _lblFriendingActivity.textColor = [UIColor colorWithRGBHex:0x838a90];
        _lblFriendingActivity.text = @"FRIENDING ACTIVITY";
        [self.bgView addSubview:self.lblFriendingActivity];
        
        // View All Button
        _btnViewAll = [[UIButton alloc] init];
        [_btnViewAll setTitle:@"View All" forState:UIControlStateNormal];
        [_btnViewAll setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _btnViewAll.backgroundColor = [UIColor colorWithRGBHex:0x4cb0fb];
        [self.bgView addSubview:self.btnViewAll];
        
        // Dismiss Button
        _btnDismiss = [[UIButton alloc] init];
        [_btnDismiss setTitle:@"Dismiss" forState:UIControlStateNormal];
        [_btnDismiss setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _btnDismiss.backgroundColor = [UIColor colorWithRGBHex:0xacb6c6];
        [self.bgView addSubview:self.btnDismiss];
    }
    
    return self;
}

#pragma mark - Reuse

- (void)resetThisView {
    // Remove images/buttons from arrays and view
    self.arrayImageButtons = nil;
    self.arrayImageViews = nil;
    self.arrayPairButtons = nil;
    
    // Clear out lookup dictionaries as well
    self.dicPairButtonTagToMemory = nil;
    self.dicImageButtonTagToPerson = nil;
}

#pragma mark - Layout

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat viewWidth = CGRectGetWidth(self.bgView.bounds);
    CGFloat viewHeight = CGRectGetHeight(self.bgView.bounds);
    const CGFloat PSD_WIDTH = 730.0f; // Width of the cell in the Photoshop comp
    const CGFloat PSD_HEIGHT = 300.0f; // Height of the cell in the Photoshop comp
    
    // Friending Activity Label
    self.lblFriendingActivity.font = [UIFont fontWithName:@"OpenSans" size:20.0f/730.0f * viewWidth];
    [self.lblFriendingActivity sizeToFit];
    self.lblFriendingActivity.center = CGPointMake(125.0f/PSD_WIDTH * viewWidth, 29.0f/PSD_HEIGHT * viewHeight);
    
    // View All Button
    self.btnViewAll.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:24.0f/730.0f * viewWidth];
    self.btnViewAll.frame = CGRectMake(0, 0, 220.0f/PSD_WIDTH * viewWidth, 50.0f/PSD_HEIGHT * viewHeight);
    self.btnViewAll.center = CGPointMake(230.0f/PSD_WIDTH * viewWidth, 245.0f/PSD_HEIGHT * viewHeight);
    self.btnViewAll.layer.cornerRadius = CGRectGetHeight(self.btnViewAll.bounds) / 2.0f;
    
    // View Dismiss Button
    self.btnDismiss.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:24.0f/730.0f * viewWidth];
    self.btnDismiss.frame = CGRectMake(0, 0, 220.0f/PSD_WIDTH * viewWidth, 50.0f/PSD_HEIGHT * viewHeight);
    self.btnDismiss.center = CGPointMake(490.0f/PSD_WIDTH * viewWidth, 245.0f/PSD_HEIGHT * viewHeight);
    self.btnDismiss.layer.cornerRadius = CGRectGetHeight(self.btnDismiss.bounds) / 2.0f;
    
    // The friending activities
    // First, let's make sure we have the right number of objects in our arrays
    if (self.arrayImageButtons.count == self.arrayImageViews.count && self.arrayImageViews.count / 2 == self.arrayPairButtons.count && self.arrayPairButtons.count == self.memories.count) {
        // Set up our spacing variables
        CGFloat leftRightPadding = 45.0f/PSD_WIDTH * viewWidth;
        
        // These formulas were just calculated from Excel
        CGFloat imageOffset = (25*self.memories.count*self.memories.count - 220*self.memories.count + 435)/PSD_WIDTH * viewWidth; // Width offset from the padding on the left
        CGFloat imageSpacing = (30*self.memories.count*self.memories.count - 200*self.memories.count + 570)/PSD_WIDTH * viewWidth; // Spacing from the previous imageOffset
        
        // Go through and layout each image/button/pairbutton
        for (NSInteger i = 0; i < self.memories.count; ++i) {
            NSInteger indexAuthor = 2 * i;
            NSInteger indexOtherPerson = 2 * i + 1;
            // It's safe to index this way, since we've checked for correct counts above already
            SPCInitialsImageView *imageAuthor = self.arrayImageViews[indexAuthor];
            SPCInitialsImageView *imageOtherPerson = self.arrayImageViews[indexOtherPerson];
            UIButton *btnAuthor = self.arrayImageButtons[indexAuthor];
            UIButton *btnOtherPerson = self.arrayImageButtons[indexOtherPerson];
            UIButton *pairButton = self.arrayPairButtons[i];
            
            CGFloat imageDimension = 90.0f/PSD_WIDTH * viewWidth;
            
            // Set styles/frames
            imageAuthor.layer.cornerRadius = imageDimension / 2.0f;
            btnAuthor.layer.cornerRadius = imageDimension / 2.0f;
            imageOtherPerson.layer.cornerRadius = imageDimension / 2.0f;
            btnOtherPerson.layer.cornerRadius = imageDimension / 2.0f;
            
            CGFloat heightOffset = 63.0f/PSD_HEIGHT * viewHeight;
            
            imageAuthor.frame = CGRectMake(leftRightPadding + imageOffset, heightOffset, imageDimension, imageDimension);
            btnAuthor.frame = imageAuthor.frame;
            imageOtherPerson.frame = CGRectOffset(imageAuthor.frame, imageDimension * 7.0f/9.0f, 0.0f);
            btnOtherPerson.frame = imageOtherPerson.frame;
            
            // Set the pair button size to be a maximum width of the spacing between images
            pairButton.titleLabel.font = [UIFont fontWithName:@"OpenSans-Semibold" size:20.0f/PSD_WIDTH*viewWidth];
            CGRect pairButtonFrame = pairButton.frame;
            CGFloat pairButtonHeight = CGRectGetMinY(self.btnViewAll.frame) - CGRectGetMaxY(btnAuthor.frame);
            pairButtonFrame.size = CGSizeMake(imageSpacing, pairButtonHeight);
            pairButton.frame = pairButtonFrame;
            pairButton.center = CGPointMake(CGRectGetMaxX(imageAuthor.frame) - (imageDimension * 1.0f/9.0f), CGRectGetMaxY(imageAuthor.frame) + CGRectGetHeight(pairButton.frame) / 2.0f);
            
            imageOffset = imageOffset + imageSpacing; // For the next iteration
        }
    } else {
        NSLog(@"Invalid array counts: arrayIB: %@, arrayIV: %@, arrayPB: %@, memories: %@", @(self.arrayImageButtons.count), @(self.arrayImageViews.count), @(self.arrayPairButtons.count), @(self.memories.count));
    }
}

#pragma mark - Configuration

- (void)configureWithFriendTypeMemories:(NSArray *)memories {
    // First, reset the view in case it was previously used
    [self resetThisView];
    
    // Next, let's make sure we have only friend memories and that we display a max of MAX_MEMORIES_COUNT
    const NSInteger MAX_MEMORIES_COUNT = 3;
    NSMutableArray *filteredFriendTypeMemories = [[NSMutableArray alloc] initWithCapacity:memories.count];
    for (NSObject *objMem in memories) {
        if ([objMem isKindOfClass:[Memory class]]) {
            Memory *mem = (Memory *)objMem;
            if (MemoryTypeFriends == mem.type) {
                [filteredFriendTypeMemories addObject:mem];
            }
        }
    }
    
    if (MAX_MEMORIES_COUNT < filteredFriendTypeMemories.count) {
        filteredFriendTypeMemories = [NSMutableArray arrayWithArray:[filteredFriendTypeMemories subarrayWithRange:NSMakeRange(0, MAX_MEMORIES_COUNT)]];
    }
    
    // Model
    self.memories = filteredFriendTypeMemories;
    
    // For each memory, create the images, the buttons, then the pair button
    for (Memory *memory in filteredFriendTypeMemories) {
        Person *author = memory.author;
        Person *otherPerson = 0 < memory.taggedUsers.count ? [memory.taggedUsers firstObject] : nil;
        
        // Only continue if we have both users. What's the point of a relationship if there is only one user?
        if (nil != author && nil != otherPerson) {
            // NOTE: THE ORDER WE ADD OBJECTS TO THESE ARRAYS DOES(!) MATTER. WE LAYOUT THE VIEWS ACCORDING TO THE ORDER IN WHICH THE IMAGES/BUTTONS WERE ADDED
            
            // Take care of the author
            SPCInitialsImageView *imageAuthor = [[SPCInitialsImageView alloc] init];
            imageAuthor.clipsToBounds = YES;
            imageAuthor.layer.masksToBounds = YES;
            [imageAuthor configureWithText:[author.firstname substringWithRange:NSMakeRange(0, 1)] url:[NSURL URLWithString:author.imageAsset.imageUrlThumbnail]];
            UIButton *btnAuthor = [[UIButton alloc] init];
            btnAuthor.clipsToBounds = YES;
            btnAuthor.layer.masksToBounds = YES;
            btnAuthor.backgroundColor = [UIColor clearColor];
            btnAuthor.tag = author.recordID;
            [btnAuthor addTarget:self action:@selector(tappedProfileButton:) forControlEvents:UIControlEventTouchUpInside];
            
            // Add the reference from the image button to the person
            // (UIButton does not conform to NSCopying, so it cannot be the key in a dictionary)
            [self.dicImageButtonTagToPerson setObject:author forKey:@(btnAuthor.tag)];
            
            // Add the image view and buttons to their arrays
            [self.arrayImageViews addObject:imageAuthor];
            [self.arrayImageButtons addObject:btnAuthor];
            
            // Add these items to the view
            [self.bgView addSubview:imageAuthor];
            [self.bgView addSubview:btnAuthor];
            
            
            // Take care of the second user
            SPCInitialsImageView *imageOtherPerson = [[SPCInitialsImageView alloc] init];
            imageOtherPerson.clipsToBounds = YES;
            imageOtherPerson.layer.masksToBounds = YES;
            [imageOtherPerson configureWithText:[otherPerson.firstname substringWithRange:NSMakeRange(0, 1)] url:[NSURL URLWithString:otherPerson.imageAsset.imageUrlThumbnail]];
            UIButton *btnOtherPerson = [[UIButton alloc] init];
            btnOtherPerson.clipsToBounds = YES;
            btnOtherPerson.layer.masksToBounds = YES;
            btnOtherPerson.backgroundColor = [UIColor clearColor];
            btnOtherPerson.tag = otherPerson.recordID;
            [btnOtherPerson addTarget:self action:@selector(tappedProfileButton:) forControlEvents:UIControlEventTouchUpInside];
            
            // Add the reference from the image button to the person
            [self.dicImageButtonTagToPerson setObject:otherPerson forKey:@(btnOtherPerson.tag)];
            
            // Add the image view and buttons to their arrays
            [self.arrayImageViews addObject:imageOtherPerson];
            [self.arrayImageButtons addObject:btnOtherPerson];
            
            // Add these items to the view
            [self.bgView addSubview:imageOtherPerson];
            [self.bgView addSubview:btnOtherPerson];
            
            // Take care of the pair label
            NSString *authorName = 0 < author.firstname.length ? author.firstname : @"A User";
            NSString *otherPersonName = 0 < otherPerson.firstname.length ? otherPerson.firstname : @"User";
            UIButton *btnPair = [[UIButton alloc] init];
            [btnPair setTitle:[NSString stringWithFormat:@"%@ & %@", authorName, otherPersonName] forState:UIControlStateNormal];
            [btnPair setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            btnPair.titleLabel.textAlignment = NSTextAlignmentCenter;
            btnPair.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
            btnPair.titleLabel.numberOfLines = 0;
            btnPair.tag = memory.recordID;
            [btnPair addTarget:self action:@selector(tappedPairButton:) forControlEvents:UIControlEventTouchUpInside];
            [self.arrayPairButtons addObject:btnPair];
            
            // Add the reference from the pair button to the memory
            [self.dicPairButtonTagToMemory setObject:memory forKey:@(btnPair.tag)];
            
            // Add the button to the view
            [self.bgView addSubview:btnPair];
        } else {
            NSLog(@"Friend memory (ID: %@) only contains one user.", @(memory.recordID));
        }
    }
    
    [self setNeedsLayout];
}

#pragma mark - Actions

- (void)tappedProfileButton:(id)sender {
    if ([sender isKindOfClass:[UIButton class]]) {
        UIButton *btnTapped = (UIButton *)sender;
        
        Person *personTapped = [self.dicImageButtonTagToPerson objectForKey:@(btnTapped.tag)];
        if (nil != personTapped && [self.delegate respondsToSelector:@selector(didTapPerson:fromFriendingActivityHeaderView:)]) {
            [self.delegate didTapPerson:personTapped fromFriendingActivityHeaderView:self];
        }
    }
}

- (void)tappedPairButton:(id)sender {
    if ([sender isKindOfClass:[UIButton class]]) {
        UIButton *btnTapped = (UIButton *)sender;
        
        Memory *memoryTapped = [self.dicPairButtonTagToMemory objectForKey:@(btnTapped.tag)];
        if (nil != memoryTapped && [self.delegate respondsToSelector:@selector(didTapFriendMemory:fromFriendingActivityHeaderView:)]) {
            [self.delegate didTapFriendMemory:memoryTapped fromFriendingActivityHeaderView:self];
        }
    }
}

#pragma mark - Accessors

- (NSArray *)memories {
    return _memories;
}

- (NSMutableDictionary *)dicPairButtonTagToMemory {
    if (nil == _dicPairButtonTagToMemory) {
        _dicPairButtonTagToMemory = [[NSMutableDictionary alloc] init];
    }
    
    return _dicPairButtonTagToMemory;
}

- (NSMutableDictionary *)dicImageButtonTagToPerson {
    if (nil == _dicImageButtonTagToPerson) {
        _dicImageButtonTagToPerson = [[NSMutableDictionary alloc] init];
    }
    
    return _dicImageButtonTagToPerson;
}

@synthesize arrayImageButtons = _arrayImageButtons;
- (NSMutableArray *)arrayImageButtons {
    if (nil == _arrayImageButtons) {
        _arrayImageButtons = [[NSMutableArray alloc] init];
    }
    
    return _arrayImageButtons;
}

- (void)setArrayImageButtons:(NSMutableArray *)arrayImageButtons {
    if (nil != _arrayImageButtons) {
        for (UIView *view in _arrayImageButtons) {
            [view removeFromSuperview];
        }
    }
    
    _arrayImageButtons = arrayImageButtons;
}

@synthesize arrayImageViews = _arrayImageViews;
- (NSMutableArray *)arrayImageViews {
    if (nil == _arrayImageViews) {
        _arrayImageViews = [[NSMutableArray alloc] init];
    }
    
    return _arrayImageViews;
}

- (void)setArrayImageViews:(NSMutableArray *)arrayImageViews {
    if (nil != _arrayImageViews) {
        for (UIView *view in _arrayImageViews) {
            [view removeFromSuperview];
        }
    }
    
    _arrayImageViews = arrayImageViews;
}

@synthesize arrayPairButtons = _arrayPairButtons;
- (NSMutableArray *)arrayPairButtons {
    if (nil == _arrayPairButtons) {
        _arrayPairButtons = [[NSMutableArray alloc] init];
    }
    
    return _arrayPairButtons;
}

- (void)setArrayPairButtons:(NSMutableArray *)arrayPairButtons {
    if (nil != _arrayPairButtons) {
        for (UIView *view in _arrayPairButtons) {
            [view removeFromSuperview];
        }
    }
    
    _arrayPairButtons = arrayPairButtons;
}

@end
