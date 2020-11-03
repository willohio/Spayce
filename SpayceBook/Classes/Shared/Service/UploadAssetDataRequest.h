//
//  UploadAssetDataRequest.h
//  SpayceBook
//
//  Created by Dmitry Miller on 7/7/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * UploadAssetDataRequestDidStartNotification;
extern NSString * UploadAssetDataRequestDidEndNotification;

@interface UploadAssetDataRequest : NSObject
{
    BOOL initiated;
    NSMutableData *responseData;
}

@property (nonatomic, strong) NSData *data;
@property (nonatomic, strong) NSString *url;
@property (nonatomic, strong) NSDictionary *queryParams;
@property (nonatomic, copy) void (^resultCallback)(NSObject *result);
@property (nonatomic, copy) void (^progressCallback)(NSInteger bytesWritten, NSInteger bytesExpectedToWrite);
@property (nonatomic, copy) void (^faultCallback)(NSError *fault);

- (void)start:(NSOperationQueue *)operationQueue;
- (void)startVideo:(NSOperationQueue *)operationQueue;
- (void)startAudio:(NSOperationQueue *)operationQueue;

@end
