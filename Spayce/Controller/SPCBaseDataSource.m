//
//  SPCBaseDataSource.m
//  Spayce
//
//  Created by William Santiago on 4/22/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCBaseDataSource.h"
#import "Flurry.h"

// Model
#import "Asset.h"
#import "Friend.h"
#import "ProfileDetail.h"
#import "SPCAlertAction.h"
#import "User.h"
#import "UserProfile.h"
#import "Location.h"

// View
#import "MemoryCell.h"
#import "PXAlertView.h"
#import "SPCLocationPromptCell.h"
#import "SPCReportAlertView.h"

// Controller
#import "SPCAlertViewController.h"
#import "SPCMainViewController.h"
#import "SPCProfileViewController.h"
#import "SPCStarsViewController.h"
#import "SPCMapViewController.h"
#import "SPCHashTagContainerViewController.h"
#import "SPCReportViewController.h"
#import "SPCAdminSockPuppetChooserViewController.h"
#import "SPCVenueDetailViewController.h"
#import "SPCCustomNavigationController.h"

// Category
#import "UIAlertView+SPCAdditions.h"
#import "UIColor+CrossFade.h"
#import "UIImageView+WebCache.h"
#import "UIScreen+Size.h"

// Coordinator
#import "SPCMemoryCoordinator.h"

// General
#import "AppDelegate.h"

// Manager
#import "AuthenticationManager.h"
#import "ContactAndProfileManager.h"
#import "LocationManager.h"
#import "MeetManager.h"
#import "ProfileManager.h"
#import "SocialService.h"
#import "AdminManager.h"

// Transitions
#import "SPCAlertTransitionAnimator.h"

// Utility
#import "APIUtils.h"
#import "ImageUtils.h"

// Subclass
#import "SPCVenueDetailDataSource.h"


NSString * SPCFeedCellIdentifier = @"SPCFeedCellIdentifier";
NSString * SPCLoadMoreDataCellIdentifier = @"SPCLoadMoreDataCellIdentifier";
NSString * SPCLoadFirstMemoryStarCellIdentifier = @"SPCLoadFirstMemoryStarDataCellIdentifier";
NSString * SPCLoadOutsideVicinityCellIdentifier = @"SPCLoadOutsideVicinityCellIdentifier";
NSString * SPCLoadInitialDataCellIdentifier = @"SPCLoadInitialDataCellIdentifier";
NSString * SPCLoadFailedDataCellIdentifier = @"SPCLoadFailedDataCellIdentifier";
NSString * SPCReloadData = @"SPCReloadData";
NSString * SPCReloadForFilters = @"SPCReloadForFilters";
NSString * SPCReloadProfileData = @"SPCReloadProfileData";
NSString * SPCReloadProfileForFilters = @"SPCReloadProfileForFilters";
NSString * SPCMemoryDeleted = @"SPCMemoryDeleted";
NSString * SPCMemoryUpdated = @"SPCMemoryUpdated";

@interface SPCBaseDataSource () <UIAlertViewDelegate, UIViewControllerTransitioningDelegate, SPCReportAlertViewDelegate, SPCReportViewControllerDelegate, SPCAdminSockPuppetChooserViewControllerDelegate>

// Data
@property (nonatomic, strong) Memory *tempMemory;
@property (strong, nonatomic) NSMutableArray *cellHeights;
@property (nonatomic, strong) NSMutableArray *precreatedImageCells;
@property (nonatomic, strong) NSMutableArray *precreatedVideoCells;

@property (nonatomic) SPCReportType reportType;
@property (strong, nonatomic) NSArray *reportMemoryOptions;

// UI
@property (strong, nonatomic) PXAlertView *alertView;
@property (strong, nonatomic) SPCReportAlertView *reportAlertView;

// Formatters
@property (strong, nonatomic) NSDateFormatter *dateFormatter;

// Scrolling
@property (nonatomic, assign) BOOL didScrollHeaderOffScreen;
@property (nonatomic, assign) BOOL didScrollHeaderOffContentArea;
@property (nonatomic, assign) BOOL didScrollSignificantlyTowardsTrigger;

@property (nonatomic, assign) CGFloat scrollOffsetLast;
@property (nonatomic, assign) CGFloat scrollOffsetOnDirectionChange;


// Coordinator
@property (nonatomic, strong) SPCMemoryCoordinator *memoryCoordinator;

@end

@implementation SPCBaseDataSource {
    NSInteger alertViewTagTwitter;
    NSInteger alertViewTagFacebook;
    NSInteger alertViewTagReport;
}

#pragma mark - Object lifecycle

-(void)dealloc {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (SPCBaseDataSource *)init {
    self = [super init];
    if (self) {
        self.hasLoaded = NO;
        self.feed = [[NSArray alloc] init];
        self.fullFeed = [[NSArray alloc] init];
        
        NSMutableArray *tempArray = [[NSMutableArray alloc] init];
        for (int i = 0; i < 5; i ++) {
            MemoryCell *cell = [[MemoryCell alloc] initWithMemoryType:MemoryTypeImage style:UITableViewCellStyleSubtitle reuseIdentifier:@"ImageCell"];
            [self setupMemoryCellButtons:cell];
            [tempArray addObject:cell];
        }
        self.precreatedImageCells = [NSMutableArray arrayWithArray:tempArray];
        
        NSMutableArray *tempArray2 = [[NSMutableArray alloc] init];
        for (int i = 0; i < 5; i ++) {
            MemoryCell *cell = [[MemoryCell alloc] initWithMemoryType:MemoryTypeVideo style:UITableViewCellStyleSubtitle reuseIdentifier:@"VideoCell"];
            [self setupMemoryCellButtons:cell];
            [tempArray addObject:cell];
        }
        self.precreatedVideoCells = [NSMutableArray arrayWithArray:tempArray2];
        
        self.statusBarBackgroundColorMin = [UIColor colorWithWhite:0.0 alpha:0.3];
        self.statusBarBackgroundColorMax = [UIColor colorWithRed:63.0f/255.0f green:85.0f/255.0f blue:120.0f/255.0f alpha:1.0f];
        
        alertViewTagFacebook = 0;
        alertViewTagTwitter = 1;
        alertViewTagReport = 2;
    }
    return self;
}


#pragma mark - Mutators


- (void)setFeed:(NSArray *)feed {
    if (_feed.count != feed.count) {
        self.feedIsNew = YES;
    } else {
        for (int i = 0; i < _feed.count; i++) {
            if (((Memory *)_feed[i]).recordID != ((Memory *)feed[i]).recordID) {
                _feedIsNew = YES;
                break;
            }
        }
    }
    
    _feed = feed;
}


- (void)setPrefetchPaused:(BOOL)prefetchPaused {
    if (_prefetchPaused != prefetchPaused) {
        _prefetchPaused = prefetchPaused;
        
        if (!prefetchPaused) {
            // restart image downloads?
            if (self.assetQueue.count > 0) {
                [self prefetchNextImageInQueue];
            }
        }
    }
}


#pragma mark - Accessors

- (NSDateFormatter *)dateFormatter {
    if (!_dateFormatter) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.dateFormat = @"MMM dd, yyyy - hh:mm a";
    }
    return _dateFormatter;
}

- (NSMutableArray *)cellHeights {
    if (!_cellHeights) {
        _cellHeights = [[NSMutableArray alloc] initWithCapacity:5];
        for (int i = 0; i < 5; i++) {
            [_cellHeights addObject:@0.0];
        }
    }
    return _cellHeights;
}

- (UIImageView *)prefetchImageView {
    if (!_prefetchImageView) {
        _prefetchImageView = [[UIImageView alloc] init];
    }
    return _prefetchImageView;
}

- (NSMutableSet *)prefetchedList {
    if (!_prefetchedList) {
        _prefetchedList = [[NSMutableSet alloc] init];
    }
    return _prefetchedList;
}

- (NSArray *)reportMemoryOptions {
    if (nil == _reportMemoryOptions) {
        _reportMemoryOptions = @[@"ABUSE", @"SPAM", @"PERTAINS TO ME"];
    }
    
    return _reportMemoryOptions;
}



// Sets the current feed to the feed provided such that the
// memories currently displayed in the table view are not displaced.
// In other words, although the feed itself has potentially changed and the
// TableView offset updated, the user should not notice that anything is different
// (until they scroll up or down).  Obviously this requires that
// 1. The memories currently displayed in the table exist in the same contiguous
//      order in the new feed
// 2. There is enough content in the list, and the user has scrolled far enough,
//      that no header / content height issues are caused as a result.
//
// If this method returns 'YES', the 'feed' property has been updated, the table
// data reloaded, and the table content offset changed appropriately.
// Otherwise, nothing has changed.  It is up to the caller to determine the
// next course of action -- do they e.g. update the feed in a way that disturbs
// user experience?
- (BOOL)setFeed:(NSArray *)feed andReloadWithoutDisplacingTableView:(UITableView *)tableView {
    NSArray *visibleCells = [tableView visibleCells];
    NSMutableArray *visibleMemoryIds = [NSMutableArray arrayWithCapacity:visibleCells.count];
    
    if (visibleCells.count == 0) {
        return NO;
    }
    
    CGPoint previousOffset = tableView.contentOffset;
    CGFloat tableHeaderHeight = tableView.tableHeaderView ? CGRectGetHeight(tableView.tableHeaderView.frame) : 0;
    
    // restrictions: we can only attempt this if
    // 1. all displayed cells are memories
    // 2. all displayed cells are in the same section
    // 3. the top cell is at or above the top of the table view
    // 4. the bottom cell is at or below the bottom of the table view
    
    for (int i = 0; i < visibleCells.count; i++) {
        UITableViewCell *cell = visibleCells[i];
        if (![cell isKindOfClass:[MemoryCell class]]) {
            return NO;
        }
        MemoryCell *memoryCell = (MemoryCell *)cell;
        // assume they are all in the same section.  Otherwise
        // there may be headers between them, but ignore this possibility for now.
        
        if (i == 0) {
            // top cell: must be at or above the top of the table (using content inset).
            if (CGRectGetMinY(cell.frame) - previousOffset.y - tableHeaderHeight > 0) {
                return NO;
            }
        }
        if (i == visibleCells.count - 1) {
            //NSLog(@"bottom cell has bottom Y %f, content offset %f, table has content inset %f", CGRectGetMaxY(cell.frame), previousOffset.y, tableView.contentInset.bottom);
            if (CGRectGetMaxY(cell.frame) - previousOffset.y - tableHeaderHeight < CGRectGetHeight(tableView.frame)) {
                return NO;
            }
        }
        
        [visibleMemoryIds addObject:@(((Memory *)self.feed[memoryCell.tag]).recordID)];
    }
    
    // it looks like we can potentially keep those cells at that position without change.
    // try to find this contiguous series of memories exists in the new feed.
    int startIndex = -1;
    for (int i = 0; i < feed.count; i++) {
        Memory *memory = feed[i];
        if (memory.recordID == [visibleMemoryIds[0] intValue]) {
            startIndex = i;
            // verify that the rest match...
            for (int j = 1; j < visibleMemoryIds.count; j++) {
                if (startIndex + j >= feed.count) {
                    return NO;
                }
                memory = feed[startIndex + j];
                if (memory.recordID != [visibleMemoryIds[j] intValue]) {
                    return NO;
                }
            }
            break;
        }
    }
    if (startIndex == -1) {
        return NO;
    }
    
    int startIndexPrevious = (int)((MemoryCell *)visibleCells[0]).tag;
    
    // It looks like we're OK to switch.  There are a few possible
    // failure cases we haven't considered -- what if the subclass has
    // weird header behavior and will insert a header between two of these
    // memories (or remove one)?  What if we are removing items from the list
    // above or below and this actually prevents maintaining the same offset?
    // We ignore these possibilities for now: the most likely use case
    // is that new memories have been added above those currently displayed
    // and that sections have not changed: this case has been effectively covered.
    
    CGFloat previousCellHeight = [self tableView:tableView contentHeightToMemoryIndex:startIndexPrevious];
    self.feed = feed;
    CGFloat cellHeight = [self tableView:tableView contentHeightToMemoryIndex:startIndex];
    CGPoint offset = CGPointMake(previousOffset.x, previousOffset.y - previousCellHeight + cellHeight);
    
    // reload data and set content offset
    [tableView reloadData];
    [tableView setContentOffset:offset];
    
    return YES;
}

- (CGFloat)tableView:(UITableView *)tableView contentHeightToMemoryIndex:(int)index {
    CGFloat height = 0;
    
    int currentSection = -1;
    int row = 0;
    for (int i = 0; i < index + 1; i++) {
        if (currentSection == -1 || i >= [self tableView:tableView numberOfRowsInSection:currentSection]) {
            if (currentSection != -1) {
                height += [self tableView:tableView heightForFooterInSection:currentSection];
            }
            currentSection++;
            height += [self tableView:tableView heightForHeaderInSection:currentSection];
            
            row = 0;
        }
        
        if (i < index) {
            CGFloat cellHeight = [self tableView:tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:currentSection]];
            height += cellHeight;
            row++;
        }
    }
    
    return height;
}


- (int)fullStarCount {
    
    int starCount = 0;
    
    for (int i = 0; i <[self.fullFeed count]; i++) {
        Memory *tempMem = (Memory *)self.fullFeed[i];
        starCount = starCount + (int)tempMem.starsCount;
    }
    
    return starCount;
}

- (SPCMemoryCoordinator *)memoryCoordinator {
    if (!_memoryCoordinator) {
        _memoryCoordinator = [[SPCMemoryCoordinator alloc] init];
    }
    return _memoryCoordinator;
}

- (NSString *)loadingMessageWhenFullFeedIsEmpty {
    return NSLocalizedString(@"No memories yet!", nil);
}

- (NSString *)loadingMessageWhenFullFeedIsNotEmptyButFeedIsEmpty {
    return NSLocalizedString(@"No memories yet!", nil);
}

- (void)selectedSegment:(id)sender {
    NSInteger index = [sender selectedSegmentIndex];
    
    if (self.selectedSegmentIndex != index) {
        self.selectedSegmentIndex = index;
        
        if (self.delegate) {
            if ([self.delegate respondsToSelector:@selector(segmentedControlValueChanged:)]) {
                [self.delegate segmentedControlValueChanged:self.selectedSegmentIndex];
            }
        }
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.feed.count + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView textCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"TextCell";
    
    MemoryCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[MemoryCell alloc] initWithMemoryType:MemoryTypeText style:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        [self setupMemoryCellButtons:cell];
    }
    
    Memory *memory;
    memory = self.feed[indexPath.row];
    
    [cell configureWithMemory:memory tag:indexPath.row dateFormatter:self.dateFormatter canShowAnonLabel:self.isProfileData];
    cell.tag = indexPath.row;
    cell.contentView.backgroundColor = tableView.backgroundColor;
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView imageCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"ImageCell";
    
    MemoryCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        if (self.precreatedImageCells.count > 0) {
            cell = self.precreatedImageCells[0];
            [self.precreatedImageCells removeObject:cell];
        }
        else {
            cell = [[MemoryCell alloc] initWithMemoryType:MemoryTypeImage style:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
            [self setupMemoryCellButtons:cell];
        }
    }
    
    Memory *memory;
    memory = self.feed[indexPath.row];
    
    [cell configureWithMemory:memory tag:indexPath.row dateFormatter:self.dateFormatter canShowAnonLabel:self.isProfileData];
    cell.tag = indexPath.row;
    cell.contentView.backgroundColor = tableView.backgroundColor;
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView videoCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"VideoCell";
    
    MemoryCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        if (self.precreatedVideoCells.count > 0) {
            cell = self.precreatedVideoCells[0];
            [self.precreatedVideoCells removeObject:cell];
        }
        else {
            cell = [[MemoryCell alloc] initWithMemoryType:MemoryTypeVideo style:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
            [self setupMemoryCellButtons:cell];
        }
    }
    
    Memory *memory;
    memory = self.feed[indexPath.row];
    
    [cell configureWithMemory:memory tag:indexPath.row dateFormatter:self.dateFormatter canShowAnonLabel:self.isProfileData];
    cell.tag = indexPath.row;
    cell.contentView.backgroundColor = tableView.backgroundColor;
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView mapCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"MapCell";
    
    MemoryCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[MemoryCell alloc] initWithMemoryType:MemoryTypeMap style:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        [self setupMemoryCellButtons:cell];
    }
    
    Memory *memory;
    memory = self.feed[indexPath.row];
    
    [cell configureWithMemory:memory tag:indexPath.row dateFormatter:self.dateFormatter canShowAnonLabel:self.isProfileData];
    cell.tag = indexPath.row;
    cell.contentView.backgroundColor = tableView.backgroundColor;
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView friendsCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"FriendsCell";
    
    MemoryCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[MemoryCell alloc] initWithMemoryType:MemoryTypeFriends style:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        [self setupMemoryCellButtons:cell];
    }
    
    Memory *memory;
    memory = self.feed[indexPath.row];
    
    [cell configureWithMemory:memory tag:indexPath.row dateFormatter:self.dateFormatter canShowAnonLabel:self.isProfileData];
    cell.tag = indexPath.row;
    cell.contentView.backgroundColor = tableView.backgroundColor;
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView feedForRowAtIndexPath:(NSIndexPath *)indexPath {
     static NSString *CellIdentifier = @"BlankCell";  //failsafe in case type-less mems sneak through somehow
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:SPCFeedCellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.userInteractionEnabled = NO;
    }
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView loadMoreDataCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.feedUnavailable && !self.hasLoaded && self.feed.count == 0) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:SPCLoadFailedDataCellIdentifier];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:SPCLoadFailedDataCellIdentifier];
            cell.contentView.backgroundColor = tableView.backgroundColor;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            // add an image view, 44 pixels from the top
            if (tableView.tag != kHereTableViewTag) {
                UIImageView * imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"placeholder-location-off"]];
                imageView.frame = CGRectOffset(imageView.frame, 8, 44);
                imageView.tag = 111;
                [cell addSubview:imageView];
                cell.clipsToBounds = NO;
            }
        }
        return cell;
    }
    else if (!self.hasLoaded) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:SPCLoadInitialDataCellIdentifier];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:SPCLoadInitialDataCellIdentifier];
            cell.contentView.backgroundColor = tableView.backgroundColor;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            //add spinner
            UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
            indicatorView.center = CGPointMake(tableView.bounds.size.width / 2, [self tableView:tableView heightForRowAtIndexPath:indexPath]/2);
            indicatorView.tag = 111;
            indicatorView.color = [UIColor grayColor];
            [cell addSubview:indicatorView];
            [indicatorView startAnimating];
        } else {
            UIActivityIndicatorView *animation = (UIActivityIndicatorView *)[cell viewWithTag:111];
            animation.center = CGPointMake(tableView.bounds.size.width / 2, [self tableView:tableView heightForRowAtIndexPath:indexPath]/2);
            [animation startAnimating];
        }
        return cell;
    }
    else if (self.hasLoaded && self.fullFeed.count == 0 && tableView.tag == kHashTagTableViewTag) {
        UITableViewCell *cell;
        cell = [tableView dequeueReusableCellWithIdentifier:SPCLoadOutsideVicinityCellIdentifier];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:SPCLoadOutsideVicinityCellIdentifier];
            cell.contentView.backgroundColor = tableView.backgroundColor;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            // set text and image
            UILabel * textView = [[UILabel alloc] init];
            textView.font = [UIFont spc_mediumSystemFontOfSize:14];
            textView.textColor = [UIColor colorWithRed:184.0/255.0 green:193.0/255.0 blue:201.0/255.0 alpha:1.0];
            textView.textAlignment = NSTextAlignmentCenter;
            textView.lineBreakMode = NSLineBreakByWordWrapping;
            textView.numberOfLines = 0;
            
            textView.text = @"No other memories found with this hashtag.";
            
            textView.tag = 110;
            [cell addSubview:textView];
            
            [textView sizeToFit];
        }
        UILabel * textView = (UILabel *)[cell viewWithTag:110];
        
        CGFloat cellHeight = [self tableView:tableView heightForRowAtIndexPath:indexPath];
        textView.center = CGPointMake(CGRectGetWidth(tableView.frame)/2, cellHeight/2);
        
        return cell;
    
    }
    else if (self.hasLoaded && self.fullFeed.count == 0 && !self.isProfileData && tableView.tag != kTrendingTableViewTag) {
        UITableViewCell *cell;
        if (self.isWithinMAMDistance) {
            cell = [tableView dequeueReusableCellWithIdentifier:SPCLoadFirstMemoryStarCellIdentifier];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:SPCLoadFirstMemoryStarCellIdentifier];
                cell.contentView.backgroundColor = tableView.backgroundColor;
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                
                // set text and image
                UILabel * textView = [[UILabel alloc] init];
                textView.font = [UIFont spc_mediumSystemFontOfSize:14];
                textView.textColor = [UIColor colorWithRed:184.0/255.0 green:193.0/255.0 blue:201.0/255.0 alpha:1.0];
                textView.textAlignment = NSTextAlignmentCenter;
                textView.lineBreakMode = NSLineBreakByWordWrapping;
                textView.numberOfLines = 0;
                
                NSMutableAttributedString *mutString = [[NSMutableAttributedString alloc] init];
                
                NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
                attachment.image = [UIImage imageNamed:@"star-gold-inline"];
                attachment.bounds = CGRectMake(0, -1.5, attachment.image.size.width, attachment.image.size.height);
                
                UIColor *goldColor = [UIColor colorWithRed:255.0/255.0 green:210.0/255.0 blue:0.0/255.0 alpha:1.0];
                
                [mutString appendAttributedString:[[NSAttributedString alloc] initWithString:@"Earn "]];
                [mutString appendAttributedString:[[NSAttributedString alloc] initWithString:@"2 " attributes:@{ NSForegroundColorAttributeName : goldColor }]];
                [mutString appendAttributedString:[NSAttributedString attributedStringWithAttachment:attachment]];
                [mutString appendAttributedString:[[NSAttributedString alloc] initWithString:@" and make the\nfirst memory here."]];
                
                
                textView.attributedText = [[NSAttributedString alloc] initWithAttributedString:mutString];
                
                textView.tag = 110;
                [cell addSubview:textView];
                
                [textView sizeToFit];
            }
        } else {
            cell = [tableView dequeueReusableCellWithIdentifier:SPCLoadOutsideVicinityCellIdentifier];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:SPCLoadOutsideVicinityCellIdentifier];
                cell.contentView.backgroundColor = tableView.backgroundColor;
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                
                // set text and image
                UILabel * textView = [[UILabel alloc] init];
                textView.font = [UIFont spc_mediumSystemFontOfSize:14];
                textView.textColor = [UIColor colorWithRed:184.0/255.0 green:193.0/255.0 blue:201.0/255.0 alpha:1.0];
                textView.textAlignment = NSTextAlignmentCenter;
                textView.lineBreakMode = NSLineBreakByWordWrapping;
                textView.numberOfLines = 0;
                
                textView.text = @"There are no memories here and\nthis venue is outside of your vicinity.";
                
                textView.tag = 110;
                [cell addSubview:textView];
                
                [textView sizeToFit];
            }
        }
        UILabel * textView = (UILabel *)[cell viewWithTag:110];
        
        CGFloat cellHeight = [self tableView:tableView heightForRowAtIndexPath:indexPath];
        CGFloat cellContentHeight = CGRectGetHeight(textView.frame);
        CGFloat cellContentTop = (cellHeight - cellContentHeight - 25)/2 - 5;
        
         //4.7"
         if ([UIScreen mainScreen].bounds.size.width == 375) {
             cellContentTop += 21;
         }
         
         //5"
         if ([UIScreen mainScreen].bounds.size.width > 375) {
             cellContentTop += 33;
         }
        
        // set content positions
        textView.center = CGPointMake(CGRectGetWidth(tableView.frame)/2, cellContentTop + CGRectGetHeight(textView.frame)/2);
        
        return cell;
    }
    else if (self.hasLoaded && self.fullFeed.count > 0 && !self.hashTagFilter && self.feed.count == 0 && !self.isProfileData && tableView.tag != kTrendingTableViewTag) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:SPCLoadFirstMemoryStarCellIdentifier];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:SPCLoadOutsideVicinityCellIdentifier];
            cell.contentView.backgroundColor = tableView.backgroundColor;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            // set text and image
            UILabel * textView = [[UILabel alloc] init];
            textView.font = [UIFont spc_mediumSystemFontOfSize:14];
            textView.textColor = [UIColor colorWithRed:184.0/255.0 green:193.0/255.0 blue:201.0/255.0 alpha:1.0];
            textView.textAlignment = NSTextAlignmentCenter;
            textView.lineBreakMode = NSLineBreakByWordWrapping;
            textView.numberOfLines = 0;
            
            textView.text = @"Your memories and your friends'\nmemories that have been left here";
            
            textView.tag = 110;
            [cell addSubview:textView];
            
            [textView sizeToFit];
        }
        
        UILabel * textView = (UILabel *)[cell viewWithTag:110];
        
        CGFloat cellHeight = [self tableView:tableView heightForRowAtIndexPath:indexPath];
        CGFloat cellContentHeight = CGRectGetHeight(textView.frame);
        CGFloat cellContentTop = (cellHeight - cellContentHeight - 25)/2 - 5;
        
        //4.7"
        if ([UIScreen mainScreen].bounds.size.width == 375) {
            cellContentTop += 21;
        }
        
        //5"
        if ([UIScreen mainScreen].bounds.size.width > 375) {
            cellContentTop += 33;
        }
        
        // set content positions
        textView.center = CGPointMake(CGRectGetWidth(tableView.frame)/2, cellContentTop + CGRectGetHeight(textView.frame)/2);
        
        return cell;
    }
    else if (self.hasLoaded && self.fullFeed.count > 0 && self.hashTagFilter && self.feed.count == 0 && !self.isProfileData && tableView.tag != kTrendingTableViewTag) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:SPCLoadFirstMemoryStarCellIdentifier];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:SPCLoadOutsideVicinityCellIdentifier];
            cell.contentView.backgroundColor = tableView.backgroundColor;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            // set text and image
            UILabel * textView = [[UILabel alloc] init];
            textView.font = [UIFont spc_mediumSystemFontOfSize:14];
            textView.textColor = [UIColor colorWithRed:184.0/255.0 green:193.0/255.0 blue:201.0/255.0 alpha:1.0];
            textView.textAlignment = NSTextAlignmentCenter;
            textView.lineBreakMode = NSLineBreakByWordWrapping;
            textView.numberOfLines = 0;
            
            textView.tag = 110;
            [cell addSubview:textView];
        }
        
        UILabel * textView = (UILabel *)[cell viewWithTag:110];
        textView.text = [NSString stringWithFormat:@"No memories found here tagged\nwith %@", self.hashTagFilter];
        [textView sizeToFit];
        
        CGFloat cellHeight = [self tableView:tableView heightForRowAtIndexPath:indexPath];
        CGFloat cellContentHeight = CGRectGetHeight(textView.frame);
        CGFloat cellContentTop = (cellHeight - cellContentHeight - 25)/2 - 5;
        
        //4.7"
        if ([UIScreen mainScreen].bounds.size.width == 375) {
            cellContentTop += 21;
        }
        
        //5"
        if ([UIScreen mainScreen].bounds.size.width > 375) {
            cellContentTop += 33;
        }
        
        // set content positions
        textView.center = CGPointMake(CGRectGetWidth(tableView.frame)/2, cellContentTop + CGRectGetHeight(textView.frame)/2);
        
        return cell;
    }
    else {
        NSString *imageName = (tableView.tag == kHereTableViewTag) ? @"flag-gray-small" : @"flag-purple";
        
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:SPCLoadMoreDataCellIdentifier];
        UIImageView * imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:imageName]];
        imageView.tag = 111;
        imageView.alpha = 0;
        [cell addSubview:imageView];
        
        UILabel * label = [[UILabel alloc] init];
        label.tag = 112;
        label.font = [UIFont spc_regularSystemFontOfSize:14];
        label.textColor = [UIColor colorWithRed:175.0/255.0 green:180.0/255.0 blue:188.0/255.0 alpha:1.0];
        label.textAlignment = NSTextAlignmentCenter;
        label.lineBreakMode = NSLineBreakByWordWrapping;
        label.numberOfLines = 0;
        label.backgroundColor = [UIColor clearColor];
        [cell addSubview:label];
        
        UILabel * titleLabel = [[UILabel alloc] init];
        titleLabel.tag = 113;
        titleLabel.font = [UIFont spc_boldSystemFontOfSize:14];
        titleLabel.textColor = [UIColor colorWithRed:139.0/255.0 green:153.0/255.0 blue:175.0/255.0 alpha:1.0];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        titleLabel.numberOfLines = 0;
        [cell addSubview:titleLabel];
        
        UILabel * textLabel = (UILabel *)[cell viewWithTag:112];
        textLabel.hidden = YES;
        cell.textLabel.font = [UIFont spc_regularSystemFontOfSize:14];
        cell.textLabel.textColor = [UIColor colorWithWhite:201.0f/255.0f alpha:1.0f];
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        cell.textLabel.numberOfLines = 0;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.contentView.backgroundColor = tableView.backgroundColor;
        
        UIImageView *bouncingArrowImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"arrow-blue"]];
        bouncingArrowImageView.tag = 113;
        bouncingArrowImageView.hidden = YES;
        [cell addSubview:bouncingArrowImageView];
        
        self.bouncingArrowImageView = bouncingArrowImageView;
        
        UILabel * textTitleLabel = (UILabel *)[cell viewWithTag:113];
        textTitleLabel.hidden = YES;
        
        cell.textLabel.text = @"Loading\n\n";
        
        if (self.hasLoaded && self.fullFeed.count == 0 && tableView.tag != kTrendingTableViewTag){
            imageView = (UIImageView *)[cell viewWithTag:111];
            imageView.alpha = 0;
            cell.textLabel.text = [self loadingMessageWhenFullFeedIsEmpty];
        }
        
        //NO PERSONAL MEMS HERE YET - Be a legend
        else if (self.hasLoaded && (self.fullFeed.count > 0 || tableView.tag == kTrendingTableViewTag) && self.feed.count == 0) {
            if (self.selectedSegmentIndex == 2 || tableView.tag == kTrendingTableViewTag) {
                NSString *msgText= self.fullFeed.count > 0 ? [self loadingMessageWhenFullFeedIsNotEmptyButFeedIsEmpty] : [self loadingMessageWhenFullFeedIsEmpty];
                NSMutableAttributedString *styledText = [[NSMutableAttributedString alloc] initWithString:msgText];
                [styledText addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithWhite:201.0f/255.0f alpha:1.0f] range:NSMakeRange(0, msgText.length)];
                [styledText addAttribute:NSFontAttributeName value:[UIFont spc_regularSystemFontOfSize:14] range:NSMakeRange(0, msgText.length)];
                NSRange headerRange = [msgText rangeOfString:@"Be a Legend"];
                if (headerRange.location == NSNotFound) {
                    headerRange = NSMakeRange(0, msgText.length);
                }
                if (![UIScreen isLegacyScreen]) {
                    [styledText addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:139.0/255.0 green:153.0/255.0 blue:175.0/255.0 alpha:1.0] range:headerRange];
                    [styledText addAttribute:NSFontAttributeName value:[UIFont spc_boldSystemFontOfSize:14] range:headerRange];
                }
                if (tableView.tag == kHereTableViewTag) {
                    cell.textLabel.text = @"";
                    textLabel.text = @"Leave a memory in this location\nand become a part of history.";
                    textLabel.attributedText = nil;
                    textTitleLabel.text = @"Be a Legend";
                } else {
                    cell.textLabel.text = @"";
                    textLabel.text = nil;
                    textLabel.attributedText = styledText;
                }
                
                imageView = (UIImageView *)[cell viewWithTag:111];
                imageView.image = [UIImage imageNamed:imageName];
                imageView.alpha = 1;
                
                CGFloat cellHeight = [self tableView:tableView heightForRowAtIndexPath:indexPath];
                
                if (tableView.tag == kHereTableViewTag) {
                    [textLabel sizeToFit];
                    [textTitleLabel sizeToFit];
                    
                    CGFloat spaceBetween = 10;
                    CGFloat cellContentHeight = CGRectGetHeight(imageView.frame) + spaceBetween + (textTitleLabel.hidden ? 0 : CGRectGetHeight(textTitleLabel.frame) + spaceBetween) + CGRectGetHeight(textLabel.frame);
                    CGFloat cellContentTop = (cellHeight - cellContentHeight - 25)/2 - 13;
                    
                    // set content positions
                    imageView.center = CGPointMake(CGRectGetWidth(tableView.frame)/2, cellContentTop + CGRectGetHeight(imageView.frame)/2);
                    textTitleLabel.center = CGPointMake(imageView.center.x, CGRectGetMaxY(imageView.frame) + spaceBetween + CGRectGetHeight(textTitleLabel.frame)/2);
                    textTitleLabel.hidden = NO;
                    textLabel.center = CGPointMake(imageView.center.x, CGRectGetMaxY(textTitleLabel.frame) + CGRectGetHeight(textLabel.frame)/2);
                    textLabel.hidden = NO;
                } else {
                    imageView.center = CGPointMake(CGRectGetWidth(tableView.frame)/2, 100);
                    [textLabel sizeToFit];
                    // FIXME: This is a hack
                    CGRect frame = textLabel.frame;
                    frame.size.width += 20;
                    textLabel.frame = frame;
                    textLabel.center = CGPointMake(imageView.center.x, CGRectGetMaxY(imageView.frame) + 30);
                    textLabel.hidden = NO;
                   
                    bouncingArrowImageView.hidden = !self.shouldShowBouncingArrowImageView;
                    bouncingArrowImageView.center = CGPointMake(CGRectGetWidth(tableView.frame)/2, cellHeight-45);
                    [bouncingArrowImageView.layer removeAllAnimations];
                    [UIView animateWithDuration:1.2
                                          delay:0.0
                                        options: UIViewAnimationOptionRepeat | UIViewAnimationOptionAutoreverse
                                     animations:^{
                                         bouncingArrowImageView.center = CGPointMake(bouncingArrowImageView.center.x, bouncingArrowImageView.center.y + 10);
                                     } completion:nil];
                }
            }
            else {
                imageView = (UIImageView *)[cell viewWithTag:111];
                imageView.alpha = 0;
            }
        }
        if (self.hasLoaded  && (self.feed.count > 0)) {
            imageView = (UIImageView *)[cell viewWithTag:111];
            imageView.alpha = 0;
            cell.textLabel.text = @"";
        }
        
        return cell;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView locationCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *CellIdentifier = @"LocationCell";
    
    SPCLocationPromptCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[SPCLocationPromptCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        [cell.actionButton addTarget:self action:@selector(promptEnableLocationServices:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    cell.textLabel.text = NSLocalizedString(@"Your Memories Need Location", nil);
    cell.detailTextLabel.text = NSLocalizedString(@"Spayce uses location to anchor your memories to places and discover new ones.", nil);
    [cell.actionButton setTitle:NSLocalizedString(@"Turn on Location", nil) forState:UIControlStateNormal];
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < self.feed.count) {
        
        if (self.feedIsNew) {
            // we have begun loading for a new feed.  Now might be a good time to queue up some
            // image precaching....
            [self performSelector:@selector(updatePrefetchQueueWithTableView:) withObject:tableView afterDelay:1.0];
            self.feedIsNew = NO;
        }
        
        Memory *memory = self.feed[indexPath.row];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(didGetCellForMemory:atIndexPath:)]) {
            [self.delegate didGetCellForMemory:memory atIndexPath:indexPath];
        }
        
        if (memory.type == MemoryTypeText) {
            return [self tableView:tableView textCellForRowAtIndexPath:indexPath];
        }
        else if (memory.type == MemoryTypeImage) {
            return [self tableView:tableView imageCellForRowAtIndexPath:indexPath];
        }
        else if (memory.type == MemoryTypeVideo) {
            return [self tableView:tableView videoCellForRowAtIndexPath:indexPath];
        }
        else if (memory.type == MemoryTypeMap) {
            return [self tableView:tableView mapCellForRowAtIndexPath:indexPath];
        }
        else if (memory.type == MemoryTypeFriends) {
            return [self tableView:tableView friendsCellForRowAtIndexPath:indexPath];
        }
        else {
            return [self tableView:tableView feedForRowAtIndexPath:indexPath];
        }
    } else {
        return [self tableView:tableView loadMoreDataCellForRowAtIndexPath:indexPath];
    }
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat height;
    if (indexPath.row < [self.feed count]) {
        Memory *memory = self.feed[indexPath.row];
        CGSize constraint = CGSizeMake(290, 20000);
        height = [MemoryCell measureHeightWithMemory:memory constrainedToSize:constraint];
    } else if (self.feedUnavailable || !self.hasLoaded || ((self.feed.count == 0) && indexPath.row == self.feed.count)) {
        height = 150;
    } else {
        height = 0;
    }
    
    if (tableView.tag == kHereTableViewTag && self.feed.count == 0) {
        // very specific sizes for loading views, that are hard to determine simply
        // by examining the table.  We need to get this exactly right; filling precisely
        // the remaining pixels in the table from the "resting offset" to the bottom.
        CGFloat tableHeight = tableView.frame.size.height;
        CGFloat tableHeaderHeight = tableView.tableHeaderView.frame.size.height;
        if (self.fullFeed.count == 0) {
            // no content -- no header, no nothing.
            // The appropriate size on 4 inch screens is 158, equal to
            // tableHeight - (tableHeaderHeight - restingOffset) - bottomContentInset.
            return tableHeight - (tableHeaderHeight - self.restingOffset) - tableView.contentInset.bottom;
        } else {
            // no PERSONAL content -- the header is displayed, however.
            // The appropriate size on 4 inch screens with our current resting offset design
            // is 113, equal to tableHeight - (tableHeaderHeight - restingOffset) - headerHeight - bottomContentInset.
            CGFloat headerHeight = [self tableView:tableView heightForHeaderInSection:0];
            return tableHeight - (tableHeaderHeight - self.restingOffset) - headerHeight - tableView.contentInset.bottom;
        }
    }
    if (indexPath.section == 0 && indexPath.row == self.feed.count && self.feed.count <= 5) {
        // In some circumstances, we want to extend the height of the final cell ("loading") to
        // fill up the table.  For example, if we have a restingOffset, we need enough content
        // in the table to be able to scroll to that offset and fill the remaining space at the
        // bottom with cells.  As a heuristic, we assume this is only necessary if the table
        // contains no more than 5 memories.
        
        // extra space: first find the content size
        CGFloat contentSize = 0;
        // header?
        if (tableView.tableHeaderView) {
            contentSize += CGRectGetHeight(tableView.tableHeaderView.frame);
        }
        // footer?
        if (tableView.tableFooterView) {
            contentSize += CGRectGetHeight(tableView.tableFooterView.frame);
        }
        // section headers?
        if ([self respondsToSelector:@selector(tableView:heightForHeaderInSection:)]) {
            for (int i = 0; i <= indexPath.section; i++) {
                contentSize += [self tableView:tableView heightForHeaderInSection:i];
            }
        }
        // section footers?
        if ([self respondsToSelector:@selector(tableView:heightForFooterInSection:)]) {
            for (int i = 0; i <= indexPath.section; i++) {
                contentSize += [self tableView:tableView heightForFooterInSection:i];
            }
        }
        // cell heights?
        for (int i = 0; i < indexPath.row && i < self.cellHeights.count; i++) {
            contentSize += [((NSNumber *)self.cellHeights[i]) floatValue];
        }
        
        // extra space: take this content size and subtract
        // the resting offset, and the total space available for display.
        // If the result is negative, then its absolute value is the appropriate cell size.  Otherwise, 0.
        CGFloat minHeight = contentSize;
        minHeight -= self.restingOffset;
        minHeight -= CGRectGetHeight(tableView.frame);
        minHeight += tableView.contentInset.bottom + MAX(0, tableView.contentInset.top - 20.0);
        minHeight = (minHeight < 0 ? -minHeight : 0);
        if (self.feedUnavailable && !self.hasLoaded && self.feed.count == 0) {
            // "location unknown" image.  For some reason
            // our table height is too large... shrink it a bit.
            minHeight -= 55;
        }
        if (height < minHeight) {
            height = minHeight;
        }
    }
    
    if (indexPath.row < self.cellHeights.count) {
        self.cellHeights[indexPath.row] = @(height);
    }
    
    return height;
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.delegate && [self.delegate respondsToSelector:@selector(updateMaxIndexViewed:)]) {
        [self.delegate updateMaxIndexViewed:indexPath.row];
    }
    
    if ([cell.reuseIdentifier isEqualToString:@"VideoCell"])  {
        [cell prepareForReuse]; //force this call right away when cell is off screen to stop video playback rather than waiting for the video cell to get naturally reused
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Empty method so subclasses can safely call 'super' on this method.
}

- (void)tableView:(UITableView *)tableView didHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    // Empty method so subclasses can safely call 'super' on this method.
}

#pragma mark - UIScrollViewDelegate

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView {
    // Only allow scroll-to-top if we don't have a resting position
    // set.  Otherwise, we scroll to the top of the header, which is
    // obviously undesired behavior (we want to function as if the
    // restingOffset is the effective top of the content, athough the
    // user can manually scroll higher temporarily).
    if (self.restingOffset == 0) {
        return YES;
    } else {
        [scrollView setContentOffset:CGPointMake(scrollView.contentOffset.x, self.restingOffset) animated:YES];
        return NO;
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    self.draggingScrollView = YES;
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    if (self.draggingScrollView) {
        // We allow resting and triggering offsets.  The two offsets define a vector,
        // resting --> triggering.  Behavior differs based on where our offset sits
        // relative to this vector:
        //              resting         -->              triggering
        //    nothing            return to rest                         notification and return
        //
        // If resting and triggering are 0, we skip this behavior.
        CGFloat currentOffset = scrollView.contentOffset.y;
        CGFloat targetOffset = (*targetContentOffset).y;
        if (self.restingOffset != 0 || self.triggeringOffset != 0) {
            int sign = self.triggeringOffset > self.restingOffset ? 1 : -1;
            if ((targetOffset - self.restingOffset) * sign > 0) {
                // return to rest, no matter what.  We send the notification if:
                // 1. the scroll view is currently past the triggering offset
                // 2. the scroll view is between rest and triggering, its velocity is high, and it
                //          will continue past the triggering offset before coming to rest.
                BOOL pastTriggering = (currentOffset - self.triggeringOffset) * sign > 0;
                BOOL pastResting = (currentOffset - self.restingOffset) * sign > 0;
                BOOL willBePastTriggering = (targetOffset - self.triggeringOffset) * sign > 0;
                if (pastTriggering || (fabsf(velocity.y) > 1.5 && pastResting && willBePastTriggering)) {
                    // trigger!
                    [self detectedTrigger];
                }
                if (sign * velocity.y > 0 || (currentOffset - self.restingOffset) * sign > 0) {
                    // moving in the opposite direction of our reset, or otherwise past
                    // the resting point.  It takes a little effort to stop our current motion
                    // if moving away from resting (just setting the target offset
                    // will cause a sudden jump to that position, not a smooth animation).  Furthermore,
                    // setting a target offset when our velocity is low will cause a very
                    // gradual climb to the offset, rather than a quick movement.
                    *targetContentOffset = CGPointMake((*targetContentOffset).x, currentOffset);
                    [scrollView setContentOffset:(*targetContentOffset) animated:NO];
                    [scrollView setContentOffset:CGPointMake((*targetContentOffset).x, self.restingOffset) animated:YES];
                } else {
                    // We are moving past the resting offset, but are not past it now.
                    // Set our target offset to rest there and allow the animation to continue.
                    *targetContentOffset = CGPointMake((*targetContentOffset).x, self.restingOffset);
                }
            }
        }
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        self.draggingScrollView = NO;
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    self.draggingScrollView = NO;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.delegate) {
        if ([self.delegate respondsToSelector:@selector(scrollViewDidScroll:)]) {
            [self.delegate scrollViewDidScroll:scrollView];
        }
    }
    
    CGFloat offset = scrollView.contentOffset.y;
    
    if (offset != self.scrollOffsetLast) {
        BOOL down = offset - self.scrollOffsetLast > 0;
        BOOL prevDown = self.scrollOffsetLast - self.scrollOffsetOnDirectionChange > 0;
        
        
        CGFloat travel = offset - self.scrollOffsetLast;
        CGFloat continuousTravel;
        if (down != prevDown || self.scrollOffsetLast == self.scrollOffsetOnDirectionChange) {
            // direction change!
            continuousTravel = travel;
            self.scrollOffsetOnDirectionChange = self.scrollOffsetLast;
        } else {
            // same direction as before
            continuousTravel = offset - self.scrollOffsetOnDirectionChange;
        }
        
        self.scrollOffsetLast = offset;
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(scrollViewDidScroll:travel:continuousTravel:)]) {
            [self.delegate scrollViewDidScroll:scrollView travel:travel continuousTravel:continuousTravel];
        }
    }

    // Detect significant offset change
    if (self.isDraggingSrollView) {
        CGFloat significantOffsetY = -100;
        if (floor(scrollView.contentOffset.y) < significantOffsetY) {
            [self detectedSignificantOffsetChange];
        }
    }
    
    int sign = self.triggeringOffset > self.restingOffset ? 1 : -1;
    float offsetPastResting = (scrollView.contentOffset.y - self.restingOffset) * sign;
    if (self.didScrollSignificantlyTowardsTrigger && offsetPastResting < 30) {
        [self detectedScrolledSignificantlyAwayFromTrigger];
        self.didScrollSignificantlyTowardsTrigger = NO;
    } else if (!self.didScrollSignificantlyTowardsTrigger && offsetPastResting > 60) {
        [self detectedScrolledSignificantlyTowardsTrigger];
        self.didScrollSignificantlyTowardsTrigger = YES;
    }
    
    // Detect rearching the header
    if ([scrollView isKindOfClass:[UITableView class]]) {
        UIView * header = ((UITableView *) scrollView).tableHeaderView;
        if (header) {
            if (scrollView.contentOffset.y > header.frame.size.height && !self.didScrollHeaderOffScreen) {
                [self detectedHeaderScrolledOffScreen];
                self.didScrollHeaderOffScreen = YES;
                
            } else if (scrollView.contentOffset.y < header.frame.size.height && self.didScrollHeaderOffScreen) {
                [self detectedHeaderScrolledOnScreen];
                self.didScrollHeaderOffScreen = NO;
            }
            
            if (scrollView.contentOffset.y > header.frame.size.height - scrollView.contentInset.top - 20.0 && !self.didScrollHeaderOffContentArea) {
                [self detectedHeaderScrolledOffContentArea];
                self.didScrollHeaderOffContentArea = YES;
            } else if (scrollView.contentOffset.y < header.frame.size.height - scrollView.contentInset.top - 20.0 && self.didScrollHeaderOffContentArea) {
                [self detectedHeaderScrolledOnContentArea];
                self.didScrollHeaderOffContentArea = NO;
            }
            
            
        }
    }
    
    // Detect reaching the bottom of the table
    CGFloat loadMoreDataOffsetY = scrollView.contentSize.height - CGRectGetHeight(scrollView.frame) - 44.0;
    if (floor(scrollView.contentOffset.y) > loadMoreDataOffsetY) {
        //[self detectedReachingTableBottom];
    };
    
    
    // 'Here', 'Profile' and 'Trending' screens require special treatment because their segmented control is part of the table
    // rather than the navigation bar. Therefore we have to fade in and out the color of segmented control and it's text color
    if (scrollView.tag == kHereTableViewTag || scrollView.tag == kProfileTableViewTag || scrollView.tag == kTrendingTableViewTag) {
        [self updateSegmentedControlWithScrollView:scrollView];
    }
    
    if ([scrollView isKindOfClass:[UITableView class]]) {
        [self updatePrefetchQueueWithTableView:((UITableView *)scrollView)];
    }
}

#pragma mark - Private

- (void)resetToRestingIfNecessary:(UIScrollView *)scrollView animated:(BOOL)animated {
    CGFloat currentOffset = scrollView.contentOffset.y;
    if (self.restingOffset != 0 || self.triggeringOffset != 0) {
        int sign = self.triggeringOffset > self.restingOffset ? 1 : -1;
        if ((currentOffset - self.restingOffset) * sign > 0) {
            [scrollView setContentOffset:CGPointMake(scrollView.contentOffset.x, self.restingOffset) animated:animated];
        }
    }
}

- (void)updateSegmentedControlWithScrollView:(UIScrollView *)scrollView {
    
    CGFloat ratio;
    
    if (self.hasSegmentedControlCustomTransitionRatio) {
        ratio = self.segmentedControlCustomTransitionRatio;
    } else {
        CGFloat offsetMinY = 0.0;
        CGFloat offsetMaxY = 0.0;
        
        if ([UIScreen isLegacyScreen] && scrollView.tag == kHereTableViewTag) {
            offsetMinY = kHere35NavigationBarTransitionOffsetMinY;
            offsetMaxY = kHere35NavigationBarTransitionOffsetMaxY;
        } else if (scrollView.tag == kHereTableViewTag) {
            offsetMinY = kHere4NavigationBarTransitionOffsetMinY;
            offsetMaxY = kHere4NavigationBarTransitionOffsetMaxY;
        } else if (scrollView.tag == kProfileTableViewTag) {
            offsetMinY = kProfileNavigationBarTransitionOffsetMinY;
            offsetMaxY = kProfileNavigationBarTransitionOffsetMaxY;
        } else if (scrollView.tag == kTrendingTableViewTag){
            offsetMinY = kTrendingNavigaionBarTransitionOffsetMinY;
            offsetMaxY = kTrendingNavigaionBarTransitionOffsetMaxY;
        }
        
        CGFloat offsetY = scrollView.contentOffset.y;
        if (offsetY < offsetMinY) {
            ratio = 0.0f;
        } else if (offsetY >= offsetMaxY) {
            ratio = 1.0f;
        } else {
            CGFloat diff = offsetY - offsetMinY;
            ratio = diff / (offsetMaxY - offsetMinY);
        }
    }
    
    [self updateSegmentedControlWithLockedToTopAppearanceProportion:ratio];
}

- (void)updateSegmentedControlWithLockedToTopAppearanceProportion:(CGFloat)proportion {
    if (proportion <= 0) {
        self.segmentedControl.superview.alpha = self.isDraggingSrollView ? 0.9 : 1.0;
        self.segmentedControl.superview.backgroundColor = [UIColor colorWithWhite:246.0/255.0 alpha:1.0];
        
        [self.segmentedControl setTitleColor:[UIColor colorWithWhite:137.0/255.0 alpha:1.0] forState:UIControlStateNormal];
        [self.segmentedControl setTitleColor:[UIColor colorWithWhite:137.0/255.0 alpha:1.0] forState:UIControlStateHighlighted];
        [self.segmentedControl setTitleColor:[UIColor colorWithWhite:137.0/255.0 alpha:1.0] forState:UIControlStateDisabled];
        [self.segmentedControl setTitleColor:[UIColor colorWithWhite:137.0/255.0 alpha:1.0] forState:UIControlStateSelected];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kStatusBarColorNotification object:self userInfo:@{ @"backgroundColor": self.statusBarBackgroundColorMin, @"proportion": @(proportion) }];
    }
    else if (proportion < 1) {
        UIColor *srcColor = [UIColor colorWithWhite:246.0/255.0 alpha:1.0];
        UIColor *desColor = [UIColor colorWithRed:63.0f/255.0f green:85.0f/255.0f blue:120.0f/255.0f alpha:1.0];
        
        self.segmentedControl.superview.alpha = self.isDraggingSrollView ? 0.9 : 1.0;
        self.segmentedControl.superview.backgroundColor = [UIColor colorForFadeBetweenFirstColor:srcColor secondColor:desColor atRatio:proportion];
        
        [self.segmentedControl setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.segmentedControl setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
        [self.segmentedControl setTitleColor:[UIColor whiteColor] forState:UIControlStateDisabled];
        [self.segmentedControl setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kStatusBarColorNotification object:self userInfo:@{ @"backgroundColor": [UIColor colorForFadeBetweenFirstColor:self.statusBarBackgroundColorMin secondColor:self.statusBarBackgroundColorMax atRatio:proportion], @"proportion": @(proportion) }];
    }
    else {
        self.segmentedControl.superview.alpha = self.isDraggingSrollView ? 0.9 : 1.0;
        self.segmentedControl.superview.backgroundColor = [UIColor colorWithRed:63.0f/255.0f green:85.0f/255.0f blue:120.0f/255.0f alpha:1.0];
        
        [self.segmentedControl setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.segmentedControl setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
        [self.segmentedControl setTitleColor:[UIColor whiteColor] forState:UIControlStateDisabled];
        [self.segmentedControl setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kStatusBarColorNotification object:self userInfo:@{ @"backgroundColor": self.statusBarBackgroundColorMax, @"proportion": @(proportion) }];
    }
}

- (void)setupMemoryCellButtons:(MemoryCell *)cell {
    __weak typeof(self) weakSelf = self;
    [cell.commentsButton addTarget:self action:@selector(showMemoryRelatedComments:) forControlEvents:UIControlEventTouchUpInside];
    [cell.starsButton addTarget:self action:@selector(updateUserStar:) forControlEvents:UIControlEventTouchUpInside];
    [cell.usersToStarButton addTarget:self action:@selector(showUsersThatStarred:) forControlEvents:UIControlEventTouchUpInside];
    [cell.authorButton addTarget:self action:@selector(showAuthor:) forControlEvents:UIControlEventTouchUpInside];
    [cell.actionButton addTarget:self action:@selector(showMemoryActions:) forControlEvents:UIControlEventTouchUpInside];
    [cell setTaggedUserTappedBlock:^(NSString * userToken) {
        //stop video playback if needed
        [[NSNotificationCenter defaultCenter] postNotificationName:@"clearVids" object:nil];
        
        if (![userToken isEqualToString:self.userTokenToIgnoreForAuthorTaps]) {
            SPCProfileViewController *profileViewController = [[SPCProfileViewController alloc] initWithUserToken:userToken];
            [self pushedNewViewController];
            [self.navigationController pushViewController:profileViewController animated:YES];
        }
    }];
    [cell setLocationTappedBlock:^(Memory * memory) {
        //stop video playback if needed
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (![weakSelf isKindOfClass:[SPCVenueDetailDataSource class]]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"clearVids" object:nil];
        
            [Flurry logEvent:@"MEMORY_GEOTAG_TAPPED"];
            SPCVenueDetailViewController *venueDetailViewController = [[SPCVenueDetailViewController alloc] init];
            venueDetailViewController.venue = memory.venue;
            [venueDetailViewController fetchMemories];
            
            SPCCustomNavigationController *navController = [[SPCCustomNavigationController alloc] initWithRootViewController:venueDetailViewController];
            [strongSelf.navigationController presentViewController:navController animated:YES completion:nil];
        }
    }];
    
    [cell setHashTagTappedBlock:^(NSString *hashTag, Memory *mem) {
        //stop video playback if needed
        [[NSNotificationCenter defaultCenter] postNotificationName:@"clearVids" object:nil];
        
        SPCHashTagContainerViewController *hashTagContainerViewController = [[SPCHashTagContainerViewController alloc] init];
        [hashTagContainerViewController configureWithHashTag:hashTag memory:mem];
             [self.navigationController pushViewController:hashTagContainerViewController animated:YES];
    }];
}

- (void)dismissAlert:(id)sender {
    [self.alertView dismiss:sender];
    self.alertView = nil;
}

#pragma mark - Private - Scrolling

- (void)detectedTrigger {}

- (void)detectedScrolledSignificantlyAwayFromTrigger {}

- (void)detectedScrolledSignificantlyTowardsTrigger {}

- (void)detectedSignificantOffsetChange {
    if (self.delegate) {
        if ([self.delegate respondsToSelector:@selector(detectedSignificantOffsetChange)]) {
            [self.delegate detectedSignificantOffsetChange];
        }
    }
}

- (void)detectedSignificantOffsetChangeBeyondResting {}

- (void)detectedHeaderScrolledOffScreen {}

- (void)detectedHeaderScrolledOnScreen {}

- (void)detectedHeaderScrolledOffContentArea {
    if (self.delegate) {
        if ([self.delegate respondsToSelector:@selector(detectedHeaderScrolledOffContentArea)]) {
            [self.delegate detectedHeaderScrolledOffContentArea];
        }
    }
}

- (void)detectedHeaderScrolledOnContentArea {
    if (self.delegate) {
        if ([self.delegate respondsToSelector:@selector(detectedHeaderScrolledOnContentArea)]) {
            [self.delegate detectedHeaderScrolledOnContentArea];
        }
    }
}

- (void)detectedReachingTableBottom {}

- (void)pushedNewViewController {}

#pragma mark - Actions

- (void)showMemoryRelatedComments:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"clearVids" object:nil];
    
    NSInteger index = [sender tag];
    
    if (index < self.feed.count) {
        Memory *memory = self.feed[index];
        [self displayComments:memory];
    }
}

- (void)showAuthor:(id)sender {
    NSInteger index = [sender tag];
    Memory *memory;

    memory = self.feed[index];
    NSLog(@"mem auth rec id %li",memory.author.recordID);
    if (memory.realAuthor && memory.realAuthor.userToken) {
        SPCProfileViewController *profileViewController = [[SPCProfileViewController alloc] initWithUserToken:memory.realAuthor.userToken];
        [self.navigationController pushViewController:profileViewController animated:YES];
    } else if (memory.author.recordID == -2) {
        [[[UIAlertView alloc] initWithTitle:nil message:@"Anonymous memories don't have a profile." delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] show];
    }
    else if (memory.author.recordID != self.profileIdToIgnoreForAuthorTaps) {
        //stop video playback if needed
        [[NSNotificationCenter defaultCenter] postNotificationName:@"clearVids" object:nil];
        
        SPCProfileViewController *profileViewController = [[SPCProfileViewController alloc] initWithUserToken:memory.author.userToken];
        [self pushedNewViewController];
        [self.navigationController pushViewController:profileViewController animated:YES];
    }
}



- (void)showUsersThatStarred:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"clearVids" object:nil];
    NSInteger index = [sender tag];
    
    SPCStarsViewController *starsViewController = [[SPCStarsViewController alloc] init];
    starsViewController.memory = self.feed[index];
    [self.navigationController pushViewController:starsViewController animated:YES];
}


- (void)updateUserStar:(id)sender {
    NSInteger index = [sender tag];
    Memory *memory;
    
    UIButton *button = (UIButton *)sender;
    button.userInteractionEnabled = NO;
    memory = self.feed[index];
    
    [self updateUserStarForMemory:memory button:button];
}


- (void)updateUserStarForMemory:(Memory *)memory button:(UIButton *)button {
    if (memory.userHasStarred) {
        [self removeStarForMemory:memory button:button sockpuppet:nil];
    }
    else if (!memory.userHasStarred) {
        [self addStarForMemory:memory button:button sockpuppet:nil];
    }
}

- (void)addStarForMemory:(Memory *)memory button:(UIButton *)button sockpuppet:(Person *)sockpuppet {
    //update locally immediately
    Person * userAsStarred = memory.userToStarMostRecently;
    if (!sockpuppet) {
        memory.userHasStarred = YES;
        Person * thisUser = [[Person alloc] init];
        thisUser.userToken = [AuthenticationManager sharedInstance].currentUser.userToken;
        thisUser.firstname = [ContactAndProfileManager sharedInstance].profile.profileDetail.firstname;
        thisUser.imageAsset = [ContactAndProfileManager sharedInstance].profile.profileDetail.imageAsset;
        thisUser.recordID = [AuthenticationManager sharedInstance].currentUser.userId;
        memory.userToStarMostRecently = thisUser;
    } else {
        memory.userToStarMostRecently = sockpuppet;
    }
    memory.starsCount = memory.starsCount + 1;
    
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SPCMemoryUpdated object:memory];
    [[NSNotificationCenter defaultCenter] postNotificationName:SPCReloadData object:nil];
    button.userInteractionEnabled = NO;
    
    [MeetManager addStarToMemory:memory
                    asSockPuppet:sockpuppet
                  resultCallback:^(NSDictionary *result) {
                      
                      int resultInt = [result[@"number"] intValue];
                      NSLog(@"add star result %i",resultInt);
                      button.userInteractionEnabled = YES;
                      
                      if (resultInt == 1) {
                          
                      }
                      //correct local update if call failed
                      else {
                          memory.userHasStarred = NO;
                          memory.starsCount = memory.starsCount - 1;
                          memory.userToStarMostRecently = userAsStarred;
                          
                          [[NSNotificationCenter defaultCenter] postNotificationName:SPCMemoryUpdated object:memory];
                          [[NSNotificationCenter defaultCenter] postNotificationName:SPCReloadData object:nil];
                          
                          [[[UIAlertView alloc] initWithTitle:nil message:@"Error adding star. Please try again later." delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] show];
                      }
                      
                  }
                   faultCallback:^(NSError *fault) {
                       if (!sockpuppet) {
                           memory.userHasStarred = NO;
                       }
                       memory.starsCount = memory.starsCount - 1;
                       memory.userToStarMostRecently = userAsStarred;
                       button.userInteractionEnabled = YES;
                       
                       //correct local update if call failed
                       [[NSNotificationCenter defaultCenter] postNotificationName:SPCMemoryUpdated object:memory];
                       [[NSNotificationCenter defaultCenter] postNotificationName:SPCReloadData object:nil];
                       
                       [[[UIAlertView alloc] initWithTitle:nil message:@"Error adding star. Please try again later." delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] show];
                   }];
}

- (void)removeStarForMemory:(Memory *)memory button:(UIButton *)button sockpuppet:(Person *)sockpuppet {
    // we might need to refresh the memory cell from the server: if the user
    // was the most recent to star the memory, AND there are multiple stars,
    // we need to pull down data again to see who is the most recent afterwards.
    BOOL refreshMemoryFromServer = NO;
    Person * userAsStarred = memory.userToStarMostRecently;
    
    //update locally immediately
    if (!sockpuppet) {
        memory.userHasStarred = NO;
        if (memory.userToStarMostRecently.recordID == [AuthenticationManager sharedInstance].currentUser.userId) {
            userAsStarred = memory.userToStarMostRecently;
            if (memory.starsCount == 0) {
                memory.userToStarMostRecently = nil;
            } else {
                refreshMemoryFromServer = YES;
            }
        }
    } else {
        if (memory.userToStarMostRecently.recordID == sockpuppet.recordID) {
            userAsStarred = memory.userToStarMostRecently;
            if (memory.starsCount == 0) {
                memory.userToStarMostRecently = nil;
            } else {
                refreshMemoryFromServer = YES;
            }
        }
    }
    memory.starsCount = memory.starsCount - 1;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SPCMemoryUpdated object:memory];
    [[NSNotificationCenter defaultCenter] postNotificationName:SPCReloadData object:nil];
    button.userInteractionEnabled = NO;
    
    [MeetManager deleteStarFromMemory:memory
                         asSockPuppet:sockpuppet
                       resultCallback:^(NSDictionary *result){
                           int resultInt = [result[@"number"] intValue];
                           NSLog(@"delete star result %i",resultInt);
                           button.userInteractionEnabled = YES;
                           
                           if (resultInt == 1) {
                               if (refreshMemoryFromServer) {
                                   [MeetManager fetchMemoryWithMemoryId:memory.recordID resultCallback:^(NSDictionary *results) {
                                       [memory setWithAttributes:results];
                                       [[NSNotificationCenter defaultCenter] postNotificationName:SPCMemoryUpdated object:memory];
                                       [[NSNotificationCenter defaultCenter] postNotificationName:SPCReloadData object:nil];
                                   } faultCallback:^(NSError *fault) {
                                       if (!sockpuppet) {
                                           memory.userHasStarred = YES;
                                       }
                                       memory.starsCount = memory.starsCount + 1;
                                       memory.userToStarMostRecently = userAsStarred;
                                       [[NSNotificationCenter defaultCenter] postNotificationName:SPCMemoryUpdated object:memory];
                                       [[NSNotificationCenter defaultCenter] postNotificationName:SPCReloadData object:nil];
                                       
                                       [[[UIAlertView alloc] initWithTitle:nil message:@"Error removing star. Please try again later." delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] show];
                                   }];
                               }
                           }
                           //correct local update if call failed
                           else {
                               if (!sockpuppet) {
                                   memory.userHasStarred = YES;
                               }
                               memory.starsCount = memory.starsCount + 1;
                               memory.userToStarMostRecently = userAsStarred;
                               
                               [[NSNotificationCenter defaultCenter] postNotificationName:SPCMemoryUpdated object:memory];
                               [[NSNotificationCenter defaultCenter] postNotificationName:SPCReloadData object:nil];
                               
                               [[[UIAlertView alloc] initWithTitle:nil message:@"Error removing star. Please try again later." delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] show];
                           }
                           
                       }
                        faultCallback:^(NSError *error){
                            
                            //correct local update if call failed
                            if (!sockpuppet) {
                                memory.userHasStarred = YES;
                            }
                            memory.starsCount = memory.starsCount + 1;
                            memory.userToStarMostRecently = userAsStarred;
                            [[NSNotificationCenter defaultCenter] postNotificationName:SPCMemoryUpdated object:memory];
                            [[NSNotificationCenter defaultCenter] postNotificationName:SPCReloadData object:nil];
                            
                            button.userInteractionEnabled = YES;
                            [[[UIAlertView alloc] initWithTitle:nil message:@"Error removing star. Please try again later." delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] show];
                        }];
}


- (void)promptEnableLocationServices:(id)sender {
    if ([CLLocationManager locationServicesEnabled] &&
        [CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kLocationServicesAuthorizationStatusWillChangeNotification object:nil];
        [[LocationManager sharedInstance] enableLocationServicesWithCompletionHandler:^(NSError *error) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kLocationServicesAuthorizationStatusDidChangeNotification object:nil];
        }];
    }
    else {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"\"Spayce\" Would Like to Use Your Current Location", nil)
                                    message:NSLocalizedString(@"Please go to Settings > Privacy and enable Location Services for the \"Spayce\" app", nil)
                                   delegate:nil
                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                          otherButtonTitles:nil] show];
    }
}

- (void)showMemoryActions:(id)sender {
    //stop video playback if needed
    [[NSNotificationCenter defaultCenter] postNotificationName:@"clearVids" object:nil];
    
    // Selected memory index
    NSInteger idx = [sender tag];
    [Flurry logEvent:@"MEMORY_ACTION_BUTTON_TAPPED"];
    
    // Selected memory
    Memory *memory = self.feed[idx];
    
    BOOL isUsersMemory = memory.author.recordID == [AuthenticationManager sharedInstance].currentUser.userId;
    BOOL userIsWatching = memory.userIsWatching;
    //BOOL isSpayceUser = memory.author.recordID == -1;
    
    // Alert view controller
    SPCAlertViewController *alertViewController = [[SPCAlertViewController alloc] init];
    alertViewController.modalPresentationStyle = UIModalPresentationCustom;
    alertViewController.transitioningDelegate = self;
    
    if ([AuthenticationManager sharedInstance].currentUser.isAdmin) {
        [alertViewController addAction:[SPCAlertAction actionWithTitle:@"Promote Memory" subtitle:@"Add memory to Local and World grids" style:SPCAlertActionStyleNormal handler:^(SPCAlertAction *action) {
            SPCAlertViewController *subAlertViewController = [[SPCAlertViewController alloc] init];
            subAlertViewController.modalPresentationStyle = UIModalPresentationCustom;
            subAlertViewController.transitioningDelegate = self;
            subAlertViewController.alertTitle = NSLocalizedString(@"Promote Memory?", nil);
            
            [subAlertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Promote", nil) style:SPCAlertActionStyleDestructive handler:^(SPCAlertAction *action) {
                [[AdminManager sharedInstance] promoteMemory:memory completionHandler:^{
                    [[[UIAlertView alloc] initWithTitle:@"Promoted Memory" message:@"This memory has been promoted.  It should now have prominent Local and World grid placement." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
                } errorHandler:^(NSError *error) {
                    [UIAlertView showError:error];
                }];
            }]];
            
            [subAlertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:SPCAlertActionStyleCancel handler:nil]];
            
            [self.navigationController presentViewController:subAlertViewController animated:YES completion:nil];
        }]];
        
        [alertViewController addAction:[SPCAlertAction actionWithTitle:@"Demote Memory" subtitle:@"Remove from Local and World grids" style:SPCAlertActionStyleNormal handler:^(SPCAlertAction *action) {
            SPCAlertViewController *subAlertViewController = [[SPCAlertViewController alloc] init];
            subAlertViewController.modalPresentationStyle = UIModalPresentationCustom;
            subAlertViewController.transitioningDelegate = self;
            subAlertViewController.alertTitle = NSLocalizedString(@"Demote Memory?", nil);
            
            [subAlertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Demote", nil) style:SPCAlertActionStyleDestructive handler:^(SPCAlertAction *action) {
                [[AdminManager sharedInstance] demoteMemory:memory completionHandler:^{
                    [[[UIAlertView alloc] initWithTitle:@"Demoted Memory" message:@"This memory has been demoted.  It should not appear on Local or World grids." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
                } errorHandler:^(NSError *error) {
                    [UIAlertView showError:error];
                }];
            }]];
            
            [subAlertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:SPCAlertActionStyleCancel handler:nil]];
            
            [self.navigationController presentViewController:subAlertViewController animated:YES completion:nil];
        }]];
        
        [alertViewController addAction:[SPCAlertAction actionWithTitle:@"Star as Puppet" style:SPCAlertActionStyleNormal handler:^(SPCAlertAction *action) {
            SPCAdminSockPuppetChooserViewController *vc = [[SPCAdminSockPuppetChooserViewController alloc] initWithSockPuppetAction:SPCAdminSockPuppetActionStar object:memory];
            vc.delegate = self;
            [self.navigationController pushViewController:vc animated:YES];
        }]];
        
        [alertViewController addAction:[SPCAlertAction actionWithTitle:@"Unstar as Puppet" style:SPCAlertActionStyleNormal handler:^(SPCAlertAction *action) {
            SPCAdminSockPuppetChooserViewController *vc = [[SPCAdminSockPuppetChooserViewController alloc] initWithSockPuppetAction:SPCAdminSockPuppetActionUnstar object:memory];
            vc.delegate = self;
            [self.navigationController pushViewController:vc animated:YES];
        }]];
    }
    
    // Alert view controller - alerts
    if (isUsersMemory) {
    
        alertViewController.alertTitle = NSLocalizedString(@"Edit or Share", nil);
        
        if (nil != memory.location && nil != memory.venue && memory.venue.addressId && SPCVenueIsReal == memory.venue.specificity && (0 != [memory.location.latitude floatValue] || 0 != [memory.location.longitude floatValue])) {
        [alertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Change Location", nil)
                                                                 style:SPCAlertActionStyleNormal
                                                               handler:^(SPCAlertAction *action) {
                                                                   [Flurry logEvent:@"MEM_UPDATED_LOCATION"];
                                                                   SPCMapViewController *mapVC = [[SPCMapViewController alloc] initForExistingMemory:memory];
                                                                   mapVC.delegate = self;
                                                                   [self.navigationController pushViewController:mapVC animated:YES];
                                                               }]];
        }
        if (memory.type != MemoryTypeFriends) {
            [alertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Tag Friends", nil)
                                                                 style:SPCAlertActionStyleNormal
                                                               handler:^(SPCAlertAction *action) {
                                                                   SPCTagFriendsViewController *tagUsersViewController = [[SPCTagFriendsViewController alloc] initWithMemory:memory];
                                                                   tagUsersViewController.delegate = self;
                                                                   [self.navigationController presentViewController:tagUsersViewController animated:YES completion:nil];
                                                               }]];
        }
            /* TODO: implement FB memory sharing on the client using a Facebook dialog.
             * This approach does not require FB review, although sharing through the server does.
            [alertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Share to Facebook", nil)
                                                                     style:SPCAlertActionStyleNormal
                                                                   handler:^(SPCAlertAction *action) {
                                                                       [self shareMemory:memory serviceName:@"FACEBOOK" serviceType:SocialServiceTypeFacebook];
                                                                   }]];
             */
        [alertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Share to Twitter", nil)
                                                                 style:SPCAlertActionStyleNormal
                                                               handler:^(SPCAlertAction *action) {
                                                                    [Flurry logEvent:@"MEM_SHARED_TO_TWITTER"];
                                                                   [self shareMemory:memory serviceName:@"TWITTER" serviceType:SocialServiceTypeTwitter];
                                                               }]];
        
        
        [alertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Delete Memory", nil)
                                                                 style:SPCAlertActionStyleDestructive
                                                               handler:^(SPCAlertAction *action) {
                                                                   [self showDeletePromptForMemory:memory];
                                                               }]];
    }
    else {
     
        alertViewController.alertTitle = NSLocalizedString(@"Watch or Report", nil);
        
        if (!userIsWatching) {
            
            [alertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Watch Memory", nil)
                                                                  subtitle:NSLocalizedString(@"Get notifications of activity on this memory", nil)
                                                                     style:SPCAlertActionStyleNormal
                                                                   handler:^(SPCAlertAction *action) {
                                                                       [self watchMemory:memory];
                                                                   }]];
        }
        else {
            [alertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Stop Watching Memory", nil)
                                                                  subtitle:NSLocalizedString(@"Stop receiving notifications about this memory", nil)
                                                                     style:SPCAlertActionStyleNormal
                                                                   handler:^(SPCAlertAction *action) {
                                                                       [self stopWatchingMemory:memory];
                                                                   }]];
        }
        
        
        NSString *reportString = [AuthenticationManager sharedInstance].currentUser.isAdmin ? @"Delete Memory" : @"Report Memory";
        [alertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(reportString, nil)
                                                                 style:SPCAlertActionStyleDestructive
                                                               handler:^(SPCAlertAction *action) {
                                                                   [self showReportPromptForMemory:memory];
                                                               }]];
        

        /*
        if (!isSpayceUser) {
            [alertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Block user", nil)
                                                                     style:SPCAlertActionStyleDestructive
                                                                   handler:^(SPCAlertAction *action) {
                                                                       [self showBlockPromptForMemory:memory];
                                                                   }]];
        }
         */
    }
    
    [alertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                             style:SPCAlertActionStyleCancel
                                                           handler:nil]];
    
    // Alert view controller - show
    [self.navigationController presentViewController:alertViewController animated:YES completion:nil];
}

- (void)displayComments:(Memory *)memory {
    //stop video playback if needed
    [[NSNotificationCenter defaultCenter] postNotificationName:@"clearVids" object:nil];
    
    self.userIsViewingComments = YES;

    MemoryCommentsViewController *memoryCommentsViewController = [[MemoryCommentsViewController alloc] initWithMemory:memory];
    if ([self isKindOfClass:[SPCVenueDetailDataSource class]]) {
        memoryCommentsViewController.viewingFromVenueDetail = YES;
    }
    memoryCommentsViewController.view.clipsToBounds = NO;
    [self pushedNewViewController];
    [self.navigationController pushViewController:memoryCommentsViewController animated:YES];
}

- (void)showBlockPromptForMemory:(Memory *)memory {
    NSString *msgText = [NSString stringWithFormat:@"You are about to block %@. This means that you will both be permanently invisible to each other.", memory.author.displayName];

    UIView *alertView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 270, 235)];
    alertView.backgroundColor = [UIColor whiteColor];

    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"oh-no"]];
    imageView.frame = CGRectMake(0, 20, 270, 42);
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.center=CGPointMake(alertView.bounds.size.width/2, imageView.center.y);
    [alertView addSubview:imageView];

    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 70, 270, 30)];
    titleLabel.font = [UIFont boldSystemFontOfSize:20];
    titleLabel.textColor = [UIColor colorWithRGBHex:0x485868];
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.text = [NSString stringWithFormat:@"Block %@?", memory.author.displayName];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [alertView addSubview:titleLabel];

    UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 80, 205, 100)];
    messageLabel.font = [UIFont systemFontOfSize:14];
    messageLabel.textColor = [UIColor colorWithRed:103.0f/255.0f green:120.0f/255.0f blue:140.0f/255.0f alpha:1.0f];
    messageLabel.backgroundColor = [UIColor clearColor];
    messageLabel.center = CGPointMake(alertView.center.x, messageLabel.center.y);
    messageLabel.text = msgText;
    messageLabel.numberOfLines = 0;
    messageLabel.lineBreakMode = NSLineBreakByWordWrapping;
    messageLabel.textAlignment = NSTextAlignmentCenter;
    [alertView addSubview:messageLabel];

    UIColor *cancelBgColor = [UIColor colorWithRed:103.0f/255.0f green:120.0f/255.0f blue:140.0f/255.0f alpha:1.0f];
    UIColor *cancelTextColor = [UIColor colorWithRed:145.0f/255.0f green:167.0f/255.0f blue:193.0f/255.0f alpha:1.0f];
    CGRect cancelBtnFrame = CGRectMake(25,180,100,40);

    UIColor *otherBgColor = [UIColor colorWithRed:22.0f/255.0f green:26.0f/255.0f blue:30.0f/255.0f alpha:1.0f];
    UIColor *otherTextColor = [UIColor colorWithRed:103.0f/255.0f green:120.0f/255.0f blue:140.0f/255.0f alpha:1.0f];
    CGRect otherBtnFrame = CGRectMake(145,180,100,40);

    NSString *targetUserName = memory.author.displayName;

    [PXAlertView showAlertWithView:alertView cancelTitle:@"Cancel" cancelBgColor:cancelBgColor cancelTextColor:cancelTextColor cancelFrame:cancelBtnFrame otherTitle:@"Block" otherBgColor:otherBgColor otherTextColor:otherTextColor otherFrame:otherBtnFrame completion:^(BOOL cancelled) {

        if (!cancelled) {
            [MeetManager blockUserWithId:memory.author.recordID
                          resultCallback:^(NSDictionary *result)  {

                              UIView *contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 280, 165)];
                              contentView.backgroundColor = [UIColor whiteColor];

                              UILabel *contentTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, 270, 30)];
                              contentTitleLabel.font = [UIFont boldSystemFontOfSize:20];
                              contentTitleLabel.textColor = [UIColor colorWithRGBHex:0x485868];
                              contentTitleLabel.backgroundColor = [UIColor clearColor];
                              contentTitleLabel.text = NSLocalizedString(@"Blocked!",nil);
                              contentTitleLabel.textAlignment = NSTextAlignmentCenter;
                              [contentView addSubview:contentTitleLabel];

                              UILabel *contentMessageLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 40, 250, 60)];
                              contentMessageLabel.font = [UIFont systemFontOfSize:16];
                              contentMessageLabel.textColor = [UIColor colorWithRGBHex:0x485868];
                              contentMessageLabel.backgroundColor = [UIColor clearColor];
                              contentMessageLabel.center=CGPointMake(contentView.center.x, contentMessageLabel.center.y);
                              contentMessageLabel.text = [NSString stringWithFormat:@"You have blocked %@.",targetUserName];
                              contentMessageLabel.numberOfLines=0;
                              contentMessageLabel.lineBreakMode=NSLineBreakByWordWrapping;
                              contentMessageLabel.textAlignment = NSTextAlignmentCenter;
                              [contentView addSubview:contentMessageLabel];

                              UIColor *contentCancelBgColor = [UIColor colorWithRed:22.0f/255.0f green:26.0f/255.0f blue:30.0f/255.0f alpha:1.0f];
                              UIColor *contentCancelTextColor = [UIColor colorWithRed:103.0f/255.0f green:120.0f/255.0f blue:140.0f/255.0f alpha:1.0f];
                              CGRect contentCancelBtnFrame = CGRectMake(70,100,130,40);

                              [PXAlertView showAlertWithView:contentView cancelTitle:@"OK" cancelBgColor:contentCancelBgColor
                                             cancelTextColor:contentCancelTextColor
                                                 cancelFrame:contentCancelBtnFrame
                                                  completion:^(BOOL cancelled) {
                                                      [[NSNotificationCenter defaultCenter] postNotificationName:SPCReloadData object:nil];
                                                      
                                                      [ProfileManager fetchProfileWithUserToken:[AuthenticationManager sharedInstance].currentUser.userToken
                                                                                 resultCallback:nil
                                                                                  faultCallback:nil];
                                                  }];
                          }
                           faultCallback:^(NSError *error){

                               NSLog(@"block failed, please try again");

                           }
             ];
        }
    }];
}

- (void)showDeletePromptForMemory:(Memory *)memory {
    self.tempMemory = memory;
    
    [self stopAssets];

    UIView *demoView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 270, 280)];
    demoView.backgroundColor = [UIColor whiteColor];

    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"oh-no"]];
    imageView.frame = CGRectMake(0, 10, 270, 40);
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    [demoView addSubview:imageView];

    NSString *title = @"Delete this memory?";

    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 60, 270, 20)];
    titleLabel.font = [UIFont boldSystemFontOfSize:16];
    titleLabel.textColor = [UIColor colorWithRGBHex:0x485868];
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.text = title;
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [demoView addSubview:titleLabel];

    UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 90, 230, 40)];
    messageLabel.font = [UIFont systemFontOfSize:14];
    messageLabel.textColor = [UIColor colorWithRGBHex:0x485868];
    messageLabel.backgroundColor = [UIColor clearColor];
    messageLabel.numberOfLines = 2;
    messageLabel.text = @"Once you delete this memory it will be gone forever!";
    messageLabel.textAlignment = NSTextAlignmentCenter;
    [demoView addSubview:messageLabel];

    UIButton *okBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    okBtn.frame = CGRectMake(70, 145, 130, 40);

    [okBtn setTitle:NSLocalizedString(@"Delete", nil) forState:UIControlStateNormal];
    okBtn.backgroundColor = [UIColor colorWithRGBHex:0x4ACBEB];
    okBtn.layer.cornerRadius = 4.0;
    okBtn.titleLabel.font = [UIFont systemFontOfSize:16];

    UIImage *selectedImage = [ImageUtils roundedRectImageWithColor:[UIColor colorWithRGBHex:0x4795AC] size:okBtn.frame.size corners:4.0f];
    [okBtn setBackgroundImage:selectedImage forState:UIControlStateHighlighted];
    [okBtn setBackgroundImage:selectedImage forState:UIControlStateSelected];

    [okBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [okBtn addTarget:self action:@selector(deleteConfirmed:) forControlEvents:UIControlEventTouchUpInside];
    [demoView addSubview:okBtn];


    CGRect cancelFrame = CGRectMake(70, 205, 130, 40);

    self.alertView = [PXAlertView showAlertWithView:demoView cancelTitle:@"Cancel" cancelBgColor:[UIColor darkGrayColor] cancelTextColor:[UIColor whiteColor] cancelFrame:cancelFrame completion:^(BOOL cancelled) {
        self.alertView = nil;
    }];
}

- (void)deleteConfirmed:(id)sender {
    // Dismiss alert
    [self dismissAlert:sender];
    [Flurry logEvent:@"MEM_DELETED"];
    // Delete memory
    [self.memoryCoordinator deleteMemory:self.tempMemory completionHandler:^(BOOL success) {
        if (success) {
            if ([self.feed containsObject:self.tempMemory]) {
                // Remove locally
                NSMutableArray *mutableMemories = [NSMutableArray arrayWithArray:self.feed];
                [mutableMemories removeObject:self.tempMemory];
                self.feed = [NSArray arrayWithArray:mutableMemories];
            }
            
            if ([self.fullFeed containsObject:self.tempMemory]) {
                // Remove locally
                NSMutableArray *mutableMemories = [NSMutableArray arrayWithArray:self.fullFeed];
                [mutableMemories removeObject:self.tempMemory];
                self.fullFeed = [NSArray arrayWithArray:mutableMemories];
            }
            
            [[NSNotificationCenter defaultCenter] postNotificationName:SPCMemoryDeleted object:self.tempMemory];
            [[NSNotificationCenter defaultCenter] postNotificationName:SPCReloadData object:nil];
        } else {
            [[[UIAlertView alloc] initWithTitle:nil
                                        message:NSLocalizedString(@"Error deleting memory. Please try again later.", nil)
                                       delegate:nil
                              cancelButtonTitle:NSLocalizedString(@"Dismiss", nil)
                              otherButtonTitles:nil] show];
        }
        self.tempMemory = nil;
    }];
}

- (void)showReportPromptForMemory:(Memory *)memory {
    self.tempMemory = memory;
    
    [self stopAssets];
    
    self.reportAlertView = [[SPCReportAlertView alloc] initWithTitle:@"Choose type of report" stringOptions:self.reportMemoryOptions dismissTitles:@[@"CANCEL"] andDelegate:self];
    
    [self.reportAlertView showAnimated:YES];
}

- (void)watchMemory:(Memory *)memory {
    
    memory.userIsWatching = YES;
    
    [MeetManager watchMemoryWithMemoryKey:memory.key
                           resultCallback:^(NSDictionary *result) {
                               NSLog(@"watching mem!");
                           }
                            faultCallback:nil];
    
}

- (void)stopWatchingMemory:(Memory *)memory {
    
    memory.userIsWatching = NO;
    
    [MeetManager unwatchMemoryWithMemoryKey:memory.key
                           resultCallback:^(NSDictionary *result) {
                               NSLog(@"unwatching mem!");
                           }
                            faultCallback:nil];
    
}

- (void)stopAssets {
    //[[NSNotificationCenter defaultCenter] postNotificationName:SPCClearVideosNotification object:nil];
}

- (void)updateWithPersonUpdate:(PersonUpdate *)personUpdate {
    if ([personUpdate applyToArray:self.fullFeed]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:SPCReloadData object:nil];
    }
}

#pragma mark - Memories - Sharing

- (void)shareMemory:(Memory *)memory serviceName:(NSString *)serviceName serviceType:(SocialServiceType)serviceType {
    BOOL isServiceAvailable = [[SocialService sharedInstance] availabilityForServiceType:serviceType];
    if (isServiceAvailable) {
        [self.memoryCoordinator shareMemory:memory serviceName:serviceName completionHandler:^{
            [[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Shared to %@", nil), [serviceName capitalizedString]]
                                        message:NSLocalizedString(@"Your memory has been successfully shared.", nil)
                                       delegate:nil
                              cancelButtonTitle:NSLocalizedString(@"OK", nil)
                              otherButtonTitles:nil] show];
        }];
    }
    else {
        self.tempMemory = memory;
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Request %@ Access", nil), [serviceName capitalizedString]]
                                                            message:[NSString stringWithFormat:NSLocalizedString(@"You have to authorize with %@ in order to invite your friends", nil), [serviceName capitalizedString]]
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                  otherButtonTitles:NSLocalizedString(@"Authorize", nil), nil];
        alertView.tag = serviceType;
        [alertView show];
    }
}

#pragma mark - Image caching

-(void)updatePrefetchQueueWithTableView:(UITableView *)tableView {
    NSArray *visibleCells = [tableView visibleCells];
    if (visibleCells != nil && [visibleCells count] != 0) {       // Don't do anything for empty table view
        
        /* Get bottom cell */
        UITableViewCell *bottomCell = [visibleCells lastObject];
        
        // Piggyback on bottomCell call and use for prefetching !
        int prefetchIndex = 1 + (int)bottomCell.tag;
        if (self.currentPrefetchIndex != prefetchIndex) {
            if (prefetchIndex < self.feed.count) {
                Memory *tempMem = self.feed[prefetchIndex];
                if (![self.prefetchedList containsObject:@(tempMem.recordID)]) {
                    self.currentPrefetchIndex = prefetchIndex;
                    [self updatePrefetchQueueWithMemAtIndex];
                }
            }
        }
    }
}

-(void)updatePrefetchQueueWithMemAtIndex {
    if (self.prefetchPaused) {
        return;
    }
    
    if (self.currentPrefetchIndex < self.feed.count) {
        Memory *tempMem = self.feed[self.currentPrefetchIndex];
        if (![self.prefetchedList containsObject:@(tempMem.recordID)]) {
            [self.prefetchedList addObject:@(tempMem.recordID)];
            
            NSMutableArray *tempArray = [NSMutableArray arrayWithArray:self.assetQueue];
            
            //get (up to 2) assets for each memory
            if (tempMem.type == MemoryTypeImage) {
                ImageMemory *tempImgMem = (ImageMemory *)tempMem;
                
                int maxStart = (int)tempImgMem.images.count - 1;
                if (maxStart > 1) {
                    maxStart = 1;
                }
                
                //insert assets into queue so the visible image loads first for multi-asset mems
                for (int i = maxStart; i >= 0; i--) {
                    [tempArray insertObject:tempImgMem.images[i] atIndex:0];
                }
                self.assetQueue = [NSArray arrayWithArray:tempArray];
                [self prefetchNextImageInQueue];
            }
            else if (tempMem.type == MemoryTypeVideo) {
                
                VideoMemory *tempImgMem = (VideoMemory *)tempMem;
                
                int maxStart = (int)tempImgMem.previewImages.count - 1;
                if (maxStart > 1) {
                    maxStart = 1;
                }
                
                for (int i = maxStart; i >= 0; i--) {
                    [tempArray insertObject:tempImgMem.previewImages[i] atIndex:0];
                }
                self.assetQueue = [NSArray arrayWithArray:tempArray];
                [self prefetchNextImageInQueue];
            }
            else {
                //go further ahead in the list if it's not a mem that needs prefetching
                self.currentPrefetchIndex = self.currentPrefetchIndex + 1;
                [self updatePrefetchQueueWithMemAtIndex];
            }
        }
        //go further ahead in the list if it's a mem that's already been prefetched
        else {
            if (self.currentPrefetchIndex < self.feed.count) {
                self.currentPrefetchIndex = self.currentPrefetchIndex + 1;
                [self updatePrefetchQueueWithMemAtIndex];
            }
        }
    }
}

-(void)prefetchNextImageInQueue {
    if (self.prefetchPaused) {
        return;
    }
    
    if (self.assetQueue.count > 0) {
        
        NSString *imageUrlStr;
        NSString *imageName;
        
        id imageAsset = self.assetQueue[0];
        if ([imageAsset isKindOfClass:[Asset class]]) {
            Asset * asset = (Asset *)imageAsset;
            imageUrlStr = [asset imageUrlSquare];
        } else {
            imageName = [NSString stringWithFormat:@"%@", self.assetQueue[0]];
            int photoID = [imageName intValue];
            imageUrlStr = [APIUtils imageUrlStringForAssetId:photoID size:ImageCacheSizeSquare];
        }
        
        BOOL imageIsCached = NO;
        
        if ([[SDWebImageManager sharedManager] cachedImageExistsForURL:[NSURL URLWithString:imageUrlStr]]) {
            imageIsCached = YES;
        }
        if ([[SDWebImageManager sharedManager] diskImageExistsForURL:[NSURL URLWithString:imageUrlStr]]) {
            imageIsCached = YES;
        }
        
        if (!imageIsCached) {
            //NSLog(@"prefetching image %@", imageUrlStr);
            [self.prefetchImageView sd_cancelCurrentImageLoad];
            [self.prefetchImageView sd_setImageWithURL:[NSURL URLWithString:imageUrlStr]
                                      placeholderImage:[UIImage imageNamed:@"placeholder-gray"]
                                             completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                                 NSMutableArray *tempArray = [NSMutableArray arrayWithArray:self.assetQueue];
                                                 [tempArray removeObject:imageAsset];
                                                 self.assetQueue = [NSArray arrayWithArray:tempArray];
                                                 //NSLog(@"prefetched image, proceed");
                                                 [self prefetchNextImageInQueue];
                                             }];
        }
        else {
            NSMutableArray *tempArray = [NSMutableArray arrayWithArray:self.assetQueue];
            [tempArray removeObject:imageAsset];
            self.assetQueue = [NSArray arrayWithArray:tempArray];
            [self prefetchNextImageInQueue];
        }
    }
    else {
        if (self.currentPrefetchIndex < self.feed.count) {
            self.currentPrefetchIndex = self.currentPrefetchIndex + 1;
            [self updatePrefetchQueueWithMemAtIndex];
        }
    }
}

#pragma mark - UIBarPositioningDelegate

- (UIBarPosition)positionForBar:(id <UIBarPositioning>)view {
    return UIBarPositionBottom;
}


#pragma mark SPCMapViewController

- (void)cancelMap {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)didAdjustLocationForMemory:(Memory *)memory {
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark SPCAdjustMemoryLocationViewControllerDelegate

-(void)didAdjustLocationForMemory:(Memory *)memory withViewController:(UIViewController *)viewController {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

-(void)dismissAdjustMemoryLocationViewController:(UIViewController *)viewController {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark SPCTagFriendsViewControllerDelegate

- (void)tagFriendsViewController:(SPCTagFriendsViewController *)viewController finishedPickingFriends:(NSArray *)selectedFriends {
    [self.memoryCoordinator updateMemory:viewController.memory taggedUsers:viewController.memory.taggedUsersIDs completionHandler:^{
        [[NSNotificationCenter defaultCenter] postNotificationName:SPCMemoryUpdated object:viewController.memory];
    }];
    [[NSNotificationCenter defaultCenter] postNotificationName:SPCReloadData object:nil];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)tagFriendsViewControllerDidCancel:(SPCTagFriendsViewController *)viewController {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - SPCReportAlertViewDelegate

- (void)tappedOption:(NSString *)option onSPCReportAlertView:(SPCReportAlertView *)reportView {
    if ([reportView isEqual:self.reportAlertView]) {
        self.reportType = [self.reportMemoryOptions indexOfObject:option] + 1;
        
        [reportView hideAnimated:YES];
        
        // Now, we need to show an alert view asking the user if they want to "Add Detail" or "Send"
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Send Report Immediately?" message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:@"Add Detail", @"Send", nil];
        alertView.tag = alertViewTagReport;
        [alertView show];
        
        self.reportAlertView = nil;
    }
}

- (void)tappedDismissTitle:(NSString *)dismissTitle onSPCReportAlertView:(SPCReportAlertView *)reportView {
    // We only have one dismiss option, so go ahead and remove the view
    [self.reportAlertView hideAnimated:YES];
    
    self.reportAlertView = nil;
}

#pragma mark - SPCReportViewControllerDelegate

- (void)invalidReportObjectOnSPCReportViewController:(SPCReportViewController *)reportViewController {
    [reportViewController.navigationController popViewControllerAnimated:YES];
    
    [self showMemoryReportWithSuccess:NO];
}

- (void)canceledReportOnSPCReportViewController:(SPCReportViewController *)reportViewController {
    [reportViewController.navigationController popViewControllerAnimated:YES];
}

- (void)sendFailedOnSPCReportViewController:(SPCReportViewController *)reportViewController {
    [reportViewController.navigationController popViewControllerAnimated:YES];
    
    [self showMemoryReportWithSuccess:NO];
}

- (void)sentReportOnSPCReportViewController:(SPCReportViewController *)reportViewController {
    [reportViewController.navigationController popViewControllerAnimated:YES];
    
    [self showMemoryReportWithSuccess:YES];
}

#pragma mark - Report/Flagging Results

- (void)showMemoryReportWithSuccess:(BOOL)succeeded {
    if (succeeded) {
        [[[UIAlertView alloc] initWithTitle:nil
                                    message:NSLocalizedString(@"This memory has been reported. Thank you.", nil)
                                   delegate:nil
                          cancelButtonTitle:NSLocalizedString(@"Dismiss", nil)
                          otherButtonTitles:nil] show];
    } else {
        [[[UIAlertView alloc] initWithTitle:nil
                                    message:NSLocalizedString(@"Error reporting issue. Please try again later.", nil)
                                   delegate:nil
                          cancelButtonTitle:NSLocalizedString(@"Dismiss", nil)
                          otherButtonTitles:nil] show];
    }
}

#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex != alertView.cancelButtonIndex) {
        if (alertView.tag == alertViewTagTwitter) {
            AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
            
            [[SocialService sharedInstance] authSocialServiceType:SocialServiceTypeTwitter viewController:appDelegate.mainViewController.customTabBarController completionHandler:^{
                [self shareMemory:self.tempMemory serviceName:@"TWITTER" serviceType:SocialServiceTypeTwitter];
                self.tempMemory = nil;
            } errorHandler:^(NSError *error) {
                [UIAlertView showError:error];
            }];
        }
        else if (alertView.tag == alertViewTagFacebook) {
            [[SocialService sharedInstance] authSocialServiceType:SocialServiceTypeFacebook viewController:nil completionHandler:^{
                [self shareMemory:self.tempMemory serviceName:@"FACEBOOK" serviceType:SocialServiceTypeFacebook];
                self.tempMemory = nil;
            } errorHandler:^(NSError *error) {
                [UIAlertView showError:error];
            }];
        } else if (alertView.tag == alertViewTagReport) {
            // These buttons were configured so that buttonIndex 1 = 'Send', buttonIndex 0 = 'Add Detail'
            if (1 == buttonIndex) {
                [Flurry logEvent:@"MEM_REPORTED"];
                [self.memoryCoordinator reportMemory:self.tempMemory withType:self.reportType text:nil completionHandler:^(BOOL success) {
                    if (success) {
                        [self showMemoryReportWithSuccess:YES];
                    } else {
                        [self showMemoryReportWithSuccess:NO];
                    }
                    self.tempMemory = nil;
                }];
            } else if (0 == buttonIndex) {
                //stop video playback if needed
                [[NSNotificationCenter defaultCenter] postNotificationName:@"clearVids" object:nil];
                
                SPCReportViewController *rvc = [[SPCReportViewController alloc] initWithReportObject:self.tempMemory reportType:self.reportType andDelegate:self];
                [self.navigationController pushViewController:rvc animated:YES];
            }
        }
    }
}


#pragma mark SPCAdminSockPuppetChooserViewControllerDelegate


- (void)adminSockPuppetChooserViewController:(UIViewController *)vc didChoosePuppet:(Person *)puppet forAction:(SPCAdminSockPuppetAction)action object:(NSObject *)object {
    
    [self.navigationController popViewControllerAnimated:YES];
    
    switch(action) {
        case SPCAdminSockPuppetActionStar:
            NSLog(@"Star action as %@", puppet.firstname);
            [self addStarForMemory:(Memory *)object button:nil sockpuppet:puppet];
            break;
            
        case SPCAdminSockPuppetActionUnstar:
            NSLog(@"Unstar action as %@", puppet.firstname);
            [self removeStarForMemory:(Memory *)object button:nil sockpuppet:puppet];
            break;
            
        default:
            NSLog(@"WOULD HAVE perfomed action %d with sock puppet %@", action, puppet.firstname);
            break;
    }
}

- (void)adminSockPuppetChooserViewControllerDidCancel:(UIViewController *)vc {
    [self.navigationController popViewControllerAnimated:YES];
}



#pragma mark UIViewControllerTransitioningDelegate

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
    SPCAlertTransitionAnimator *animator = [SPCAlertTransitionAnimator new];
    animator.presenting = YES;
    return animator;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    SPCAlertTransitionAnimator *animator = [SPCAlertTransitionAnimator new];
    return animator;
}

@end
