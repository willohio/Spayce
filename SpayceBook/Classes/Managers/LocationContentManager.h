//
//  LocationContentManager.h
//  Spayce
//
//  Created by Jake Rosin on 5/21/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <CoreLocation/CoreLocation.h>

// Types of Content.  Users of this class can make requests for a specific
// set of content types.
extern NSString *SPCLocationContentVenue;
extern NSString *SPCLocationContentDeviceVenue;
extern NSString *SPCLocationContentNearbyVenues;
extern NSString *SPCLocationContentFuzzedVenue;

extern NSString * SPCLocationContentFuzzedNeighborhoodVenue;
extern NSString * SPCLocationContentFuzzedCityVenue;


// NSError domain / types.
extern NSString * SPC_LCM_ErrorDomain;
extern NSString * SPC_LCM_ErrorInfoKey_Content;
extern NSString * SPC_LCM_ErrorInfoKey_NSError;
extern NSInteger SPC_LCM_ErrorCode_InternalInconsistency;
extern NSInteger SPC_LCM_ErrorCode_NoLocation;
extern NSInteger SPC_LCM_ErrorCode_ContentFetch;

// Location Content updated
extern NSString * SPCLocationContentVenuesUpdatedInternally;
extern NSString * SPCLocationContentUpdatedInternally;

extern NSString * SPCLocationContentNearbyVenuesUpdatedFromServer;


@interface LocationContentManager : NSObject

@property (nonatomic, readonly) CLLocation *contentLocation;

+(LocationContentManager *)sharedInstance;

-(void) clearContentAndLocation;
-(void) clearContent:(NSArray *)contentTypes;

-(void) getContentFromCache:(NSArray *)contentTypes resultCallback:(void (^)(NSDictionary *results))resultCallback faultCallback:(void (^)(NSError *fault))faultCallback;

-(void) getContent:(NSArray *)contentTypes resultCallback:(void (^)(NSDictionary *results))resultCallback faultCallback:(void (^)(NSError *fault))faultCallback;

-(void) getContent:(NSArray *)contentTypes progressCallback:(void (^)(NSDictionary *partialResults, BOOL *cancel))progressCallback resultCallback:(void (^)(NSDictionary *results))resultCallback faultCallback:(void (^)(NSError *fault))faultCallback;

-(void) getUncachedContent:(NSArray *)contentTypes resultCallback:(void (^)(NSDictionary *results))resultCallback faultCallback:(void (^)(NSError *fault))faultCallback;

-(void) getUncachedContent:(NSArray *)contentTypes progressCallback:(void (^)(NSDictionary *partialResults, BOOL *cancel))progressCallback resultCallback:(void (^)(NSDictionary *results))resultCallback faultCallback:(void (^)(NSError *fault))faultCallback;



@end
