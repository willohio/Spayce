//
//  SPCHiSpeedViewController.m
//  Spayce
//
//  Created by Christopher Taylor on 9/5/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCHiSpeedViewController.h"

// Framework
#import <GoogleMaps/GoogleMaps.h>
#import "SPCMarker.h"

// Cells
#import "SPCHighSpeedVenueCell.h"

// Managers
#import "LocationManager.h"
#import "ContactAndProfileManager.h"
#import "MeetManager.h"

// Model
#import "ProfileDetail.h"
#import "SPCMemoryAsset.h"
#import "UserProfile.h"
#import "Asset.h"

// Views
#import "UIImageView+WebCache.h"

static NSString * VenueCellIdentifier = @"SPCHiSpeedVenue";
static NSString * MemCellIdentifier = @"SPCHiSpeedMems";

@interface SPCHiSpeedViewController ()

@property (nonatomic, strong) UIView *navView;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) GMSMapView *mapView;
@property (nonatomic, strong) SPCMarker *userMarker;
@property (nonatomic, strong) NSArray *tempVenues;
@property (nonatomic, strong) UIImage *profilePicImg;

@property (nonatomic, assign) NSInteger cellSlotType;
@property (nonatomic, strong) NSArray *assetsArray;
@property (nonatomic, strong) NSArray *tempAssetsArray;
@property (nonatomic, strong) UIButton *closeBtn;

@property (nonatomic, strong) UIImageView *asyncLoadView;

@end

@implementation SPCHiSpeedViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)init {
    self = [super init];
    if (self) {
        self.view.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.collectionView registerClass:[SPCHighSpeedVenueCell class] forCellWithReuseIdentifier:VenueCellIdentifier];
    [self.collectionView registerClass:[SPCHighSpeedMemCell class] forCellWithReuseIdentifier:MemCellIdentifier];
    
    
    [self.view addSubview:self.navView];
    [self.view addSubview:self.mapView];
    [self.view addSubview:self.mapTitle];
    self.mapTitle.text = @"";
    [self.view addSubview:self.collectionView];
    [self.view addSubview:self.closeBtn];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateUserLocation) name:@"updateHighSpeedPosition" object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Accessors 

- (UIView *)navView {
    if (!_navView) {
        _navView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(self.view.frame), 64)];
        _navView.backgroundColor = [UIColor colorWithRed:45.0f/255.0f green:55.0f/255.0f blue:71.0f/255.0f alpha:1.0f];
        
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.text = NSLocalizedString(@"High Speed Mode", nil);
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:18];
        titleLabel.frame = CGRectMake(CGRectGetMidX(_navView.frame) - 75.0, CGRectGetMidY(_navView.frame) - 5, 150.0, titleLabel.font.lineHeight);
        titleLabel.textColor = [UIColor whiteColor];
        
        [_navView addSubview:titleLabel];
    }
    
    return _navView;
}

- (GMSMapView *)mapView {
    if (!_mapView) {
        _mapView = [[GMSMapView alloc] initWithFrame:CGRectMake(0, 64, CGRectGetWidth(self.view.frame), 110)];
        _mapView.userInteractionEnabled = NO;
        _mapView.settings.rotateGestures = NO;
        _mapView.settings.tiltGestures = NO;
        _mapView.layer.shadowColor = [UIColor colorWithWhite:0.0f/255.0f alpha:.25].CGColor;
        _mapView.layer.shadowOffset = CGSizeMake(0, 1);
        _mapView.clipsToBounds = NO;
        _mapView.layer.masksToBounds = NO;
        
        CAGradientLayer *l = [CAGradientLayer layer];
        l.frame = _mapView.bounds;
        l.name = @"Gradient";
        l.colors = @[(id)[UIColor colorWithRed:0/255.0f green:0/255.0f blue:0/255.0f alpha:0].CGColor, (id)[UIColor colorWithRed:0 green:0.0f/255.0f blue:0.0f/255.0f alpha:.4].CGColor];
        l.startPoint = CGPointMake(0.5, 1.0f);
        l.endPoint = CGPointMake(0.5f, 0.0f);
        [_mapView.layer addSublayer:l];
    }
    return _mapView;
}

- (UIImageView *)asyncLoadView {
    if (!_asyncLoadView) {
        _asyncLoadView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    }
    return _asyncLoadView;
}

- (SPCMarker *)userMarker {
    
    if (!_userMarker) {
    
        _userMarker = [[SPCMarker alloc] init];
        
        [self.asyncLoadView sd_setImageWithURL:[NSURL URLWithString:[ContactAndProfileManager sharedInstance].profile.profileDetail.imageAsset.imageUrlThumbnail] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            if (image) {
                self.profilePicImg = image;
                self.asyncLoadView.image = nil;
                _userMarker.icon = [self generateMarkerImg];
            }
        }];
        
        _userMarker.position = [[CLLocation alloc] initWithLatitude:0 longitude:0].coordinate;
        if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse) {
            _userMarker.position = [LocationManager sharedInstance].currentLocation.coordinate;
        }
        _userMarker.map = self.mapView;
    }
    return _userMarker;
}

- (UILabel *)mapTitle {
    if (!_mapTitle) {
        _mapTitle = [[UILabel alloc] initWithFrame:CGRectMake(8, 74, CGRectGetWidth(self.view.frame) - 20, 16)];
        _mapTitle.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:14];
        _mapTitle.backgroundColor = [UIColor clearColor];
        _mapTitle.textColor = [UIColor whiteColor];
    }
    return _mapTitle;
}

- (UICollectionView *)collectionView {
    if (!_collectionView){
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.sectionInset = UIEdgeInsetsMake(4, 4, 4, 4);
        layout.minimumInteritemSpacing = 4;
        layout.minimumLineSpacing = 4;
        
        CGRect frame = CGRectMake(0, CGRectGetMaxY(self.mapView.frame), self.view.bounds.size.width, CGRectGetHeight(self.view.frame)-CGRectGetMaxY(self.mapView.frame) - 47);
        
        _collectionView = [[UICollectionView alloc] initWithFrame:frame collectionViewLayout:layout];
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        _collectionView.allowsMultipleSelection = NO;
        _collectionView.autoresizesSubviews = YES;
        _collectionView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        _collectionView.alwaysBounceVertical = YES;
        _collectionView.delaysContentTouches = NO;
        _collectionView.showsVerticalScrollIndicator = NO;
        _collectionView.backgroundColor = [UIColor whiteColor];
    }
    return _collectionView;
}


- (UIButton *)closeBtn {
    if (!_closeBtn) {
        _closeBtn = [[UIButton alloc] initWithFrame:CGRectMake(10, 25, 65, 30)];
        _closeBtn.backgroundColor = [UIColor colorWithRed:66.0f/255.0f green:71.0f/255.0f blue:97.0f/255.0f alpha:1.0f];
        [_closeBtn setTitle:@"Close" forState:UIControlStateNormal];
        _closeBtn.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:14];
        [_closeBtn addTarget:self action:@selector(closeHighSpeed) forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeBtn;
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
   
    NSInteger rowsBasedOnVenues = self.venues.count;
    NSInteger totalAssets = self.assetsArray.count;
    
    NSInteger numRowsWithAssets = totalAssets / 4;
    
    if (numRowsWithAssets >= rowsBasedOnVenues) {
        return rowsBasedOnVenues * 2;
    }
    else {
        if (numRowsWithAssets > 0) {
            return numRowsWithAssets * 2;
        }
        else {
            return 2;
        }
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
   
    self.cellSlotType = indexPath.item % 4;
    
    if (self.cellSlotType == 0  || self.cellSlotType == 3) {
        SPCHighSpeedVenueCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:VenueCellIdentifier forIndexPath:indexPath];
        cell.backgroundColor = [UIColor colorWithWhite:245.0f/255.0f alpha:1.0f];
       
        NSInteger tempIndex = indexPath.item / 2;
        [cell configureWithVenue:self.venues[tempIndex]];
        return cell;
    }
    else {
        SPCHighSpeedMemCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:MemCellIdentifier forIndexPath:indexPath];
        cell.backgroundColor = [UIColor whiteColor];

        NSMutableArray *tempArray = [[NSMutableArray alloc] init];

        NSInteger rowIndex = indexPath.item / 2;
        NSInteger baseIndex = rowIndex * 4;
        
        for (int i = (int)baseIndex; i < ((int)baseIndex + 4); i++) {
            if (i < self.assetsArray.count) {
                [tempArray addObject:self.assetsArray[i]];
            }
        }
        [cell configureWithAssetsArray:tempArray];
        cell.delegate = self;
        return cell;
    }
}

#pragma mark - CHTCollectionViewDelegateWaterfallLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    CGSize cellSize = CGSizeMake(154, 154);
    return cellSize;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    //do stuff
    
    int tempSlot = indexPath.item % 4;
    
    if (tempSlot == 0  || tempSlot == 3) {
        NSInteger tempIndex = indexPath.item / 2;
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(showFeedForHighSpeedVenue:)]) {
            if (tempIndex < self.venues.count) {
                Venue *displayVenue = (Venue *)self.venues[tempIndex];
                [self.delegate showFeedForHighSpeedVenue:displayVenue];
            }
        }
    }
}

-(void)reloadData {
    [self updateCamera];
    [self updateUserLocation];
    [self processAssets];
    self.tempVenues = [NSArray arrayWithArray:self.venues];
    [self.collectionView reloadData];
}

-(void)updateCamera {
    
    GMSCameraPosition *camera;
    camera = [GMSCameraPosition cameraWithLatitude:[LocationManager sharedInstance].currentLocation.coordinate.latitude
                                         longitude:[LocationManager sharedInstance].currentLocation.coordinate.longitude
                                              zoom:17
                                           bearing:0
                                      viewingAngle:15];
    _mapView.camera = camera;

}

-(void)updateUserLocation {
    self.userMarker.position = [LocationManager sharedInstance].currentLocation.coordinate;
    self.mapView.camera = [GMSCameraPosition cameraWithLatitude:[LocationManager sharedInstance].currentLocation.coordinate.latitude
                                                      longitude:[LocationManager sharedInstance].currentLocation.coordinate.longitude
                                                           zoom:17
                                                        bearing:0
                                                   viewingAngle:15];
}

- (void)processAssets {
    
    NSMutableArray *tempAssetArray = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < self.mems.count; i++) {
        
        Memory *tempMem = (Memory *)self.mems[i];
        
      if (tempMem.type == MemoryTypeImage) {
            //NSLog(@" -- image asset -- ");
            
            ImageMemory *tempImageMem = (ImageMemory *)self.mems[i];
            
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
            
            
            VideoMemory *tempVidMem = (VideoMemory *)self.mems[i];
            
            
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
    
    //Eliminate duplicate mem images by checking against our venue images
    for (int i = 0; i < self.venues.count; i++) {
        
        Venue *tempV = (Venue *)self.venues[i];
        if (!tempV.imageAsset) {
            
            ImageMemory *imgMem = (ImageMemory *)tempV.popularMemories[0];
            Asset *assImg = imgMem.images[0];
            NSInteger venAssId = assImg.assetID;
            
            for (int j = 0; j < tempAssetArray.count; j++) {
                SPCMemoryAsset *tempAsset = (SPCMemoryAsset *)tempAssetArray[j];
                if (tempAsset.asset.assetID == venAssId) {
                    [tempAssetArray removeObjectAtIndex:j];
                    break;
                }
            }
        }
    }
    
    self.assetsArray = [NSArray arrayWithArray:tempAssetArray];
    
}

-(UIImage *)generateMarkerImg {
    
    UIImageView *baseImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 35, 35)];
    baseImageView.image = self.profilePicImg;
    baseImageView.backgroundColor = [UIColor clearColor];
    baseImageView.layer.cornerRadius = baseImageView.frame.size.width/2;
    baseImageView.clipsToBounds = YES;
    
    // Render
    UIGraphicsBeginImageContextWithOptions(baseImageView.bounds.size, NO, 0.0);
    [baseImageView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *markerImg = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
   
    return markerImg;
}

- (void)closeHighSpeed {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"closeHighSpeed" object:nil];
    [[LocationManager sharedInstance] cancelHiSpeed];
    [self.view removeFromSuperview];
}



- (void)fetchMemForComments:(NSInteger)memId {
 
     [MeetManager fetchMemoryWithMemoryId:memId
                           resultCallback:^(NSDictionary *result){
   
                               NSInteger success = [result[@"success"] integerValue];
     
                               if (success == 1) {
                                     //memory is unavailable!
                                     [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Uh oh!", nil)
                                     message:@"Memory is unavailable. Please try again later."
                                     delegate:nil
                                     cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                     otherButtonTitles:nil] show];
                               }
                               else if (result[@"dateCreated"] != nil)  {
                                   if (self.delegate && [self.delegate respondsToSelector:@selector(showCommentsForHighSpeedMemory:)]){
                                       Memory *memory = [Memory memoryWithAttributes:result];
                                       [self.delegate showCommentsForHighSpeedMemory:memory];
                                   }
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
 

@end
