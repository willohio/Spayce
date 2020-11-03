//
//  SPCHereEnums.h
//  Spayce
//
//  Created by Jake Rosin on 8/10/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#ifndef Spayce_SPCHereEnums_h
#define Spayce_SPCHereEnums_h

typedef NS_ENUM(NSInteger, SpayceState) {
    SpayceStateLocationOff,
    SpayceStateSeekingLocationFix,
    SpayceStateUpdatingLocation,
    SpayceStateRetrievingLocationData,
    SpayceStateDisplayingLocationData
};

typedef NS_ENUM(NSInteger, SpayceMapFilters) {
    SpayceMapAllPins,
    SpayceMapNearbyPins,
    SpayceMapPopularPins,
    SpayceMapNightPins,
    SpayceMapDayPins
};


#endif
