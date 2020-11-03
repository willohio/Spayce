//
//  APIService.h
//  SpayceBook
//
//  Created by Dmitry Miller on 7/3/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "APIServiceRequest.h"
#import "Asset.h"

extern NSString *HEADER_DEVICE_KEY;
extern NSString *HEADER_AUTH_KEY;
extern NSString *PRIVATE_KEY;
extern NSString *DEVICE_TYPE;

@interface APIService : NSObject

+ (NSString *)baseUrl;
+ (NSString *)getXAuthHeader:(NSString *)url;
+ (NSString *)getXDeviceHeader;
+ (NSOperationQueue *)apiRequestQueue;
+ (NSOperationQueue *)assetUploadQueue;

+ (void)makeApiCallWithMethodUrl:(NSString *)methodUrl
                  resultCallback:(void (^)(NSObject * result))resultCallback
                   faultCallback:(void (^)(NSError * fault))faultCallback;

+ (void)makeApiCallWithMethodUrl:(NSString *)methodUrl
                  andRequestType:(RequestType)requestType
                   andPathParams:(NSArray *)pathParams
                  andQueryParams:(NSDictionary *)queryParams
                  resultCallback:(void (^)(NSObject * result))resultCallback
                   faultCallback:(void (^)(NSError * fault))faultCallback;

+ (void)makeApiCallWithMethodUrl:(NSString *)methodUrl
                  andRequestType:(RequestType)requestType
                   andPathParams:(NSArray *)pathParams
                  andQueryParams:(NSDictionary *)queryParams
                  resultCallback:(void (^)(NSObject * result))resultCallback
                   faultCallback:(void (^)(NSError * fault))faultCallback
                      foreignAPI:(BOOL)foreignAPI;

+ (void)uploadAssetToSpayceVaultWithData:(NSData *)assetData
                          andQueryParams:(NSDictionary *)queryParams
                        progressCallback:(void (^)(NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite))progressCallback
                          resultCallback:(void (^)(Asset * asset))resultCallback
                           faultCallback:(void (^)(NSError * fault))faultCallback;

+ (void)uploadVideoAssetWithMethodURL:(NSString *)methodUrl
                             andData:(NSData *)assetData
                      andQueryParams:(NSDictionary *)queryParams
                    progressCallback:(void (^)(NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite))progressCallback
                      resultCallback:(void (^)(NSObject * result))resultCallback
                       faultCallback:(void (^)(NSError * fault))faultCallback;


+ (void)uploadAudioAssetWithMethodURL:(NSString *)methodUrl
                              andData:(NSData *)assetData
                       andQueryParams:(NSDictionary *)queryParams
                     progressCallback:(void (^)(NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite))progressCallback
                       resultCallback:(void (^)(NSObject * result))resultCallback
                        faultCallback:(void (^)(NSError * fault))faultCallback;

+ (void)uploadVideoAssetToSpayceVaultWithData:(NSData *)assetData
                               andQueryParams:(NSDictionary *)queryParams
                             progressCallback:(void (^)(NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite))progressCallback
                               resultCallback:(void (^)(Asset * asset))resultCallback
                                faultCallback:(void (^)(NSError * fault))faultCallback;

+ (void)uploadVideoAssetWithMethodURL:(NSString *)methodUrl
                              andData:(NSData *)assetData
                       andQueryParams:(NSDictionary *)queryParams
                        andMaxRetries:(NSUInteger)maxRetries
                     progressCallback:(void (^)(NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite))progressCallback
                       resultCallback:(void (^)(NSObject * result))resultCallback
                        faultCallback:(void (^)(NSError * fault))faultCallback;

+ (void)uploadAudioAssetWithMethodURL:(NSString *)methodUrl
                              andData:(NSData *)assetData
                       andQueryParams:(NSDictionary *)queryParams
                        andMaxRetries:(NSUInteger)maxRetries
                     progressCallback:(void (^)(NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite))progressCallback
                       resultCallback:(void (^)(NSObject * result))resultCallback
                        faultCallback:(void (^)(NSError * fault))faultCallback;

+ (void)uploadAddressBookWithMethodURL:(NSString *)methodUrl
                 addressBookDictionary:(NSDictionary *)addressBookDictionary
                     completionHandler:(void (^)(NSObject *result))completionHandler
                          errorHandler:(void (^)(NSError *error))errorHandler;

@end
