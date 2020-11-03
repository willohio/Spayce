//
//  SPCLookBackViewController.m
//  Spayce
//
//  Created by Christopher Taylor on 7/2/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCLookBackViewController.h"

// Model
#import "Asset.h"

// View
#import "CHTCollectionViewWaterfallCell.h"
#import "CHTCollectionViewWaterfallHeader.h"
#import "CHTCollectionViewWaterfallFooter.h"

// Controller
#import "MemoryCommentsViewController.h"

// Category
#import "UIImageView+WebCache.h"

// Manager
#import "MeetManager.h"

#define CELL_IDENTIFIER @"WaterfallCell"
#define HEADER_IDENTIFIER @"WaterfallHeader"
#define FOOTER_IDENTIFIER @"WaterfallFooter"

@interface SPCLookBackViewController ()

@property (nonatomic, strong) UIView *customHeader;
@property (nonatomic, strong) UILabel *dateLabel;
@property (nonatomic, strong) NSArray *memsArray;
@property (nonatomic, strong) NSArray *assetsArray;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;

//prefetching feed iamges
@property (nonatomic, strong) NSArray *assetQueue;
@property (nonatomic, strong) UIImageView *prefetchImageView;


@end

@implementation SPCLookBackViewController

#pragma mark - Accessors

- (UICollectionView *)collectionView {
    if (!_collectionView) {
        CHTCollectionViewWaterfallLayout *layout = [[CHTCollectionViewWaterfallLayout alloc] init];
        layout.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0);
        layout.headerHeight = 0;
        layout.footerHeight = 0;
        layout.minimumColumnSpacing = 4;
        layout.minimumInteritemSpacing = 4;
        
        CGRect collectionFrame = CGRectMake(4, 48, self.view.frame.size.width-8, self.view.bounds.size.height-52);
        
        _collectionView = [[UICollectionView alloc] initWithFrame:collectionFrame collectionViewLayout:layout];
        _collectionView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        _collectionView.clipsToBounds = NO;
        _collectionView.backgroundColor = [UIColor whiteColor];
        [_collectionView registerClass:[CHTCollectionViewWaterfallCell class]
            forCellWithReuseIdentifier:CELL_IDENTIFIER];
        [_collectionView registerClass:[CHTCollectionViewWaterfallHeader class]
            forSupplementaryViewOfKind:CHTCollectionElementKindSectionHeader
                   withReuseIdentifier:HEADER_IDENTIFIER];
        [_collectionView registerClass:[CHTCollectionViewWaterfallFooter class]
            forSupplementaryViewOfKind:CHTCollectionElementKindSectionFooter
                   withReuseIdentifier:FOOTER_IDENTIFIER];
    }
    return _collectionView;
}

-(UIView *)customHeader {
    if (!_customHeader) {
        _customHeader = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 64)];
        _customHeader.backgroundColor = [UIColor colorWithRed:45.0f/255.0f green:55.0f/255.0f blue:71.0f/255.0f alpha:1.0f];
        
        UIButton *backButton = [[UIButton alloc] initWithFrame:CGRectMake(-10.0, 20.0, 45.0, 45.0)];
        [backButton setImage:[UIImage imageNamed:@"camera-cancel"] forState:UIControlStateNormal];
        [backButton addTarget:self action:@selector(pop) forControlEvents:UIControlEventTouchUpInside];
        [backButton sizeToFit];
        
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.text = NSLocalizedString(@"Look Back", nil);
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:18];
        titleLabel.frame = CGRectMake(CGRectGetMidX(_customHeader.frame) - 60.0, CGRectGetMidY(_customHeader.frame), 120.0, titleLabel.font.lineHeight);
        titleLabel.textColor = [UIColor whiteColor];
        
        [_customHeader addSubview:backButton];
        [_customHeader addSubview:titleLabel];
        [_customHeader addSubview:self.dateLabel];
        self.dateLabel.frame = CGRectMake(CGRectGetMaxX(titleLabel.frame), titleLabel.frame.origin.y, 100, titleLabel.font.lineHeight);
    }
    return _customHeader;
}

-(UILabel *)dateLabel {
    if (!_dateLabel) {
        _dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 150, 60)];
        _dateLabel.text = @"";
        _dateLabel.backgroundColor = [UIColor clearColor];
        _dateLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:14];
        _dateLabel.textColor = [UIColor colorWithWhite:155.0f/255.0f alpha:1.0f];
     }
    return _dateLabel;
}

- (NSDateFormatter *)dateFormatter
{
    if (!_dateFormatter) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        _dateFormatter.dateFormat = @"MMM d, yyyy";
    }
    return _dateFormatter;
}


- (UIImageView *)prefetchImageView {
    if (!_prefetchImageView) {
        _prefetchImageView = [[UIImageView alloc] init];
    }
    return _prefetchImageView;
}

#pragma mark - Life Cycle

- (void)dealloc {
    _collectionView.delegate = nil;
    _collectionView.dataSource = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.collectionView];
    [self.view addSubview:self.customHeader];
    self.view.backgroundColor = [UIColor whiteColor];
}

-(void)viewWillAppear:(BOOL)animated     {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.assetsArray.count;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    CHTCollectionViewWaterfallCell *cell =
    (CHTCollectionViewWaterfallCell *)[collectionView dequeueReusableCellWithReuseIdentifier:CELL_IDENTIFIER
                                                                                forIndexPath:indexPath];
    
    if (!cell) {
        cell = [[CHTCollectionViewWaterfallCell alloc] init];
    }

    SPCMemoryAsset *tempAsset = (SPCMemoryAsset *)self.assetsArray[indexPath.item];
    cell.tag = (int)indexPath.item;
    [cell configureWithAsset:tempAsset];
    
    if (tempAsset.type != MemoryTypeText) {
        cell.backgroundColor = [UIColor colorWithWhite:240.0f/255.0f alpha:1.0f];
    }
    else {
        cell.backgroundColor = [UIColor whiteColor];
    }
    
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    UICollectionReusableView *reusableView = nil;
    
    if ([kind isEqualToString:CHTCollectionElementKindSectionHeader]) {
        reusableView = [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                          withReuseIdentifier:HEADER_IDENTIFIER
                                                                 forIndexPath:indexPath];
    } else if ([kind isEqualToString:CHTCollectionElementKindSectionFooter]) {
        reusableView = [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                          withReuseIdentifier:FOOTER_IDENTIFIER
                                                                 forIndexPath:indexPath];
    }
    
    return reusableView;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    int itemIndex = (int)indexPath.item;
    
    SPCMemoryAsset *selectedAsset = self.assetsArray[itemIndex];
    
    int memoryId = (int)selectedAsset.memoryID;
    
    [self fetchMemForComments:memoryId];
}

#pragma mark - CHTCollectionViewDelegateWaterfallLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    SPCMemoryAsset *asset = (SPCMemoryAsset *)self.assetsArray[indexPath.item];
    CGSize cellSize = CGSizeMake(154, asset.height);
    //NSLog(@"indexPath.item %i height %f",(int)indexPath.item,asset.height);
    
    return cellSize;
}

#pragma mark - Asset Methods

-(void)fetchLookBackWithID:(int)notificationID {
    __weak typeof(self) weakSelf = self;
    [MeetManager fetchLookBackMemoriesWithID:notificationID
                          completionHandler:^(NSArray *memories, NSInteger totalRetrieved, NSDate *lookBackDate) {
                              __strong typeof(weakSelf) strongSelf = weakSelf;
                              strongSelf.memsArray = memories;
                              NSLog(@"look back mems fetched %i",(int)strongSelf.memsArray.count);
                              [strongSelf handleDate:lookBackDate];
                              [strongSelf processAssets];
                          } errorHandler:^(NSError *error) {
                              
                          }];
}

- (void)processAssets {
    
    NSMutableArray *tempAssetArray = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < self.memsArray.count; i++) {
     
        Memory *tempMem = (Memory *)self.memsArray[i];
        
        if (tempMem.type == MemoryTypeText) {
            //NSLog(@" -- text asset -- ");
            
            //create asset
            NSDictionary *assetAttributes = @{  @"assetID"  : @0,
                                                @"memoryID" : @(tempMem.recordID),
                                                @"type"     : @(MemoryTypeText),
                                                @"memText"  : tempMem.text,
                                                };
            
            SPCMemoryAsset *asset = [[SPCMemoryAsset alloc] initWithAttributes:assetAttributes];
            [tempAssetArray addObject:asset];
        }
        
        
        if (tempMem.type == MemoryTypeImage) {
            //NSLog(@" -- image asset -- ");
            
            ImageMemory *tempImageMem = (ImageMemory *)self.memsArray[i];
            
            
            for (int j = 0; j < tempImageMem.images.count; j++) {
            
                //get asset dictionary
                NSDictionary *assetDict = [(Asset *)tempImageMem.images[j] attributes];
                
                //create asset
                NSDictionary *assetAttributes = @{  @"assetInfo"  : assetDict,
                                                    @"memoryID" : @(tempMem.recordID),
                                                    @"type"     : @(MemoryTypeImage),
                                                    @"memText"  : @"",
                                                    };
            
                SPCMemoryAsset *asset = [[SPCMemoryAsset alloc] initWithAttributes:assetAttributes];
                [tempAssetArray addObject:asset];
            }
        }
        
        if (tempMem.type == MemoryTypeVideo) {
            //NSLog(@" -- vid asset -- ");


            VideoMemory *tempVidMem = (VideoMemory *) self.memsArray[i];
            
            
            for (int j = 0; j < tempVidMem.previewImages.count; j++) {
                
                //get asset dictionary
                NSDictionary *assetDict = [(Asset *)tempVidMem.previewImages[j] attributes];
                
                //create asset
                NSDictionary *assetAttributes = @{  @"assetInfo"  : assetDict,
                                                    @"memoryID" : @(tempMem.recordID),
                                                    @"type"     : @(MemoryTypeVideo),
                                                    @"memText"  : @"",
                                                    };
                
                SPCMemoryAsset *asset = [[SPCMemoryAsset alloc] initWithAttributes:assetAttributes];
                [tempAssetArray addObject:asset];
            }
        }
    }
    
    self.assetsArray = [NSArray arrayWithArray:tempAssetArray];
    
    //generate queue to start prefetching images
    NSArray *visibleCells = [self.collectionView visibleCells];
    CHTCollectionViewWaterfallCell *cell = [visibleCells lastObject];
    int startTag = (int)cell.tag;
    NSLog(@"start Tag %i",startTag);
    
    NSMutableArray *prefetchArray = [NSMutableArray arrayWithArray:self.assetQueue];
    for (int i = startTag; i < self.assetsArray.count; i++) {
        SPCMemoryAsset *memAsset = self.assetsArray[i];
        [prefetchArray addObject:memAsset];
        NSLog(@"added asset to prefetch array!");
    }
    
    self.assetQueue = [NSArray arrayWithArray:prefetchArray];
    [self prefetchNextImageInQueue];
    
    NSLog(@"look back mems assets handled %i",(int)self.assetsArray.count);

    [self reloadData];
}

-(void)reloadData {
    [self.collectionView reloadData];
}

-(void)pop {
    if (self.delegate && [self.delegate respondsToSelector:@selector(dismissLookBack)]) {
        [self.delegate dismissLookBack];
    }
}


#pragma mark - Private

-(void)fetchMemForComments:(int)memId {
    
    [MeetManager fetchMemoryWithMemoryId:memId
                          resultCallback:^(NSDictionary *result){
                              //NSLog(@"memDictionary %@",result);
                              NSInteger success = [result[@"success"] integerValue];
                              if (success == 1) {
                                  //memory is unavailable!
                                  [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Uh oh!", nil)
                                                              message:@"Memory is unavailable. Please try again later."
                                                             delegate:nil
                                                    cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                    otherButtonTitles:nil] show];
                                  
                                  
                              } else if (result[@"dateCreated"] != nil)  {
                                  Memory *memory = [Memory memoryWithAttributes:result];
                                  MemoryCommentsViewController *memoryCommentsViewController = [[MemoryCommentsViewController alloc] initWithMemory:memory];
                                  memoryCommentsViewController.viewingFromNotification = YES;
                                  
                                  [self.navigationController pushViewController:memoryCommentsViewController animated:YES];
                              }
                              else  {
                                  //memory has been deleted!
                                  [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Uh oh!", nil)
                                                              message:@"Memory has been deleted by the author!"
                                                             delegate:nil
                                                    cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                    otherButtonTitles:nil] show];
                                  

                                  
                              }
                              

                          }
                           faultCallback:^(NSError *error){
                 
                           }];
}


-(void)handleDate:(NSDate *)lookBackDate {
    NSLog(@"handleDate %@",[self.dateFormatter stringFromDate:lookBackDate]);
    self.dateLabel.text =  [self.dateFormatter stringFromDate:lookBackDate];
}

#pragma  mark - Orientation Methods

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

#pragma mark - Prefetching Feed Images

-(void)prefetchNextImageInQueue {
    
    //NSLog(@"attempt next prefetch!");
    // If we have an asset in our queue, we:
    // 1 - grab it
    // 2 - cache the image (if necessary)
    // 3 - proceed thru our queue recursively
    
    if (self.assetQueue.count > 0) {
        
        //NSLog(@"assets to cache!");
        NSString *imageUrlStr;
        
        id imageAsset = self.assetQueue[0];
        SPCMemoryAsset * memAsset = (SPCMemoryAsset *)imageAsset;
        Asset * asset = memAsset.asset;
        imageUrlStr = [asset imageUrlSquare];
        
        BOOL imageIsCached = NO;
        
        if ([[SDWebImageManager sharedManager] cachedImageExistsForURL:[NSURL URLWithString:imageUrlStr]]) {
            imageIsCached = YES;
        }
        if ([[SDWebImageManager sharedManager] diskImageExistsForURL:[NSURL URLWithString:imageUrlStr]]) {
            imageIsCached = YES;
        }
        
        if (!imageIsCached) {
            //NSLog(@"prefetch image %@",imageUrlStr);
            [self.prefetchImageView sd_cancelCurrentImageLoad];
            [self.prefetchImageView sd_setImageWithURL:[NSURL URLWithString:imageUrlStr]
                                      placeholderImage:[UIImage imageNamed:@"placeholder-gray"]
                                             completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                                 NSMutableArray *tempArray = [NSMutableArray arrayWithArray:self.assetQueue];
                                                 [tempArray removeObject:imageAsset];
                                                 self.assetQueue = [NSArray arrayWithArray:tempArray];
                                                 //NSLog(@"prefetched image %@, proceed",imageUrlStr);
                                                 [self prefetchNextImageInQueue];
                                                 //NSLog(@"caching error %@",error);
                                             }];
        }
        else {
            //NSLog(@"no need to prefetch, image is already cached");
            NSMutableArray *tempArray = [NSMutableArray arrayWithArray:self.assetQueue];
            [tempArray removeObject:imageAsset];
            self.assetQueue = [NSArray arrayWithArray:tempArray];
            [self prefetchNextImageInQueue];
        }
    }
    
    //if we have no assets in our queue, we are done
}


@end
