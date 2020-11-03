//
//  SPCVenueTypes.m
//  Spayce
//
//  Created by Jake Rosin on 8/6/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCVenueTypes.h"

@implementation SPCVenueTypes

+(NSArray *)types {
    NSMutableArray *mutArray = [[NSMutableArray alloc] init];
    for (int e = VenueTypeAirport; e <= VenueTypeNone; e++) {
        [mutArray addObject:@(e)];
    }
    return [NSArray arrayWithArray:mutArray];
}


+(UIImage *)imageForVenue:(Venue *)venue withIconType:(VenueIconType)venueIconType {
    VenueType type = [SPCVenueTypes typeForVenue:venue];
    return [SPCVenueTypes imageForVenueType:type withIconType:venueIconType];
}
+(UIImage *)largeImageForVenue:(Venue *)venue withIconType:(VenueIconType)venueIconType {
    VenueType type = [SPCVenueTypes typeForVenue:venue];
    return [SPCVenueTypes largeImageForVenueType:type withIconType:venueIconType];
}

+(NSString *)imageNameForVenue:(Venue *)venue withIconType:(VenueIconType)venueIconType {
    VenueType type = [SPCVenueTypes typeForVenue:venue];
    return [SPCVenueTypes imageNameForVenueType:type withIconType:venueIconType];
}
+(NSString *)largeImageNameForVenue:(Venue *)venue withIconType:(VenueIconType)venueIconType {
    
    VenueType type = [SPCVenueTypes typeForVenue:venue];
    NSString *imgName = [SPCVenueTypes imageNameForVenueType:type withIconType:venueIconType];
    NSString *largeImgName = [NSString stringWithFormat:@"lg-%@",imgName];
    
    return largeImgName;
}




+(UIColor *)colorForVenue:(Venue *)venue {
    VenueType type = [SPCVenueTypes typeForVenue:venue];
    return [SPCVenueTypes colorForVenueType:type];
}

+(UIColor *)colorSecondaryForVenue:(Venue *)venue {
    VenueType type = [SPCVenueTypes typeForVenue:venue];
    return [SPCVenueTypes colorSecondaryForVenueType:type];
}

+(UIImage *)headerImageForVenue:(Venue *)venue {
    VenueType type = [SPCVenueTypes typeForVenue:venue];
    
    NSString * bannerName = [SPCVenueTypes bannerImageNameForVenueType:type];
    //NSLog(@"type %li",type);
    if (bannerName) {
        //NSLog(@"bannerName %@",bannerName);
        return [UIImage imageNamed:bannerName];
    }
    else {
        return [UIImage imageNamed:@"residential-banner"];
    }
}

# pragma mark - helpers

+(VenueType)typeForVenue:(Venue *)venue {
    if (!venue) {
        return VenueTypeNone;
    }
    
    if (venue.isCustomVenue) {
        // rocket label
        return VenueTypeSpayce;
    }
    
    VenueType type;
    if ([venue.venueTypes count] == 0) {
        type = VenueTypeResidential;
    } else if ([SPCVenueTypes venue:venue isOneOfTypes:@[@"airport"]]) {
        type = VenueTypeAirport;
    } else if ([SPCVenueTypes venue:venue isOneOfTypes:@[@"amusement_park",@"zoo"]]) {
        type = VenueTypeAmusement;
    } else if ([SPCVenueTypes venue:venue isOneOfTypes:@[@"aquarium"]]) {
        type = VenueTypeAquarium;
    }  else if ([SPCVenueTypes venue:venue isOneOfTypes:@[@"art_gallery"]]) {
        type = VenueTypeArt;
    } else if ([SPCVenueTypes venue:venue isOneOfTypes:@[@"atm"]]) {
        type = VenueTypeAtm;
    } else if ([SPCVenueTypes venue:venue isOneOfTypes:@[@"bakery"]]) {
        type = VenueTypeBakery;
    } else if ([SPCVenueTypes venue:venue isOneOfTypes:@[@"bank"]]) {
        type = VenueTypeBank;
    } else if ([SPCVenueTypes venue:venue isOneOfTypes:@[@"bank"]]) {
        type = VenueTypeBank;
    } else if ([SPCVenueTypes venue:venue isOneOfTypes:@[@"bar", @"night_club"]]) {
        type = VenueTypeBar;
    } else if ([SPCVenueTypes venue:venue isOneOfTypes:@[@"bicycle_store"]]) {
        type = VenueTypeBicycle;
    } else if ([SPCVenueTypes venue:venue isOneOfTypes:@[@"book_store"]]) {
        type = VenueTypeBookstore;
    } else if ([SPCVenueTypes venue:venue isOneOfTypes:@[@"bowling_alley"]]) {
        type = VenueTypeBowling;
    } else if ([SPCVenueTypes venue:venue isOneOfTypes:@[@"bus_station"]]) {
        type = VenueTypeBus;
    } else if ([SPCVenueTypes venue:venue isOneOfTypes:@[@"cafe"]]) {
        type = VenueTypeCafe;
    } else if ([SPCVenueTypes venue:venue isOneOfTypes:@[@"accounting"]]) {
        type = VenueTypeAccounting;
    } else if ([SPCVenueTypes venue:venue isOneOfTypes:@[@"campground"]]) {
        type = VenueTypeCamp;
    } else if ([SPCVenueTypes venue:venue isOneOfTypes:@[@"car_repair"]]) {
        type = VenueTypeCarRepair;
    } else if ([SPCVenueTypes venue:venue isOneOfTypes:@[@"car_wash"]]) {
        type = VenueTypeCarWash;
    } else if ([SPCVenueTypes venue:venue isOneOfTypes:@[@"car_dealer"]]) {
        type = VenueTypeCar;
    } else if ([SPCVenueTypes venue:venue isOneOfTypes:@[@"casino"]]) {
        type = VenueTypeCasino;
    } else if ([SPCVenueTypes venue:venue isOneOfTypes:@[@"cemetery"]]) {
        type = VenueTypeCemetery;
    } else if ([SPCVenueTypes venue:venue isOneOfTypes:@[@"city_hall", @"local_government_office"]]) {
        type = VenueTypeCityHall;
    } else if ([SPCVenueTypes venue:venue isOneOfTypes:@[@"church"]]) {
        type = VenueTypeChurch;
    } else if ([SPCVenueTypes venue:venue isOneOfTypes:@[@"clothing_store"]]) {
        type = VenueTypeClothing;
    } else if ([SPCVenueTypes venue:venue isOneOfTypes:@[@"convenience_store"]]) {
        type = VenueTypeConvenience;
    } else if ([SPCVenueTypes venue:venue isOneOfTypes:@[@"court"]]) {
        type = VenueTypeCourthouse;
    } else if ([SPCVenueTypes venue:venue isOneOfTypes:@[@"dentist"]]) {
        type = VenueTypeDentist;
    } else if ([SPCVenueTypes venue:venue isOneOfTypes:@[@"department_store"]]) {
        type = VenueTypeDepartment;
    } else if ([SPCVenueTypes venue:venue isOneOfTypes:@[@"doctor"]]) {
        type = VenueTypeDoctor;
    } else if ([SPCVenueTypes venue:venue isOneOfTypes:@[@"electrician"]]) {
        type = VenueTypeElectrician;
    } else if ([SPCVenueTypes venue:venue isOneOfTypes:@[@"electronics_store"]]) {
        type = VenueTypeElectronics;
    } else if ([SPCVenueTypes venue:venue isOneOfTypes:@[@"embassy"]]) {
        type = VenueTypeEmbassy;
    } else if ([SPCVenueTypes venue:venue isOneOfTypes:@[@"finance"]]) {
        type = VenueTypeFinance;
    } else if ([SPCVenueTypes venue:venue isOneOfTypes:@[@"fire_station"]]) {
        type = VenueTypeFire;
    } else if ([SPCVenueTypes venue:venue isOneOfTypes:@[@"florist"]]) {
        type = VenueTypeFlorist;
    } else if ([SPCVenueTypes venue:venue isOneOfTypes:@[@"food"]]) {
        type = VenueTypeFood;
    } else if ([SPCVenueTypes venue:venue isOneOfTypes:@[@"furniture_store"]]) {
        type = VenueTypeFurniture;
    } else if ([SPCVenueTypes venue:venue isOneOfTypes:@[@"gas_station"]]) {
        type = VenueTypeGas;
    } else if ([SPCVenueTypes venue:venue isOneOfTypes:@[@"general_contractor"]]) {
        type = VenueTypeGC;
    } else if ([SPCVenueTypes venue:venue isOneOfTypes:@[@"grocery_or_supermarket"]]) {
        type = VenueTypeGrocery;
    } else if ([SPCVenueTypes venue:venue isOneOfTypes:@[@"gym"]]) {
        type = VenueTypeGym;
    } else if ([SPCVenueTypes venue:venue isOneOfTypes:@[@"hair_care", @"salon",@"spa"]]) {
        type = VenueTypeHair;
    } else if ([SPCVenueTypes venue:venue isOneOfTypes:@[@"hardware_store"]]) {
        type = VenueTypeHardware;
    } else if ([SPCVenueTypes venue:venue isOneOfTypes:@[@"health"]]) {
        type = VenueTypeHealth;
    } else if ([SPCVenueTypes venue:venue isOneOfTypes:@[@"home_goods_store"]]) {
        type = VenueTypeHomegoods;
    } else if ([SPCVenueTypes venue:venue isOneOfTypes:@[@"hospital"]]) {
        type = VenueTypeHospital;
    } else if ([SPCVenueTypes venue:venue isOneOfTypes:@[@"insurance_agency"]]) {
        type = VenueTypeInsurance;
    } else if ([SPCVenueTypes venue:venue isOneOfTypes:@[@"jewelry_store"]]) {
        type = VenueTypeJewelry;
    } else if ([SPCVenueTypes venue:venue isOneOfTypes:@[@"laundry"]]) {
        type = VenueTypeLaundry;
    } else if ([SPCVenueTypes venue:venue isOneOfTypes:@[@"lawyer"]]) {
        type = VenueTypeLawyer;
    } else if ([SPCVenueTypes venue:venue isOneOfTypes:@[@"library"]]) {
        type = VenueTypeLibrary;
    } else if ([SPCVenueTypes venue:venue isOneOfTypes:@[@"liquor_store"]]) {
        type = VenueTypeLiquor;
    } else if ([SPCVenueTypes venue:venue isOneOfTypes:@[@"locksmith"]]) {
        type = VenueTypeLocksmith;
    } else if ([SPCVenueTypes venue:venue isOneOfTypes:@[@"movie_rental"]]) {
        type = VenueTypeMovieRental;
    } else if ([SPCVenueTypes venue:venue isOneOfTypes:@[@"movie_theater"]]) {
        type = VenueTypeMovieTheater;
    } else if ([SPCVenueTypes venue:venue isOneOfTypes:@[@"moving_company"]]) {
        type = VenueTypeMoving;
    } else if ([SPCVenueTypes venue:venue isOneOfTypes:@[@"museum"]]) {
        type = VenueTypeMuseum;
    } else if ([SPCVenueTypes venue:venue isOneOfTypes:@[@"painter"]]) {
        type = VenueTypePainter;
    } else if ([SPCVenueTypes venue:venue isOneOfTypes:@[@"park"]]) {
        type = VenueTypePark;
    } else if ([SPCVenueTypes venue:venue isOneOfTypes:@[@"parking"]]) {
        type = VenueTypeParking;
    } else if ([SPCVenueTypes venue:venue isOneOfTypes:@[@"pharmacy"]]) {
        type = VenueTypePharmacy;
    } else if ([SPCVenueTypes venue:venue isOneOfTypes:@[@"physiotherapist"]]) {
        type = VenueTypePhysio;
    } else if ([SPCVenueTypes venue:venue isOneOfTypes:@[@"police"]]) {
        type = VenueTypePolice;
    } else if ([SPCVenueTypes venue:venue isOneOfTypes:@[@"post_office"]]) {
        type = VenueTypePost;
    } else if ([SPCVenueTypes venue:venue isOneOfTypes:@[@"real_estate_agency"]]) {
        type = VenueTypeRealEstate;
    } else if ([SPCVenueTypes venue:venue isOneOfTypes:@[@"restaurant"]]) {
        type = VenueTypeRestaurant;
    } else if ([SPCVenueTypes venue:venue isOneOfTypes:@[@"roofing_contractor"]]) {
        type = VenueTypeRoofing;
    } else if ([SPCVenueTypes venue:venue isOneOfTypes:@[@"rv_park"]]) {
        type = VenueTypeRV;
    } else if ([SPCVenueTypes venue:venue isOneOfTypes:@[@"school", @"university"]]) {
        type = VenueTypeSchool;
    } else if ([SPCVenueTypes venue:venue isOneOfTypes:@[@"shoe_store"]]) {
        type = VenueTypeShoe;
    } else if ([SPCVenueTypes venue:venue isOneOfTypes:@[@"shopping_mall"]]) {
        type = VenueTypeShopping;
    } else if ([SPCVenueTypes venue:venue isOneOfTypes:@[@"stadium"]]) {
        type = VenueTypeStadium;
    } else if ([SPCVenueTypes venue:venue isOneOfTypes:@[@"storage"]]) {
        type = VenueTypeStorage;
    } else if ([SPCVenueTypes venue:venue isOneOfTypes:@[@"store"]]) {
        type = VenueTypeStore;
    } else if ([SPCVenueTypes venue:venue isOneOfTypes:@[@"subway_station"]]) {
        type = VenueTypeSubway;
    } else if ([SPCVenueTypes venue:venue isOneOfTypes:@[@"train_station"]]) {
        type = VenueTypeTrain;
    } else if ([SPCVenueTypes venue:venue isOneOfTypes:@[@"travel_agency"]]) {
        type = VenueTypeTravel;
    }
    
    else {
        type = VenueTypeResidential;
    }
    return type;
}

+(BOOL)venue:(Venue *)venue isOneOfTypes:(NSArray *)types {
    for (NSString * type in types) {
        if ([venue.venueTypes containsObject:type]) {
            return YES;
        }
    }
    return NO;
}

+(NSString *)imageNameForVenueType:(VenueType)venueType withIconType:(VenueIconType)venueIconType {
    if (venueType == VenueTypeNone) {
        switch (venueIconType) {
            case VenueIconTypeIconWhite:
                return @"pin-blue";
            default:
                return nil;
        }
    }
    
    NSString * iconName;
    switch (venueType) {
        case VenueTypeAccounting:
            iconName = @"calculator";
            break;
        case VenueTypeAirport:
            iconName = @"airport";
            break;
        case VenueTypeAmusement:
            iconName = @"amusement";
            break;
        case VenueTypeAquarium:
            iconName = @"aquarium";
            break;
        case VenueTypeArt:
            iconName = @"art_gallery";
            break;
        case VenueTypeAtm:
            iconName = @"atm";
            break;
        case VenueTypeBakery:
            iconName = @"bakery";
            break;
        case VenueTypeBar:
            iconName = @"bar";
            break;
        case VenueTypeBank:
            iconName = @"bank";
            break;
        case VenueTypeBicycle:
            iconName = @"bicycle";
            break;
        case VenueTypeBookstore:
            iconName = @"bookstore";
            break;
        case VenueTypeBowling:
            iconName = @"bowling";
            break;
        case VenueTypeBus:
            iconName = @"bus";
            break;
        case VenueTypeCafe:
            iconName = @"cafe";
            break;
        case VenueTypeCamp:
            iconName = @"canp";
            break;
        case VenueTypeCar:
            iconName = @"car";
            break;
        case VenueTypeCarRepair:
            iconName = @"car-repair";
            break;
        case VenueTypeCarWash:
            iconName = @"car-wash";
            break;
        case VenueTypeCasino:
            iconName = @"casino";
            break;
        case VenueTypeCemetery:
            iconName = @"cemetery";
            break;
        case VenueTypeCityHall:
            iconName = @"cityhall";
            break;
        case VenueTypeClothing:
            iconName = @"clothing";
            break;
        case VenueTypeConvenience:
            iconName = @"convenience";
            break;
        case VenueTypeCourthouse:
            iconName = @"courthouse";
            break;
        case VenueTypeDentist:
            iconName = @"dentist";
            break;
        case VenueTypeDepartment:
            iconName = @"department";
            break;
        case VenueTypeDoctor:
            iconName = @"doctor";
            break;
        case VenueTypeElectrician:
            iconName = @"electrician";
            break;
        case VenueTypeElectronics:
            iconName = @"electronics";
            break;
        case VenueTypeEmbassy:
            iconName = @"embassy";
            break;
        case VenueTypeFinance:
            iconName = @"finance";
            break;
        case VenueTypeFire:
            iconName = @"fire";
            break;
        case VenueTypeFlorist:
            iconName = @"florist";
            break;
        case VenueTypeFood:
            iconName = @"food";
            break;
        case VenueTypeFurniture:
            iconName = @"furniture";
            break;
        case VenueTypeGas:
            iconName = @"gas";
            break;
        case VenueTypeGC:
            iconName = @"gc";
            break;
        case VenueTypeGrocery:
            iconName = @"grocery";
            break;
        case VenueTypeGym:
            iconName = @"gym";
            break;
        case VenueTypeHair:
            iconName = @"hair";
            break;
        case VenueTypeHardware:
            iconName = @"hardware";
            break;
        case VenueTypeHealth:
            iconName = @"health";
            break;
        case VenueTypeHomegoods:
            iconName = @"homegoods";
            break;
        case VenueTypeHospital:
            iconName = @"hospital";
            break;
        case VenueTypeInsurance:
            iconName = @"insurance";
            break;
        case VenueTypeJewelry:
            iconName = @"jewelry";
            break;
        case VenueTypeLaundry:
            iconName = @"laundry";
            break;
        case VenueTypeLawyer:
            iconName = @"lawyer";
            break;
        case VenueTypeLibrary:
            iconName = @"library";
            break;
        case VenueTypeLiquor:
            iconName = @"liquor";
            break;
        case VenueTypeLocksmith:
            iconName = @"locksmith";
            break;
        case VenueTypeMovieRental:
            iconName = @"movie-rental";
            break;
        case VenueTypeMovieTheater:
            iconName = @"movie-theater";
            break;
        case VenueTypeMoving:
            iconName = @"moving";
            break;
        case VenueTypeMuseum:
            iconName = @"museum";
            break;
        case VenueTypePainter:
            iconName = @"painter";
            break;
        case VenueTypePark:
            iconName = @"park";
            break;
        case VenueTypeParking:
            iconName = @"parking";
            break;
        case VenueTypePharmacy:
            iconName = @"pharmacy";
            break;
        case VenueTypePhysio:
            iconName = @"physio";
            break;
        case VenueTypePolice:
            iconName = @"police";
            break;
        case VenueTypePost:
            iconName = @"post";
            break;
        case VenueTypeRealEstate:
            iconName = @"real-estate";
            break;
        case VenueTypeRestaurant:
            iconName = @"restaurant";
            break;
        case VenueTypeRoofing:
            iconName = @"roofing";
            break;
        case VenueTypeRV:
            iconName = @"rv";
            break;
        case VenueTypeSchool:
            iconName = @"school";
            break;
        case VenueTypeShoe:
            iconName = @"shoe";
            break;
        case VenueTypeShopping:
            iconName = @"shopping";
            break;
        case VenueTypeStadium:
            iconName = @"stadium";
            break;
        case VenueTypeStorage:
            iconName = @"storage";
            break;
        case VenueTypeStore:
            iconName = @"store";
            break;
        case VenueTypeSubway:
            iconName = @"subway";
            break;
        case VenueTypeTrain:
            iconName = @"train";
            break;
        case VenueTypeTravel:
            iconName = @"travel";
            break;
        case VenueTypeResidential:
            iconName = @"residential";
            break;
        case VenueTypeSpayce:
            iconName = @"custom";
            break;
            
        //TODO - still missing icons for these types:
            
        case VenueTypeChurch:
            iconName = @"";
            break;
    
        default:
            break;
    }
    
    if (!iconName) {
        return nil;
    }
    
    NSString * format;
    switch (venueIconType) {
        case VenueIconTypeMapPinFilled:
            format = @"pin-filled-%@";
            break;
        case VenueIconTypeMapPinGray:
            format = @"pin-gray-%@";
            break;
        case VenueIconTypeIconSmallColor:
            format = @"icon-solid-%@";
            break;
        case VenueIconTypeIconSmallBlue:
            format = @"icon-blue-%@";
            break;
        case VenueIconTypeIconWhite:
            format = @"icon-white-%@";
            break;
        case VenueIconTypeIconSmallWhite:
            format = @"icon-white-small-%@";
            break;
        case VenueIconTypeIconNewColor:
            format = @"icon-pin-%@";
            break;
        case VenueIconTypeIconNewColorLarge:
            format = @"lg-icon-pin-%@";
            break;
        
    }
    
    if (!format) {
        return nil;
    }
    
    return [NSString stringWithFormat:format, iconName];
}


+(NSString *)largeImageNameForVenueType:(VenueType)venueType withIconType:(VenueIconType)venueIconType {
    
    NSString *imgName = [SPCVenueTypes imageNameForVenueType:venueType withIconType:venueIconType];
    NSString *largeImgName = [NSString stringWithFormat:@"lg-%@",imgName];
    return largeImgName;
}

+(NSString *)bannerImageNameForVenueType:(VenueType)venueType {
    if (venueType == VenueTypeNone) {
        return nil;
    }
    
    NSString * iconName = @"";
    switch (venueType) {
        case VenueTypeAccounting:
            iconName = @"calculator";
            break;
        case VenueTypeAirport:
            iconName = @"airport";
            break;
        case VenueTypeAmusement:
            iconName = @"amusement";
            break;
        case VenueTypeAquarium:
            iconName = @"aquarium";
            break;
        case VenueTypeArt:
            iconName = @"art_gallery";
            break;
        case VenueTypeAtm:
            iconName = @"atm";
            break;
        case VenueTypeBakery:
            iconName = @"bakery";
            break;
        case VenueTypeBar:
            iconName = @"bar";
            break;
        case VenueTypeBank:
            iconName = @"bank";
            break;
        case VenueTypeBicycle:
            iconName = @"bicycle";
            break;
        case VenueTypeBookstore:
            iconName = @"bookstore";
            break;
        case VenueTypeBowling:
            iconName = @"bowling";
            break;
        case VenueTypeBus:
            iconName = @"bus";
            break;
        case VenueTypeCafe:
            iconName = @"cafe";
            break;
        case VenueTypeCamp:
            iconName = @"canp";
            break;
        case VenueTypeCar:
            iconName = @"car";
            break;
        case VenueTypeCarRepair:
            iconName = @"car-repair";
            break;
        case VenueTypeCarWash:
            iconName = @"car-wash";
            break;
        case VenueTypeCasino:
            iconName = @"casino";
            break;
        case VenueTypeCemetery:
            iconName = @"cemetery";
            break;
        case VenueTypeCityHall:
            iconName = @"cityhall";
            break;
        case VenueTypeClothing:
            iconName = @"clothing";
            break;
        case VenueTypeConvenience:
            iconName = @"convenience";
            break;
        case VenueTypeCourthouse:
            iconName = @"courthouse";
            break;
        case VenueTypeDentist:
            iconName = @"dentist";
            break;
        case VenueTypeDepartment:
            iconName = @"department";
            break;
        case VenueTypeDoctor:
            iconName = @"doctor";
            break;
        case VenueTypeElectrician:
            iconName = @"electrician";
            break;
        case VenueTypeElectronics:
            iconName = @"electronics";
            break;
        case VenueTypeEmbassy:
            iconName = @"embassy";
            break;
        case VenueTypeFinance:
            iconName = @"finance";
            break;
        case VenueTypeFire:
            iconName = @"fire";
            break;
        case VenueTypeFlorist:
            iconName = @"florist";
            break;
        case VenueTypeFood:
            iconName = @"food";
            break;
        case VenueTypeFurniture:
            iconName = @"furniture";
            break;
        case VenueTypeGas:
            iconName = @"gas";
            break;
        case VenueTypeGC:
            iconName = @"residential";
            break;
        case VenueTypeGrocery:
            iconName = @"grocery";
            break;
        case VenueTypeGym:
            iconName = @"gym";
            break;
        case VenueTypeHair:
            iconName = @"hair";
            break;
        case VenueTypeHardware:
            iconName = @"hardware";
            break;
        case VenueTypeHealth:
            iconName = @"health";
            break;
        case VenueTypeHomegoods:
            iconName = @"homegoods";
            break;
        case VenueTypeHospital:
            iconName = @"hospital";
            break;
        case VenueTypeInsurance:
            iconName = @"lawyer";
            break;
        case VenueTypeJewelry:
            iconName = @"jewelry";
            break;
        case VenueTypeLaundry:
            iconName = @"laundry";
            break;
        case VenueTypeLawyer:
            iconName = @"lawyer";
            break;
        case VenueTypeLibrary:
            iconName = @"library";
            break;
        case VenueTypeLiquor:
            iconName = @"liquor";
            break;
        case VenueTypeLocksmith:
            iconName = @"locksmith";
            break;
        case VenueTypeMovieRental:
            iconName = @"movie-rental";
            break;
        case VenueTypeMovieTheater:
            iconName = @"movie-theater";
            break;
        case VenueTypeMoving:
            iconName = @"moving";
            break;
        case VenueTypeMuseum:
            iconName = @"museum";
            break;
        case VenueTypePainter:
            iconName = @"painter";
            break;
        case VenueTypePark:
            iconName = @"park";
            break;
        case VenueTypeParking:
            iconName = @"parking";
            break;
        case VenueTypePharmacy:
            iconName = @"pharmacy";
            break;
        case VenueTypePhysio:
            iconName = @"physio";
            break;
        case VenueTypePolice:
            iconName = @"police";
            break;
        case VenueTypePost:
            iconName = @"post";
            break;
        case VenueTypeRealEstate:
            iconName = @"real-estate";
            break;
        case VenueTypeRestaurant:
            iconName = @"restaurant";
            break;
        case VenueTypeRoofing:
            iconName = @"roofing";
            break;
        case VenueTypeRV:
            iconName = @"rv";
            break;
        case VenueTypeSchool:
            iconName = @"school";
            break;
        case VenueTypeShoe:
            iconName = @"shoe";
            break;
        case VenueTypeShopping:
            iconName = @"shopping";
            break;
        case VenueTypeStadium:
            iconName = @"stadium";
            break;
        case VenueTypeStorage:
            iconName = @"storage";
            break;
        case VenueTypeStore:
            iconName = @"store";
            break;
        case VenueTypeSubway:
            iconName = @"subway";
            break;
        case VenueTypeTrain:
            iconName = @"train";
            break;
        case VenueTypeTravel:
            iconName = @"travel";
            break;
            
            //TODO - still missing icons for these types:
            
        case VenueTypeResidential:
            iconName = @"residential";  //TEMP!!!
            break;
        case VenueTypeChurch:
            iconName = @"church";
            break;
        case VenueTypeSpayce:
            iconName = @"park";
            break;
            
        default:
            break;
    }
    
    return [NSString stringWithFormat:@"%@-banner",iconName];
}

+(UIImage *)largeImageForVenueType:(VenueType)venueType withIconType:(VenueIconType)venueIconType {
    NSString * iconName = [SPCVenueTypes largeImageNameForVenueType:venueType withIconType:venueIconType];
    if (iconName) {
        return [UIImage imageNamed:iconName];
    }
    return nil;
}

+(UIImage *)imageForVenueType:(VenueType)venueType withIconType:(VenueIconType)venueIconType {
    NSString * iconName = [SPCVenueTypes imageNameForVenueType:venueType withIconType:venueIconType];
    if (iconName) {
        return [UIImage imageNamed:iconName];
    }
    return nil;
}

+(UIColor *)colorForVenueType:(VenueType)venueType {
    UInt32 hex = 0xffffff;
    switch (venueType) {
            /*
        case VenueTypeAirport:
            hex = 0x6ab1fb;
            break;
        case VenueTypeBank:
            hex = 0xb88971;
            break;
        case VenueTypeBar:
            hex = 0xffce65;
            break;
        case VenueTypeCafe:
            hex = 0x9bca3e;
            break;
        case VenueTypeChurch:
            hex = 0xca7ae0;
            break;
        
            
        case VenueTypeCommercial:
            hex = 0x7891ba;
            break;
        case VenueTypeEntertainment:
            hex = 0x3c4d5e;
            break;
        case VenueTypeFood:
            hex = 0xca833e;
            break;
        case VenueTypeHospital:
            hex = 0xe74c3c;
            break;
        case VenueTypeMunicipal:
            hex = 0x707275;
            break;
        case VenueTypeResidential:
            hex = 0xf78065;
            break;
        case VenueTypeSchool:
            hex = 0x833a29;
            break;
        case VenueTypeShopping:
            hex = 0x4d9e75;
            break;
        case VenueTypeSpayce:
            hex = 0xa398a6;
            break;
        case VenueTypeSports:
            hex = 0x3f86cf;
            break;
        case VenueTypeSupermarket:
            hex = 0xf19441;
            break;
        case VenueTypeTransportation:
            hex = 0xfad74a;
            break;
        case VenueTypeNone:
            hex = 0x414f67;
            break;
         */
            
        default:
            break;
    }
    
    return [UIColor colorWithRGBHex:hex];
}

+(UIColor *)colorSecondaryForVenueType:(VenueType)venueType {
    if (venueType == VenueTypeNone) {
        return [UIColor colorWithRGBHex:0x7188ae];
    } else {
        UIColor *color = [SPCVenueTypes colorForVenueType:venueType];
        // darken slightly
        CGFloat r, g, b, a;
        if ([color getRed:&r green:&g blue:&b alpha:&a]) {
            return [UIColor colorWithRed:MAX(r - 0.2, 0.0)
                                   green:MAX(g - 0.2, 0.0)
                                    blue:MAX(b - 0.2, 0.0)
                                   alpha:a];
        }
    }
    return [UIColor colorWithWhite:0.9 alpha:1.0];
}

+(BOOL)isNightVenue:(VenueType)venueType {
    BOOL nightVenue = NO;
    
    if ((venueType == VenueTypeBar) || (venueType == VenueTypeAmusement) || (venueType == VenueTypeCafe)  || (venueType == VenueTypeMovieTheater)
    || (venueType == VenueTypeRestaurant)  || (venueType == VenueTypeShopping) || (venueType == VenueTypeStadium))  {
        nightVenue = YES;
    }
    
    return nightVenue;
}

+(BOOL)isDayVenue:(VenueType)venueType {
    BOOL dayVenue = NO;
    
    if ((venueType == VenueTypeAirport) || (venueType == VenueTypeAmusement) || (venueType == VenueTypeAquarium)  ||
        (venueType == VenueTypeArt) || (venueType == VenueTypeAtm)  || (venueType == VenueTypeBakery) ||
        (venueType == VenueTypeBank) || (venueType == VenueTypeHair)  || (venueType == VenueTypeBicycle) ||
        (venueType == VenueTypeBookstore) || (venueType == VenueTypeBowling)  || (venueType == VenueTypeBus) ||
        (venueType == VenueTypeCafe) || (venueType == VenueTypeCar)  || (venueType == VenueTypeCarWash) ||
        (venueType == VenueTypeCasino) || (venueType == VenueTypeCemetery)  || (venueType == VenueTypeChurch) ||
        (venueType == VenueTypeCityHall) || (venueType == VenueTypeClothing)  || (venueType == VenueTypeConvenience) ||
        (venueType == VenueTypeCourthouse) || (venueType == VenueTypeDentist)  || (venueType == VenueTypeDepartment) ||
        (venueType == VenueTypeDoctor) || (venueType == VenueTypeElectrician)  || (venueType == VenueTypeElectronics) ||
        (venueType == VenueTypeEmbassy) || (venueType == VenueTypeFinance)  || (venueType == VenueTypeFire) ||
        (venueType == VenueTypeFlorist) || (venueType == VenueTypeFood)  || (venueType == VenueTypeFurniture) ||
        (venueType == VenueTypeGas) || (venueType == VenueTypeGC)  || (venueType == VenueTypeGrocery) ||
        (venueType == VenueTypeGym) || (venueType == VenueTypeHardware)  || (venueType == VenueTypeHealth) ||
        (venueType == VenueTypeHomegoods) || (venueType == VenueTypeHospital)  || (venueType == VenueTypeInsurance) ||
        (venueType == VenueTypeJewelry) || (venueType == VenueTypeLaundry)  || (venueType == VenueTypeLawyer) ||
        (venueType == VenueTypeLibrary) || (venueType == VenueTypeLiquor)  || (venueType == VenueTypeLocksmith) ||
        (venueType == VenueTypeMovieRental) || (venueType == VenueTypeMoving)  || (venueType == VenueTypeMuseum) ||
        (venueType == VenueTypePainter) || (venueType == VenueTypePark)  || (venueType == VenueTypeParking) ||
        (venueType == VenueTypePharmacy) || (venueType == VenueTypePhysio)  || (venueType == VenueTypePolice) ||
        (venueType == VenueTypePost) || (venueType == VenueTypeRealEstate)  || (venueType == VenueTypeRestaurant) ||
        (venueType == VenueTypeRoofing) || (venueType == VenueTypeRV)  || (venueType == VenueTypeSchool) ||
        (venueType == VenueTypeShoe) || (venueType == VenueTypeStadium)  || (venueType == VenueTypeStorage) ||
        (venueType == VenueTypeStore) || (venueType == VenueTypeSubway)  || (venueType == VenueTypeTrain) || (venueType == VenueTypeTravel)
        )
    {
        dayVenue = YES;
    }
    return dayVenue;
}

@end
