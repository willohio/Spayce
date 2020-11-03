//
//  SettingsManager.h
//  SpayceBook
//
//  Created by Dmitry Miller on 8/10/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SettingsManager : NSObject

+ (SettingsManager *)sharedInstance;

@property (assign, nonatomic) BOOL friendsHereEnabled;
@property (assign, nonatomic) BOOL fbAutoShareEnabled;
@property (assign, nonatomic) BOOL twitAutoShareEnabled;
@property (assign, nonatomic) BOOL anonPostingEnabled;
@property (nonatomic, assign) NSInteger numStarsNeeed;
@property (assign, nonatomic) BOOL anonWarningNeeded;
@property (nonatomic, assign) NSInteger currAnonWarningCount;
@property (assign, nonatomic) BOOL adminWarningNeeded;
@property (assign, nonatomic) NSInteger currAdminWarningCount;

- (void)saveSettings;

- (void)updateAutoShareToFacebookEnabled:(BOOL)autoShareToFacebookEnabled
                       completionHandler:(void (^)(BOOL availability))completionHandler
                            errorHandler:(void (^)(NSError *error))errorHandler;

- (void)updateAutoShareToTwitterEnabled:(BOOL)autoShareToTwitterEnabled
                      completionHandler:(void (^)(BOOL availability))completionHandler
                           errorHandler:(void (^)(NSError *error))errorHandler;

- (void)updateProfileLocked:(BOOL)profileLocked
          completionHandler:(void (^)(BOOL locked))completionHandler
               errorHandler:(void (^)(NSError *error))errorHandler;

@end
