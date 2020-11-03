//
//  SocialService.m
//  Spayce
//
//  Created by Pavel Dušátko on 1/25/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SocialService.h"
#import "Flurry.h"

// Framework
#import <FacebookSDK/FacebookSDK.h>

// Model
#import "SocialProfile.h"

// General
#import "Singleton.h"
#import "SPCLiterals.h"

// Manager
#import "AuthenticationManager.h"
#import "SpayceSessionManager.h"

// Utility
#import "APIService.h"
#import "FHSTwitterEngine.h"
#import "LIALinkedInHttpClient.h"
#import "LIALinkedInApplication.h"
#import "TranslationUtils.h"

@interface SocialService () <FHSTwitterEngineAccessTokenDelegate>

@property (nonatomic, strong) LIALinkedInHttpClient *linkedInClient;
@property (nonatomic, assign) BOOL facebookAvailable;
@property (nonatomic, assign) BOOL twitterAvailable;
@property (nonatomic, assign) BOOL linkedAvailable;
@property (nonatomic, assign) BOOL refreshNeeded;

@property (nonatomic, readonly) NSArray *facebookServicePermissions;

@end

@implementation SocialService



#pragma mark - NSObject - Creating, Copying, and Deallocating Objects

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

SINGLETON_GCD(SocialService);

- (id)init {
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleApplicationWillTerminate:)
                                                     name:UIApplicationWillTerminateNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleApplicationDidBecomeActive:)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleLogout)
                                                     name:kAuthenticationDidLogoutNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(checkServiceAvailability)
                                                     name:kAuthenticationDidFinishWithSuccessNotification object:nil];
    }
    
    return self;
}

#pragma mark - Service name

- (NSString *)serviceNameForType:(NSInteger)type {
    if (type == SocialServiceTypeFacebook) {
        return @"Facebook";
    } else if (type == SocialServiceTypeTwitter) {
        return @"Twitter";
    } else if (type == SocialServiceTypeLinkedIn) {
        return @"LinkedIn";
    } else if (type == SocialServiceTypeAddressBook) {
        return @"Contacts";
    }
    else {
        return nil;
    }
}

#pragma mark - Service permissions

- (NSArray *)facebookServicePermissions {
    return @[@"public_profile", @"user_friends", @"email"];
}

#pragma mark - Service Availability

-(void)checkServiceAvailability {
    
    //NSLog(@"check social service avaiability");

    NSString *url = @"/availableSocialServices";
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypeGet
                           andPathParams:nil
                          andQueryParams:nil
                          resultCallback:^(NSObject *result) {
                              NSDictionary *JSON = (NSDictionary *)result;
                             
                              NSDictionary *service;
                              
                              for (service in JSON) {
                                  if ([service[@"socialMediaType"] isEqualToString:@"LINKEDIN"]){
                                      self.linkedAvailable = YES;
                                  }
                                  if ([service[@"socialMediaType"] isEqualToString:@"FACEBOOK"]){
                                      self.facebookAvailable = YES;
                                  }
                                  if ([service[@"socialMediaType"] isEqualToString:@"TWITTER"]){
                                      self.twitterAvailable = YES;
                                  }
                              }
                              if (self.refreshNeeded){
                                  [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshSocial" object:nil];
                              }
                             
                          } faultCallback:^(NSError *error) {
                             
                          }];
}



- (BOOL)availabilityForServiceType:(NSInteger)type {
    if (type == SocialServiceTypeFacebook) {
        return self.facebookAvailable;
    }
    else if (type == SocialServiceTypeTwitter) {
         return self.twitterAvailable;
    }
    else if (type == SocialServiceTypeLinkedIn) {
        return self.linkedAvailable;
    }
    else return NO;
}

#pragma mark - Authentication

- (void)authSocialServiceType:(NSInteger)type
               viewController:(UIViewController *)viewController
            completionHandler:(void (^)())completionHandler
                 errorHandler:(void (^)(NSError *error))errorHandler {
    if (type == SocialServiceTypeFacebook) {
        [self authFacebookWithCompletionHandler:completionHandler errorHandler:errorHandler];
    } else if (type == SocialServiceTypeTwitter) {
        [self authTwitterWithViewController:viewController completionHandler:completionHandler errorHandler:errorHandler];
    } else if (type == SocialServiceTypeLinkedIn) {
        [self authLinkedInWithViewController:viewController completionHandler:completionHandler errorHandler:errorHandler];
    }
}

- (void)authFacebookWithCompletionHandler:(void (^)())completionHandler
                             errorHandler:(void (^)(NSError *error))errorHandler {
    NSLog(@"authFB");
    FBSession *session = [FBSession activeSession];
    if (session.state == FBSessionStateOpen || session.state == FBSessionStateOpenTokenExtended) {
        NSLog(@"FB session open / extended");
        [self completeFacebookAuthWithAccessToken:session.accessTokenData.accessToken
                                completionHandler:completionHandler
                                     errorHandler:errorHandler];
        
        return;
    } else if (session.state == FBSessionStateCreatedTokenLoaded) {
         NSLog(@"FBSessionStateCreatedTokenLoaded");
        __weak typeof(self)weakSelf = self;
        
        [session openWithCompletionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
            __strong typeof(weakSelf)strongSelf = weakSelf;
            
            if (error) {
                NSLog(@"error in FB auth!");
                [session closeAndClearTokenInformation];
                
                [strongSelf authFacebookWithCompletionHandler:completionHandler
                                                 errorHandler:errorHandler];
            } else {
                NSLog(@"complete FB auth!");
                [strongSelf completeFacebookAuthWithAccessToken:session.accessTokenData.accessToken
                                              completionHandler:completionHandler
                                                   errorHandler:errorHandler];
            }
        }];
    } else {
        
        [[FBSession activeSession] closeAndClearTokenInformation];
        [FBSession.activeSession close];
        [FBSession setActiveSession:nil];
        [self completeLoginToFBWithCompletionHandler:completionHandler errorHandler:errorHandler];
    }
}

//used to finish fb login w/in find friend
- (void)completeLoginToFBWithCompletionHandler:completionHandler
                                  errorHandler:errorHandler {
    __weak typeof(self)weakSelf = self;
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"ffAuthInProgress"];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"facebookBatchInProgress"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    NSString *fbAppID = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"FacebookAppID"];
    
    FBSession *session = [[FBSession alloc] initWithAppID:fbAppID
                                   permissions:self.facebookServicePermissions
                               defaultAudience:FBSessionDefaultAudienceNone
                               urlSchemeSuffix:nil
                            tokenCacheStrategy:nil];
    
    [FBSession setActiveSession:session];
    
    NSLog(@"FB session create new session!");
    [session openWithBehavior:FBSessionLoginBehaviorWithFallbackToWebView
     
            completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
                __strong typeof(weakSelf)strongSelf = weakSelf;
                
                if (error) {
                    NSLog(@"fb auth errror");
                    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"ffAuthInProgress"];
                    
                } else if (session.accessTokenData.accessToken == nil) {
                    NSLog(@"fb session.accessTokenData.accessToken nil");
                    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"ffAuthInProgress"];
                    
                } else {
                    if (session.state == FBSessionStateOpen) {
                        NSLog(@"login w/token!");
                        [strongSelf completeFacebookAuthWithAccessToken:session.accessTokenData.accessToken
                                                      completionHandler:completionHandler
                                                           errorHandler:errorHandler];
                    } else {
                        NSLog(@"failed to login !");
                        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"ffAuthInProgress"];
                    }
                }
            }
     ];

}

//used for fb login when logging into app
- (void)loginToFacebook {
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"facebookBatchInProgress"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    FBSession *session = [FBSession activeSession];
    if (session.state == FBSessionStateOpen || session.state == FBSessionStateOpenTokenExtended) {
         NSLog(@"FBSessionStateOpen || FBSessionStateOpenTokenExtended");
        [self completeFacebookLoginWithAccessToken:session.accessTokenData.accessToken];
        
        return;
    } else if (session.state == FBSessionStateCreatedTokenLoaded) {
        __weak typeof(self)weakSelf = self;
           NSLog(@"FBSessionStateCreatedTokenLoaded");
        [session openWithCompletionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
            __strong typeof(weakSelf)strongSelf = weakSelf;
            
            if (error) {
                [session closeAndClearTokenInformation];
                
                [strongSelf loginToFacebook];
            } else {
                [strongSelf completeFacebookLoginWithAccessToken:session.accessTokenData.accessToken];
            }
        }];
    } else {
        __weak typeof(self)weakSelf = self;
        NSLog(@"prompt fb login!");
        [FBSession.activeSession close];
        [FBSession setActiveSession:nil];
        
        NSString *fbAppID = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"FacebookAppID"];
        
        session = [[FBSession alloc] initWithAppID:fbAppID
                                       permissions:self.facebookServicePermissions
                                   defaultAudience:FBSessionDefaultAudienceNone
                                   urlSchemeSuffix:nil
                                tokenCacheStrategy:nil];
        
        [FBSession setActiveSession:session];
        
        [session openWithBehavior:FBSessionLoginBehaviorWithFallbackToWebView
                completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
                    __strong typeof(weakSelf)strongSelf = weakSelf;
                    
                        if (error) {
                            NSLog(@"failed to login !");
                           [[NSNotificationCenter defaultCenter] postNotificationName:@"removeInitialLoadingScreen" object:nil];
                            if(![FBErrorUtility errorCategoryForError:error] == FBErrorCategoryUserCancelled){
                                [strongSelf handleFacebookLoginError:error];
                            }
                        } else if (session.accessTokenData.accessToken == nil) {
                            [strongSelf handleFacebookLoginError:error];
                        } else {
                            if (session.state == FBSessionStateOpen) {
                                NSLog(@"login w/token!");
                                [strongSelf completeFacebookLoginWithAccessToken:session.accessTokenData.accessToken];
                            } else {
                               [strongSelf handleFacebookLoginError:error]; 
                            }
                        }
                }
         ];
    }
}

- (void)handleFacebookLoginError:(NSError *)error {
    NSLog(@"fb login error!");
    [[NSNotificationCenter defaultCenter] postNotificationName:@"removeInitialLoadingScreen" object:nil];
    if (error) {
        NSString *message = error.userInfo[@"description"];
        NSString *title = error.userInfo[@"title"];
        
        if (title == nil) {
            title = NSLocalizedString(@"Ooops", nil);
        }
        if (message == nil) {
            message = NSLocalizedString(@"An error has occurred", nil);
        }
        
        [[[UIAlertView alloc] initWithTitle:title
                                    message:message
                                   delegate:nil
                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                          otherButtonTitles:nil] show];
    }
}

- (void)authTwitterWithViewController:(UIViewController *)viewController
                    completionHandler:(void (^)())completionHandler
                         errorHandler:(void (^)(NSError *error))errorHandler {
    NSString *serviceIdentifier = [[self serviceNameForType:SocialServiceTypeTwitter] uppercaseString];
    
    [APIService makeApiCallWithMethodUrl:@"/syncTokenAndTokenSecret"
                          andRequestType:RequestTypeGet
                           andPathParams:nil
                          andQueryParams:@{@"service": serviceIdentifier}
                          resultCallback:^(NSObject *syncResult) {
                              NSDictionary *JSON = (NSDictionary *)syncResult;
                              
                              NSString *token = JSON[@"token"];
                              NSString *tokenSecret = JSON[@"token_secret"];
                              
                              [[FHSTwitterEngine sharedEngine] permanentlySetConsumerKey:token andSecret:tokenSecret];
                              [[FHSTwitterEngine sharedEngine] setDelegate:self];
                              [[FHSTwitterEngine sharedEngine] loadAccessToken];
                              
                              [[FHSTwitterEngine sharedEngine] showOAuthLoginControllerFromViewController:viewController
                                                                                           withCompletion:^(BOOL success) {
                                                                                               FHSToken *twitterToken = [FHSTwitterEngine sharedEngine].accessToken;
                                                                                               
                                                                                               if (success) {
                                                                                                   NSDictionary *userInfo = @{ @"accessToken": twitterToken .key, @"accessTokenSecret": twitterToken .secret };
                                                                                                   
                                                                                                   [APIService makeApiCallWithMethodUrl:[NSString stringWithFormat:@"/auth/%@", serviceIdentifier]
                                                                                                                         andRequestType:RequestTypePost
                                                                                                                          andPathParams:nil
                                                                                                                         andQueryParams:userInfo
                                                                                                                         resultCallback:^(NSObject *authResult) {
                                                                                                                             self.twitterAvailable = YES;
                                                                                                                             if (completionHandler) {
                                                                                                                                 completionHandler();
                                                                                                                             }
                                                                                                                         } faultCallback:^(NSError *error) {
                                                                                                                             if (errorHandler) {
                                                                                                                                 errorHandler(error);
                                                                                                                             }
                                                                                                                             
                                                                                                                             if (error.code == -2400) {
                                                                                                                                 [self forceTwitterLogout];
                                                                                                                             }
                                                                                                                         }];
                                                                                               } else {
                                                                                                   if (errorHandler) {
                                                                                                       errorHandler(nil);
                                                                                                   }
                                                                                               }
                                                                                           }];
                          } faultCallback:^(NSError *error) {
                              if (errorHandler) {
                                  errorHandler(error);
                              }
                          }];
}

- (void)authLinkedInWithViewController:(UIViewController *)viewController
                     completionHandler:(void (^)())completionHandler
                          errorHandler:(void (^)(NSError *error))errorHandler {
    NSString *serviceIdentifier = [[self serviceNameForType:SocialServiceTypeLinkedIn] uppercaseString];
    
    [APIService makeApiCallWithMethodUrl:@"/syncTokenAndTokenSecret"
                          andRequestType:RequestTypeGet
                           andPathParams:nil
                          andQueryParams:@{@"service": serviceIdentifier}
                          resultCallback:^(NSObject *syncResult) {
                              NSDictionary *JSON = (NSDictionary *)syncResult;
                              
                              NSString *token = JSON[@"token"];
                              NSString *tokenSecret = JSON[@"token_secret"];
                              NSString *tokenState = JSON[@"token_state"];
                              NSString *url = @"http://spayce.me";
                              
                              LIALinkedInApplication *linkedInApplication = [LIALinkedInApplication applicationWithRedirectURL:url clientId:token clientSecret:tokenSecret state:tokenState grantedAccess:@[@"r_fullprofile", @"r_network", @"w_messages"]];
                              self.linkedInClient = [LIALinkedInHttpClient clientForApplication:linkedInApplication];
                              
                              self.linkedInClient.presentingViewController = viewController;
                              
                              [self.linkedInClient getAuthorizationCode:^(NSString *code) {
                                  [self.linkedInClient getAccessToken:code
                                                              success:^(NSDictionary *accessTokenData) {
                                                                  NSString *accessToken = accessTokenData[@"access_token"];

                                                                  [APIService makeApiCallWithMethodUrl:[NSString stringWithFormat:@"/auth/%@", serviceIdentifier]
                                                                                        andRequestType:RequestTypePost
                                                                                         andPathParams:nil
                                                                                        andQueryParams:@{@"accessToken": accessToken}
                                                                                        resultCallback:^(NSObject *authResult) {
                                                                                            self.linkedAvailable = YES;
                                                                                            if (completionHandler) {
                                                                                                completionHandler();
                                                                                            }
                                                                                        } faultCallback:^(NSError *error) {
                                                                                            if (errorHandler) {
                                                                                                errorHandler(error);
                                                                                            }
                                                                                        }];
                                                              } failure:^(NSError *error) {
                                                                  if (errorHandler) {
                                                                      errorHandler(error);
                                                                  }
                                                              }];
                              } cancel:^{
                                  if (errorHandler) {
                                      errorHandler(nil);
                                  }
                              } failure:^(NSError *error) {
                                  if (errorHandler) {
                                      errorHandler(error);
                                  }
                              }];
                          } faultCallback:^(NSError *error) {
                              if (errorHandler) {
                                  errorHandler(error);
                              }
                          }];
}

#pragma mark - Facebook

- (void)completeFacebookAuthWithAccessToken:(NSString *)accessToken
                          completionHandler:(void (^)())completionHandler
                               errorHandler:(void (^)(NSError *error))errorHandler {
    NSString *serviceIdentifier = [[self serviceNameForType:SocialServiceTypeFacebook] uppercaseString];
    
    [APIService makeApiCallWithMethodUrl:[NSString stringWithFormat:@"/auth/%@", serviceIdentifier]
                          andRequestType:RequestTypePost
                           andPathParams:nil
                          andQueryParams:@{@"accessToken": accessToken}
                          resultCallback:^(NSObject *result) {
                              self.facebookAvailable = YES;
                              [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"ffAuthInProgress"];
                              if (completionHandler) {
                                  completionHandler();
                              }
                          } faultCallback:^(NSError *error) {
                              [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"ffAuthInProgress"];
                              if (errorHandler) {
                                  errorHandler(error);
                              }
                              
                              if (error.code == -2400) {
                                  [self forceFacebookLogout];
                              }
                          }];
}

- (void)completeFacebookLoginWithAccessToken:(NSString *)accessToken {
    NSString *serviceIdentifier = [[self serviceNameForType:SocialServiceTypeFacebook] uppercaseString];
    
    __weak typeof(self)weakSelf = self;
    
    if (accessToken) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"addLoadingView" object:nil];
        
        [AuthenticationManager sharedInstance].authenticationInProgress = YES;
        
        [APIService makeApiCallWithMethodUrl:[NSString stringWithFormat:@"/loginOrCreateUserVia/%@", serviceIdentifier]
                              andRequestType:RequestTypePost
                               andPathParams:nil
                              andQueryParams:@{ @"accessToken": accessToken }
                              resultCallback:^(NSObject *result) {

                                  weakSelf.facebookAvailable = YES;
                                  NSLog(@"login result %@",result);
                                
                                  NSDictionary *JSON = (NSDictionary *)result;
                                 
                                  //Force handle creation if necessary
                                  NSNumber *needsHandle = (NSNumber *)[TranslationUtils valueOrNil:JSON[@"shouldChangeHandle"]];
                                  if (needsHandle && [needsHandle boolValue]) {
                                      NSLog(@"prompt handle change!");
                                      [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"shouldChangeHandle"];
                                  }
                                  else {
                                      [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"shouldChangeHandle"];
                                  }
                                  
                                  NSString *email = (NSString *)[TranslationUtils valueOrNil:JSON[@"email"]];
                                  NSString *firstName = (NSString *)[TranslationUtils valueOrNil:JSON[@"firstName"]];
                                  [[AuthenticationManager sharedInstance] finishAuthenticationWithEmail:email firstName:firstName attributes:JSON];
                                  
                              } faultCallback:^(NSError *error) {
                                  // Show an alert
                                  [[NSNotificationCenter defaultCenter] postNotificationName:@"removeInitialLoadingScreen" object:nil];
                                  [AuthenticationManager sharedInstance].authenticationInProgress = NO;
                                  [weakSelf handleFacebookLoginError:error];
                                  // Close FB session and clear token in order
                                  // for the user to be able to approach login again
                                  [weakSelf invalidateFacebookSession];
                              }];
    } else {
        NSDictionary *userInfo = @{ @"description": NSLocalizedString(@"Access token unavailable", nil) };
        NSError *error = [[NSError alloc] initWithDomain:@"kSpayceErrorDomain" code:666 userInfo:userInfo];
        
        [self handleFacebookLoginError:error];
    }
}

#pragma mark - Lists

- (void)fetchABFriendsWithCompletionHandler:(void (^)(BOOL inviteAllSent, NSArray *spayceFriends, NSArray *nonSpayceFriends))completionHandler
                       errorHandler:(void (^)(NSError *))errorHandler {
    
    if ([AuthenticationManager sharedInstance].currentUser != nil){
    
    [APIService makeApiCallWithMethodUrl:@"/inviteFriends/addressbook"
                          andRequestType:RequestTypeGet
                           andPathParams:nil
                          andQueryParams:nil
                          resultCallback:^(NSObject * result) {
                              NSDictionary *JSON = (NSDictionary *)result;
                              //NSLog(@"/inviteFriends/addressbook result %@",result);
                              
                              BOOL inviteAllSent = [JSON[@"invitesAllSent"] boolValue];
                              NSMutableArray *spayceFriends = [NSMutableArray array];
                              NSMutableArray *nonSpayceFriends = [NSMutableArray array];
                              
                              for (NSDictionary *attributes in JSON[@"friends"]) {
                                  SocialProfile *socialProfile = [[SocialProfile alloc] initWithAttributes:attributes];
                                  if (socialProfile.firstname.length>0){
                                  
                                      if (socialProfile.isSpayceMember) {
                                          [spayceFriends addObject:socialProfile];
                                      } else {
                                          [nonSpayceFriends addObject:socialProfile];
                                      }
                                  }
                              }
                        
                              if (completionHandler) {
                                  completionHandler(inviteAllSent, [spayceFriends copy], [nonSpayceFriends copy]);
                              }
                          } faultCallback:^(NSError *fault) {
                              if (errorHandler) {
                                  NSLog(@"/inviteFriends/addressbook fault %@", [fault description]);
                                  errorHandler(fault);
                              }
                          }];
    }
   
}

- (void)fetchFriendsForServiceOfType:(NSInteger)type
                   completionHandler:(void (^)(BOOL inviteAllSent, NSArray *spayceFriends, NSArray *nonSpayceFriends))completionHandler
                        errorHandler:(void (^)(NSError *error))errorHandler {
    NSString *serviceIdentifier = [[self serviceNameForType:type] uppercaseString];
    
    
    [APIService makeApiCallWithMethodUrl:[NSString stringWithFormat:@"/inviteFriends"]
                          andRequestType:RequestTypeGet
                           andPathParams:nil
                          andQueryParams:@{@"socialMediaType": serviceIdentifier}
                          resultCallback:^(NSObject *result) {
                              NSDictionary *JSON = (NSDictionary *)result;
                              //NSLog(@"/inviteFriends result %@",result);
                              
                              BOOL inviteAllSent = [JSON[@"invitesAllSent"] boolValue];
                              
                              NSMutableArray *spayceFriends = [NSMutableArray array];
                              NSMutableArray *nonSpayceFriends = [NSMutableArray array];
                              
                              for (NSDictionary *attributes in JSON[@"friends"]) {
                                  SocialProfile *socialProfile = [[SocialProfile alloc] initWithAttributes:attributes];
                                  
                                  if (socialProfile.isSpayceMember) {
                                      [spayceFriends addObject:socialProfile];
                                  } else {
                                      [nonSpayceFriends addObject:socialProfile];
                                  }
                              }
                              
                              if (completionHandler) {
                                  completionHandler(inviteAllSent, [spayceFriends copy], [nonSpayceFriends copy]);
                              }
                          } faultCallback:^(NSError *error) {
                              if (errorHandler) {
                                  errorHandler(error);
                              }
                          }];
    
}

#pragma mark - Invite

- (void)inviteFBBatch:(NSArray *)batchIds
              allSent:(BOOL)allSent
    completionHandler:(void (^)())completionHandler
        errorHandler:(void (^)(NSError *error))errorHandler {
    
         NSInteger type = SocialServiceTypeFacebook;
         NSString *serviceIdentifier = [[self serviceNameForType:type] uppercaseString];
                         
         //create string of ids from array
         NSString *idString =  [batchIds componentsJoinedByString:@","];
         NSLog(@"idString %@",idString);

        BOOL batchSent = YES;
         NSString *url = @"/inviteFriends";
         NSDictionary *params = @{@"socialMediaType": serviceIdentifier,
                                      @"ids" : idString,
                                      @"sent" : @(batchSent)
                                      };
    
         [APIService makeApiCallWithMethodUrl:url
                               andRequestType:RequestTypePost
                                andPathParams:nil
                               andQueryParams:params
                               resultCallback:^(NSObject *result) {
                                   if (completionHandler) {
                                       completionHandler();
                                   }
                               } faultCallback:^(NSError *error) {
                                   if (errorHandler) {
                                       NSLog(@"/invite fb batch error %@",error);
                                       errorHandler(error);
                                   }
                               }];
}


     
- (void)inviteFriendWithUid:(NSString *)uid
               contactToken:(NSString *)contactToken
              socialService:(NSInteger)type
         completionHandler:(void (^)())completionHandler
              errorHandler:(void (^)(NSError *error))errorHandler {

    
    NSLog(@"inviteFriendWithUid %@ %i",uid, (int)type);
    NSString *serviceIdentifier = [[self serviceNameForType:type] uppercaseString];
    NSString *url = @"/inviteFriends";
    
    NSDictionary *params;
    if ([serviceIdentifier isEqualToString:@"CONTACTS"]){
        params = @{@"contactTokens" : contactToken
                             };
        url = @"/inviteFriends/addressbook/inviteByContactTokens";
    }
    else if (type == SocialServiceTypeFacebook) {
        BOOL sentFromClient = YES;
        params = @{@"socialMediaType": serviceIdentifier,
                   @"ids" : uid,
                   @"sent" : @(sentFromClient)
                   };
    }
    else {
    params = @{@"socialMediaType": serviceIdentifier,
                             @"ids" : uid
                             };
        
    
    }
    [APIService makeApiCallWithMethodUrl:url
                      andRequestType:RequestTypePost
                       andPathParams:nil
                      andQueryParams:params
                      resultCallback:^(NSObject *result) {
                          if (completionHandler) {
                              completionHandler();
                          }
                      } faultCallback:^(NSError *error) {
                          NSLog(@"req url: %@ faultCallback: %@",url,error);
                          if (errorHandler) {
                              errorHandler(error);
                          }
                      }];

}

#pragma mark - ABAddressBook

- (NSDictionary *)contactsJSONFromAddressBook:(ABAddressBookRef)addressBook {
    NSMutableDictionary *JSON;
    
    CFIndex count = ABAddressBookGetPersonCount(addressBook);
    if (count > 0) {
        CFArrayRef allPeople = ABAddressBookCopyArrayOfAllPeople(addressBook);
        
        JSON = [NSMutableDictionary dictionary];
        NSMutableArray *contactsArray = [NSMutableArray arrayWithCapacity:count];
        
        for (int i = 0; i < count; i++) {
            ABRecordRef person = CFArrayGetValueAtIndex(allPeople, i);
            
            if (!person) {
                continue;
            }
            
            CFStringRef abFirstNameRef = ABRecordCopyValue(person, kABPersonFirstNameProperty);
            NSString *abFirstName = (__bridge id)abFirstNameRef;
            CFStringRef abLastNameRef = ABRecordCopyValue(person, kABPersonLastNameProperty);
            NSString *abLastName = (__bridge id)abLastNameRef;
            
            ABMultiValueRef emailRef = ABRecordCopyValue(person, kABPersonEmailProperty);
            CFArrayRef abEmailsRef = ABMultiValueCopyArrayOfAllValues(emailRef);
            NSArray *abEmails = (__bridge id)abEmailsRef;
            
            ABMultiValueRef phoneNumRef = ABRecordCopyValue(person, kABPersonPhoneProperty);
            CFArrayRef abPhoneNumbersRef = ABMultiValueCopyArrayOfAllValues(phoneNumRef);
            NSArray *abPhoneNumbers = (__bridge id)abPhoneNumbersRef;
            
            // Create contact dictionary
            NSMutableDictionary *contactDictionary = [NSMutableDictionary dictionary];
            if (abFirstName) {
                contactDictionary[@"firstName"] = abFirstName;
            }
            if (abLastName) {
                contactDictionary[@"lastName"] = abLastName;
            }
            if (abEmails.count > 0) {
                contactDictionary[@"emails"] = abEmails;
            }
            if (abPhoneNumbers.count > 0) {
                contactDictionary[@"phoneNumbers"] = abPhoneNumbers;
            }
            
            // Add to contacts array
            [contactsArray addObject:contactDictionary];
            
            // Clean up
            if (abFirstNameRef) {
                CFRelease(abFirstNameRef);
            }
            if (abLastNameRef) {
                CFRelease(abLastNameRef);
            }
            if (emailRef) {
                CFRelease(emailRef);
            }
            if (abEmailsRef) {
                CFRelease(abEmailsRef);
            }
            if (phoneNumRef) {
                CFRelease(phoneNumRef);
            }
            if (abPhoneNumbersRef) {
                CFRelease(abPhoneNumbersRef);
            }
        }

        JSON[@"contacts_count"] = @(contactsArray.count);
        JSON[@"contacts"] = contactsArray;
        
        if (allPeople) {
            CFRelease(allPeople);
        }
    }
    
    return JSON;
}


- (void)syncFriendsFromAddressBook:(ABAddressBookRef)addressBook
                  completionHandler:(void (^)(BOOL inviteAllSent, NSArray *spayceFriends, NSArray *nonSpayceFriends))completionHandler
                       errorHandler:(void (^)(NSError *))errorHandler {
    
    NSString *url = [NSString stringWithFormat:@"/inviteFriends/addressbook?ses=%@",[SpayceSessionManager sharedInstance].currentSessionId];
    
    NSLog(@"sync url %@",url);
    NSDictionary *contactsJSON = [self contactsJSONFromAddressBook:addressBook];
    
    if (contactsJSON) {
        [APIService uploadAddressBookWithMethodURL:url
                             addressBookDictionary:contactsJSON
                                 completionHandler:^(NSObject *result) {
                                     NSLog(@"addressBook synced %@",result);
                                     
                                     NSDictionary *JSON = (NSDictionary *)result;
                                     NSLog(@"/inviteFriends result %@",result);
                                     
                                     BOOL inviteAllSent = [JSON[@"invitesAllSent"] boolValue];
                                     
                                     NSMutableArray *spayceFriends = [NSMutableArray array];
                                     NSMutableArray *nonSpayceFriends = [NSMutableArray array];
                                     
                                     for (NSDictionary *attributes in JSON[@"friends"]) {
                                         SocialProfile *socialProfile = [[SocialProfile alloc] initWithAttributes:attributes];
                                         
                                         if (socialProfile.isSpayceMember) {
                                             if (socialProfile.followingStatus != FollowingStatusFollowing) {
                                                 [spayceFriends addObject:socialProfile];
                                             }
                                             
                                         } else {
                                             if (socialProfile.followingStatus != FollowingStatusFollowing) {
                                                 [nonSpayceFriends addObject:socialProfile];
                                             }
                                         }
                                     }
                                     
                                     if (completionHandler) {
                                         completionHandler(inviteAllSent, [spayceFriends copy], [nonSpayceFriends copy]);
                                     }
                                     
                                 } errorHandler:^(NSError *error) {
                                     if (errorHandler) {
                                         NSLog(@"/inviteFriends/addressbook error %@",error);
                                         errorHandler(error);
                                     }
                                 }];
    }
}

#pragma mark - UIApplication notifications

- (void)handleApplicationWillTerminate:(NSNotification *)notification {
    [FBSession.activeSession close];
}

- (void)handleApplicationDidBecomeActive:(NSNotification *)notification {
    [[FBSession activeSession] handleDidBecomeActive];
}

- (void)handleLogout {
    //NSLog(@"fb session close and clear token!!");
    [[FBSession activeSession] closeAndClearTokenInformation];
    [FBSession.activeSession close];
    [FBSession setActiveSession:nil];
    self.facebookAvailable = NO;
    self.linkedAvailable = NO;
    self.twitterAvailable = NO;
    self.refreshNeeded = YES;
}

- (void)invalidateFacebookSession {
    [[FBSession activeSession] closeAndClearTokenInformation];
}

#pragma mark - Forced logout

- (void)forceFacebookLogout {
    [[FBSession activeSession] closeAndClearTokenInformation];
    [FBSession.activeSession close];
    [FBSession setActiveSession:nil];
}

- (void)forceTwitterLogout {
    self.twitterAvailable = NO;
    self.refreshNeeded = YES;
}

@end
