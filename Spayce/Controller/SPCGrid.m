//
//  SPCGrid.m
//  Spayce
//
//  Created by Christopher Taylor on 12/2/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCGrid.h"

//Controller
#import "SPCVenueDetailViewController.h"
#import "SPCCustomNavigationController.h"

// Category
#import "UIViewController+SPCAdditions.h"

// Manager
#import "MeetManager.h"
#import "VenueManager.h"
#import "SDWebImageManager.h"
#import "LocationManager.h"
#import "AuthenticationManager.h"

// View
#import "SPCHashTagVenueCell.h"
#import "SPCFeaturedPlaceCell.h"
#import "UIImageView+WebCache.h"
#import "SPCMontageView.h"
#import "SPCRisingStarHeaderCell.h"
#import "SPCRisingStarCell.h"

// Model
#import "Asset.h"
#import "Memory.h"
#import "Venue.h"
#import "Location.h"
#import "Person.h"
#import "User.h"
#import "SPCNeighborhood.h"
#import "Constants.h"

// Framework
#import "Flurry.h"

static NSString * CellIdentifier = @"SPCTrendingVenueCell";
static NSString * HashCellIdentifier = @"SPCHashTagVenueCell";
static NSString * FeaturedPlaceCellIdentifier = @"FeaturedPlaceCellIndentifier";
static NSString * RisingStarCellIdentifier = @"RisingStarCellIdentifier";
static NSString * RisingStarSharedNeighborhoodCellIdentifier = @"RisingStarSharedNeighborhoodCellIdentifier";



static NSTimeInterval CYCLE_IMAGE_EVERY = 2.0f;
static NSTimeInterval FIRST_IMAGE_CYCLE_AFTER_AT_LEAST = 2.0f;
static NSTimeInterval REFRESH_FIRST_PAGE_EVERY = 30.f;
static NSTimeInterval FORCE_REFRESH_LOCAL_FIRST_PAGE_EVERY = 900.f;     // 15 minutes

static CGFloat HIDE_NEW_MEMORIES_BUTTON_DISTANCE = 10.f;     // 10 density-independent points

static const NSTimeInterval MONTAGE_REFRESH_INTERVAL = 5 * 60.0f; // 5 minutes



@interface SPCGridItem : NSObject

@property (nonatomic, strong) Memory *memory;
@property (nonatomic, strong) Venue *venue;
@property (nonatomic, strong) Person *person;
@property (nonatomic, strong) SPCNeighborhood *neighborhood;
@property (nonatomic, assign) NSInteger typeArrayIndex;

@property (nonatomic, readonly) BOOL isMemory;
@property (nonatomic, readonly) BOOL isVenue;
@property (nonatomic, readonly) BOOL isBanner;
@property (nonatomic, readonly) BOOL isHashTagVenue;
@property (nonatomic, readonly) BOOL isPerson;
@property (nonatomic, readonly) BOOL isNeighborhoodForPeople;

- (instancetype)initWithMemory:(Memory *)memory;
- (instancetype)initWithVenue:(Venue *)venue;
- (instancetype)initWithBannerVenue:(Venue *)venue;
- (instancetype)initWithHashTagVenue:(Venue *)venue;
- (instancetype)initWithPerson:(Person *)person;
- (instancetype)initWithNeighborhoodForPeople:(SPCNeighborhood *)neighborhood;
@end

@interface SPCGridItem() {
    BOOL isBanner;
    BOOL isHashTag;
}
@end

@implementation SPCGridItem

- (BOOL)isMemory {
    return self.venue == nil && self.person == nil && self.neighborhood == nil;
}

- (BOOL)isVenue {
    return self.venue != nil;
}

- (BOOL)isBanner {
    return isBanner;
}

- (BOOL)isHashTagVenue {
    return isHashTag;
}

- (BOOL)isPerson {
    return self.person != nil;
}

- (BOOL)isNeighborhoodForPeople {
    return self.neighborhood != nil;
}

- (instancetype)initWithMemory:(Memory *)memory {
    self = [super init];
    if (self) {
        self.memory = memory;
        isBanner = NO;
    }
    return self;
}

- (instancetype)initWithVenue:(Venue *)venue {
    self = [super init];
    if (self) {
        self.venue = venue;
        isBanner = NO;
    }
    return self;
}

- (instancetype)initWithBannerVenue:(Venue *)venue {
    self = [super init];
    if (self) {
        self.venue = venue;
        isBanner = YES;
    }
    return self;
}

- (instancetype)initWithHashTagVenue:(Venue *)venue {
    self = [super init];
    if (self) {
        self.venue = venue;
        isHashTag = YES;
    }
    return self;
}

- (instancetype)initWithPerson:(Person *)person {
    self = [super init];
    if (self) {
        self.person = person;
    }
    return self;
}

- (instancetype)initWithNeighborhoodForPeople:(SPCNeighborhood *)neighborhood {
    self = [super init];
    if (self) {
        self.neighborhood = neighborhood;
    }
    return self;
}

@end


@interface SPCGrid() {
    NSTimeInterval _fetchStartedAt;
}

@property (nonatomic, assign) NSInteger currGridState;

@property (nonatomic, strong) NSArray *gridItems;
@property (nonatomic, assign) NSInteger gridItemMemoryCount;
@property (nonatomic, assign) NSInteger gridItemVenueCount;
@property (nonatomic, assign) NSInteger gridItemPersonCount;
@property (nonatomic, assign) NSInteger gridItemConsecutiveCellRows;
@property (nonatomic, strong) NSArray *gridBannerVenueColors;
@property (nonatomic, strong) NSString * nextPageKey;
@property (nonatomic, strong) NSString * stalePageKey;
@property (nonatomic, assign) double nextPageLatitude;
@property (nonatomic, assign) double nextPageLongitude;
@property (nonatomic, assign) NSTimeInterval currentFirstPageUpdatedAt;
@property (nonatomic, assign) CGFloat footerHeight;

@property (nonatomic, assign) NSTimeInterval venuesUpdatedAt;
@property (nonatomic, assign) BOOL gridContentIsNearby;

@property (nonatomic, readonly) BOOL hasContent;
@property (nonatomic, assign) BOOL prefetchPaused;
@property (nonatomic, assign) BOOL isLocalSelected;

@property (nonatomic, assign) BOOL fetchPendingScrollingStop;
@property (nonatomic, assign) BOOL fetchOngoing;
@property (nonatomic, assign) BOOL hasFetched;
@property (nonatomic, assign) BOOL hasAppeared;
@property (nonatomic, assign) BOOL viewIsVisible;

@property (nonatomic, assign) NSTimeInterval firstPageRefreshedAt;
@property (nonatomic, assign) BOOL refreshOngoing;
@property (nonatomic, strong) NSArray *pendingFirstPageMemories;
@property (nonatomic, strong) NSArray *pendingFirstPageVenues;
@property (nonatomic, strong) NSArray *pendingFirstPagePeople;
@property (nonatomic, strong) NSString *pendingFirstPageNextPageKey;
@property (nonatomic, assign) BOOL pendingFirstPageVenuesAreNew;
@property (nonatomic, strong) UIButton *newMemoriesButton;
@property (nonatomic, assign) CGFloat newMemoriesHidePosition;
@property (nonatomic, readonly) BOOL readyToUpdateToPendingFirstPage;
@property (nonatomic, assign) BOOL gridFirstPageContentIsStale;

@property (nonatomic, strong) NSTimer *refreshTimer;

@property (nonatomic, strong) UIImageView *prefetchImageView;


//offset handling
@property (nonatomic, assign) float previousOffsetY;

@property (nonatomic, assign) BOOL userHasBeenScrollingUp;
@property (nonatomic, assign) float changedDirectionAtOffSetY;

@property (nonatomic, assign) float triggerUpDelta;
@property (nonatomic, assign) float triggerDownDelta;

//BOOLs for bounce check
@property (nonatomic, assign) BOOL userHasEndedDrag;
@property (nonatomic, assign) BOOL directionSetForThisDrag;
@property (nonatomic, assign) BOOL autoScrollInProgress;;


// image cycling
@property (nonatomic, strong) NSTimer * cycleImageTimer;
@property (nonatomic, assign) NSInteger cycleImageLastCellCycled;
@property (nonatomic, strong) NSMutableArray * cycleCells;

// image prefetching
@property (nonatomic, strong) NSArray *prefetchAssetQueue;
@property (nonatomic, assign) BOOL prefetchOngoing;

@property (nonatomic, strong) UICollectionReusableView *locationPromptView;
@property (nonatomic, strong) UICollectionReusableView *paginationLoadingView;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;

//hashtag stuff
@property (nonatomic, strong) NSString *currHash;
@property (nonatomic, strong) NSArray *hashTextCellBgColors;
@property (nonatomic, assign) int activeHashColor;
@property (nonatomic, strong) Memory *fallbackHashMem;

//montage state
@property (nonatomic) BOOL hasShownMontage;
@property (nonatomic) BOOL isFetchingMontageContent;
@property (nonatomic) BOOL failedToLoadMontage;

@end

@implementation SPCGrid


-(void)dealloc  {
    [self.refreshTimer invalidate];
    self.refreshTimer = nil;
    [self.cycleImageTimer invalidate];
    self.cycleImageTimer = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.footerHeight = 50;
        [self addSubview:self.collectionView];
        [self addSubview:self.newMemoriesButton];
        [self configureHashBGColors];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRequestFollowNotification:) name:kFollowDidRequestWithUserToken object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didFollowNotification:) name:kFollowDidFollowWithUserToken object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUnfollowNotification:) name:kFollowDidUnfollowWithUserToken object:nil];
        
    }
    return self;
}

#pragma mark - Accessors

-(NSInteger) cellCount {
    return self.gridItems.count;
}

-(NSArray *) gridBannerVenueColors {
    if (!_gridBannerVenueColors) {
        _gridBannerVenueColors = @[ [UIColor colorWithRGBHex:0x5f23a9],
                                    [UIColor colorWithRGBHex:0x41107d],
                                    [UIColor colorWithRGBHex:0x34115f],
                                    [UIColor colorWithRGBHex:0x210a3c]
                                   ];
    }
    return _gridBannerVenueColors;
}

-(UICollectionView *) collectionView {
    if (!_collectionView) {
        UICollectionViewFlowLayout *layout=[[UICollectionViewFlowLayout alloc] init];
        layout.scrollDirection = UICollectionViewScrollDirectionVertical;
        
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height) collectionViewLayout:layout];
        [_collectionView setDataSource:self];
        [_collectionView setDelegate:self];
        _collectionView.allowsMultipleSelection = NO;
        
        _collectionView.alwaysBounceVertical = YES;
        _collectionView.backgroundColor = [UIColor colorWithRGBHex:0xf0f1f1];
        [_collectionView registerClass:[SPCTrendingVenueCell class] forCellWithReuseIdentifier:CellIdentifier];
        
        [_collectionView registerClass:[SPCHashTagVenueCell class] forCellWithReuseIdentifier:HashCellIdentifier];
        
        [_collectionView registerClass:[SPCFeaturedPlaceCell class] forCellWithReuseIdentifier:FeaturedPlaceCellIdentifier];
        
        [_collectionView registerClass:[SPCRisingStarCell class] forCellWithReuseIdentifier:RisingStarCellIdentifier];
        
        [_collectionView registerClass:[SPCRisingStarHeaderCell class] forCellWithReuseIdentifier:RisingStarSharedNeighborhoodCellIdentifier];
         
                
        [_collectionView registerClass:[UICollectionReusableView class]
                forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                       withReuseIdentifier:@"sectionHeader"];
        
        [_collectionView registerClass:[UICollectionReusableView class]
            forSupplementaryViewOfKind:UICollectionElementKindSectionFooter
                   withReuseIdentifier:@"sectionFooter"];

    }
    return _collectionView;
}

- (UICollectionReusableView *)locationPromptView {
    
    if (!_locationPromptView) {
        _locationPromptView = [[UICollectionReusableView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, 126)];
        _locationPromptView.backgroundColor = [UIColor whiteColor];
        
        UILabel *promptLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, self.bounds.size.width, 40)];
        promptLbl.text = @"Spayce requires location to show you\nthe great memories around you.";
        promptLbl.textAlignment = NSTextAlignmentCenter;
        promptLbl.numberOfLines = 0;
        promptLbl.lineBreakMode = NSLineBreakByWordWrapping;
        promptLbl.font = [UIFont spc_regularSystemFontOfSize:14];
        promptLbl.textColor = [UIColor colorWithRed:139.0f/255.0f green:153.0f/255.0f blue:175.0f/255.0f alpha:1.0f];
        [_locationPromptView addSubview:promptLbl];
        
        UIButton *locationBtn = [[UIButton alloc] initWithFrame:CGRectMake((self.bounds.size.width - 210)/2, CGRectGetMaxY(promptLbl.frame) + 10, 210, 40)];
        [locationBtn setTitle:@"Turn On Location" forState:UIControlStateNormal];
        locationBtn.titleLabel.font = [UIFont spc_mediumSystemFontOfSize:14];
        [locationBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [locationBtn setBackgroundColor:[UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f]];
        locationBtn.layer.cornerRadius = 20;
        [locationBtn addTarget:self action:@selector(showLocationPrompt:) forControlEvents:UIControlEventTouchUpInside];
        [_locationPromptView addSubview:locationBtn];
    
    }
    return _locationPromptView;

}

- (UICollectionReusableView *)paginationLoadingView {
    
    if (!_paginationLoadingView) {
        _paginationLoadingView = [[UICollectionReusableView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, 50)];
        _paginationLoadingView.backgroundColor = [UIColor clearColor];
        
        [_paginationLoadingView addSubview:self.spinner];
        [self.spinner startAnimating];
    }
    return _paginationLoadingView;
    
}

-(UIActivityIndicatorView *)spinner {
    if (!_spinner) {
        _spinner = [[UIActivityIndicatorView alloc]initWithFrame:CGRectMake((self.bounds.size.width - 50)/2,0,50,50)];
        _spinner.color = [UIColor darkGrayColor];

    }
    return _spinner;
}

-(NSMutableArray *)cycleCells {
    if (!_cycleCells) {
        _cycleCells = [[NSMutableArray alloc] init];
    }
    return _cycleCells;
}


- (UIButton *)newMemoriesButton {
    if (!_newMemoriesButton) {
        _newMemoriesButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 130, 28)];
        _newMemoriesButton.backgroundColor = [UIColor whiteColor];
        _newMemoriesButton.layer.cornerRadius = 14;
        _newMemoriesButton.clipsToBounds = NO;
        [_newMemoriesButton setTitle:@"New Moments" forState:UIControlStateNormal];
        [_newMemoriesButton setTitleColor:[UIColor colorWithRGBHex:0x6ab1fb] forState:UIControlStateNormal];
        [_newMemoriesButton.titleLabel setFont:[UIFont spc_mediumSystemFontOfSize:13]];
        _newMemoriesButton.titleEdgeInsets = UIEdgeInsetsMake(2, 8, 0, 0);
        [_newMemoriesButton setImage:[UIImage imageNamed:@"arrow-new-memories"] forState:UIControlStateNormal];
        _newMemoriesButton.imageEdgeInsets = UIEdgeInsetsMake(0, -6, 0, 0);
        
        _newMemoriesButton.center = CGPointMake(CGRectGetWidth(self.frame)/2, CGRectGetHeight(self.frame) - 80);
        
        _newMemoriesButton.layer.shadowColor = [UIColor blackColor].CGColor;
        _newMemoriesButton.layer.shadowOffset = CGSizeMake(0, 1);
        _newMemoriesButton.layer.shadowRadius = 1;
        _newMemoriesButton.layer.shadowOpacity = 0.2f;
        
        _newMemoriesButton.enabled = NO;
        _newMemoriesButton.hidden = YES;
        
        [_newMemoriesButton addTarget:self action:@selector(refreshFirstPage) forControlEvents:UIControlEventTouchUpInside];
    }
    return _newMemoriesButton;
}


- (UIImageView *)prefetchImageView {
    if (!_prefetchImageView) {
        _prefetchImageView = [[UIImageView alloc] init];
    }
    return _prefetchImageView;
}


- (BOOL)readyToUpdateToPendingFirstPage {
    BOOL ready = self.pendingFirstPageMemories && self.collectionView.contentOffset.y <= 0 && (self.pendingFirstPageVenuesAreNew || ([NSDate date].timeIntervalSince1970 - self.currentFirstPageUpdatedAt > FORCE_REFRESH_LOCAL_FIRST_PAGE_EVERY && self.currGridState == GridStateLocal));
    
    return ready;
}


- (void)setPendingFirstPageVenuesAreNew:(BOOL)pendingFirstPageVenuesAreNew {
    _pendingFirstPageVenuesAreNew = pendingFirstPageVenuesAreNew;
    if (self.readyToUpdateToPendingFirstPage) {
        // immediate grid substitution
        [self updateToPendingFirstPage];
    }
}

- (BOOL)hasShownMontage {
    BOOL boolReturn = _hasShownMontage;
    
    if (NO == _hasShownMontage) {
        _hasShownMontage = YES; // Update the value for future accesses
    }
    
    return boolReturn;
}


#pragma mark - mutators

- (void)setMemories:(NSArray *)memories {
    if (self.currGridState == GridStateLocal || self.currGridState == GridStateWorld) {
        NSArray *blockedIds = [MeetManager getBlockedIds];
        if (blockedIds) {
            NSMutableArray *mems = [NSMutableArray arrayWithCapacity:memories.count];
            for (Memory *memory in memories) {
                if (![blockedIds containsObject:@(memory.author.recordID)]) {
                    [mems addObject:memory];
                }
            }
            memories = [NSArray arrayWithArray:mems];
        }
    }
    _memories = memories;
}


#pragma mark - UICollectionViewDataSource


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.cellCount;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    // it might be worthwhile to fetch another page.  Start loading when
    // there is 3 row of content remaining.
    if (!self.fetchOngoing && self.nextPageKey && indexPath.item + 6 > self.cellCount && !self.fetchPendingScrollingStop) {
        self.fetchPendingScrollingStop = YES;
        [self fetchNextPage];
    }
    
    //hash tag cells work slighltly differently than other grid cells
    SPCGridItem *item = self.gridItems[indexPath.item];
    if (item.isBanner) {
        // test banner
        SPCFeaturedPlaceCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:FeaturedPlaceCellIdentifier forIndexPath:indexPath];
        [cell configureWithFeaturedVenue:item.venue];
        cell.color = self.gridBannerVenueColors[item.typeArrayIndex % self.gridBannerVenueColors.count];
        return cell;
    }  else if (item.isMemory) {
        SPCTrendingVenueCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
        // this is the standard cell
        //CGFloat width = self.collectionView.frame.size.width/2.0f - 1.0f;
        //CGRect frame = cell.frame;
        //cell.frame = CGRectMake(frame.origin.x, frame.origin.y, width, width);
        [cell configureWithMemory:item.memory isLocal:self.gridContentIsNearby];
        
        int currIndex = indexPath.item % 7;
        if (currIndex < self.hashTextCellBgColors.count) {
            UIColor *newColor = (UIColor *)self.hashTextCellBgColors[currIndex];
            cell.textMemView.backgroundColor = newColor;
        }
        
        cell.delegate = self;
        cell.tag = indexPath.item;
        return cell;
    } else if (item.isPerson) {
        SPCRisingStarCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:RisingStarCellIdentifier forIndexPath:indexPath];
        // configure!
        [cell configureWithPerson:item.person];
        cell.horizontalOverreach = 2;
        cell.tag = indexPath.item;
        return cell;
    } else if (item.isNeighborhoodForPeople) {
        SPCRisingStarHeaderCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:RisingStarSharedNeighborhoodCellIdentifier forIndexPath:indexPath];
        // configure!
        [cell configureWithNeighborhood:item.neighborhood risingStars:self.currGridState == GridStateLocal];
        cell.bottomOverreach = 2;
        if ([UIScreen mainScreen].bounds.size.width <= 375) {
            cell.textCenterOffset = CGPointMake(0, 4);
        } else {    // 5"
            cell.textCenterOffset = CGPointMake(0, 7);
        }
        cell.tag = indexPath.item;
        return cell;
    } else if (item.isHashTagVenue) {
        SPCHashTagVenueCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:HashCellIdentifier forIndexPath:indexPath];
        //CGFloat width = self.collectionView.frame.size.width/2.0f - 1.0f;
        //CGRect frame = cell.frame;
        //cell.frame = CGRectMake(frame.origin.x, frame.origin.y, width, width);
        [cell configureWithVenue:item.venue isLocal:NO];
        
        int currIndex = indexPath.item % 7;
        if (currIndex < self.hashTextCellBgColors.count) {
            UIColor *newColor = (UIColor *)self.hashTextCellBgColors[currIndex];
            cell.textMemView.backgroundColor = newColor;
        }
        
        cell.delegate = self;
        cell.tag = indexPath.item;
        return cell;
    } else {
        // just a venue
        SPCTrendingVenueCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
        // this is the standard cell
        //CGFloat width = self.collectionView.frame.size.width/2.0f - 1.0f;
        //CGRect frame = cell.frame;
        //cell.frame = CGRectMake(frame.origin.x, frame.origin.y, width, width);
        [cell configureWithVenue:item.venue isLocal:self.gridContentIsNearby];
        
        int currIndex = indexPath.item % 7;
        if (currIndex < self.hashTextCellBgColors.count) {
            UIColor *newColor = (UIColor *)self.hashTextCellBgColors[currIndex];
            cell.textMemView.backgroundColor = newColor;
        }
        
        cell.delegate = self;
        cell.tag = indexPath.item;
        return cell;
    }
}



#pragma mark - UICollectionViewDelegate


- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    SPCGridItem *item = self.gridItems[indexPath.item];
    if (item.isBanner) {
        return CGSizeMake(self.bounds.size.width, self.bounds.size.width * 0.2666667f);
    } else if (item.isNeighborhoodForPeople) {
        if ([UIScreen mainScreen].bounds.size.width <= 375) {
            return CGSizeMake(self.bounds.size.width, 26);
        }
        //5"
        return CGSizeMake(self.bounds.size.width, 32);
    } else if (item.isPerson) {
        if ([UIScreen mainScreen].bounds.size.width <= 375) {
            return CGSizeMake(self.bounds.size.width/3.0 -2, 125);
        }
        //5"
        return CGSizeMake(self.bounds.size.width/3.0 -2, 135);
    }
    return CGSizeMake(self.bounds.size.width/2.0f -1, self.bounds.size.width/2.0f - 1);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0, 0, 0, 0);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 2;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 2;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        if (self.viewMontage.isReady) {
            return CGSizeMake(self.viewMontage.previewImageSize.width, self.viewMontage.previewImageSize.height + 2.0f);
        }
        else {
            return CGSizeMake(self.frame.size.width, 0);
        }
    }
    else {
        return CGSizeMake(self.frame.size.width, 0);
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    CGSize size = CGSizeMake(self.bounds.size.width, self.footerHeight == 0 ? 0.0001 : self.footerHeight);
    return size;
}



- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    // Deselect cell
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    
    // Push venue feed
    SPCGridItem *item = self.gridItems[indexPath.item];
    Memory *memory = item.memory;
    UIImage *image = nil;
    CGRect rect = CGRectZero;
    
    UICollectionViewCell *genericCell = [self.collectionView cellForItemAtIndexPath:indexPath];
    if ([genericCell isKindOfClass:[SPCTrendingVenueCell class]]) {
        SPCTrendingVenueCell *cell = (SPCTrendingVenueCell *)genericCell;
        memory = cell.memoryDisplayed;
        if (memory.type == MemoryTypeImage) {
            image = cell.imageView.image;
        }
        if (memory.type == MemoryTypeVideo) {
            image = cell.imageView.image;
        }
        rect = CGRectOffset(cell.frame, 0, -self.collectionView.contentOffset.y + CGRectGetMinY(self.frame));
    }
    
    if (self.delegate) {
        if (item.isMemory) {
            
            if (self.currGridState == GridStateLocal) {
                [Flurry logEvent:@"GRID_CELL_TAPPED_LOCAL"];
            }
            else if (self.currGridState == GridStateWorld)  {
                [Flurry logEvent:@"GRID_CELL_TAPPED_WORLD"];
            }
            else if (self.currGridState == GridStateHash)  {
                [Flurry logEvent:@"GRID_CELL_TAPPED_HASH"];
            }
            [Flurry logEvent:@"GRID_CELL_TAPPED_ALL"];
            
            
            
            if ([self.delegate respondsToSelector:@selector(showMemoryComments:withImage:atRect:)]) {
                [self.delegate showMemoryComments:memory withImage:image atRect:rect];
            } else if ([self.delegate respondsToSelector:@selector(showMemoryComments:)]) {
                [self.delegate showMemoryComments:memory];
            }
        } else if (item.isVenue) {
            
            if (self.currGridState == GridStateLocal) {
                [Flurry logEvent:@"FEATURED_VENUE_TAPPED_LOCAL"];
            }
            else if (self.currGridState == GridStateWorld)  {
              [Flurry logEvent:@"FEATURED_VENUE_TAPPED_WORLD"];
            }
            [Flurry logEvent:@"FEATURED_VENUE_TAPPED"];
            
            if (memory != nil && [self.delegate respondsToSelector:@selector(showVenueDetail:jumpToMemory:withImage:atRect:)]) {
                [self.delegate showVenueDetail:item.venue jumpToMemory:memory withImage:image atRect:rect];
            } else if ([self.delegate respondsToSelector:@selector(showVenueDetail:)]) {
                [self.delegate showVenueDetail:item.venue];
            }
        } else if (item.isPerson) {
            if (self.currGridState == GridStateLocal) {
                [Flurry logEvent:@"FEATURED_PERSON_TAPPED_LOCAL"];
            }
            else if (self.currGridState == GridStateWorld)  {
                [Flurry logEvent:@"FEATURED_PERSON_TAPPED_WORLD"];
            }
            [Flurry logEvent:@"FEATURED_PERSON_TAPPED"];
            
            if ([self.delegate respondsToSelector:@selector(showPerson:)]) {
                [self.delegate showPerson:item.person];
            }
        }
    }
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    UICollectionReusableView *reusableView = nil;
    
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        
        
        reusableView = [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                          withReuseIdentifier:@"sectionHeader"
                                                                 forIndexPath:indexPath];
        
        // Determine if this is the first time we're presenting this montage, so we can show a 'rad' animation bra
        // It's getting late...
        if (NO == self.hasShownMontage) {
            self.viewMontage.alpha = 0.0f;
            [reusableView addSubview:self.viewMontage];
            [UIView animateWithDuration:0.5f animations:^{
                self.viewMontage.alpha = 1.0f;
            }];
        } else {
            [self.viewMontage removeFromSuperview];
            [reusableView addSubview:self.viewMontage];
        }
        return reusableView;
    }
    
    if ([kind isEqualToString:UICollectionElementKindSectionFooter]) {
        
        reusableView = [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                          withReuseIdentifier:@"sectionFooter"
                                                                 forIndexPath:indexPath];
        
        [reusableView addSubview:self.paginationLoadingView];


        return reusableView;

    }
    
    return reusableView;
}


#pragma mark - SPCTrendingVenueCellDelegate

- (void)removeCellFromCycledListWithTag:(NSInteger)cellTag {
 
    //clean up our list of cycled cells when scrolling occurs and a cell is reused
    
    NSString *tagStr = [NSString stringWithFormat:@"%@",@(cellTag)];
    
    for (int j = 0; j < self.cycleCells.count; j++) {
        NSString *recentlyCycled = self.cycleCells[j];
        
        if ([recentlyCycled isEqualToString:tagStr]) {
            [self.cycleCells removeObjectAtIndex:j];
            break;
        }
    }
}

#pragma mark - Private


- (void)extendGridItemsWithMemories:(NSArray *)memories locations:(NSArray *)locations people:(NSArray *)people {
    if (memories) {
        if (self.memories) {
            NSMutableArray *mut = [NSMutableArray arrayWithArray:self.memories];
            NSMutableSet *memKeys = [NSMutableSet setWithCapacity:self.memories.count];
            for (Memory *memory in self.memories) {
                [memKeys addObject:memory.key];
            }
            for (Memory *memory in memories) {
                if (![memKeys containsObject:memory.key]) {
                    [mut addObject:memory];
                }
            }
            self.memories = [NSArray arrayWithArray:mut];
        } else {
            self.memories = memories;
        }
    }
    
    if (locations) {
        if (self.venues) {
            NSMutableArray *mut = [NSMutableArray arrayWithArray:self.venues];
            NSMutableSet *venueKeys = [NSMutableSet setWithCapacity:self.venues.count];
            for (Venue *venue in self.venues) {
                [venueKeys addObject:venue.locationKey];
            }
            for (Venue *venue in locations) {
                if (![venueKeys containsObject:venue.locationKey]) {
                    [mut addObject:venue];
                }
            }
            self.venues = [NSArray arrayWithArray:mut];
        } else {
            self.venues = locations;
        }
    }
    
    if (people) {
        if (self.people) {
            NSMutableArray *mut = [NSMutableArray arrayWithArray:self.people];
            NSMutableSet *personKeys = [NSMutableSet setWithCapacity:self.people.count];
            for (Person *person in self.people) {
                [personKeys addObject:person.userToken];
            }
            for (Person *person in people) {
                if (![personKeys containsObject:person.userToken]) {
                    [mut addObject:person];
                }
            }
            self.people = [NSArray arrayWithArray:mut];
        } else {
            self.people = people;
        }
    }
    
    [self extendGridItemsIfPossible];
}

- (void)extendGridItemsIfPossible {
    NSMutableArray *grid;
    if (self.gridItems) {
        grid = [NSMutableArray arrayWithArray:self.gridItems];
    } else {
        grid = [NSMutableArray array];
    }
    
    // Interstitials are placed with simulated randomness that, in fact, is fully
    // deterministic given the memories and venues.
    NSInteger interstitialRandSeed = self.memories.count > 0 ? ((Memory *)self.memories[0]).recordID : 0;
    NSInteger interstitialRandVal = self.gridItemVenueCount > 0 && self.venues.count > self.gridItemVenueCount-1
            ? ((Venue *)self.venues[self.gridItemVenueCount-1]).addressId : 0;
    
    // For now, place a banner every 4.  We can worry about a deterministic shuffling
    // procedure later -- our goals are 1. the APPEARANCE of randomness, where different grid
    // content would have slightly different orders of "tile rows" and "venue banners",
    // 2. the actual BEHAVIOR of a deterministic system, where identical content would be rendered
    // in exactly the same way across sessions, and 3. a maximum "banner concentration" of approximately
    // 1 banner for every 2 cell rows.
    while(true) {
        //NSLog(@"inserting a row");
        // insert a row
        SPCGridItem *item1 = nil;
        SPCGridItem *item2 = nil;
        SPCGridItem *item3 = nil;
        SPCGridItem *item4 = nil;
        if ((self.currGridState == GridStateLocal || self.currGridState == GridStateWorld)
            && self.gridItemConsecutiveCellRows >= (interstitialRandSeed + interstitialRandVal) % 5 + 2 && self.people.count >= self.gridItemPersonCount + 3) {
            //NSLog(@"a line of people");
            // time for a line of people.  Represent this as a neighborhood (the most specific territory
            // that contains these three peeps), then three people.
            Person *person1 = self.people[self.gridItemPersonCount++];
            Person *person2 = self.people[self.gridItemPersonCount++];
            Person *person3 = self.people[self.gridItemPersonCount++];
            SPCNeighborhood *neighborhood = [self smallestSharedTerritoryForPeople:@[person1, person2, person3]];
            // neighborhood "header"
            item1 = [[SPCGridItem alloc] initWithNeighborhoodForPeople:neighborhood];
            // three people there
            item2 = [[SPCGridItem alloc] initWithPerson:person1];
            item3 = [[SPCGridItem alloc] initWithPerson:person2];
            item4 = [[SPCGridItem alloc] initWithPerson:person3];
            item1.typeArrayIndex = -1;
            item2.typeArrayIndex = self.gridItemPersonCount - 3;
            item3.typeArrayIndex = self.gridItemPersonCount - 2;
            item4.typeArrayIndex = self.gridItemPersonCount - 1;
            self.gridItemConsecutiveCellRows = 0;
            interstitialRandVal = person1.recordID + person2.recordID + person3.recordID;
        } else if ((self.currGridState == GridStateLocal || self.currGridState == GridStateWorld)
            && self.gridItemConsecutiveCellRows >= (interstitialRandSeed + interstitialRandVal) % 3 + 2 && self.venues.count > self.gridItemVenueCount) {
            //NSLog(@"venue banner");
            // time for a banner...
            Venue *venue = self.venues[self.gridItemVenueCount++];
            item1 = [[SPCGridItem alloc] initWithBannerVenue:venue];
            item1.typeArrayIndex = self.gridItemVenueCount - 1;
            self.gridItemConsecutiveCellRows = 0;
            interstitialRandVal = venue.addressId;
        } else if (self.currGridState == GridStateHash && self.venues.count > self.gridItemVenueCount+1) {
            //NSLog(@"hash tag venue");
            Venue *venue1 = self.venues[self.gridItemVenueCount++];
            Venue *venue2 = self.venues[self.gridItemVenueCount++];
            item1 = [[SPCGridItem alloc] initWithHashTagVenue:venue1];
            item2 = [[SPCGridItem alloc] initWithHashTagVenue:venue2];
            item1.typeArrayIndex = self.gridItemVenueCount - 2;
            item2.typeArrayIndex = self.gridItemVenueCount - 1;
            self.gridItemConsecutiveCellRows++;
        } else if (self.memories.count > self.gridItemMemoryCount+1) {
            //NSLog(@"memory pair");
            Memory *memory1 = self.memories[self.gridItemMemoryCount++];
            Memory *memory2 = self.memories[self.gridItemMemoryCount++];
            item1 = [[SPCGridItem alloc] initWithMemory:memory1];
            item2 = [[SPCGridItem alloc] initWithMemory:memory2];
            item1.typeArrayIndex = self.gridItemVenueCount - 2;
            item2.typeArrayIndex = self.gridItemVenueCount - 1;
            self.gridItemConsecutiveCellRows++;
        }
        //NSLog(@"adding items...");
        if (item1) {
            [grid addObject:item1];
            if (item2) {
                [grid addObject:item2];
            }
            if (item3) {
                [grid addObject:item3];
            }
            if (item4) {
                [grid addObject:item4];
            }
        } else {
            break;
        }
    }
    
    self.gridItems = [NSArray arrayWithArray:grid];
}


- (SPCNeighborhood *)smallestSharedTerritoryForPeople:(NSArray *)array {
    SPCNeighborhood *neighborhood = [[SPCNeighborhood alloc] init];
    // first person...
    Person *person = (Person *)array.firstObject;
    neighborhood.countryAbbr = person.risingStarTerritory.countryAbbr;
    neighborhood.stateAbbr = person.risingStarTerritory.stateAbbr;
    neighborhood.county = person.risingStarTerritory.county;
    neighborhood.cityName = person.risingStarTerritory.cityName;
    neighborhood.neighborhood = person.risingStarTerritory.neighborhood;
    neighborhood.neighborhoodName = person.risingStarTerritory.neighborhoodName;
    
    for (Person *person in array) {
        if (![neighborhood.countryAbbr isEqualToString:person.risingStarTerritory.countryAbbr]) {
            neighborhood.countryAbbr = nil;
            neighborhood.stateAbbr = nil;
            neighborhood.county = nil;
            neighborhood.cityName = nil;
            neighborhood.neighborhood = nil;
            neighborhood.neighborhoodName = nil;
        } else if (![neighborhood.stateAbbr isEqualToString:person.risingStarTerritory.stateAbbr]) {
            neighborhood.stateAbbr = nil;
            neighborhood.county = nil;
            neighborhood.cityName = nil;
            neighborhood.neighborhood = nil;
            neighborhood.neighborhoodName = nil;
        } else if (![neighborhood.county isEqualToString:person.risingStarTerritory.county]) {
            neighborhood.county = nil;
            neighborhood.cityName = nil;
            neighborhood.neighborhood = nil;
            neighborhood.neighborhoodName = nil;
        } else if (![neighborhood.cityName isEqualToString:person.risingStarTerritory.cityName]) {
            neighborhood.cityName = nil;
            neighborhood.neighborhood = nil;
            neighborhood.neighborhoodName = nil;
        } else if (![neighborhood.neighborhood isEqualToString:person.risingStarTerritory.neighborhood] && ![neighborhood.neighborhoodName isEqualToString:person.risingStarTerritory.neighborhoodName]) {
            neighborhood.neighborhood = nil;
            neighborhood.neighborhoodName = nil;
        }
    }
    return neighborhood;
}


- (void)fetchGridContent {
    [self restoreFooterIfNeeded];  //needed after max pagination followed by PTR
    self.currGridState = GridStateWorld;
    self.spinner.hidden = NO;
    __weak typeof(self)weakSelf = self;
    
    if (self.fetchOngoing == YES) {
        return;
    }
    
    self.fetchOngoing = YES;
    self.gridFirstPageContentIsStale = NO;
    self.newMemoriesButton.hidden = YES;
    
    [[MeetManager sharedInstance] fetchWorldFeaturedMemoryAndVenueGridPageWithPageKey:nil completionHandler:^(NSArray *memories, NSArray *people, NSString *nextPageKey, NSString *stalePageKey) {
        //NSLog(@"got %d memories, %d people", memories.count, people.count);
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf) {
            return ;
        }
        strongSelf.spinner.hidden = YES;
        
        BOOL changed = ![strongSelf memoryList:memories isEquivalentTo:strongSelf.memories] || ![strongSelf personList:people isEquivalentTo:strongSelf.people];
        strongSelf.gridContentIsNearby = NO;
        strongSelf.memories = memories;
        strongSelf.people = people;
        strongSelf.nextPageKey = nextPageKey;
        strongSelf.stalePageKey = stalePageKey;
        strongSelf.venuesUpdatedAt = [[NSDate date] timeIntervalSince1970];
        strongSelf.currentFirstPageUpdatedAt = strongSelf.venuesUpdatedAt;
        strongSelf.pendingFirstPageMemories = nil;
        strongSelf.pendingFirstPageVenues = nil;
        strongSelf.pendingFirstPagePeople = nil;
        strongSelf.pendingFirstPageNextPageKey = nil;
        strongSelf.pendingFirstPageVenuesAreNew = NO;
        strongSelf.gridFirstPageContentIsStale = NO;
        
        if (changed) {
            [strongSelf addMemoriesForPrefetching:memories];
            [strongSelf addPeopleForPrefetching:people];
            [strongSelf prefetchNextAsset];
            [strongSelf reloadData];
        }
        
        strongSelf.fetchOngoing = NO;
        
        if (strongSelf.delegate && [strongSelf.delegate respondsToSelector:@selector(worldContentComplete)]) {
            [strongSelf.delegate worldContentComplete];
        }
        
        if (!nextPageKey) {
            //adjust eliminate footer
            self.footerHeight = 0;
            [strongSelf.collectionView performBatchUpdates:^{
                UICollectionViewFlowLayout* flowLayout = (UICollectionViewFlowLayout*) strongSelf.collectionView.collectionViewLayout;
                flowLayout.footerReferenceSize = CGSizeMake(strongSelf.bounds.size.width, 0);
            } completion:^(BOOL done) {
                if (done) {
                    //NSLog(@"footer gone!");
                }
            }];
        }
    } errorHandler:^(NSError *error) {
        NSLog(@"error %@",error);
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf) {
            return ;
        }
        
        strongSelf.fetchOngoing = NO;
        strongSelf.spinner.hidden = YES;
        if (strongSelf.delegate && [strongSelf.delegate respondsToSelector:@selector(worldContentComplete)]) {
            [strongSelf.delegate worldContentComplete];
        }
    }];
}


- (void)fetchGridContentNextPage {
    
    __weak typeof(self)weakSelf = self;
    
    if (self.fetchOngoing == YES) {
        return;
    }
    if (!self.nextPageKey) {
        return;
    }
    
    NSLog(@"fetchGridContentNextPage with key %@", self.nextPageKey);
    
    self.fetchOngoing = YES;
    self.spinner.hidden = NO;

    NSString *pageKey = self.nextPageKey;
    
    [Flurry logEvent:@"WORLD_GRID_PAGINATION"];
    
    [[MeetManager sharedInstance] fetchWorldFeaturedMemoryAndVenueGridPageWithPageKey:pageKey completionHandler:^(NSArray *memories, NSArray *people, NSString *nextPageKey, NSString *stalePageKey) {
        __strong typeof(weakSelf)strongSelf = weakSelf;
        //NSLog(@"result are back!");
        
        // sanity check: we might have applied a pending first page during this fetch.
        // Make sure that's not the case.
        if (!strongSelf.nextPageKey || ![strongSelf.nextPageKey isEqualToString:pageKey]) {
            // don't touch the spinner or 'fetchOngoing' boolean!
            return;
        }
        
        strongSelf.nextPageKey = nextPageKey;
        
        [strongSelf whenScrollingHasStoppedUpdateWorldGridWithMemories:memories venues:nil people:people];
    } errorHandler:^(NSError *error) {
        NSLog(@"error %@",error);
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf) {
            return ;
        }
        
        
        // sanity check: we might have applied a pending first page during this fetch.
        // Make sure that's not the case.
        if (!strongSelf.nextPageKey || ![strongSelf.nextPageKey isEqualToString:pageKey]) {
            // don't touch the spinner or 'fetchOngoing' boolean!
            return;
        }
        strongSelf.spinner.hidden = YES;
        strongSelf.fetchOngoing = NO;
        
        if (strongSelf.delegate && [strongSelf.delegate respondsToSelector:@selector(worldContentComplete)]) {
            [strongSelf.delegate worldContentComplete];
        }
    }];
}

- (void)fetchMontageWorldContent {
    if (NO == self.isFetchingMontageContent) {
        self.isFetchingMontageContent = YES;
        __weak typeof(self) weakSelf = self;
        [MeetManager fetchMontageWorldMemoriesWithCurrentMemoryKeys:self.montageLastViewedMemories completionHandler:^(NSArray *memories, BOOL wasMontageStale) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            
            // Make sure we have a new set of memories
            if (wasMontageStale || [AuthenticationManager sharedInstance].currentUser.isAdmin) {
                if (0 >= strongSelf.viewMontage.memories.count) {
                    [strongSelf.viewMontage configureWithMemories:memories title:@"Today in your World" overlayColor:[UIColor colorWithRGBHex:0x070657 alpha:0.65f] useLocalLocations:NO andPreviewImageSize:strongSelf.viewMontage.bounds.size];
                } else {
                    BOOL needsToLoad = YES;
                    [strongSelf.viewMontage updateWithMemories:memories withMontageNeedsLoadReturn:&needsToLoad];
                    if (needsToLoad) {
                        [strongSelf.collectionView.collectionViewLayout invalidateLayout];
                    }
                }
            }
            
            strongSelf.isFetchingMontageContent = NO;
            
            [strongSelf performSelector:@selector(refreshMontageContentIfNeeded) withObject:nil afterDelay:MONTAGE_REFRESH_INTERVAL];
        } errorHandler:^(NSError *error) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            strongSelf.isFetchingMontageContent = NO;
            
            [strongSelf performSelector:@selector(refreshMontageContentIfNeeded) withObject:nil afterDelay:MONTAGE_REFRESH_INTERVAL];
        }];
    } else {
        [self performSelector:@selector(refreshMontageContentIfNeeded) withObject:nil afterDelay:MONTAGE_REFRESH_INTERVAL];
    }
}

-(void)checkGridContentFirstPageForFreshness {
    
    if (self.refreshOngoing == YES) {
        //NSLog(@"refresh is ongoing!");
        return;
    }
    if (!self.stalePageKey) {
        // have no pages
        return;
    }
    if (!self.currentFirstPageUpdatedAt || [[NSDate dateWithTimeIntervalSince1970:self.currentFirstPageUpdatedAt] timeIntervalSince1970] <= REFRESH_FIRST_PAGE_EVERY) {
        return;
    }
    
    // use stale page key to check to see if first page results are new!
    [[MeetManager sharedInstance] checkForFreshFirstPageWorldFeaturedMemoryAndVenueGridWithStaleKey:self.stalePageKey completionHandler:^(BOOL firstPageIsStale) {
        self.firstPageRefreshedAt = [NSDate date].timeIntervalSince1970;
        
        if (firstPageIsStale) {
            //NSLog(@"world grid is stale!");
            self.gridFirstPageContentIsStale = YES;
        }else {
            //NSLog(@"world grid still fresh!");
        }

    } errorHandler:nil];
    
}

-(void)refreshGridContentFirstPage {
    
     //NSLog(@"content is stale, proceed with refreshing first page!");
     self.refreshOngoing = YES;
     __weak typeof(self)weakSelf = self;
    
    [[MeetManager sharedInstance] fetchWorldFeaturedMemoryAndVenueGridPageWithPageKey:nil
                                                                    completionHandler:^(NSArray *memories, NSArray *people, NSString *nextPageKey, NSString *stalePageKey) {
                                                                        //NSLog(@"received fresh grid content");
                                                                        __strong typeof(weakSelf)strongSelf = weakSelf;
                                                                        if (!strongSelf) {
                                                                            return ;
                                                                        }
                                                                        
                                                                        strongSelf.firstPageRefreshedAt = [NSDate date].timeIntervalSince1970;
                                                                        strongSelf.refreshOngoing = NO;
                                                                        strongSelf.stalePageKey = stalePageKey;
                                                                        
                                                                        strongSelf.pendingFirstPageMemories = memories;
                                                                        strongSelf.pendingFirstPagePeople = people;
                                                                        strongSelf.pendingFirstPageNextPageKey = nextPageKey;
                                                                        strongSelf.pendingFirstPageVenuesAreNew = YES;
                                                                        
                                                                        //NSLog(@"set pending first page content: %d memories, %d people", strongSelf.pendingFirstPageMemories.count, strongSelf.pendingFirstPagePeople.count);
                                                                        
                                                                        [strongSelf updateToPendingFirstPage];
                                                                        
                                                                        [strongSelf refreshMontageContentIfNeeded];
                                                                        
                                                                        
                                                                        
                                                                    } errorHandler:^(NSError *error) {
                                                                        __strong typeof(weakSelf)strongSelf = weakSelf;
                                                                        if (!strongSelf) {
                                                                            return ;
                                                                        }
                                                                        
                                                                        strongSelf.refreshOngoing = NO;
                                                                    }];
}

-(void)whenScrollingHasStoppedUpdateWorldGridWithMemoriesAndVenues:(NSDictionary *)dictionary {
    [self whenScrollingHasStoppedUpdateWorldGridWithMemories:dictionary[@"memories"] venues:dictionary[@"venues"] people:dictionary[@"people"]];
}

-(void)whenScrollingHasStoppedUpdateWorldGridWithMemories:(NSArray *)memories venues:(NSArray *)venues people:(NSArray *)people {
    
    if (!self.collectionView.isDecelerating && !self.collectionView.isDragging) {
        
        self.spinner.hidden = YES;
    
        NSLog(@"user has stopped scrolling, it's safe to insert our new cells!");
       
        if (self.delegate && [self.delegate respondsToSelector:@selector(worldContentComplete)]) {
            [self.delegate worldContentComplete];
        }
        
        
        
        [self addMemoriesForPrefetching:memories];
        [self addVenuesForPrefetching:venues];
        // TODO: add people for prefeteching
        [self prefetchNextAsset];
        
        NSInteger lastRow = self.cellCount;
        [self extendGridItemsWithMemories:memories locations:venues people:people];
        
        NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:(self.gridItems.count - lastRow)];
        for (NSInteger i = lastRow; i < self.gridItems.count; i++) {
            [indexPaths addObject:[NSIndexPath indexPathForItem:i inSection:0]];
        }
        [self.collectionView insertItemsAtIndexPaths:indexPaths];
        
        self.fetchOngoing = NO;
        
        if (!self.nextPageKey) {
            //adjust eliminate footer
            self.footerHeight = 0;
            [self.collectionView performBatchUpdates:^{
                UICollectionViewFlowLayout* flowLayout = (UICollectionViewFlowLayout*) self.collectionView.collectionViewLayout;
                flowLayout.footerReferenceSize = CGSizeMake(self.bounds.size.width, 0);
            } completion:^(BOOL done) {
                if (done) {
                    //NSLog(@"footer gone!");
                }
            }];
        } else {
            [self restoreFooterIfNeeded];
        }
    }
    else {
        NSLog(@"hold on our update, user is still scrolling..");
        [self performSelector:@selector(whenScrollingHasStoppedUpdateWorldGridWithMemoriesAndVenues:) withObject:@{ @"memories": memories ? memories : @[], @"venues": venues ? venues : @[], @"people": people ? people : @[]} afterDelay:.3];
    }
}

//nearby

- (void)fetchNearbyGridContent {
    
    [self restoreFooterIfNeeded];
    self.currGridState = GridStateLocal;
    
    self.isLocalSelected = YES;
    
    __weak typeof(self)weakSelf = self;
    
    if (self.fetchOngoing == YES) {
        return;
    }
    
    self.fetchOngoing = YES;
    self.gridFirstPageContentIsStale = NO;
    self.newMemoriesButton.hidden = YES;
    
    //is location available to fetch nearby venues?
    if ([CLLocationManager locationServicesEnabled] &&
        ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse)) {
        
        [[LocationManager sharedInstance] getCurrentLocationWithResultCallback:^(double gpsLat, double gpsLong) {
            //NSLog(@"getting content nearby %f, %f", gpsLat, gpsLong);
            [[MeetManager sharedInstance] fetchNearbyFeaturedMemoryAndVenueGridPageWithPageKey:nil latitude:gpsLat longitude:gpsLong resultCallback:^(NSArray *memories, NSArray *people, NSString *nextPageKey, NSString *stalePageKey) {
                __strong typeof(weakSelf)strongSelf = weakSelf;
                if (!strongSelf) {
                    return ;
                }
                
                //NSLog(@"grid content %@", people);
                strongSelf.spinner.hidden = YES;
                BOOL changed = ![strongSelf memoryList:memories isEquivalentTo:self.memories] || ![strongSelf personList:people isEquivalentTo:strongSelf.people];
                strongSelf.gridContentIsNearby = YES;
                strongSelf.memories = memories;
                strongSelf.people = people;
                strongSelf.nextPageKey = nextPageKey;
                strongSelf.stalePageKey = stalePageKey;
                //NSLog(@"stalePageKey %@",stalePageKey);
                strongSelf.nextPageLatitude = gpsLat;
                strongSelf.nextPageLongitude = gpsLong;
                strongSelf.pendingFirstPageMemories = nil;
                strongSelf.pendingFirstPageVenues = nil;
                strongSelf.pendingFirstPagePeople = nil;
                strongSelf.pendingFirstPageNextPageKey = nil;
                strongSelf.pendingFirstPageVenuesAreNew = NO;
                strongSelf.venuesUpdatedAt = [[NSDate date] timeIntervalSince1970];
                strongSelf.currentFirstPageUpdatedAt = strongSelf.venuesUpdatedAt;
                strongSelf.gridFirstPageContentIsStale = NO;
                
                if (changed) {
                    [strongSelf addMemoriesForPrefetching:memories];
                    [strongSelf addPeopleForPrefetching:people];
                    [strongSelf prefetchNextAsset];
                    [strongSelf reloadData];
                }
                
                strongSelf.fetchOngoing = NO;
                
                if (strongSelf.delegate && [strongSelf.delegate respondsToSelector:@selector(nearbyContentComplete)]) {
                    //NSLog(@"fetchNearbyGridContent complete");
                    [strongSelf.delegate nearbyContentComplete];
                }
                
                if (!nextPageKey) {
                    //adjust eliminate footer
                    strongSelf.footerHeight = 0;
                    [strongSelf.collectionView performBatchUpdates:^{
                        UICollectionViewFlowLayout* flowLayout = (UICollectionViewFlowLayout*) strongSelf.collectionView.collectionViewLayout;
                        flowLayout.footerReferenceSize = CGSizeMake(strongSelf.bounds.size.width, 0);
                    } completion:^(BOOL done) {
                        if (done) {
                            //NSLog(@"footer gone!");
                        }
                    }];
                }
            } faultCallback:^(NSError *fault) {
                NSLog(@"Fault fetching nearby grid %@",fault);
                __strong typeof(weakSelf)strongSelf = weakSelf;
                if (!strongSelf) {
                    return ;
                }
                
                strongSelf.fetchOngoing = NO;
                strongSelf.spinner.hidden = YES;
                if (strongSelf.delegate && [strongSelf.delegate respondsToSelector:@selector(nearbyContentComplete)]) {
                    //NSLog(@"fetchNearbyGridContent fault");
                    [strongSelf.delegate nearbyContentComplete];
                }
            }];
            
        } faultCallback:^(NSError *fault) {
            __strong typeof(weakSelf)strongSelf = weakSelf;
            if (!strongSelf) {
                return ;
            }
            strongSelf.spinner.hidden = YES;
            strongSelf.fetchOngoing = NO;
            if (strongSelf.delegate && [strongSelf.delegate respondsToSelector:@selector(nearbyContentComplete)]) {
                [strongSelf.delegate nearbyContentComplete];
            }
        }];
    }
}

- (void)fetchNearbyGridContentNextPage {
    //NSLog(@"fetchNearbyGridContentNextPage with key %@", self.nextPageKey);
    
    __weak typeof(self)weakSelf = self;
    
    if (self.fetchOngoing == YES) {
        return;
    }
    if (!self.nextPageKey) {
        return;
    }
    
    self.fetchOngoing = YES;
    self.spinner.hidden = NO;
    
    NSString *pageKey = self.nextPageKey;
    
    [Flurry logEvent:@"LOCAL_GRID_PAGINATION"];
    
    [[MeetManager sharedInstance] fetchNearbyFeaturedMemoryAndVenueGridPageWithPageKey:pageKey latitude:self.nextPageLatitude longitude:self.nextPageLongitude resultCallback:^(NSArray *memories, NSArray *people, NSString *nextPageKey, NSString *stalePageKey) {
        __strong typeof(weakSelf)strongSelf = weakSelf;
        
        // sanity check: we might have applied a pending first page during this fetch.
        // Make sure that's not the case.
        if (!strongSelf.nextPageKey || ![strongSelf.nextPageKey isEqualToString:pageKey]) {
            // don't touch the spinner or 'fetchOngoing' boolean!
            return;
        }
        
        strongSelf.nextPageKey = nextPageKey;
        [strongSelf whenScrollingHasStoppedUpdateNearbyGridWithMemories:memories venues:nil people:people];
        
        //NSLog(@"grid page %@\nnext page key %@",venues,nextPageKey);

    } faultCallback:^(NSError *fault) {
        NSLog(@"error %@",fault);
        __strong typeof(weakSelf)strongSelf = weakSelf;
        // sanity check: we might have applied a pending first page during this fetch.
        // Make sure that's not the case.
        if (!strongSelf.nextPageKey || ![strongSelf.nextPageKey isEqualToString:pageKey]) {
            // don't touch the spinner or 'fetchOngoing' boolean!
            return;
        }
        strongSelf.fetchOngoing = NO;
        strongSelf.spinner.hidden = YES;
        
        if (strongSelf.delegate && [strongSelf.delegate respondsToSelector:@selector(nearbyContentComplete)]) {
            [strongSelf.delegate nearbyContentComplete];
        }
    }];
}

- (void)fetchMontageNearbyContentWithLatitude:(CGFloat)latitude andLongitude:(CGFloat)longitude {
    if (NO == self.isFetchingMontageContent) {
        self.isFetchingMontageContent = YES;
        __weak typeof(self) weakSelf = self;
        [MeetManager fetchMontageNearbyMemoriesWithCurrentMemoryKeys:self.montageLastViewedMemories latitude:latitude longitude:longitude withCompletionHandler:^(NSArray *memories, BOOL wasMontageStale) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            
            // Make sure we have a new set of memories
            if (wasMontageStale || [AuthenticationManager sharedInstance].currentUser.isAdmin)
            {
                if (0 >= self.viewMontage.memories.count) {
                    [strongSelf.viewMontage configureWithMemories:memories title:@"Today in your Neighborhood" overlayColor:[UIColor colorWithRGBHex:0x070657 alpha:0.65f] useLocalLocations:YES andPreviewImageSize:strongSelf.viewMontage.bounds.size];
                } else {
                    BOOL needsToLoad = YES;
                    [strongSelf.viewMontage updateWithMemories:memories withMontageNeedsLoadReturn:&needsToLoad];
                    if (needsToLoad) {
                        [strongSelf.collectionView.collectionViewLayout invalidateLayout];
                    }
                }
            }
            
            strongSelf.isFetchingMontageContent = NO;
            
            [strongSelf performSelector:@selector(refreshMontageContentIfNeeded) withObject:nil afterDelay:MONTAGE_REFRESH_INTERVAL];
        } errorHandler:^(NSError *error) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            
            strongSelf.isFetchingMontageContent = NO;
            [strongSelf performSelector:@selector(refreshMontageContentIfNeeded) withObject:nil afterDelay:MONTAGE_REFRESH_INTERVAL];
        }];
    } else {
        [self performSelector:@selector(refreshMontageContentIfNeeded) withObject:nil afterDelay:MONTAGE_REFRESH_INTERVAL];
    }
}

- (void)checkNearbyGridContentFirstPageForFreshness {
    
    //__weak typeof(self)weakSelf = self;
    
    if (self.refreshOngoing == YES) {
        return;
    }
    if (!self.stalePageKey) {
        // have no pages
       // NSLog(@"no current first page venues!");
        return;
    }
    if (!self.currentFirstPageUpdatedAt || [[NSDate dateWithTimeIntervalSince1970:self.currentFirstPageUpdatedAt] timeIntervalSince1970] <= REFRESH_FIRST_PAGE_EVERY) {
        return;
    }
    
    //is location available to fetch nearby venues?
    if ([CLLocationManager locationServicesEnabled] &&
        ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse)) {
        
        __weak typeof(self)weakSelf = self;
        
        [[LocationManager sharedInstance] getCurrentLocationWithResultCallback:^(double gpsLat, double gpsLong) {
            
            [[MeetManager sharedInstance] checkForFreshFirstPageNearbyFeaturedMemoryAndVenueGridWithStalePageKey:self.stalePageKey latitude:gpsLat longitude:gpsLong resultCallback:^(BOOL firstPageIsStale) {
                __strong typeof(weakSelf)strongSelf = weakSelf;
                if (!strongSelf) {
                    return ;
                }
                
                self.firstPageRefreshedAt = [NSDate date].timeIntervalSince1970;
                
                if (firstPageIsStale) {
                    NSLog(@"nearby grid is stale");
                    self.gridFirstPageContentIsStale = YES;
                }
                else {
                    //NSLog(@"nearby grid still fresh");
                }
            } faultCallback:^(NSError *fault) {
                __strong typeof(weakSelf)strongSelf = weakSelf;
                if (!strongSelf) {
                    return ;
                }
            }];
        } faultCallback:^(NSError *fault) {
            __strong typeof(weakSelf)strongSelf = weakSelf;
            if (!strongSelf) {
                return ;
            }
         
        }];
    }
}

- (void)refreshNearbyGridContentFirstPage {
    //NSLog(@"refreshNearbyGridContentFirstPage");
    
    self.refreshOngoing = YES;
    
    //is location available to fetch nearby venues?
    if ([CLLocationManager locationServicesEnabled] &&
        ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse)) {
        
        __weak typeof(self)weakSelf = self;
        
        [[LocationManager sharedInstance] getCurrentLocationWithResultCallback:^(double gpsLat, double gpsLong) {
            [[MeetManager sharedInstance] fetchNearbyFeaturedMemoryAndVenueGridPageWithPageKey:nil latitude:gpsLat longitude:gpsLong resultCallback:^(NSArray *memories, NSArray *people, NSString *nextPageKey, NSString *stalePageKey) {
                //Memory *firstMem = memories[0];
                //NSLog(@"first page refresh: first memory is %d %s at %s with text %s", firstMem.recordID, firstMem.key, firstMem.venue.displayName, firstMem.text);
                __strong typeof(weakSelf)strongSelf = weakSelf;
                
                strongSelf.firstPageRefreshedAt = [NSDate date].timeIntervalSince1970;
                strongSelf.refreshOngoing = NO;
                strongSelf.stalePageKey = stalePageKey;
                
                strongSelf.pendingFirstPageMemories = memories;
                strongSelf.pendingFirstPagePeople = people;
                strongSelf.pendingFirstPageNextPageKey = nextPageKey;
                strongSelf.pendingFirstPageVenuesAreNew = YES;
                
                [strongSelf updateToPendingFirstPage];
                
                [strongSelf refreshMontageContentIfNeeded];
            } faultCallback:^(NSError *fault) {
                __strong typeof(weakSelf)strongSelf = weakSelf;
                strongSelf.refreshOngoing = NO;
            }];
        } faultCallback:^(NSError *fault) {
            __strong typeof(weakSelf)strongSelf = weakSelf;
            strongSelf.refreshOngoing = NO;
        }];
    }
}



-(void)whenScrollingHasStoppedUpdateNearbyGridWithMemoriesAndVenues:(NSDictionary *)dictionary {
    [self whenScrollingHasStoppedUpdateNearbyGridWithMemories:dictionary[@"memories"] venues:dictionary[@"venues"] people:dictionary[@"people"]];
}


-(void)whenScrollingHasStoppedUpdateNearbyGridWithMemories:(NSArray *)memories venues:(NSArray *)venues people:(NSArray *)people {
    
    if (!self.collectionView.isDecelerating && !self.collectionView.isDragging) {
        
        NSLog(@"user has stopped scrolling, it's safe to insert our new local cells!");
        
        self.fetchOngoing = NO;
        self.spinner.hidden = YES;
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(nearbyContentComplete)]) {
            //NSLog(@"nearby next page complete!");
            [self.delegate nearbyContentComplete];
        }
        
        
        [self addMemoriesForPrefetching:memories];
        [self addVenuesForPrefetching:venues];
        [self addPeopleForPrefetching:people];
        [self prefetchNextAsset];
        
        NSInteger lastRow = self.cellCount;
        [self extendGridItemsWithMemories:memories locations:venues people:people];
        
        NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:(self.gridItems.count - lastRow)];
        for (NSInteger i = lastRow; i < self.gridItems.count; i++) {
            [indexPaths addObject:[NSIndexPath indexPathForItem:i inSection:0]];
        }
        [self.collectionView insertItemsAtIndexPaths:indexPaths];
        
        if (!self.nextPageKey) {
            //adjust to eliminate footer
            self.footerHeight = 0;
            [self.collectionView performBatchUpdates:^{
                UICollectionViewFlowLayout* flowLayout = (UICollectionViewFlowLayout*) self.collectionView.collectionViewLayout;
                flowLayout.footerReferenceSize = CGSizeMake(self.bounds.size.width, 0);
            } completion:^(BOOL done) {
                if (done) {
                }
            }];
        }
        else {
            [self restoreFooterIfNeeded];
        }
    }
    else {
        NSLog(@"hold on our update to the local cells, user is still scrolling..");
        [self performSelector:@selector(whenScrollingHasStoppedUpdateNearbyGridWithMemoriesAndVenues:) withObject:@{@"memories": memories ? memories : @[], @"venues": venues ? venues : @[], @"people": people ? people : @[]} afterDelay:.3];
    }
}

// Hash Grid
- (void)fetchContentForHash:(NSString *)hashTag memory:(Memory *)fallbackMem {
   
    self.currHash = hashTag;
    self.fallbackHashMem = fallbackMem;
    self.currGridState = GridStateHash;
    
    //NSLog(@"fetch content for hash tag %@",hashTag);
    //NSLog(@"curr grid state %li",self.currGridState);
    
    
    
    __weak typeof(self)weakSelf = self;
    
    if (self.fetchOngoing == YES) {
        return;
    }
    
    self.fetchOngoing = YES;
    
    [[MeetManager sharedInstance] fetchGridPageForHashTag:hashTag
                                              withPageKey:nil
                                        completionHandler:^(NSArray *gridVenues, NSString *nextPageKey) {
                                                     __strong typeof(weakSelf)strongSelf = weakSelf;
                                                     
                                                     //NSLog(@"next page key? %@",nextPageKey);
                                                     
                                                     //NSLog(@"grid content %@",gridVenues);
                                            
                                                     BOOL changed = ![strongSelf venueList:gridVenues isEquivalentTo:strongSelf.venues];
                                                     strongSelf.gridContentIsNearby = NO;
                                                     strongSelf.memories = nil;
                                            
                                                    NSMutableArray *tempArray = [NSMutableArray arrayWithArray:gridVenues];
                                                    if (tempArray.count % 2) {
                                                        [tempArray removeLastObject];
                                                    }
                                            
                                                     strongSelf.venues = tempArray;
                                            
                                                    //make sure to set a lat/long for any fuzzed venues
                                            
                                                    for (int i = 0; i < strongSelf.venues.count; i++) {
                                                
                                                        Venue *hashVenue = strongSelf.venues[i];
                                                        
                                                        if (hashVenue.specificity >= SPCVenueIsReal) {
                                                            if (hashVenue.recentHashtagMemories.count > 0) {
                                                                Memory *hashMem = hashVenue.recentHashtagMemories[0];
                                                                hashVenue.latitude = hashMem.location.latitude;
                                                                hashVenue.longitude = hashMem.location.longitude;
                                                            }
                                                            if (hashVenue.specificity == SPCVenueIsFuzzedToNeighhborhood) {
                                                                hashVenue.customName = hashVenue.neighborhood;
                                                            }
                                                            if (hashVenue.specificity == SPCVenueIsFuzzedToCity) {
                                                                 hashVenue.customName = hashVenue.city;
                                                            }
                                                        }
                                                    }
                                            
                                            
                                                    if (strongSelf.venues.count == 0) {
                                                        
                                                        NSLog(@"fallback !");
                                                        
                                                        //add the venue from the mem that the user tapped on in the case that we have no mems/venues (pre-hashtag, hashtags)
                                                        NSMutableArray *tempArray = [[NSMutableArray alloc] init];
                                                        
                                                        
                                                        //handle fuzzed fallback
                                                        if (fallbackMem.venue.specificity >= SPCVenueIsReal) {
                                                            fallbackMem.venue.latitude = fallbackMem.location.latitude;
                                                            fallbackMem.venue.longitude = fallbackMem.location.longitude;
                                                            
                                                            if (fallbackMem.venue.specificity == SPCVenueIsFuzzedToNeighhborhood) {
                                                                fallbackMem.venue.customName = fallbackMem.venue.neighborhood;
                                                            }
                                                            if (fallbackMem.venue.specificity == SPCVenueIsFuzzedToCity) {
                                                                fallbackMem.venue.customName = fallbackMem.venue.city;
                                                            }
                                                        }
                                                        
                                                        
                                                        [tempArray addObject:fallbackMem.venue];
                                                        strongSelf.memories = nil;
                                                        strongSelf.venues = [NSArray arrayWithArray:tempArray];
                                                        
                                                    }
                                            
                                            
                                                     if (strongSelf.delegate && [strongSelf.delegate respondsToSelector:@selector(contentComplete)]) {
                                                        [strongSelf.delegate contentComplete];
                                                     }
                                            
                                                     if (strongSelf.venues.count < 6) {
                                                         
                                                         [self compileMemoriesForFeed];
                                                     }
                                                     else {
                                                     
                                                          
                                                         strongSelf.nextPageKey = nextPageKey;
                                                         strongSelf.venuesUpdatedAt = [[NSDate date] timeIntervalSince1970];
                                                         strongSelf.currentFirstPageUpdatedAt = strongSelf.venuesUpdatedAt;
                                                         if (changed) {
                                                             [strongSelf addVenuesForPrefetching:gridVenues];
                                                             [strongSelf prefetchNextAsset];
                                                             [strongSelf reloadData];
                                                         }
                                                         
                                                         strongSelf.fetchOngoing = NO;
                                                         
                                                         if (!nextPageKey) {
                                                             //adjust eliminate footer
                                                             strongSelf.footerHeight = 0;
                                                             [strongSelf.collectionView performBatchUpdates:^{
                                                                 UICollectionViewFlowLayout* flowLayout = (UICollectionViewFlowLayout*) strongSelf.collectionView.collectionViewLayout;
                                                                 flowLayout.footerReferenceSize = CGSizeMake(strongSelf.bounds.size.width, 0);
                                                             } completion:^(BOOL done) {
                                                                 if (done) {
                                                                     NSLog(@"footer gone!");
                                                                 }
                                                             }];
                                                         }
                                                     }
                                                     
                                                 } errorHandler:^(NSError *errror) {
                                                     //NSLog(@"error %@",errror);
                                                     __strong typeof(weakSelf)strongSelf = weakSelf;
                                                     strongSelf.fetchOngoing = NO;
                                                     
                                                     
                                                     //add the venue from the mem that the user tapped on
                                                     NSMutableArray *tempArray = [[NSMutableArray alloc] init];
                                                     
                                                     //handle fuzzed fallback
                                                     if (fallbackMem.venue.specificity >= SPCVenueIsReal) {
                                                         fallbackMem.venue.latitude = fallbackMem.location.latitude;
                                                         fallbackMem.venue.longitude = fallbackMem.location.longitude;
                                                         
                                                         if (fallbackMem.venue.specificity == SPCVenueIsFuzzedToNeighhborhood) {
                                                             fallbackMem.venue.customName = fallbackMem.venue.neighborhood;
                                                         }
                                                         if (fallbackMem.venue.specificity == SPCVenueIsFuzzedToCity) {
                                                             fallbackMem.venue.customName = fallbackMem.venue.city;
                                                         }
                                                     }
                                                     
                                                     [tempArray addObject:fallbackMem.venue];
                                                     strongSelf.memories = nil;
                                                     strongSelf.venues = [NSArray arrayWithArray:tempArray];
                                                     if (strongSelf.delegate && [strongSelf.delegate respondsToSelector:@selector(contentComplete)]) {
                                                         [strongSelf.delegate contentComplete];
                                                     }
                                                     [self compileMemoriesForFeed];
                                                     
                                                 }];
    
    
}

- (void)fetchHashContentNextPage {
    //NSLog(@"fetchHashContentNextPage %@",self.currHash);

    __weak typeof(self)weakSelf = self;
    
    if (self.fetchOngoing == YES) {
        return;
    }
    
    self.fetchOngoing = YES;
    self.spinner.hidden = NO;
    
    [[MeetManager sharedInstance] fetchGridPageForHashTag:self.currHash
                                              withPageKey:self.nextPageKey
                                        completionHandler:^(NSArray *gridVenues, NSString *nextPageKey) {
                                            __strong typeof(weakSelf)strongSelf = weakSelf;
                                            
                                            //NSLog(@"next page key? %@",nextPageKey);
                                            
                                            //NSLog(@"grid content %@",gridVenues);
                                          
                                            
                                            strongSelf.nextPageKey = nextPageKey;
                                            
                                            //NSLog(@"grid page %@\nnext page key %@",venues,nextPageKey);
                                            strongSelf.spinner.hidden = YES;
                                            strongSelf.fetchOngoing = NO;
                                            
                                            if (gridVenues.count > 0) {
                                                int lastRow = (int)strongSelf.venues.count;
                                                
                                                NSMutableArray *array = [NSMutableArray arrayWithArray:strongSelf.venues];
                                                [array addObjectsFromArray:gridVenues];
                                                
                                                // - Requirement: always display an even number of venues in the grids..
                                                int newVenuesCount = (int)gridVenues.count;
                                                
                                                if (array.count % 2) {
                                                    [array removeLastObject];
                                                    newVenuesCount = newVenuesCount - 1;
                                                }
                                                strongSelf.memories = nil;
                                                strongSelf.venues = [NSArray arrayWithArray:array];
                                                
                                                
                                                //handle fuzzing as necessary for map
                                                for (int i = 0; i < strongSelf.venues.count; i++) {
                                                    
                                                    Venue *hashVenue = strongSelf.venues[i];
                                                    
                                                    if (hashVenue.specificity >= SPCVenueIsReal) {
                                                        if (hashVenue.recentHashtagMemories.count > 0) {
                                                            Memory *hashMem = hashVenue.recentHashtagMemories[0];
                                                            hashVenue.latitude = hashMem.location.latitude;
                                                            hashVenue.longitude = hashMem.location.longitude;
                                                        }
                                                        if (hashVenue.specificity == SPCVenueIsFuzzedToNeighhborhood) {
                                                            hashVenue.customName = hashVenue.neighborhood;
                                                        }
                                                        if (hashVenue.specificity == SPCVenueIsFuzzedToCity) {
                                                            hashVenue.customName = hashVenue.city;
                                                        }
                                                    }
                                                }
                                                
                                                
                                                [strongSelf addVenuesForPrefetching:gridVenues];
                                                [strongSelf prefetchNextAsset];
                                                
                                                [self extendGridItemsWithMemories:nil locations:strongSelf.venues people:nil];
                                                
                                                NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:(self.gridItems.count - lastRow)];
                                                
                                                for (int i = lastRow; i < self.gridItems.count; i++) {
                                                        [indexPaths addObject:[NSIndexPath indexPathForItem:i inSection:0]];
                                                }
                                                [strongSelf.collectionView insertItemsAtIndexPaths:indexPaths];
                                            }
                                            
                                            if (strongSelf.delegate && [strongSelf.delegate respondsToSelector:@selector(contentComplete)]) {
                                                [strongSelf.delegate contentComplete];
                                            }
                                            
                                            if (!nextPageKey) {
                                                //adjust to eliminate footer
                                                //NSLog(@"no next page key, footer gone?");
                                                strongSelf.footerHeight = 0;
                                                [strongSelf.collectionView performBatchUpdates:^{
                                                    UICollectionViewFlowLayout* flowLayout = (UICollectionViewFlowLayout*) strongSelf.collectionView.collectionViewLayout;
                                                    flowLayout.footerReferenceSize = CGSizeMake(strongSelf.bounds.size.width, 0);
                                                } completion:^(BOOL done) {
                                                    if (done) {
                                                    }
                                                }];
                                            }
                                            
                                        } errorHandler:^(NSError *errror) {
                                            //NSLog(@"error %@",errror);
                                            __strong typeof(weakSelf)strongSelf = weakSelf;
                                            strongSelf.fetchOngoing = NO;
                                        }];
    
    
}

- (void)compileMemoriesForFeed {
    
    NSMutableArray *tempArray = [[NSMutableArray alloc] init];
    
    
    for (int i = 0; i < self.venues.count; i++) {
        
        Venue *tempVenue = self.venues[i];
        NSArray *hashMems = tempVenue.recentHashtagMemories;
        
        for (int j = 0; j < hashMems.count; j++) {
            [tempArray addObject:hashMems[j]];
        }
    }
    if (tempArray.count == 0) {
        [tempArray addObject:self.fallbackHashMem];
    }
    
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(showFeedForMemories:)]) {
        [self.delegate showFeedForMemories:tempArray];
    }
}


- (void)fetchNextPage {
   
    //NSLog(@"fetch next page and curr grid state %li",self.currGridState);
    self.spinner.hidden = NO;

    //hold until user has stopped scrolling!
    if (!self.collectionView.isDecelerating && !self.collectionView.isDragging && !self.fetchOngoing) {
        NSLog(@"clear to fetch next page");
        self.fetchPendingScrollingStop = NO;
        
        if (self.currGridState == GridStateLocal) {
            [self fetchNearbyGridContentNextPage];
        }
        else if (self.currGridState == GridStateWorld) {
            [self fetchGridContentNextPage];
        }
        else if (self.currGridState == GridStateHash) {
            [self fetchHashContentNextPage];
        }
    }
    else {
        NSLog(@"hold on fetching next page..user is scrolling...");
        if (!self.fetchOngoing) {
            [self performSelector:@selector(fetchNextPage) withObject:nil afterDelay:.5];
        } else {
            self.fetchPendingScrollingStop = NO;
        }
    }
}


- (void)checkFirstPageFreshness {
    if (self.currentFirstPageUpdatedAt && self.viewIsVisible && self.stalePageKey && [[NSDate dateWithTimeIntervalSince1970:self.currentFirstPageUpdatedAt] timeIntervalSince1970] > REFRESH_FIRST_PAGE_EVERY) {
        if (self.currGridState == GridStateLocal) {
            //NSLog(@"checking first local page for freshness...");
            [self checkNearbyGridContentFirstPageForFreshness];
        } else if (self.currGridState == GridStateWorld) {
            //NSLog(@"checking first global page for freshness...");
            [self checkGridContentFirstPageForFreshness];
        }
    }
}

- (void)refreshFirstPage {
    //scroll to top
    self.gridFirstPageContentIsStale = NO;
    [self scrollToTop];
    
    //animate out button
    self.newMemoriesButton.enabled = NO;
    [UIView animateWithDuration:0.4 animations:^{
        self.newMemoriesButton.alpha = 0;
    } completion:^(BOOL finished) {
        self.newMemoriesButton.hidden = YES;
    }];

    //fetch the fresh content
    if (self.currGridState == GridStateLocal) {
        [self refreshNearbyGridContentFirstPage];
    } else if (self.currGridState == GridStateWorld) {
        [self refreshGridContentFirstPage];
    }
}

-(void)reloadData {
    //NSLog(@"reloadData with %d memories, %d venues, %d people", self.memories.count, self.venues.count, self.people.count);
    self.gridItems = nil;
    self.gridItemMemoryCount = 0;
    self.gridItemVenueCount = 0;
    self.gridItemPersonCount = 0;
    self.gridItemConsecutiveCellRows = 0;
    [self extendGridItemsIfPossible];
    //NSLog(@"extended to %d items", self.gridItems.count);
    
    [self.collectionView reloadData];
    
    if (self.isLocalSelected) {
        [self.collectionView setContentInset:UIEdgeInsetsMake(-1 * self.baseOffSetY, 0, 0, 0)];
        
        float bottomInset = 45;
        
        if (self.cellCount > 6) {
                bottomInset = 0;
        }

        [self.collectionView setContentInset:UIEdgeInsetsMake(-1 * self.baseOffSetY, 0, bottomInset, 0)];
        [self.collectionView setContentOffset:CGPointMake(0, self.baseOffSetY) animated:NO];
    }
    else {
        [self.collectionView setContentInset:UIEdgeInsetsMake(-1 * self.baseOffSetY, 0, 0, 0)];
        [self.collectionView setContentOffset:CGPointMake(0, self.baseOffSetY) animated:NO];
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(restoreGridHeadersAndFooters)]) {
        [self.delegate restoreGridHeadersAndFooters];
    }
     
    //NSLog(@"done with reloadData");
}

-(void)gridDidAppear {
 
    [self resetCyclingImages];
    self.venuesUpdatedAt = [[NSDate date] timeIntervalSince1970];
    if (!self.viewIsVisible) {
        self.prefetchPaused = NO;
        [self prefetchNextAsset];
        self.viewIsVisible = YES;
        self.cycleImageTimer = [NSTimer scheduledTimerWithTimeInterval:CYCLE_IMAGE_EVERY target:self selector:@selector(cycleImage) userInfo:nil repeats:YES];
        self.refreshTimer = [NSTimer scheduledTimerWithTimeInterval:REFRESH_FIRST_PAGE_EVERY+4 target:self selector:@selector(checkFirstPageFreshness) userInfo:nil repeats:YES];
        
        // check for freshness of first page now?
        if (self.currentFirstPageUpdatedAt && self.stalePageKey && [[NSDate dateWithTimeIntervalSince1970:self.currentFirstPageUpdatedAt] timeIntervalSince1970] > REFRESH_FIRST_PAGE_EVERY) {
            [self checkFirstPageFreshness];
        }
    }
}

-(void)gridDidDisappear {
    if (self.viewIsVisible) {
        self.prefetchPaused = YES;
        self.viewIsVisible = NO;
        [self.cycleImageTimer invalidate];
        [self.refreshTimer invalidate];
    }
}

-(void) cycleImage {
    if (!self.viewIsVisible) {
        return;
    }
    
    if (self.venuesUpdatedAt + FIRST_IMAGE_CYCLE_AFTER_AT_LEAST > [[NSDate date] timeIntervalSince1970]) {
        return;
    }
    
    SPCTrendingVenueCell * cell;
    
    //get the currenlty visible cells and sort them by index path
    // (not done by default for some odd reason..thx cupertino..)
    NSArray *indexPathsOfVisibleCells = [self.collectionView indexPathsForVisibleItems];
    NSArray *sortedIndexPaths = [indexPathsOfVisibleCells sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSIndexPath *path1 = (NSIndexPath *)obj1;
        NSIndexPath *path2 = (NSIndexPath *)obj2;
        return [path1 compare:path2];
    }];
    
    
    //get index paths for the animatable, visible cells
    NSMutableArray *sortedArray = [[NSMutableArray alloc] init];
    for (int i = 0; i < sortedIndexPaths.count; i++) {
        UICollectionViewCell *genericCell = [self.collectionView cellForItemAtIndexPath:sortedIndexPaths[i]];
        if ([genericCell isKindOfClass:[SPCTrendingVenueCell class]]) {
            cell = (SPCTrendingVenueCell *)genericCell;
            
            if ([cell canAnimateCell]) {
                [sortedArray addObject:sortedIndexPaths[i]];
            }
        }
    }
    
    //loop through animatable, visible cells, looking for next one to animate
    for (int i = 0; i < sortedArray.count; i++) {
        
        cell = (SPCTrendingVenueCell *)[self.collectionView cellForItemAtIndexPath:sortedArray[i]];
        
        //did we recently animate this cell?
        BOOL justCycled = NO;
        NSString *tagStr = [NSString stringWithFormat:@"%@",@(cell.tag)];
        
        for (int j = 0; j < self.cycleCells.count; j++) {
            NSString *recentlyCycled = self.cycleCells[j];
            if ([recentlyCycled isEqualToString:tagStr]) {
                justCycled = YES;
                break;
            }
        }

        if (!justCycled) {
            if ([cell cycleImageAnimated:YES]) {
                [self.cycleCells addObject:tagStr];
                
                //clear list of recently cycled cells
                if (self.cycleCells.count >= sortedArray.count) {
                    [self.cycleCells removeAllObjects];
                }
                break;
            }
        }
    }
}

-(void)resetCyclingImages {
    
    [self.cycleCells removeAllObjects];
    
    SPCTrendingVenueCell * cell;
    
    //get the currenlty visible cells and sort them by index path
    // (not done by default for some odd reason..thx cupertino..)
    NSArray *indexPathsOfVisibleCells = [self.collectionView indexPathsForVisibleItems];
    NSArray *sortedIndexPaths = [indexPathsOfVisibleCells sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSIndexPath *path1 = (NSIndexPath *)obj1;
        NSIndexPath *path2 = (NSIndexPath *)obj2;
        return [path1 compare:path2];
    }];
    
    
    //reset the visible cells
    for (int i = 0; i < sortedIndexPaths.count; i++) {
        UICollectionViewCell *genericCell = [self.collectionView cellForItemAtIndexPath:sortedIndexPaths[i]];
        if ([genericCell isKindOfClass:[SPCTrendingVenueCell class]]) {
            cell = (SPCTrendingVenueCell *)genericCell;
            [cell resetCycleImage];
        }
    }
}

-(BOOL) memoryList:(NSArray *)memoryList1 isEquivalentTo:(NSArray *)memoryList2 {
    BOOL same = memoryList1.count == memoryList2.count;
    for (int i = 0; i < memoryList1.count && same; i++) {
        same = same && [SPCTrendingVenueCell memory:memoryList1[i] isEquivalentTo:memoryList2[i]];
    }
    return same;
}

-(BOOL) venueList:(NSArray *)venueList1 isEquivalentTo:(NSArray *)venueList2 {
    BOOL same = venueList1.count == venueList2.count;
    for (int i = 0; i < venueList1.count && same; i++) {
        same = same && [SPCTrendingVenueCell venue:venueList1[i] isEquivalentTo:venueList2[i]];
    }
    return same;
}


-(BOOL) personList:(NSArray *)personList1 isEquivalentTo:(NSArray *)personList2 {
    BOOL same = personList1.count == personList2.count;
    for (int i = 0; i < personList1.count && same; i++) {
        same = same && [((Person *)personList1[i]).userToken isEqualToString:((Person *)personList2[i]).userToken];
    }
    return same;
}

-(BOOL) firstVenuePage:(NSArray *)firstVenuePage hasVenuesNotPresentInPreviousFirstVenuePage:(NSArray *)previousFirstVenuePage {
    // star count / memory counts may have updated.  We don't care about that.
    // We care about whether the results have CHANGED in a significant way --
    // are there results that don't appear?  If they do appear, have they been bumped?
    for (int i = 0; i < firstVenuePage.count; i++) {
        Venue *venue = firstVenuePage[i];
        BOOL hasMatch = NO;
        
        // first: it is most likely the case that this result occurs in the same spot.
        if (i < previousFirstVenuePage.count) {
            Venue *venue2 = previousFirstVenuePage[i];
            if (venue.addressId == venue2.addressId && ((!venue.featuredTime && !venue2.featuredTime) || [venue.featuredTime isEqualToDate:venue2.featuredTime])) {
                hasMatch = YES;
            }
        }
        
        for (int j = 0; j < previousFirstVenuePage.count && !hasMatch; j++) {
            Venue *venue2 = previousFirstVenuePage[j];
            if (venue.addressId == venue2.addressId && ((!venue.featuredTime && !venue2.featuredTime) || [venue.featuredTime isEqualToDate:venue2.featuredTime])) {
                hasMatch = YES;
            }
        }
        
        if (!hasMatch) {
            return YES;
        }
    }
    
    return NO;
}

- (void)setBaseContentOffset:(float)baseOffsetY {

    self.baseOffSetY = baseOffsetY;
    self.changedDirectionAtOffSetY = self.baseOffSetY;
    
    //we begin to animate the containing vc & tab bar when we've moved more than our trigger distances
    float cellHeight = (self.collectionView.frame.size.width/2.0f - 1.0f);

    self.triggerUpDelta = ceilf(cellHeight * .25);
    self.triggerDownDelta = ceilf(cellHeight * .2);
}

- (void)resetScrollingAdjustment {
    self.changedDirectionAtOffSetY = self.collectionView.contentOffset.y;
}

-(void)showLocationPrompt:(id)sender {
    
    BOOL hasShownSystemPrompt = [[NSUserDefaults standardUserDefaults] boolForKey:@"systemHasShownLocationPrompts"];
    
    if (!hasShownSystemPrompt && [CLLocationManager locationServicesEnabled]) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"systemHasShownLocationPrompts"];
        [[LocationManager sharedInstance] requestSystemAuthorization];
    }
    else if (!hasShownSystemPrompt && ![CLLocationManager locationServicesEnabled]) {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"\"Spayce\" Would Like to Use Your Current Location", nil)
                                    message:NSLocalizedString(@"Please go to Settings > Privacy and enable Location Services", nil)
                                   delegate:nil
                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                          otherButtonTitles:nil] show];
    }
    else {
        
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"\"Spayce\" Would Like to Use Your Current Location", nil)
                                    message:NSLocalizedString(@"Please go to Settings > Privacy and enable Location Services for the \"Spayce\" app", nil)
                                   delegate:nil
                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                          otherButtonTitles:nil] show];
    }
}

-(float)headerHeight {
    // previously we used a header to indicate that location was off
    return 0;
}

-(void)configureHashBGColors {
    
    NSMutableArray *testArray = [[NSMutableArray alloc] init];
    [testArray addObject:[UIColor colorWithRed:150.0f/255.0f green:200.0f/255.0f blue:252.0f/255.0f alpha:1.0f]];
    [testArray addObject:[UIColor colorWithRed:128.0f/255.0f green:189.0f/255.0f blue:252.0f/255.0f alpha:1.0f]];
    [testArray addObject:[UIColor colorWithRed:77.0f/255.0f green:158.0f/255.0f blue:244.0f/255.0f alpha:1.0f]];
    [testArray addObject:[UIColor colorWithRed:49.0f/255.0f green:140.0f/255.0f blue:236.0f/255.0f alpha:1.0f]];
    [testArray addObject:[UIColor colorWithRed:7.0f/255.0f green:106.0f/255.0f blue:209.0f/255.0f alpha:1.0f]];
    [testArray addObject:[UIColor colorWithRed:4.0f/255.0f green:93.0f/255.0f blue:185.0f/255.0f alpha:1.0f]];
    [testArray addObject:[UIColor colorWithRed:13.0f/255.0f green:85.0f/255.0f blue:158.0f/255.0f alpha:1.0f]];
    [testArray addObject:[UIColor colorWithRed:3.0f/255.0f green:71.0f/255.0f blue:140.0f/255.0f alpha:1.0f]];
 
    self.hashTextCellBgColors = [NSArray arrayWithArray:testArray];
}

-(void)restoreFooterIfNeeded {
    
    UICollectionViewFlowLayout* flowLayout = (UICollectionViewFlowLayout*) self.collectionView.collectionViewLayout;
   
    if (flowLayout.footerReferenceSize.height == 0) {
    
        self.footerHeight = 50;
        [self.collectionView performBatchUpdates:^{
            UICollectionViewFlowLayout* flowLayout = (UICollectionViewFlowLayout*) self.collectionView.collectionViewLayout;
            flowLayout.footerReferenceSize = CGSizeMake(self.bounds.size.width,50);
        } completion:^(BOOL done) {
            if (done) {
                //NSLog(@"footer restored!");
            }
        }];
    }
}

#pragma mark - Prefetching images

- (void)addMemoriesForPrefetching:(NSArray *)memories {
    NSMutableArray *tempArray = [NSMutableArray arrayWithArray:self.prefetchAssetQueue];
    for (Memory *memory in memories) {
        Asset *asset = [self assetForMemory:memory];
        if (asset) {
            [tempArray addObject:asset];
        }
    }
    self.prefetchAssetQueue = [NSArray arrayWithArray:tempArray];
}

- (void)addVenuesForPrefetching:(NSArray *)venues {
    NSMutableArray *tempArray = [NSMutableArray arrayWithArray:self.prefetchAssetQueue];
    for (Venue *venue in venues) {
        Asset *asset = [self assetForVenue:venue];
        if (asset) {
            [tempArray addObject:asset];
        }
    }
    self.prefetchAssetQueue = [NSArray arrayWithArray:tempArray];
}

- (void)addPeopleForPrefetching:(NSArray *)people {
    // TODO
}

- (Asset *)assetForMemory:(Memory *)memory {
    // attempt a memory first...
    if ([memory isKindOfClass:[ImageMemory class]]) {
        ImageMemory *imageMemory = (ImageMemory *)memory;
        if (imageMemory.images.count > 0) {
            return imageMemory.images[0];
        }
    } else if ([memory isKindOfClass:[VideoMemory class]]) {
        //NSLog(@"VIDeo mem?");
        VideoMemory *videoMemory = (VideoMemory *)memory;
        if (videoMemory.previewImages.count > 0) {
            return videoMemory.previewImages[0];
        }
    }
    
    return memory.locationMainPhotoAsset;
}

- (Asset *)assetForVenue:(Venue *)venue {
    // attempt a memory first...
    if (venue.popularMemories.count > 0) {
        for (Memory *memory in venue.popularMemories) {
            if ([memory isKindOfClass:[ImageMemory class]]) {
                ImageMemory *imageMemory = (ImageMemory *)memory;
                if (imageMemory.images.count > 0) {
                    return imageMemory.images[0];
                }
            } else if ([memory isKindOfClass:[VideoMemory class]]) {
                //NSLog(@"VIDeo mem?");
                VideoMemory *videoMemory = (VideoMemory *)memory;
                if (videoMemory.previewImages.count > 0) {
                    return videoMemory.previewImages[0];
                }
            }
        }
    }
    
    return venue.imageAsset;
}

- (void)prefetchNextAsset {
    [self prefetchNextAssetWithRetryCount:0];
}

- (void)prefetchNextAssetWithRetryCount:(int)retryCount {
    static int MAX_FETCH_RETRY_COUNT = 10; // Maximum number of fetch attempts prior to quitting
    
    if (self.prefetchPaused || self.prefetchOngoing) {
        return;
    }
    
    NSMutableArray *assets = [NSMutableArray arrayWithArray:self.prefetchAssetQueue];
    if (assets.count > 0) {
        Asset *asset = assets[0];
        [assets removeObjectAtIndex:0];
        self.prefetchAssetQueue = [NSArray arrayWithArray:assets];
        
        BOOL imageIsCached = NO;
        
        NSString *imageUrlStr = asset.imageUrlHalfSquare;
        if ([[SDWebImageManager sharedManager] cachedImageExistsForURL:[NSURL URLWithString:imageUrlStr]]) {
            imageIsCached = YES;
        }
        if ([[SDWebImageManager sharedManager] diskImageExistsForURL:[NSURL URLWithString:imageUrlStr]]) {
            imageIsCached = YES;
        }
        
        if (!imageIsCached && MAX_FETCH_RETRY_COUNT > retryCount) {
            self.prefetchOngoing = YES;
            [self.prefetchImageView sd_cancelCurrentImageLoad];
            [self.prefetchImageView sd_setImageWithURL:[NSURL URLWithString:imageUrlStr]
                                      placeholderImage:[UIImage imageNamed:@"placeholder-gray"]
                                             completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                                 if (image) {
                                                     self.prefetchOngoing = NO;
                                                     [self prefetchNextAsset];
                                                 } else {
                                                     self.prefetchOngoing = NO;
                                                     NSMutableArray *tempArray = [NSMutableArray arrayWithArray:self.prefetchAssetQueue];
                                                     [tempArray insertObject:asset atIndex:0];
                                                     self.prefetchAssetQueue = [NSArray arrayWithArray:tempArray];
                                                     [self prefetchNextAssetWithRetryCount:(retryCount + 1)];
                                                 }
                                             }];
        }
        else {
            [self prefetchNextAsset];
        }
    }
}

- (void)refreshMontageContentIfNeeded {
    // Cancel previous requests to refresh
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(refreshMontageContentIfNeeded) object:nil];
    
    if ((GridStateLocal == self.currGridState || GridStateWorld == self.currGridState)) {
        // If we ERROR out, make sure to call this method again after a delay
        // Otherwise, if we ARE stale, or have not yet fetched memories, the fetchMontageNearby/WorldContent methods will call this method again automatically
        
        // Grab a weak ref
        __weak typeof(self) weakSelf = self;
        if (GridStateWorld == self.currGridState) {
            [self fetchMontageWorldContent];
        } else if (GridStateLocal == self.currGridState) {
            [[LocationManager sharedInstance] getCurrentLocationWithResultCallback:^(double gpsLat, double gpsLong) {
                __strong typeof(weakSelf) strongSelf = weakSelf;
                
                [strongSelf fetchMontageNearbyContentWithLatitude:gpsLat andLongitude:gpsLong];
            } faultCallback:^(NSError *fault) {
                __strong typeof(weakSelf) strongSelf = weakSelf;
                
                [strongSelf performSelector:@selector(refreshMontageContentIfNeeded) withObject:nil afterDelay:MONTAGE_REFRESH_INTERVAL];
            }];
        }
    } else {
        // Maybe
        [self performSelector:@selector(refreshMontageContentIfNeeded) withObject:nil afterDelay:MONTAGE_REFRESH_INTERVAL];
    }
}


- (void)scrollToTop {
    if (self.collectionView.contentOffset.y == self.baseOffSetY) {
        //do nothing!
    }
    else {
        self.autoScrollInProgress = YES;
        [self.collectionView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
    }
}


- (void)updateToPendingFirstPage {
    //NSLog(@"update to pending first page with memories %d, venues %d, people %d", self.pendingFirstPageMemories.count, self.pendingFirstPageVenues.count, self.pendingFirstPagePeople.count);
    if (self.pendingFirstPageMemories.count || self.pendingFirstPageVenues.count || self.pendingFirstPagePeople.count) {
        self.memories = self.pendingFirstPageMemories;
        self.venues = self.pendingFirstPageVenues;
        self.people = self.pendingFirstPagePeople;
        self.nextPageKey = self.pendingFirstPageNextPageKey;
        self.venuesUpdatedAt = self.firstPageRefreshedAt;
        self.currentFirstPageUpdatedAt = self.venuesUpdatedAt;
        self.pendingFirstPageVenues = nil;
        self.pendingFirstPageMemories = nil;
        self.pendingFirstPagePeople = nil;
        self.pendingFirstPageNextPageKey = nil;
        self.pendingFirstPageVenuesAreNew = NO;
        
        [self addMemoriesForPrefetching:self.memories];
        [self addVenuesForPrefetching:self.venues];
        [self addPeopleForPrefetching:self.people];
        [self prefetchNextAsset];
        [self reloadData];
        
        //adjust footer
        if (self.nextPageKey) {
            [self restoreFooterIfNeeded];
        } else {
            self.footerHeight = 0;
            [self.collectionView performBatchUpdates:^{
                UICollectionViewFlowLayout* flowLayout = (UICollectionViewFlowLayout*) self.collectionView.collectionViewLayout;
                flowLayout.footerReferenceSize = CGSizeMake(self.bounds.size.width, self.nextPageKey ? 50 : 0);
            } completion:^(BOOL done) {
                if (done) {
                    //NSLog(@"footer adjusted!");
                }
            }];
        }
    }
    
    self.pendingFirstPageVenuesAreNew = NO;
    if (self.newMemoriesButton.enabled) {
        self.newMemoriesButton.enabled = NO;
        [UIView animateWithDuration:0.4 animations:^{
            self.newMemoriesButton.alpha = 0;
        } completion:^(BOOL finished) {
            self.newMemoriesButton.hidden = YES;
        }];
    }
}



#pragma mark - UIScrollViewDelegate

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    self.draggingScrollView = YES;
    self.directionSetForThisDrag = NO;
    self.userHasEndedDrag = NO;
    self.autoScrollInProgress = NO;
}

-(void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    self.userHasEndedDrag = YES;
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    self.userHasEndedDrag = YES;
    self.draggingScrollView = NO;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(gridDragEnded:willDecelerate:)]) {
        if (self.viewIsVisible){
            [self.delegate gridDragEnded:scrollView willDecelerate:decelerate];
        }
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    self.draggingScrollView = NO;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    /*
     // - Goal animate elements in containing view controllers based upon scroll movement
     
        Requirements:
        1. Hide elements when user has scrolled more than 25% of a cell upwards since last change in direction
        2. Show elements when user has scrolled more than 20% of a cell downwards since last change in direction
    */
     
    //User is scrolling up
    if (self.previousOffsetY < scrollView.contentOffset.y) {
        
        self.userHasBeenScrollingUp = YES;
        
        //are we sure we haven't overscrolled (i.e. pull to refresh)
        if (scrollView.contentOffset.y < self.baseOffSetY) {
            self.changedDirectionAtOffSetY = scrollView.contentOffset.y;
            return;
        }
        
        
        //discount initial scrolling 
        float headerHeight = [self headerHeight];
        
        if (scrollView.contentOffset.y < self.baseOffSetY + headerHeight) {
            self.changedDirectionAtOffSetY = scrollView.contentOffset.y;
            return;
        }
   
        
        
        //is this a change in direction?  If so, we need to note it
        if (!self.userHasBeenScrollingUp) {
            self.changedDirectionAtOffSetY = scrollView.contentOffset.y;
        }
        
        //user has released drag: note this, because any further directional changes are because the scroll view is bouncing and should be discarded
        if (self.userHasEndedDrag) {
            self.directionSetForThisDrag = YES;
        }
        
        //how far have we scrolled up since we changed directions?
        float deltaAdj = fabsf(self.changedDirectionAtOffSetY - scrollView.contentOffset.y);
        
        //is this far enough to matter?
        if (deltaAdj > self.triggerUpDelta) {
            
            //do we have enough content to bother?
            if (self.cellCount > 6) {
            
                //are we sure we haven't overscrolled (i.e. pull to refresh)
                if (scrollView.contentOffset.y >= self.baseOffSetY) {
                
                    //tell the delegate to adjust the view
                    float deltaToMoveViews = fabsf(scrollView.contentOffset.y - self.previousOffsetY);
                    if (self.delegate && [self.delegate respondsToSelector:@selector(scrollingUpAdjustViewsWithDelta:)]) {
                        if (self.viewIsVisible && !self.autoScrollInProgress) {
                            [self.delegate scrollingUpAdjustViewsWithDelta:deltaToMoveViews];
                        }
                    }
                }
            }
        }
    }
    //User is scrolling down
    else {

        //make sure we are not bouncing!
        if (!self.directionSetForThisDrag) {
        
            //is this a change in direction?  If so, we need to note it
            if (self.userHasBeenScrollingUp) {
                self.changedDirectionAtOffSetY = scrollView.contentOffset.y;
            }
            
            self.userHasBeenScrollingUp = NO;
            
            //how far have we scrolled down since we changed directions?
            float deltaAdj = fabsf(self.changedDirectionAtOffSetY - scrollView.contentOffset.y);
            
            //is this far enough to matter?
            if (deltaAdj > self.triggerDownDelta) {
            
                //do we have enough content to bother?
                if (self.cellCount > 6) {
                    
                    //tell the delegate to adjust the view
                    float deltaToMoveViews = fabsf(scrollView.contentOffset.y - self.previousOffsetY);
                    if (self.delegate && [self.delegate respondsToSelector:@selector(scrollingDownAdjustViewsWithDelta:)]) {
                        if (self.viewIsVisible && !self.autoScrollInProgress) {
                            [self.delegate scrollingDownAdjustViewsWithDelta:deltaToMoveViews];
                        }
                    }
                        
                }
            }
            else if (scrollView.contentOffset.y > self.baseOffSetY) {
               //do a fallback absolute position check to avoid the up/down/up down wiggle offset issue
                if (scrollView.contentOffset.y < 0) {
                    float deltaToMoveViews = fabsf(scrollView.contentOffset.y - self.previousOffsetY);
                    if (self.delegate && [self.delegate respondsToSelector:@selector(scrollingDownAdjustViewsWithDelta:)]) {
                        if (self.viewIsVisible && !self.autoScrollInProgress) {
                            [self.delegate scrollingDownAdjustViewsWithDelta:deltaToMoveViews];
                        }
                    }
                }
            }
        }
    }
    
    // New Memories button?
    if (self.previousOffsetY > scrollView.contentOffset.y) {
        // scrolling to the top...
        if (self.gridFirstPageContentIsStale) {
            if (!self.newMemoriesButton.enabled) {
                // show!
                self.newMemoriesButton.alpha = 0;
                self.newMemoriesButton.hidden = NO;
                self.newMemoriesButton.enabled = YES;
                [UIView animateWithDuration:0.4 animations:^{
                    self.newMemoriesButton.alpha = 1;
                }];
            }
        }
        self.newMemoriesHidePosition = scrollView.contentOffset.y + HIDE_NEW_MEMORIES_BUTTON_DISTANCE;
        
    } else if (self.previousOffsetY < scrollView.contentOffset.y && scrollView.contentOffset.y > 0 && scrollView.contentOffset.y >= self.newMemoriesHidePosition) {
        // scrolling to the bottom...
        if (self.newMemoriesButton.enabled) {
            self.newMemoriesButton.enabled = NO;
            [UIView animateWithDuration:0.4 animations:^{
                self.newMemoriesButton.alpha = 0;
            } completion:^(BOOL finished) {
                self.newMemoriesButton.hidden = YES;
            }];
        }
    } else if (self.previousOffsetY < scrollView.contentOffset.y && scrollView.contentOffset.y > 0 && scrollView.contentOffset.y + HIDE_NEW_MEMORIES_BUTTON_DISTANCE < self.newMemoriesHidePosition) {
        self.newMemoriesHidePosition = scrollView.contentOffset.y + HIDE_NEW_MEMORIES_BUTTON_DISTANCE;
    }
    
    self.previousOffsetY = scrollView.contentOffset.y;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(gridScrolled:)]) {
        if (self.viewIsVisible && !self.autoScrollInProgress) {
            [self.delegate gridScrolled:scrollView];
        }
    }
}

-(void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    if (self.delegate && [self.delegate respondsToSelector:@selector(restoreGridHeadersAndFooters)]) {
        if (scrollView.contentOffset.y == self.baseOffSetY) {
            if (!self.delegate.pullToRefreshInProgress) {
                NSLog(@"FIX OUR HEADER AFTER AUTOSCROLL WHEN UPDATING FIRST PAGE CONTENT");
                [self.delegate restoreGridHeadersAndFooters];
            }
        }
    }
}

#pragma mark - Local updates


- (void)didRequestFollowNotification:(NSNotification *)note {
    NSString *userToken = (NSString *)[note object];
    
    
    //update grid
    for (int i = 0; i < self.gridItems.count; i++) {
        SPCGridItem *item = self.gridItems[i];
        if (item.isMemory) {
            if ([item.memory.author.userToken isEqualToString:userToken]) {
                item.memory.author.followingStatus = FollowingStatusRequested;
            }
        }
    }
    
    //update montage
    NSMutableArray *montageMems = [NSMutableArray arrayWithArray:self.viewMontage.memories];
    BOOL needsToUpdate = NO;
    
    for (int i = 0; i < montageMems.count; i++) {
        Memory *montageMem = montageMems[i];
    
        if ([montageMem.author.userToken isEqualToString:userToken]) {
            montageMem.author.followingStatus = FollowingStatusRequested;
            needsToUpdate = YES;
        }
    }

    if (needsToUpdate) {
        NSArray *updatedMemories = [NSArray arrayWithArray:montageMems];
        BOOL needsToLoad = YES;
        [self.viewMontage updateWithMemories:updatedMemories withMontageNeedsLoadReturn:&needsToLoad];
        if (needsToLoad) {
            [self.collectionView.collectionViewLayout invalidateLayout];
        }
    }
}

- (void)didFollowNotification:(NSNotification *)note {
    NSString *userToken = (NSString *)[note object];
    
    //update grid
    for (int i = 0; i < self.gridItems.count; i++) {
        SPCGridItem *item = self.gridItems[i];
        if (item.isMemory) {
            if ([item.memory.author.userToken isEqualToString:userToken]) {
                item.memory.author.followingStatus = FollowingStatusFollowing;
            }
        }
    }
    
    //update montage
    NSMutableArray *montageMems = [NSMutableArray arrayWithArray:self.viewMontage.memories];
    BOOL needsToUpdate = NO;
    
    for (int i = 0; i < montageMems.count; i++) {
        Memory *montageMem = montageMems[i];
        
        if ([montageMem.author.userToken isEqualToString:userToken]) {
            montageMem.author.followingStatus = FollowingStatusFollowing;
            needsToUpdate = YES;
        }
    }
    
    if (needsToUpdate) {
        NSArray *updatedMemories = [NSArray arrayWithArray:montageMems];
        BOOL needsToLoad = YES;
        [self.viewMontage updateWithMemories:updatedMemories withMontageNeedsLoadReturn:&needsToLoad];
        if (needsToLoad) {
            [self.collectionView.collectionViewLayout invalidateLayout];
        }
    }
}

- (void)didUnfollowNotification:(NSNotification *)note {
    NSString *userToken = (NSString *)[note object];
    
    //update grid
    for (int i = 0; i < self.gridItems.count; i++) {
        SPCGridItem *item = self.gridItems[i];
        if (item.isMemory) {
            if ([item.memory.author.userToken isEqualToString:userToken]) {
                item.memory.author.followingStatus = FollowingStatusNotFollowing;
            }
        }
    }
    
    //update montage
    NSMutableArray *montageMems = [NSMutableArray arrayWithArray:self.viewMontage.memories];
    BOOL needsToUpdate = NO;
    
    for (int i = 0; i < montageMems.count; i++) {
        Memory *montageMem = montageMems[i];
        
        if ([montageMem.author.userToken isEqualToString:userToken]) {
            montageMem.author.followingStatus = FollowingStatusNotFollowing;
            needsToUpdate = YES;
        }
    }
    
    if (needsToUpdate) {
        NSArray *updatedMemories = [NSArray arrayWithArray:montageMems];
        BOOL needsToLoad = YES;
        [self.viewMontage updateWithMemories:updatedMemories withMontageNeedsLoadReturn:&needsToLoad];
        if (needsToLoad) {
            [self.collectionView.collectionViewLayout invalidateLayout];
        }
    }
}

@end
