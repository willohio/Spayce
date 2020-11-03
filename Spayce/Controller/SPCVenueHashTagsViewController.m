//
//  SPCVenueHashTagsViewController.m
//  Spayce
//
//  Created by Christopher Taylor on 12/19/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

//controller
#import "SPCVenueHashTagsViewController.h"

//view
#import "KTCenterFlowLayout.h"
#import "SPCSearchTextField.h"

//cell
#import "SPCHashTagSuggestionCollectionViewCell.h"
#import "SPCNoResultsCollectionViewCell.h"


static NSString * CellIdentifier = @"SPCHashTagSuggestionCell";
static NSString * RecentHashTagsKey = @"SPCRecentHashTags";


@interface SPCVenueHashTagsViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UITextFieldDelegate>


@property (nonatomic,strong) UITextView *textView;
@property (nonatomic, strong) UIButton *cancelBtn;

@property (nonatomic, strong) UIView *bgView;
@property (nonatomic ,strong) UICollectionReusableView *headerView;
@property (nonatomic,strong) UICollectionView *collectionView;


@property (nonatomic, strong) SPCSearchTextField *textField;
@property (nonatomic, strong) NSOperationQueue *searchOperationQueue;

@property (nonatomic, strong) NSArray *venueHashTags;
@property (nonatomic, strong) NSArray *filteredHashTags;
@property (nonatomic, strong) NSArray *selectedHashTags;
@property (nonatomic, strong) NSString *activeTag;



@end

@implementation SPCVenueHashTagsViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.textField];
    
    UIImageView *glassView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"magnifying-glass-off"]];
    glassView.frame = CGRectMake(10,20,11,11);
    [self.view addSubview:glassView];
    
    [self.view addSubview:self.cancelBtn];
    
    [UIColor colorWithWhite:248.0f/255.0f alpha:1.0f];
    
    [self.view addSubview:self.bgView];
    [self.view addSubview:self.collectionView];

}

-(void)configureForHashTags:(NSArray *)venueHashTags withSelectedTag:(NSString *)selectedTag{
    //NSLog(@"configure for hashtags %@ with selectedTag %@",venueHashTags,selectedTag);
    if (venueHashTags.count > 0) {
        self.venueHashTags = [NSArray arrayWithArray:venueHashTags];
        self.filteredHashTags = self.venueHashTags;
        self.activeTag = [NSString stringWithFormat:@"#%@",selectedTag];
    }
    
    [self reloadData];
}

-(void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated {
    [self prefersStatusBarHidden];
    [self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
}

-(BOOL)prefersStatusBarHidden {
    return YES;
}

#pragma mark - Accessors

-(UIButton *)cancelBtn {
    if (!_cancelBtn) {
        _cancelBtn = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.view.frame)-82, 13, 70, 26)];
        _cancelBtn.backgroundColor = [UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f];
        _cancelBtn.titleLabel.font = [UIFont spc_regularSystemFontOfSize:12];
        _cancelBtn.layer.cornerRadius = 2;
        [_cancelBtn setTitle:@"Cancel" forState:UIControlStateNormal];
        _cancelBtn.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        [_cancelBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_cancelBtn addTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cancelBtn;
}

-(SPCSearchTextField *)textField {
    if (!_textField) {
        _textField = [[SPCSearchTextField alloc] initWithFrame:CGRectMake(30, 12, CGRectGetWidth(self.view.frame)-120, 29)];
        _textField.delegate = self;
        _textField.backgroundColor = [UIColor clearColor];
        _textField.textColor = [UIColor colorWithRed:106.0f/255.0f green:177.0f/255.0f blue:251.0f/255.0f alpha:1.000f];
        _textField.tintColor = [UIColor colorWithRed:106.0f/255.0f green:177.0f/255.0f blue:251.0f/255.0f alpha:1.000f];
        _textField.font = [UIFont spc_regularSystemFontOfSize:17];
        _textField.placeholder = @"Search #hashtags here";
        _textField.spellCheckingType = UITextSpellCheckingTypeNo;
        _textField.autocorrectionType = UITextAutocorrectionTypeNo;
        _textField.leftView = nil;
        _textField.placeholderAttributes = @{ NSForegroundColorAttributeName: [UIColor colorWithRed:184.0f/255.0f green:193.0f/255.0f blue:201.0f/255.0f alpha:1.0f], NSFontAttributeName: [UIFont spc_regularSystemFontOfSize:14] };
        
    }
    return _textField;
}

-(NSOperationQueue *)searchOperationQueue {
    if (!_searchOperationQueue) {
        _searchOperationQueue = [[NSOperationQueue alloc] init];
        _searchOperationQueue.maxConcurrentOperationCount = 1;
    }
    return _searchOperationQueue;
}


-(UIView *)bgView {
    if (!_bgView) {
        _bgView = [[UIView alloc] initWithFrame:CGRectMake(0, 50, self.view.bounds.size.width, self.view.bounds.size.height-50)];
        _bgView.backgroundColor = [UIColor colorWithWhite:248.0f/255.0f alpha:1.0f];
    }
    return _bgView;
}

-(UICollectionView *) collectionView {
    if (!_collectionView) {
        
        KTCenterFlowLayout *layout = [KTCenterFlowLayout new];
        layout.minimumInteritemSpacing = 10.f;
        layout.minimumLineSpacing = 10.f;
        
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(10, 50, self.view.bounds.size.width-20, self.view.bounds.size.height-50) collectionViewLayout:layout];
        [_collectionView setDataSource:self];
        [_collectionView setDelegate:self];
        _collectionView.allowsMultipleSelection = YES;
        
        _collectionView.alwaysBounceVertical = YES;
        _collectionView.backgroundColor = [UIColor colorWithWhite:248.0f/255.0f alpha:1.0f];
        [_collectionView registerClass:[SPCHashTagSuggestionCollectionViewCell class] forCellWithReuseIdentifier:CellIdentifier];
        [_collectionView registerClass:[SPCNoResultsCollectionViewCell class] forCellWithReuseIdentifier:@"noResults"];
        
        [_collectionView registerClass:[UICollectionReusableView class]
            forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                   withReuseIdentifier:@"sectionHeader"];
    }
    return _collectionView;
}

-(UICollectionReusableView *)headerView {
    
    if (!_headerView) {
        _headerView = [[UICollectionReusableView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width-20, 55)];
        _headerView.backgroundColor = [UIColor colorWithWhite:248.0f/255.0f alpha:1.0f];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.collectionView.frame.size.width, 55)];
        label.text = @"#'s LEFT HERE";
        label.textAlignment = NSTextAlignmentCenter;
        label.numberOfLines = 0;
        label.lineBreakMode = NSLineBreakByWordWrapping;
        label.font = [UIFont spc_regularSystemFontOfSize:14];
        label.textColor = [UIColor colorWithRed:139.0f/255.0f green:153.0f/255.0f blue:175.0f/255.0f alpha:1.0f];
        [_headerView addSubview:label];
        
    }
    return _headerView;
}

#pragma mark - UICollectionViewDataSource

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    if (section == 0) {
        if (self.filteredHashTags.count > 0) {
            return self.filteredHashTags.count;
        }
        else {
            return 1; //no results cell
        }
    }
    
    return 0;
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}


-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView hashCellForItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView registerClass:[SPCHashTagSuggestionCollectionViewCell class] forCellWithReuseIdentifier:CellIdentifier];
    
    NSString *itemText = self.filteredHashTags[indexPath.item];
    SPCHashTagSuggestionCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    BOOL selected = [self hashTagIsSelected:itemText];
    [cell configureWithHashTag:itemText selected:selected];
    return cell;
    
}


-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView noResultsCellForItemAtIndexPath:(NSIndexPath *)indexPath {

    [collectionView registerClass:[SPCNoResultsCollectionViewCell class] forCellWithReuseIdentifier:@"noResults"];
    SPCNoResultsCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"noResults" forIndexPath:indexPath];
    cell.contentView.backgroundColor = [UIColor clearColor];
    
    if (self.venueHashTags.count > 0) {
        cell.msgLbl.text = @"No memories here with #hashtags\nmatching that search";
    }
    
    return cell;
}
-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if (self.filteredHashTags.count > 0) {
        return [self collectionView:collectionView hashCellForItemAtIndexPath:indexPath];
    }
    else {
        return [self collectionView:collectionView noResultsCellForItemAtIndexPath:indexPath];
    }
}

-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    
    return CGSizeMake(self.view.frame.size.width, 55.0f);
}

-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if (self.filteredHashTags.count > 0) {
        
        NSString *itemText = @"";
        itemText = self.filteredHashTags[indexPath.item];
        float width = [self itemWidthForHashTag:itemText];
        
        return CGSizeMake(width, 30.0f);
    }
    else {
        return CGSizeMake(self.collectionView.bounds.size.width, self.collectionView.bounds.size.height);
    }
}


#pragma mark - UICollectionViewDelegate

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.filteredHashTags.count > 0) {
        SPCHashTagSuggestionCollectionViewCell *cell = (SPCHashTagSuggestionCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
        [self tappedHashTag:cell.tagLabel.text atIndexPath:indexPath];
    }
}

-(void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.filteredHashTags.count > 0) {
        SPCHashTagSuggestionCollectionViewCell *cell = (SPCHashTagSuggestionCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
        [self tappedHashTag:cell.tagLabel.text atIndexPath:indexPath];
    }
}


-(UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    UICollectionReusableView *reusableView = nil;
    
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        
        reusableView = [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                          withReuseIdentifier:@"sectionHeader"
                                                                 forIndexPath:indexPath];
        
        
            [reusableView addSubview:self.headerView];
        }
    
    return reusableView;
}


#pragma mark - UITextFieldDelegate - Editing the Text Field’s Text

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    return YES;
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *text = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    if (text.length == 0) {
        textField.text = @""; //NOTE: update immediately so reloadData works based on textfield.text length
        // Cancel previous filter request
        if (self.searchOperationQueue) {
            [self.searchOperationQueue cancelAllOperations];
        }
        self.filteredHashTags = self.venueHashTags;
        [self reloadData];
    }
    
    if (text.length > 0) {
        // Cancel previous filter request
        if (self.searchOperationQueue) {
            [self.searchOperationQueue cancelAllOperations];
        }
        textField.text = text; //NOTE: update immediately so reloadData works based on textfield.text length
        [self filterContentForSearchText:text];
    }
    
    
    return NO; //NOTE: return NO to avoid duplicate updates to search string
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField.returnKeyType == UIReturnKeyDefault) {
        [textField resignFirstResponder];
    }
    return YES;
}

-(BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    return YES;
}

#pragma mark - Actions

-(void)cancel {
    if ([self.textField isFirstResponder]) {
        [self.textField resignFirstResponder];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)tappedHashTag:(NSString *)hashTag atIndexPath:(NSIndexPath *)indexPath {
    
    
    if (![self hashTagIsSelected:hashTag])  {
    
        //strip out the #s
        NSString *cleanTag = [hashTag substringFromIndex:1];

        //update delegate
        if (self.delegate && [self.delegate respondsToSelector:@selector(showMemoriesForHashTag:)]) {
            [self.delegate showMemoriesForHashTag:cleanTag];
        }
    }
    else {
        //update delegate
        if (self.delegate && [self.delegate respondsToSelector:@selector(showMemoriesForHashTag:)]) {
            [self.delegate showMemoriesForHashTag:@""];
        }
    }
    //dismiss vc
    [self cancel];
}


#pragma mark - Private

-(void)reloadData {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.collectionView reloadData];
    });
}

-(BOOL)hashTagIsSelected:(NSString *)hashTag {
    BOOL alreadyIncluded = NO;
    
    if ([hashTag isEqualToString:self.activeTag]) {
        alreadyIncluded = YES;
    }
    return alreadyIncluded;
}

-(float)itemWidthForHashTag:(NSString *)hashTag {
    
    NSDictionary *attributes = @{ NSFontAttributeName: [UIFont spc_mediumSystemFontOfSize:14] };
    CGRect frame = [hashTag boundingRectWithSize:CGSizeMake(self.view.frame.size.width, 20)
                                         options:NSStringDrawingUsesLineFragmentOrigin
                                      attributes:attributes
                                         context:NULL];
    
    return frame.size.width + 15 + 30;
}


#pragma mark - Content filtering

-(void)filterContentForSearchText:(NSString *)searchText {
    NSBlockOperation *operation = [[NSBlockOperation alloc] init];
    
    __weak typeof(self)weakSelf = self;
    __weak typeof(operation)weakOperation = operation;
    
    [operation addExecutionBlock:^{
        __strong typeof(weakSelf)strongSelf = weakSelf;
        __strong typeof(weakOperation)strongOperation = weakOperation;
        
        NSString *expression=[NSString stringWithFormat:@"SELF contains '%@'",searchText];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:expression];
        NSArray *filteredTags = [strongSelf.venueHashTags filteredArrayUsingPredicate:predicate];
        
        if (strongOperation.isCancelled) {
            return;
        }
        
        strongSelf.filteredHashTags = filteredTags;
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if (strongOperation.isCancelled) {
                return;
            }
            [strongSelf reloadData];
        }];
    }];
    [self.searchOperationQueue addOperation:operation];
}

#pragma  mark - Orientation Methods

-(NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
}
@end
