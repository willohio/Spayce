//
//  SPCTerritory.m
//  Spayce
//
//  Created by Jake Rosin on 4/1/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import "SPCTerritory.h"

@implementation SPCTerritory

NSDictionary *COUNTRY_NAME_BY_CODE = nil;
NSDictionary *STATE_NAME_BY_COUNTRY_CODE_STATE_CODE = nil;
NSDictionary *CITY_NAME_BY_COUNTRY_CODE_STATE_CODE_CITY_ABBREVIATION = nil;

+ (void)initialize {
    NSLog(@"initialize");
    if (!COUNTRY_NAME_BY_CODE) {
        COUNTRY_NAME_BY_CODE = @{
                                 @"AD":	@"Andorra",
                                 @"AE": 	@"United Arab Emirates",
                                 @"AF": 	@"Afghanistan",
                                 @"AG": 	@"Antigua & Barbuda",
                                 @"AI": 	@"Anguilla",
                                 @"AL": 	@"Albania",
                                 @"AM": 	@"Armenia",
                                 @"AN": 	@"Netherlands Antilles",
                                 @"AO": 	@"Angola",
                                 @"AQ": 	@"Antarctica",
                                 @"AR": 	@"Argentina",
                                 @"AS": 	@"American Samoa",
                                 @"AT": 	@"Austria",
                                 @"AU": 	@"Australia",
                                 @"AW": 	@"Aruba",
                                 @"AZ": 	@"Azerbaijan",
                                 @"BA": 	@"Bosnia and Herzegovina",
                                 @"BB": 	@"Barbados",
                                 @"BD": 	@"Bangladesh",
                                 @"BE": 	@"Belgium",
                                 @"BF": 	@"Burkina Faso",
                                 @"BG": 	@"Bulgaria",
                                 @"BH": 	@"Bahrain",
                                 @"BI": 	@"Burundi",
                                 @"BJ": 	@"Benin",
                                 @"BM": 	@"Bermuda",
                                 @"BN": 	@"Brunei Darussalam",
                                 @"BO": 	@"Bolivia",
                                 @"BR": 	@"Brazil",
                                 @"BS": 	@"Bahama",
                                 @"BT": 	@"Bhutan",
                                 @"BU": 	@"Burma",     // no longer exists
                                 @"BV": 	@"Bouvet Island",
                                 @"BW": 	@"Botswana",
                                 @"BY": 	@"Belarus",
                                 @"BZ": 	@"Belize",
                                 @"CA": 	@"Canada",
                                 @"CC": 	@"Cocos (Keeling) Islands",
                                 @"CF": 	@"Central African Republic",
                                 @"CG": 	@"Congo",
                                 @"CH": 	@"Switzerland",
                                 @"CI": 	@"Côte D'ivoire (Ivory Coast)",
                                 @"CK": 	@"Cook Iislands",
                                 @"CL": 	@"Chile",
                                 @"CM": 	@"Cameroon",
                                 @"CN": 	@"China",
                                 @"CO": 	@"Colombia",
                                 @"CR": 	@"Costa Rica",
                                 @"CS": 	@"Czechoslovakia",    // no longer exists
                                 @"CU": 	@"Cuba",
                                 @"CV": 	@"Cape Verde",
                                 @"CX": 	@"Christmas Island",
                                 @"CY": 	@"Cyprus",
                                 @"CZ": 	@"Czech Republic",
                                 @"DD": 	@"German Democratic Republic",    // no longer exists
                                 @"DE": 	@"Germany",
                                 @"DJ": 	@"Djibouti",
                                 @"DK": 	@"Denmark",
                                 @"DM": 	@"Dominica",
                                 @"DO": 	@"Dominican Republic",
                                 @"DZ": 	@"Algeria",
                                 @"EC": 	@"Ecuador",
                                 @"EE": 	@"Estonia",
                                 @"EG": 	@"Egypt",
                                 @"EH": 	@"Western Sahara",
                                 @"ER": 	@"Eritrea",
                                 @"ES": 	@"Spain",
                                 @"ET": 	@"Ethiopia",
                                 @"FI": 	@"Finland",
                                 @"FJ": 	@"Fiji",
                                 @"FK": 	@"Falkland Islands (Malvinas)",
                                 @"FM": 	@"Micronesia",
                                 @"FO": 	@"Faroe Islands",
                                 @"FR": 	@"France",
                                 @"FX": 	@"France, Metropolitan",
                                 @"GA": 	@"Gabon",
                                 @"GB": 	@"United Kingdom",        // Great Britain
                                 @"GD": 	@"Grenada",
                                 @"GE": 	@"Georgia",
                                 @"GF": 	@"French Guiana",
                                 @"GH": 	@"Ghana",
                                 @"GI": 	@"Gibraltar",
                                 @"GL": 	@"Greenland",
                                 @"GM": 	@"Gambia",
                                 @"GN": 	@"Guinea",
                                 @"GP": 	@"Guadeloupe",
                                 @"GQ": 	@"Equatorial Guinea",
                                 @"GR": 	@"Greece",
                                 @"GS": 	@"South Georgia and the South Sandwich Islands",
                                 @"GT": 	@"Guatemala",
                                 @"GU": 	@"Guam",
                                 @"GW": 	@"Guinea-Bissau",
                                 @"GY": 	@"Guyana",
                                 @"HK": 	@"Hong Kong",
                                 @"HM": 	@"Heard & McDonald Islands",
                                 @"HN": 	@"Honduras",
                                 @"HR": 	@"Croatia",
                                 @"HT": 	@"Haiti",
                                 @"HU": 	@"Hungary",
                                 @"ID": 	@"Indonesia",
                                 @"IE": 	@"Ireland",
                                 @"IL": 	@"Israel",
                                 @"IN": 	@"India",
                                 @"IO": 	@"British Indian Ocean Territory",
                                 @"IQ": 	@"Iraq",
                                 @"IR": 	@"Islamic Republic of Iran",
                                 @"IS": 	@"Iceland",
                                 @"IT": 	@"Italy",
                                 @"JM": 	@"Jamaica",
                                 @"JO": 	@"Jordan",
                                 @"JP": 	@"Japan",
                                 @"KE": 	@"Kenya",
                                 @"KG": 	@"Kyrgyzstan",
                                 @"KH": 	@"Cambodia",
                                 @"KI": 	@"Kiribati",
                                 @"KM": 	@"Comoros",
                                 @"KN": 	@"St. Kitts and Nevis",
                                 @"KP": 	@"North Korea",     // Democratic People's Republic of Korea
                                 @"KR": 	@"South Korea",     // Republic of Korea
                                 @"KW": 	@"Kuwait",
                                 @"KY": 	@"Cayman Islands",
                                 @"KZ": 	@"Kazakhstan",
                                 @"LA": 	@"Lao People's Democratic Republic",
                                 @"LB": 	@"Lebanon",
                                 @"LC": 	@"Saint Lucia",
                                 @"LI": 	@"Liechtenstein",
                                 @"LK": 	@"Sri Lanka",
                                 @"LR": 	@"Liberia",
                                 @"LS": 	@"Lesotho",
                                 @"LT": 	@"Lithuania",
                                 @"LU": 	@"Luxembourg",
                                 @"LV": 	@"Latvia",
                                 @"LY": 	@"Libyan Arab Jamahiriya",
                                 @"MA": 	@"Morocco",
                                 @"MC": 	@"Monaco",
                                 @"MD": 	@"Republic of Moldova",
                                 @"MG": 	@"Madagascar",
                                 @"MH": 	@"Marshall Islands",
                                 @"ML": 	@"Mali",
                                 @"MM": 	@"Myanmar",
                                 @"MN": 	@"Mongolia",
                                 @"MO": 	@"Macau",
                                 @"MP": 	@"Northern Mariana Islands",
                                 @"MQ": 	@"Martinique",
                                 @"MR": 	@"Mauritania",
                                 @"MS": 	@"Monserrat",
                                 @"MT": 	@"Malta",
                                 @"MU": 	@"Mauritius",
                                 @"MV": 	@"Maldives",
                                 @"MW": 	@"Malawi",
                                 @"MX": 	@"Mexico",
                                 @"MY": 	@"Malaysia",
                                 @"MZ": 	@"Mozambique",
                                 @"NA": 	@"Nambia",
                                 @"NC": 	@"New Caledonia",
                                 @"NE": 	@"Niger",
                                 @"NF": 	@"Norfolk Island",
                                 @"NG": 	@"Nigeria",
                                 @"NI": 	@"Nicaragua",
                                 @"NL": 	@"Netherlands",
                                 @"NO": 	@"Norway",
                                 @"NP": 	@"Nepal",
                                 @"NR": 	@"Nauru",
                                 @"NT": 	@"Neutral Zone",  // No longer exists.  Also the Romulans probably have cloaked vessels there.
                                 @"NU": 	@"Niue",
                                 @"NZ": 	@"New Zealand",
                                 @"OM": 	@"Oman",
                                 @"PA": 	@"Panama",
                                 @"PE": 	@"Peru",
                                 @"PF": 	@"French Polynesia",
                                 @"PG": 	@"Papua New Guinea",
                                 @"PH": 	@"Philippines",
                                 @"PK": 	@"Pakistan",
                                 @"PL": 	@"Poland",
                                 @"PM": 	@"St. Pierre & Miquelon",
                                 @"PN": 	@"Pitcairn",
                                 @"PR": 	@"Puerto Rico",
                                 @"PT": 	@"Portugal",
                                 @"PW": 	@"Palau",
                                 @"PY": 	@"Paraguay",
                                 @"QA": 	@"Qatar",
                                 @"RE": 	@"Réunion",
                                 @"RO": 	@"Romania",
                                 @"RU": 	@"Russian Federation",
                                 @"RW": 	@"Rwanda",
                                 @"SA": 	@"Saudi Arabia",
                                 @"SB": 	@"Solomon Islands",
                                 @"SC": 	@"Seychelles",
                                 @"SD": 	@"Sudan",
                                 @"SE": 	@"Sweden",
                                 @"SG": 	@"Singapore",
                                 @"SH": 	@"St. Helena",
                                 @"SI": 	@"Slovenia",
                                 @"SJ": 	@"Svalbard & Jan Mayen Islands",
                                 @"SK": 	@"Slovakia",
                                 @"SL": 	@"Sierra Leone",
                                 @"SM": 	@"San Marino",
                                 @"SN": 	@"Senegal",
                                 @"SO": 	@"Somalia",
                                 @"SR": 	@"Suriname",
                                 @"ST": 	@"Sao Tome & Principe",
                                 @"SU": 	@"USSR",        // Union of Soviet Socialist Republics
                                 @"SV": 	@"El Salvador",
                                 @"SY": 	@"Syrian Arab Republic",
                                 @"SZ": 	@"Swaziland",
                                 @"TC": 	@"Turks & Caicos Islands",
                                 @"TD": 	@"Chad",
                                 @"TF": 	@"French Southern Territories",
                                 @"TG": 	@"Togo",
                                 @"TH": 	@"Thailand",
                                 @"TJ": 	@"Tajikistan",
                                 @"TK": 	@"Tokelau",
                                 @"TM": 	@"Turkmenistan",
                                 @"TN": 	@"Tunisia",
                                 @"TO": 	@"Tonga",
                                 @"TP": 	@"East Timor",
                                 @"TR": 	@"Turkey",
                                 @"TT": 	@"Trinidad & Tobago",
                                 @"TV": 	@"Tuvalu",
                                 @"TW": 	@"Taiwan",        // officially "Republic of China"
                                 @"TZ": 	@"Tanzania", // United Republic of Tanzania
                                 @"UA": 	@"Ukraine",
                                 @"UG": 	@"Uganda",
                                 @"UM": 	@"US Minor Outlying Islands",
                                 @"US": 	@"USA",    // United States of America
                                 @"UY": 	@"Uruguay",
                                 @"UZ": 	@"Uzbekistan",
                                 @"VA": 	@"Vatican City State",        // Holy See
                                 @"VC": 	@"St. Vincent & the Grenadines",
                                 @"VE": 	@"Venezuela",
                                 @"VG": 	@"British Virgin Islands",
                                 @"VI": 	@"US Virgin Islands",
                                 @"VN": 	@"Viet Nam",
                                 @"VU": 	@"Vanuatu",
                                 @"WF": 	@"Wallis & Futuna Islands",
                                 @"WS": 	@"Samoa",
                                 @"YE": 	@"Yemen",
                                 @"YT": 	@"Mayotte",
                                 @"YU": 	@"Yugoslavia",
                                 @"ZA": 	@"South Africa",
                                 @"ZM": 	@"Zambia",
                                 @"ZR": 	@"Zaire",
                                 @"ZW": 	@"Zimbabwe"
                                 };
    }
    
    if (!STATE_NAME_BY_COUNTRY_CODE_STATE_CODE) {
        NSDictionary *stateNameByStateCodeUS = @{
                                                 @"AL":	@"Alabama",
                                                 @"AK":	@"Alaska",
                                                 @"AZ":	@"Arizona",
                                                 @"AR":	@"Arkansas",
                                                 @"CA":	@"California",
                                                 @"CO":	@"Colorado",
                                                 @"CT":	@"Connecticut",
                                                 @"DE":	@"Delaware",
                                                 @"FL":	@"Florida",
                                                 @"GA":	@"Georgia",
                                                 @"HI":	@"Hawaii",
                                                 @"ID":	@"Idaho",
                                                 @"IL":	@"Illinois",
                                                 @"IN":	@"Indiana",
                                                 @"IA":	@"Iowa",
                                                 @"KS":	@"Kansas",
                                                 @"KY":	@"Kentucky",
                                                 @"LA":	@"Louisiana",
                                                 @"ME":	@"Maine",
                                                 @"MD":	@"Maryland",
                                                 @"MA":	@"Massachusetts",
                                                 @"MI":	@"Michigan",
                                                 @"MN":	@"Minnesota",
                                                 @"MS":	@"Mississippi",
                                                 @"MO":	@"Missouri",
                                                 @"MT":	@"Montana",
                                                 @"NE":	@"Nebraska",
                                                 @"NV":	@"Nevada",
                                                 @"NH":	@"New Hampshire",
                                                 @"NJ":	@"New Jersey",
                                                 @"NM":	@"New Mexico",
                                                 @"NY":	@"New York",
                                                 @"NC":	@"North Carolina",
                                                 @"ND":	@"North Dakota",
                                                 @"OH":	@"Ohio",
                                                 @"OK":	@"Oklahoma",
                                                 @"OR":	@"Oregon",
                                                 @"PA":	@"Pennsylvania",
                                                 @"RI":	@"Rhode Island",
                                                 @"SC":	@"South Carolina",
                                                 @"SD":	@"South Dakota",
                                                 @"TN":	@"Tennessee",
                                                 @"TX":	@"Texas",
                                                 @"UT":	@"Utah",
                                                 @"VT":	@"Vermont",
                                                 @"VA":	@"Virginia",
                                                 @"WA":	@"Washington",
                                                 @"WV":	@"West Virginia",
                                                 @"WI":	@"Wisconsin",
                                                 @"WY":	@"Wyoming",
                                                 
                                                 @"AS":	@"American Samoa",
                                                 @"DC":	@"District of Columbia",
                                                 @"FM":	@"Federated States of Micronesia",
                                                 @"GU":	@"Guam",
                                                 @"MH":	@"Marshall Islands",
                                                 @"MP":	@"Northern Mariana Islands",
                                                 @"PW":	@"Palau",
                                                 @"PR":	@"Puerto Rico",
                                                 @"VI":	@"Virgin Islands",
                                                 
                                                 @"AE":	@"Armed Forces Africa",
                                                 @"AA":	@"Armed Forces Americas",
                                                 @"AE":	@"Armed Forces Canada",
                                                 @"AE":	@"Armed Forces Europe",
                                                 @"AE":	@"Armed Forces Middle East",
                                                 @"AP":	@"Armed Forces Pacific"
                                                 };
                                                 
        NSDictionary *stateNameByStateCodeCA = @{
                                                 @"AB": 	@"Alberta",
                                                 @"BC": 	@"British Columbia",
                                                 @"MB": 	@"Manitoba",
                                                 @"NB": 	@"New Brunswick",
                                                 @"NL": 	@"Newfoundland and Labrador",
                                                 @"NS": 	@"Nova Scotia",
                                                 @"NT": 	@"Northwest Territories",
                                                 @"NU": 	@"Nunavut",
                                                 @"ON": 	@"Ontario",
                                                 @"PE": 	@"Prince Edward Island",
                                                 @"QC": 	@"Quebec",
                                                 @"SK": 	@"Saskatchewan",
                                                 @"YT": 	@"Yukon"
                                                 };
        
        STATE_NAME_BY_COUNTRY_CODE_STATE_CODE = @{
                                                  @"US": stateNameByStateCodeUS,
                                                  @"CA": stateNameByStateCodeCA
                                                  };
    }
    
    if (!CITY_NAME_BY_COUNTRY_CODE_STATE_CODE_CITY_ABBREVIATION) {
        CITY_NAME_BY_COUNTRY_CODE_STATE_CODE_CITY_ABBREVIATION = @{
                                                                   @"US": @{
                                                                           @"CA": @{@"SF": @"San Francisco",
                                                                                    @"LA": @"Los Angeles"},
                                                                           @"IL": @{@"Chcgo": @"Chicago",
                                                                                    @"Chgo": @"Chicago"},
                                                                           @"MD": @{@"Balt": @"Baltimore"},
                                                                           @"NY": @{@"NY": @"New York"},
                                                                           @"WI": @{@"Milw": @"Milwaukee"}
                                                                           
                                                                           }
                                                                   };
    }
}

+ (NSString *)countryNameForCountryCode:(NSString *)countryCode {
    if (!countryCode) {
        return nil;
    }
    NSString *name = COUNTRY_NAME_BY_CODE[countryCode];
    return name ? name : countryCode;
}

+ (NSString *)stateNameForStateCode:(NSString *)stateCode countryCode:(NSString *)countryCode {
    if (!stateCode || !countryCode) {
        return nil;
    }
    // We only know US and Canada.
    NSDictionary *stateNameByStateCode = STATE_NAME_BY_COUNTRY_CODE_STATE_CODE[countryCode];
    NSString *name = stateNameByStateCode ? stateNameByStateCode[stateCode] : nil;
    return name ? name : stateCode;
}

+ (NSString *)fixCityName:(NSString *)cityName stateCode:(NSString *)stateCode countryCode:(NSString *)countryCode {
    if (!cityName || !stateCode || !countryCode) {
        return cityName;
    }
    NSDictionary *cityNameByStateCodeCityAbbreviation = CITY_NAME_BY_COUNTRY_CODE_STATE_CODE_CITY_ABBREVIATION[countryCode];
    NSDictionary *cityNameByCityAbbreviation = cityNameByStateCodeCityAbbreviation ? cityNameByStateCodeCityAbbreviation[stateCode] : nil;
    NSString *name = cityNameByCityAbbreviation ? cityNameByCityAbbreviation[cityName] : nil;
    return name ? name : cityName;
}


@end
