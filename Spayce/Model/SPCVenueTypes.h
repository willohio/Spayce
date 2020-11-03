//
//  SPCVenueTypes.h
//  Spayce
//
//  Created by Jake Rosin on 8/6/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Venue.h"

typedef NS_ENUM(NSInteger, VenueIconType) {
    VenueIconTypeMapPinFilled,
    VenueIconTypeMapPinGray,
    VenueIconTypeIconSmallColor,
    VenueIconTypeIconSmallBlue,
    VenueIconTypeIconWhite,
    VenueIconTypeIconSmallWhite,
    VenueIconTypeIconNewColor,
    VenueIconTypeIconNewColorLarge
};

typedef NS_ENUM(NSInteger, VenueType) {
    VenueTypeAccounting,
    VenueTypeAirport,
    VenueTypeAmusement,
    VenueTypeAquarium,
    VenueTypeArt,
    VenueTypeAtm,
    VenueTypeBakery,
    VenueTypeBank,
    VenueTypeBar,
    VenueTypeBicycle,
    VenueTypeBookstore,
    VenueTypeBowling,
    VenueTypeBus,
    VenueTypeCafe,
    VenueTypeCamp,
    VenueTypeCarRepair,
    VenueTypeCarWash,
    VenueTypeCar,
    VenueTypeCasino,
    VenueTypeCemetery,
    VenueTypeCityHall,
    VenueTypeChurch,
    VenueTypeClothing,
    VenueTypeConvenience,
    VenueTypeCourthouse,
    VenueTypeDentist,
    VenueTypeDepartment,
    VenueTypeDoctor,
    VenueTypeElectrician,
    VenueTypeElectronics,
    VenueTypeEmbassy,
    VenueTypeFinance,
    VenueTypeFire,
    VenueTypeFlorist,
    VenueTypeFood,
    VenueTypeFurniture,
    VenueTypeGas,
    VenueTypeGC,
    VenueTypeGrocery,
    VenueTypeGym,
    VenueTypeHair,
    VenueTypeHardware,
    VenueTypeHealth,
    VenueTypeHomegoods,
    VenueTypeHospital,
    VenueTypeInsurance,
    VenueTypeJewelry,
    VenueTypeLaundry,
    VenueTypeLawyer,
    VenueTypeLibrary,
    VenueTypeLiquor,
    VenueTypeLocksmith,
    VenueTypeMovieRental,
    VenueTypeMovieTheater,
    VenueTypeMoving,
    VenueTypeMuseum,
    VenueTypePainter,
    VenueTypePark,
    VenueTypeParking,
    VenueTypePharmacy,
    VenueTypePhysio,
    VenueTypePolice,
    VenueTypePost,
    VenueTypeRealEstate,
    VenueTypeRestaurant,
    VenueTypeRoofing,
    VenueTypeRV,
    VenueTypeSchool,
    VenueTypeShoe,
    VenueTypeShopping,
    VenueTypeStadium,
    VenueTypeStorage,
    VenueTypeStore,
    VenueTypeSubway,
    VenueTypeTrain,
    VenueTypeTravel,
    VenueTypeResidential,
    VenueTypeSpayce,
    VenueTypeNone
};


@interface SPCVenueTypes : NSObject

/* Returns an array of all supported VenueTypes (as NSNumbers containing the enum values) */
// TODO: Seems like types is never being used
+(NSArray *)types;

+(UIImage *)largeImageForVenue:(Venue *)venue withIconType:(VenueIconType)venueIconType;
+(NSString *)largeImageNameForVenue:(Venue *)venue withIconType:(VenueIconType)venueIconType;

+(UIImage *)imageForVenue:(Venue *)venue withIconType:(VenueIconType)venueIconType;
+(NSString *)imageNameForVenue:(Venue *)venue withIconType:(VenueIconType)venueIconType;

+(UIColor *)colorForVenue:(Venue *)venue;
+(UIColor *)colorSecondaryForVenue:(Venue *)venue;

+(VenueType)typeForVenue:(Venue *)venue;

+(UIImage *)imageForVenueType:(VenueType)venueType withIconType:(VenueIconType)venueIconType;
+(NSString *)imageNameForVenueType:(VenueType)venueType withIconType:(VenueIconType)venueIconType;

+(UIImage *)largeImageForVenueType:(VenueType)venueType withIconType:(VenueIconType)venueIconType;
+(NSString *)largeImageNameForVenueType:(VenueType)venueType withIconType:(VenueIconType)venueIconType;



+(UIColor *)colorForVenueType:(VenueType)venueType;
+(UIColor *)colorSecondaryForVenueType:(VenueType)venueType;


+(UIImage *)headerImageForVenue:(Venue *)venue;

+(BOOL)isDayVenue:(VenueType)venueType;
+(BOOL)isNightVenue:(VenueType)venueType;

@end
