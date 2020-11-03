//
//  SPCHashTagSuggestions.h
//  Spayce
//
//  Created by Christopher Taylor on 12/10/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>



@protocol SPCHashTagSuggestionsDelegate <NSObject>

@optional
- (void)tappedToAddLocationHashTag:(NSString *)hashTag;
- (void)tappedToAddHashTag:(NSString *)hashTag;
- (void)tappedToRemoveHashTag:(NSString *)hashTag;
- (void)hashTagsDidScroll;
@end

@interface SPCHashTagSuggestions : UIView <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, weak) NSObject <SPCHashTagSuggestionsDelegate> *delegate;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSArray *locationHashTags;
@property (nonatomic, strong) NSArray *selectedHashTags;

-(NSArray *)getSelectedHashTags;
-(void)updateRecentHashTags;
-(void)addedHashTagViaKeyboard:(NSString *)hashTag;
-(void)deletedHashTagViaKeyboard:(NSString *)hashTag;
-(void)updateAllSelectedHashTags:(NSMutableArray *)hashTags;
-(void)updateForNewMam;
@end
