//
//  APIService.m
//  SpayceBook
//
//  Created by Dmitry Miller on 7/3/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import "APIService.h"

// Manager
#import "SpayceSessionManager.h"

// Utility
#import "APIUtils.h"

// Networking
#import "AddressBookRequest.h"
#import "UploadAssetDataRequest.h"

@implementation APIService

NSString *HEADER_DEVICE_KEY = @"X-DEVICE";
NSString *HEADER_AUTH_KEY = @"X-AUTH";
NSString *PRIVATE_KEY = @"6BC1783B-6A81-4570-92A3-C6691A6B02E3";
NSString *DEVICE_TYPE = @"IPHONE";

#pragma mark - Accessors

+ (NSString *)baseUrl {
    return @"https://www.inspayce.com/spayce-server"; // Production
//    return @"http://staging.inspayce.com/spayce-server"; // Staging
//    return @"http://dev.inspayce.com/spayce-server"; // Development
//    return @"http://192.168.0.110:8080/spayce-server"; // Local (Jake)
//    return @"http://devdyndb.inspayce.com/spayce-server"; //Dynamo
}

+ (NSString *)getXAuthHeader:(NSString *)url {
    NSTimeInterval currentDate = [[NSDate date] timeIntervalSince1970];

    NSString *dateStr = [[NSString stringWithFormat:@"%f", currentDate] stringByReplacingOccurrencesOfString:@"." withString:@""];

    NSString *token = [PRIVATE_KEY stringByAppendingFormat:@",Spayce,%@,%@", dateStr, url];
    //NSLog(@"token: %@", token);

    NSString *xAuth = [NSString stringWithFormat:@"%@,%@", dateStr, [APIUtils md5:token]];
    //NSLog(@"X-AUTH: %@", xAuth);

    return xAuth;
}

+ (NSString *)getXDeviceHeader
{
    NSString *xDevice = [DEVICE_TYPE stringByAppendingFormat:@",%@,%@",
                         [[SpayceSessionManager sharedInstance] getUUID],
                         [NSBundle mainBundle].infoDictionary[@"CFBundleVersion"]];
    //NSLog(@"X-DEVICE: %@", xDevice);

    return xDevice;
}

+ (NSOperationQueue *)apiRequestQueue
{
    static NSOperationQueue *queue = nil;
    
    if (!queue) {
        queue = [[NSOperationQueue alloc] init];
    }
    
    return queue;
}

+ (NSOperationQueue *)assetUploadQueue
{
    static NSOperationQueue *assetQueue = nil;
    
    if (!assetQueue) {
        assetQueue = [[NSOperationQueue alloc] init];
    }
    
    return assetQueue;
}

#pragma mark - Actions

+ (void)makeApiCallWithMethodUrl:(NSString *)methodUrl
                  resultCallback:(void (^)(NSObject * result))resultCallback
                   faultCallback:(void (^)(NSError * fault))faultCallback
{
    [APIService makeApiCallWithMethodUrl:methodUrl
                          andRequestType:RequestTypeGet
                           andPathParams:nil
                          andQueryParams:nil
                          resultCallback:resultCallback
                           faultCallback:faultCallback
                              foreignAPI:NO];
}

+ (void)makeApiCallWithMethodUrl:(NSString *)methodUrl
                  andRequestType:(RequestType)requestType
                   andPathParams:(NSArray *)pathParams
                  andQueryParams:(NSDictionary *)queryParams
                  resultCallback:(void (^)(NSObject * result))resultCallback
                   faultCallback:(void (^)(NSError * fault))faultCallback
{
    [APIService makeApiCallWithMethodUrl:methodUrl
                          andRequestType:requestType
                           andPathParams:pathParams
                          andQueryParams:queryParams
                          resultCallback:resultCallback
                           faultCallback:faultCallback
                              foreignAPI:NO];
}

+ (void)makeApiCallWithMethodUrl:(NSString *)methodUrl
                  andRequestType:(RequestType)requestType
                   andPathParams:(NSArray *)pathParams
                  andQueryParams:(NSDictionary *)queryParams
                  resultCallback:(void (^)(NSObject * result))resultCallback
                   faultCallback:(void (^)(NSError * fault))faultCallback
                      foreignAPI:(BOOL)foreignAPI
{
    
    NSString *fullUrl;
    if (foreignAPI) {
        fullUrl = methodUrl;
    } else {
        fullUrl = [[APIService baseUrl] stringByAppendingString:methodUrl];
    }
    
    NSDictionary *actualQueryParams = queryParams;
    
    if ([SpayceSessionManager sharedInstance].currentSessionId.length > 0 && !foreignAPI) {
        actualQueryParams = queryParams != nil ? [NSMutableDictionary dictionaryWithDictionary:queryParams] : [NSMutableDictionary dictionaryWithCapacity:1];
        
       ((NSMutableDictionary *)actualQueryParams)[@"ses"] = [SpayceSessionManager sharedInstance].currentSessionId;
    }
    
    APIServiceRequest *request = [[APIServiceRequest alloc] init];
    request.url = fullUrl;
    request.type = requestType;
    request.queryParams = actualQueryParams;
    request.pathParams = pathParams;
    request.timeoutInterval = 60;
    request.resultCallback = resultCallback;
    request.faultCallback = faultCallback;
    request.foreignAPI = foreignAPI;

    [request start:[APIService apiRequestQueue]];
}

+ (void)uploadAssetToSpayceVaultWithData:(NSData *)assetData
                          andQueryParams:(NSDictionary *)queryParams
                        progressCallback:(void (^)(NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite))progressCallback
                          resultCallback:(void (^)(Asset * asset))resultCallback
                           faultCallback:(void (^)(NSError * fault))faultCallback {
    [APIService uploadAssetWithMethodURL:@"/spaycevault/upload"
                                 andData:assetData
                          andQueryParams:queryParams
                           andMaxRetries:1
                        progressCallback:progressCallback
                          resultCallback:^(NSObject *result) {
                              // TODO: @JR - Can you please review this code
                              //           - It's faulty for the case that faultCallback is nil in the firstplace (run an analyzer an you'll see)
                              //           - I have wrapped resultCallback & faultCallback's execution within a condition that checks for their availability - please review if this is a correct behavior
                              if (!result) {
                                  if (faultCallback) {
                                      faultCallback(nil);
                                      // TODO: @JR - How about putting a return; statement here, would omit the next couple lines from execution
                                  }
                              }
                              
                              Asset *asset = [[Asset alloc] initWithAttributes:(NSDictionary *)result];
                              if (asset) {
                                  if (resultCallback) {
                                      resultCallback(asset);
                                  }
                              }
                              else if (!asset) {
                                  if (faultCallback) {
                                      faultCallback(nil);
                                  }
                              }
                          } faultCallback:faultCallback];
}

+ (void)uploadVideoAssetToSpayceVaultWithData:(NSData *)assetData
                               andQueryParams:(NSDictionary *)queryParams
                             progressCallback:(void (^)(NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite))progressCallback
                               resultCallback:(void (^)(Asset * asset))resultCallback
                                faultCallback:(void (^)(NSError * fault))faultCallback {
    [APIService uploadVideoAssetWithMethodURL:@"/spaycevault/upload"
                                      andData:assetData
                               andQueryParams:queryParams
                                andMaxRetries:1
                             progressCallback:progressCallback
                               resultCallback:^(NSObject *result) {
                                   // TODO: @JR - Can you please review this code
                                   //           - It's faulty for the case that faultCallback is nil in the firstplace (run an analyzer an you'll see)
                                   //           - I have wrapped resultCallback & faultCallback's execution within a condition that checks for their availability - please review if this is a correct behavior
                                   if (!result) {
                                       if (faultCallback) {
                                           faultCallback(nil);
                                           // TODO: @JR - How about putting a return; statement here, would omit the next couple lines from execution
                                       }
                                   }
                                   
                                   Asset *asset = [[Asset alloc] initWithAttributes:(NSDictionary *)result];
                                   if (asset) {
                                       if (resultCallback) {
                                           resultCallback(asset);
                                       }
                                   }
                                   else {
                                       if (faultCallback) {
                                           faultCallback(nil);
                                       }
                                   }
                               } faultCallback:faultCallback];
}

+ (void)uploadVideoAssetWithMethodURL:(NSString *)methodUrl
                             andData:(NSData *)assetData
                      andQueryParams:(NSDictionary *)queryParams
                    progressCallback:(void (^)(NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite))progressCallback
                      resultCallback:(void (^)(NSObject * result))resultCallback
                       faultCallback:(void (^)(NSError * fault))faultCallback
{
    NSLog(@"uploadVideoAssetWithMethodURL");
    [APIService uploadVideoAssetWithMethodURL:methodUrl
                                     andData:assetData
                              andQueryParams:queryParams
                               andMaxRetries:1
                            progressCallback:progressCallback
                              resultCallback:resultCallback
                               faultCallback:faultCallback];
    
}

+ (void)uploadAudioAssetWithMethodURL:(NSString *)methodUrl
                              andData:(NSData *)assetData
                       andQueryParams:(NSDictionary *)queryParams
                     progressCallback:(void (^)(NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite))progressCallback
                       resultCallback:(void (^)(NSObject * result))resultCallback
                        faultCallback:(void (^)(NSError * fault))faultCallback
{
    NSLog(@"uploadAudioAssetWithMethodURL");
    [APIService uploadAudioAssetWithMethodURL:methodUrl
                                      andData:assetData
                               andQueryParams:queryParams
                                andMaxRetries:1
                             progressCallback:progressCallback
                               resultCallback:resultCallback
                                faultCallback:faultCallback];
    
}

+ (void)uploadAssetWithMethodURL:(NSString *)methodUrl
                         andData:(NSData *)assetData
                  andQueryParams:(NSDictionary *)queryParams
                   andMaxRetries:(NSUInteger)maxRetries
                progressCallback:(void (^)(NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite))progressCallback
                  resultCallback:(void (^)(NSObject * result))resultCallback
                   faultCallback:(void (^)(NSError * fault))faultCallback
{
    @try
    {
        NSString *fullUrl = [[APIService baseUrl] stringByAppendingString:methodUrl];

        NSDictionary *actualQueryParams = queryParams;

        if ([SpayceSessionManager sharedInstance].currentSessionId.length > 0) {
            actualQueryParams = queryParams == nil ? [NSMutableDictionary dictionaryWithCapacity:1] : [NSMutableDictionary dictionaryWithDictionary:queryParams];

            ((NSMutableDictionary *)actualQueryParams)[@"ses"] = [SpayceSessionManager sharedInstance].currentSessionId;
        }

        NSLog(@"fullURL%@",fullUrl);
        NSLog(@"query params %@",actualQueryParams);
        
        __block NSError *lastFault = nil;
        __block NSInteger numAttempts = 0;
        __block void (^doUpload)(void) = nil;

        void (^actualFaultCallback)(NSError * fault) = ^(NSError * fault) {
            lastFault = fault;

            if (numAttempts >= maxRetries) {
                
                if (faultCallback) {
                    faultCallback(lastFault);
                }
            } else {
                doUpload();
            }
        };

        doUpload = ^ {
            numAttempts ++;

            UploadAssetDataRequest *request = [[UploadAssetDataRequest alloc] init];
            request.url = fullUrl;
            request.data= assetData;
            request.queryParams = actualQueryParams;
            request.resultCallback = resultCallback;
            request.progressCallback = progressCallback;
            request.faultCallback  = actualFaultCallback;

            [request start:[APIService assetUploadQueue]];
        };
        
        doUpload();
    }
    @catch (NSException *exception)
    {
        if (faultCallback) {
            faultCallback(nil);
        }
    }
}

+ (void)uploadVideoAssetWithMethodURL:(NSString *)methodUrl
                         andData:(NSData *)assetData
                  andQueryParams:(NSDictionary *)queryParams
                   andMaxRetries:(NSUInteger)maxRetries
                progressCallback:(void (^)(NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite))progressCallback
                  resultCallback:(void (^)(NSObject * result))resultCallback
                   faultCallback:(void (^)(NSError * fault))faultCallback
{
    @try
    {
        NSString *fullUrl = [[APIService baseUrl] stringByAppendingString:methodUrl];
        
        NSDictionary *actualQueryParams = queryParams;
        
        if ([SpayceSessionManager sharedInstance].currentSessionId.length > 0) {
            actualQueryParams = queryParams == nil ? [NSMutableDictionary dictionaryWithCapacity:1] : [NSMutableDictionary dictionaryWithDictionary:queryParams];
            
            ((NSMutableDictionary *)actualQueryParams)[@"ses"] = [SpayceSessionManager sharedInstance].currentSessionId;
        }
        
        NSLog(@"fullURL for vid upload%@",fullUrl);
        NSLog(@"query params %@",actualQueryParams);
        
        __block NSError *lastFault = nil;
        __block NSInteger numAttempts = 0;
        __block void (^doUpload)(void) = nil;
        
        void (^actualFaultCallback)(NSError * fault) = ^(NSError * fault) {
            lastFault = fault;
            
            if (numAttempts >= maxRetries) {
                if (faultCallback) {
                    faultCallback(lastFault);
                }
            } else {
                doUpload();
            }
        };
        
        doUpload = ^ {
            numAttempts ++;
            
            UploadAssetDataRequest *request = [[UploadAssetDataRequest alloc] init];
            request.url = fullUrl;
            request.data= assetData;
            request.queryParams = actualQueryParams;
            request.resultCallback = resultCallback;
            request.progressCallback = progressCallback;
            request.faultCallback  = actualFaultCallback;
            [request startVideo:[APIService assetUploadQueue]];
            
        };
        
        doUpload();
    }
    @catch (NSException *exception)
    {
        if (faultCallback) {
            faultCallback(nil);
        }
    }
}

+ (void)uploadAudioAssetWithMethodURL:(NSString *)methodUrl
                              andData:(NSData *)assetData
                       andQueryParams:(NSDictionary *)queryParams
                        andMaxRetries:(NSUInteger)maxRetries
                     progressCallback:(void (^)(NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite))progressCallback
                       resultCallback:(void (^)(NSObject * result))resultCallback
                        faultCallback:(void (^)(NSError * fault))faultCallback
{
    @try
    {
        NSString *fullUrl = [[APIService baseUrl] stringByAppendingString:methodUrl];
        
        NSDictionary *actualQueryParams = queryParams;
        
        if ([SpayceSessionManager sharedInstance].currentSessionId.length > 0) {
            actualQueryParams = queryParams == nil ? [NSMutableDictionary dictionaryWithCapacity:1] : [NSMutableDictionary dictionaryWithDictionary:queryParams];
            
            ((NSMutableDictionary *)actualQueryParams)[@"ses"] = [SpayceSessionManager sharedInstance].currentSessionId;
        }
        
        NSLog(@"fullURL for vid upload%@",fullUrl);
        NSLog(@"query params %@",actualQueryParams);
        
        __block NSError *lastFault = nil;
        __block NSInteger numAttempts = 0;
        __block void (^doUpload)(void) = nil;
        
        void (^actualFaultCallback)(NSError * fault) = ^(NSError * fault) {
            lastFault = fault;
            
            if (numAttempts >= maxRetries) {
                if (faultCallback) {
                    faultCallback(lastFault);
                }
            } else {
                doUpload();
            }
        };
        
        doUpload = ^ {
            numAttempts ++;
            
            UploadAssetDataRequest *request = [[UploadAssetDataRequest alloc] init];
            request.url = fullUrl;
            request.data= assetData;
            request.queryParams = actualQueryParams;
            request.resultCallback = resultCallback;
            request.progressCallback = progressCallback;
            request.faultCallback  = actualFaultCallback;
            [request startAudio:[APIService assetUploadQueue]];
            
        };
        
        doUpload();
    }
    @catch (NSException *exception)
    {
        if (faultCallback) {
            faultCallback(nil);
        }
    }
}

+ (void)uploadAddressBookWithMethodURL:(NSString *)methodUrl
                 addressBookDictionary:(NSDictionary *)addressBookDictionary
                     completionHandler:(void (^)(NSObject *result))completionHandler
                          errorHandler:(void (^)(NSError *error))errorHandler {
    NSString *urlString = [[APIService baseUrl] stringByAppendingString:methodUrl];
    
    if ([SpayceSessionManager sharedInstance].currentSessionId.length > 0) {
//        [(NSMutableDictionary *)actualQueryParams setObject:[SpayceSessionManager sharedInstance].currentSessionId forKey:@"ses"];
    }
    
    AddressBookRequest *request = [[AddressBookRequest alloc] init];
    request.url = urlString;
    request.addressBookDictionary = addressBookDictionary;
//    request.queryParams = actualQueryParams;
    request.timeoutInterval = 60;
    request.completionHandler = completionHandler;
    request.errorHandler = errorHandler;
    
    [request start:[APIService apiRequestQueue]];
}

@end
