//
//  SPCHashTagSuggestions.m
//  Spayce
//
//  Created by Christopher Taylor on 12/10/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCHashTagSuggestions.h"
#import "SPCHashTagSuggestionCollectionViewCell.h"
#import "KTCenterFlowLayout.h"

static NSString * CellIdentifier = @"SPCHashTagSuggestionCell";
static NSString * RecentHashTagsKey = @"SPCRecentHashTags";


@interface SPCHashTagSuggestions ()

@property (nonatomic, strong) NSArray *recentHashTags;

@property (nonatomic ,strong) UICollectionReusableView *headerView;
@property (nonatomic ,strong) UICollectionReusableView *locationHeaderView;
@property (nonatomic, assign) BOOL isNewMam;
@end

@implementation SPCHashTagSuggestions

-(void)dealloc  {
    
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor colorWithWhite:248.0f/255.0f alpha:1.0f];
        
        [self restoreRecentHashTags];
        [self addSubview:self.collectionView];
    }
    return self;
}

#pragma mark - Accessors

-(UICollectionView *) collectionView {
    if (!_collectionView) {

        KTCenterFlowLayout *layout = [KTCenterFlowLayout new];
        layout.minimumInteritemSpacing = 10.f;
        layout.minimumLineSpacing = 10.f;
        
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(10, 0, self.frame.size.width-20, self.frame.size.height) collectionViewLayout:layout];
        [_collectionView setDataSource:self];
        [_collectionView setDelegate:self];
        _collectionView.allowsMultipleSelection = YES;
        
        _collectionView.alwaysBounceVertical = YES;
        _collectionView.backgroundColor = [UIColor colorWithWhite:248.0f/255.0f alpha:1.0f];
        [_collectionView registerClass:[SPCHashTagSuggestionCollectionViewCell class] forCellWithReuseIdentifier:CellIdentifier];
        
        [_collectionView registerClass:[UICollectionReusableView class]
            forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                   withReuseIdentifier:@"sectionHeader"];
    }
    return _collectionView;
}

- (UICollectionReusableView *)headerView {
    
    if (!_headerView) {
        _headerView = [[UICollectionReusableView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width-20, 55)];
        _headerView.backgroundColor = [UIColor colorWithWhite:248.0f/255.0f alpha:1.0f];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.collectionView.frame.size.width, 55)];
        label.text = @"RECENT #'s";
        label.textAlignment = NSTextAlignmentCenter;
        label.numberOfLines = 0;
        label.lineBreakMode = NSLineBreakByWordWrapping;
        label.font = [UIFont spc_regularSystemFontOfSize:14];
        label.textColor = [UIColor colorWithRed:139.0f/255.0f green:153.0f/255.0f blue:175.0f/255.0f alpha:1.0f];
        [_headerView addSubview:label];
        
    }
    return _headerView;
}

- (UICollectionReusableView *)locationHeaderView {
    
    if (!_locationHeaderView) {
        _locationHeaderView = [[UICollectionReusableView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width-20, 55)];
        _locationHeaderView.backgroundColor = [UIColor colorWithWhite:248.0f/255.0f alpha:1.0f];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.collectionView.frame.size.width, 55)];
        label.text = @"LOCATION #'s";
        label.textAlignment = NSTextAlignmentCenter;
        label.numberOfLines = 0;
        label.lineBreakMode = NSLineBreakByWordWrapping;
        label.backgroundColor = [UIColor clearColor];
        label.font = [UIFont spc_regularSystemFontOfSize:14];
        label.textColor = [UIColor colorWithRed:139.0f/255.0f green:153.0f/255.0f blue:175.0f/255.0f alpha:1.0f];
        [_locationHeaderView addSubview:label];
        
        UILabel *subhead = [[UILabel alloc] initWithFrame:CGRectMake(0, 40, self.collectionView.frame.size.width, 15)];
        subhead.text = @"#hashtags that better describe your location";
        subhead.font = [UIFont spc_regularSystemFontOfSize:12];
        subhead.textColor = [UIColor colorWithRed:139.0f/255.0f green:153.0f/255.0f blue:175.0f/255.0f alpha:1.0f];
        subhead.textAlignment = NSTextAlignmentCenter;
        [_locationHeaderView addSubview:subhead];
    }
    return _locationHeaderView;
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.recentHashTags.count;
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView registerClass:[SPCHashTagSuggestionCollectionViewCell class] forCellWithReuseIdentifier:CellIdentifier];
  
    SPCHashTagSuggestionCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    NSString *itemText = @"";
    if (self.recentHashTags.count > indexPath.item) {
        itemText = self.recentHashTags[indexPath.item];
    }
    
    BOOL selected = [self hashTagIsSelected:itemText];
    [cell configureWithHashTag:itemText selected:selected];
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    
    if (self.isNewMam) {
        return CGSizeMake(0, 0);
    }
    
    if (section == 0) {
        if (self.recentHashTags.count > 0) {
            return CGSizeMake(self.frame.size.width, 55.0f);
        }
        else {
        return CGSizeMake(self.frame.size.width, 75.0f);        }
    }
    
    else if (section == 1) {
        return CGSizeMake(self.frame.size.width, 75.0f);
    }
    
    else return CGSizeMake(0, 0);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *itemText = @"";
    
    if (self.recentHashTags.count > indexPath.item) {
        itemText = self.recentHashTags[indexPath.item];
    }
    float width = [self itemWidthForHashTag:itemText];
    
    return CGSizeMake(width, 30.0f);
}


#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    SPCHashTagSuggestionCollectionViewCell *cell = (SPCHashTagSuggestionCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    [self tappedHashTag:cell.tagLabel.text atIndexPath:indexPath];
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    SPCHashTagSuggestionCollectionViewCell *cell = (SPCHashTagSuggestionCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    [self tappedHashTag:cell.tagLabel.text atIndexPath:indexPath];
}


- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    UICollectionReusableView *reusableView = nil;
    
    if (!self.isNewMam) {
    
        if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
            
            reusableView = [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                              withReuseIdentifier:@"sectionHeader"
                                                                     forIndexPath:indexPath];
            
            if (indexPath.section == 0) {
                if (self.recentHashTags.count > 0) {
                    [reusableView addSubview:self.headerView];
                }
                else {
                     [reusableView addSubview:self.locationHeaderView];
                }

            } else if (indexPath.section == 1) {
                [reusableView addSubview:self.locationHeaderView];
            }
        }
    }
    
    return reusableView;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.delegate && [self.delegate respondsToSelector:@selector(hashTagsDidScroll)]) {
        [self.delegate hashTagsDidScroll];
    }
}

#pragma mark - Actions

-(void)tappedHashTag:(NSString *)hashTag atIndexPath:(NSIndexPath *)indexPath {

    NSLog(@"tapped tag %@",hashTag);
    
    BOOL alreadyIncluded = NO;
    NSMutableArray *tempArray = [NSMutableArray arrayWithArray:self.selectedHashTags];
 
    for (int i = 0; i < self.selectedHashTags.count; i++) {
        NSString *existingTag = self.selectedHashTags[i];
        if ([existingTag isEqualToString:hashTag]) {
            //NSLog(@"tapped to remove tag %@",existingTag);
            [tempArray removeObjectAtIndex:i];
            alreadyIncluded = YES;
            
            SPCHashTagSuggestionCollectionViewCell *cell = (SPCHashTagSuggestionCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
            [cell configureWithHashTag:cell.tagLabel.text selected:NO];
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(tappedToRemoveHashTag:)]) {
                [self.delegate tappedToRemoveHashTag:hashTag];
            }
            break;
        }
    }
    
    if (!alreadyIncluded) {
        //NSLog(@"add hash %@ on tap",hashTag);
        SPCHashTagSuggestionCollectionViewCell *cell = (SPCHashTagSuggestionCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        [cell configureWithHashTag:cell.tagLabel.text selected:YES];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(tappedToAddHashTag:)]) {
            [self.delegate tappedToAddHashTag:hashTag];
        }
        
        tempArray = [NSMutableArray arrayWithArray:self.selectedHashTags];
        [tempArray addObject:hashTag];
        
    }
    
    self.selectedHashTags = [NSArray arrayWithArray:tempArray];
    //NSLog(@"selectedHashTags %@",self.selectedHashTags);
}


-(void)addedHashTagViaKeyboard:(NSString *)hashTag {
    
    //NSLog(@"addedHashTagViaKeyboard");
    BOOL alreadyIncluded = NO;
    NSMutableArray *tempArray = [NSMutableArray arrayWithArray:self.selectedHashTags];
    
    for (int i = 0; i < self.selectedHashTags.count; i++) {
        NSString *existingTag = self.selectedHashTags[i];
        if ([existingTag isEqualToString:hashTag]) {
            alreadyIncluded = YES;
            break;
        }
    }
    
    if (!alreadyIncluded ) {
        
        //NSLog(@"added hash tag %@",hashTag);
        [tempArray addObject:hashTag];

        //update highlight state of any relevant hashtag pills
        NSInteger recentHashTagSection = 0;
        NSInteger locationHashTagSection = 1;
        if (self.recentHashTags.count == 0) {
            locationHashTagSection = 0;
        }
        
        for (int j = 0; j < self.recentHashTags.count; j++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:j inSection:recentHashTagSection];
            SPCHashTagSuggestionCollectionViewCell *cell = (SPCHashTagSuggestionCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
            if ([cell.tagLabel.text isEqualToString:hashTag]) {
                [cell configureWithHashTag:cell.tagLabel.text selected:YES];
            }
        }
    }
    
    self.selectedHashTags = [NSArray arrayWithArray:tempArray];
    //NSLog(@"selectedHashTags %@",self.selectedHashTags);
}

-(void)deletedHashTagViaKeyboard:(NSString *)hashTag {
    
    NSMutableArray *tempArray = [NSMutableArray arrayWithArray:self.selectedHashTags];
    
    for (int i = 0; i < self.selectedHashTags.count; i++) {
        NSString *existingTag = self.selectedHashTags[i];
        if ([existingTag isEqualToString:hashTag]) {
            //NSLog(@"remove hash tag %@",hashTag);
            [tempArray removeObjectAtIndex:i];
            break;
        }
    }
    
    //update highlight state of any relevant hashtag pills
    
    NSInteger recentHashTagSection = 0;
    NSInteger locationHashTagSection = 1;
    if (self.recentHashTags.count == 0) {
        locationHashTagSection = 0;
    }
    
    for (int j = 0; j < self.recentHashTags.count; j++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:j inSection:recentHashTagSection];
        SPCHashTagSuggestionCollectionViewCell *cell = (SPCHashTagSuggestionCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        if ([cell.tagLabel.text isEqualToString:hashTag]) {
            //NSLog(@"deselect recent hash tag! %@",hashTag);
            [cell configureWithHashTag:cell.tagLabel.text selected:NO];
        }
    }
   
    self.selectedHashTags = [NSArray arrayWithArray:tempArray];
}

#pragma mark - Private

-(void)reloadData {
    [self.collectionView reloadData];
}

-(void)updateForNewMam {
    self.isNewMam = YES;
    self.collectionView.frame = CGRectMake(10, 20, self.frame.size.width-20, self.frame.size.height - 20);
    self.collectionView.clipsToBounds = NO;
    self.clipsToBounds = YES;
}

-(BOOL)hashTagIsSelected:(NSString *)hashTag {
    BOOL alreadyIncluded = NO;

    for (int i = 0; i < self.selectedHashTags.count; i++) {
        NSString *existingTag = self.selectedHashTags[i];
        if ([existingTag isEqualToString:hashTag]) {
            alreadyIncluded = YES;
            break;
        }
    }
    return alreadyIncluded;
}

-(void)updateAllSelectedHashTags:(NSMutableArray *)hashTags {
    self.selectedHashTags = [NSArray arrayWithArray:hashTags];
}

-(void)createStarterTags {
    NSMutableArray *tempArray2 = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < 6; i++) {
        
        if (i == 0) {
            [tempArray2 addObject:@"#omg"];
        }
        if (i == 1) {
            [tempArray2 addObject:@"#hotspot"];
        }
        if (i == 2) {
            [tempArray2 addObject:@"#theplacetobe"];
        }
        if (i == 3) {
            [tempArray2 addObject:@"#chillin"];
        }
        if (i == 4) {
            [tempArray2 addObject:@"#firsttime"];
        }
    }
    
    self.recentHashTags = [NSArray arrayWithArray:tempArray2];
}

-(void)restoreRecentHashTags {
    
    NSArray *tempArray = [[NSUserDefaults standardUserDefaults] arrayForKey:RecentHashTagsKey];
    
    if (tempArray.count > 0) {
        self.recentHashTags = [NSArray arrayWithArray:tempArray];
    }
    else {
        [self createStarterTags];
    }
}

-(void)updateRecentHashTags {
    
    //NSLog(@"update recent hash tags");
    
    NSMutableArray *tempArray = [NSMutableArray arrayWithArray:self.recentHashTags];
    
    for (int i = 0; i < self.selectedHashTags.count; i++) {
        
        NSString *selectedTag = self.selectedHashTags[i];
        BOOL alreadyIncluded = NO;
        
        for (int j = 0; j < self.recentHashTags.count; j++) {
            
            NSString *recentTag = self.recentHashTags[j];
            if ([recentTag isEqualToString:selectedTag]) {
                alreadyIncluded = YES;
                break;
            }
        }
        
        if (!alreadyIncluded) {
            [tempArray insertObject:selectedTag atIndex:0];
        }
        
    }
    
    BOOL trimmed = NO;
    
    if (tempArray.count < 10) {
        self.recentHashTags = [NSArray arrayWithArray:tempArray];
    }
    else {
        trimmed = YES;
        NSMutableArray *trimmedArray = [[NSMutableArray alloc] init];
        for (int i = 0; i < 10; i++) {
            [trimmedArray addObject:tempArray[i]];
        }
        self.recentHashTags = [NSArray arrayWithArray:trimmedArray];
        
    }
    
    
    [[NSUserDefaults standardUserDefaults] setObject:self.recentHashTags forKey:RecentHashTagsKey];
}



-(float)itemWidthForHashTag:(NSString *)hashTag {

    NSDictionary *attributes = @{ NSFontAttributeName: [UIFont spc_mediumSystemFontOfSize:14] };
    CGRect frame = [hashTag boundingRectWithSize:CGSizeMake(self.frame.size.width, 20)
                                           options:NSStringDrawingUsesLineFragmentOrigin
                                        attributes:attributes
                                           context:NULL];
    
    return frame.size.width + 30;
}

-(NSArray *)getSelectedHashTags {
    return self.selectedHashTags;
}

@end
