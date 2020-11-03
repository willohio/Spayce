//
//  SPCServerResponses.h
//  Spayce
//
//  Created by Arria P. Owlia on 3/5/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

// Huge list of server responses
static const int SUCCESS = 0;
static const int UNEXPECTED_ERROR = -666;
static const int REQUIRED_FIELD_ERROR = -100;
static const int ENTITY_NOT_FOUND_ERROR = -200;
static const int INVALID_PASSWORD_ERROR = -300;
//static const int LOGIN_BUSY_ERROR = -400;
static const int SESSION_NOT_FOUND_ERROR = -500;
static const int SESSION_EXPIRED_ERROR = -600;
//static const int LAST_LOCATION_NOT_FOUND_ERROR = -700;
//static const int LAST_LOCATION_EXPIRED_ERROR = -800;
static const int NOTIFICATION_ERROR = -1200;
//static const int NOTIFICATION_USER_NOT_REGISTERED_ERROR = -1300;
//static const int NOTIFICATION_COUNT_EXCEED_ERROR = -1400;
static const int AUTHORIZATION_ERROR = -1500;
//static const int EXISTING_CONTACT_ERROR = -1600;
//static const int MAX_REJECTIONS_REACHED_ERROR = -1700;
//static const int CODE_NOT_VALIDATED_ERROR = -1800;
//static const int CODE_DOES_NOT_MATCH_ERROR = -1900;
static const int EMAIL_IS_WRONG_DOMAIN = -2000;
static const int DEVICE_IS_BLOCKED = -2100;
static const int EXISTING_USER_ERROR = -2200;
static const int SERVICE_USER_AFFILIATION_NOT_BETA_COMPLIANT = -2300;
static const int SERVICE_USER_ALREADY_REGISTERED = -2400;
static const int SERVICE_AUTHORIZATION_ERROR = -2500;
static const int MEMORY_NOT_FOUND_ERROR = -2600;
static const int SERVICE_POSTING_ERROR = -2700;
static const int HANDLE_TAKEN_ERROR = -2800;
static const int HANDLE_INVALID_CHARACTERS = -2900;
static const int HANDLE_INVALID_LENGTH = -3000;
static const int HANDLE_ALREADY_SET_ERROR = -3100;
static const int CANNOT_POST_COMMENT_YOU_ARE_BLOCKED = -3200;
static const int CANNOT_POST_COMMENT_THEY_ARE_BLOCKED = -3300;
static const int CANNOT_POST_COMMENT_YOU_ARE_MUTED = -3400;