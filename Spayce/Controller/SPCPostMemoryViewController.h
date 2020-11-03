//
//  SPCPostMemoryViewController.h
//  Spayce
//
//  Created by Christopher Taylor on 5/4/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SPCTagFriendsViewController.h"
#import "SPCMapViewController.h"
#import "SPCImageEditingController.h"
#import "SPCCity.h"

@class Venue;
@class SPCAssetUploadCoordinator;
@class SPCPendingAsset;

@protocol SPCPostMemoryViewControllerDelegate <NSObject>

@optional

- (void)spcPostMemoryViewControllerDidCancel:(id)sender withSelectedVenue:(Venue *)venue;
- (void)spcPostMemoryViewControllerDidCancel:(id)sender withSelectedTerritory:(SPCCity *)territory;
- (void)spcPostMemoryViewControllerDidCancelToUpdateLocation:(id)sender withSelectedVenue:(Venue *)venue;
- (void)spcPostMemoryViewControllerDidFinish:(id)sender;
- (void)spcPostMemoryViewControllerDidUpdatePendingAssets:(SPCAssetUploadCoordinator *)assetUploadCoordinator;
- (void)spcPostMemoryViewControllerUpdateTaggedFriendsToRestore:(NSArray *)selectedFriends;
- (void)spcPostMemoryViewControllerUpdateMemoryTextToRestore:(NSString *)textToRestore;
- (void)spcPostMemoryViewControllerAnimateInChangeLocation;
- (void)updateSelectedVenue:(Venue *)venue;
- (void)updateSelectedTerritory:(SPCCity *)territory;
- (void)spcPostMemoryViewControllerUpdateAnonStatusToRestore:(BOOL)isAnon;
@end

@interface SPCPostMemoryViewController : UIViewController <UITextViewDelegate, SPCTagFriendsViewControllerDelegate, SPCMapViewControllerDelegate, SPCImageEditingControllerDelegate> {
    
    SPCPendingAsset *editingAsset;
}

@property (nonatomic, weak) NSObject <SPCPostMemoryViewControllerDelegate> *delegate;
@property (nonatomic, strong) Venue *selectedVenue;
@property (nonatomic, strong) SPCCity *selectedTerritory;
@property (nonatomic, assign) BOOL resetVenueIfAssetsDeleted;

-(void)configureWithAssetUploadCoordinator:(SPCAssetUploadCoordinator *)assetUploadCoordinator canEdit:(BOOL)canEdit;
-(void)restoreSelectedFriends:(NSArray *)selectedFriends;
-(void)restoreMemoryText:(NSString *)textToRestore;
-(void)restoreAnon:(BOOL)isAnon;
-(void)pickLocation;
-(void)setFuzzedDefaultForTextMem;
- (void)updateLocationWithTerritory:(SPCCity *)territory;
@end
