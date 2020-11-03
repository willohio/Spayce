//
//  Comment.m
//  Spayce
//
//  Created by Christopher Taylor on 6/24/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "Comment.h"
#import "Asset.h"
#import "Person.h"
#import <CoreText/CoreText.h>

@interface Comment ()

@property (nonatomic, strong) NSAttributedString *attributedText;
@property (nonatomic) CGFloat attributedTextHeight;

@end

@implementation Comment

- (id)initWithAttributes:(NSDictionary *)attributes
{
    self = [super init];
    if (self) {

        _dateCreated = (NSString *)[TranslationUtils valueOrNil:attributes[@"dateCreated"]];
        _recordID = [TranslationUtils integerValueFromDictionary:attributes withKey:@"id"];
        _starCount = [TranslationUtils integerValueFromDictionary:attributes withKey:@"starCount"];
        _text = (NSString *)[TranslationUtils valueOrNil:attributes[@"text"]];
        _markupText = (NSString *)[TranslationUtils valueOrNil:attributes[@"markupText"]];
        _userHasStarred = [TranslationUtils booleanValueFromDictionary:attributes withKey:@"userHasStarred"];
      
        NSArray *taggedUsers = (NSArray *)[TranslationUtils valueOrNil:attributes[@"taggedUsers"]];
        
        if (taggedUsers.count > 0) {
            [self handleTaggedUsers:taggedUsers];
        }
        
        NSDictionary *authorDict = (NSDictionary *)attributes[@"author"];
        _author = [[Person alloc] initWithAttributes:authorDict];
        
        _pic = [Asset assetFromDictionary:authorDict withAssetKey:@"profilePhotoAssetInfo" assetIdKey:@"profilePhotoAssetID"];
        
        if (!_pic) {
            _localPicUrl = (NSString *)[TranslationUtils valueOrNil:attributes[@"localPicUrl"]];
        }
        
        _userName = (NSString *)[TranslationUtils valueOrNil:authorDict[@"firstname"]];
        _userToken = (NSString *)[TranslationUtils valueOrNil:authorDict[@"userToken"]];
        
        if (!_markupText && _text) {
            _markupText = _text;
        }
        if (!_text && _markupText) {
            _text = _markupText;
        }

        // Preload Attributed Text for display
        _attributedTextHeight = 0;
        _attributedText = nil;
        [self attributedText];
    }
    return self;
}

- (void)handleTaggedUsers:(NSArray *)taggedUsers {
    
    NSMutableArray *tempNames = [[NSMutableArray alloc] init];
    NSMutableArray *tempTokens = [[NSMutableArray alloc] init];
    NSMutableArray *tempIds = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < taggedUsers.count; i++) {
        
        NSDictionary *userDict = (NSDictionary *)taggedUsers[i];
        
        NSString *tempName = userDict[@"firstname"];
        [tempNames addObject:tempName];
        
        NSString *tempToken = userDict[@"userToken"];
        [tempTokens addObject:tempToken];
        
        NSString *tempId = userDict[@"id"];
        [tempIds addObject:tempId];
    }
    
    self.taggedUserTokens = [NSArray arrayWithArray:tempTokens];
    self.taggedUserNames = [NSArray arrayWithArray:tempNames];
    self.taggedUserIds = [NSArray arrayWithArray:tempIds];
}

- (NSAttributedString *)attributedText {
    if (!_attributedText) {
        CGSize constraint = CGSizeMake([UIScreen mainScreen].bounds.size.width - 36, FLT_MAX);
        NSDictionary *attributes = @{ NSFontAttributeName: [UIFont spc_regularSystemFontOfSize:14] };
        
        NSString *comAuthor = self.userName;
        NSString *comText = self.text;
        NSString *comboText = [NSString stringWithFormat:@"%@ %@",comAuthor,comText];
        
        NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:comboText attributes:attributes];
        
        [attrString addAttribute:NSFontAttributeName value:[UIFont spc_regularSystemFontOfSize:14] range:NSMakeRange(0, attrString.length)];
        [attrString addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:102.0f/255.0f green:113.0f/255.0f blue:130.0f/255.0f alpha:1.0f] range:NSMakeRange(0, attrString.length)];
        
        //using core text to correctly handle sizing for emoji
        CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)attrString);
        CGSize targetSize = CGSizeMake(constraint.width, CGFLOAT_MAX);
        CGSize fitSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, [attrString length]), NULL, targetSize, NULL);
        _attributedTextHeight = fitSize.height;
        CFRelease(framesetter);
        
        NSRange authorRange = NSMakeRange(0, comAuthor.length);
        NSMutableAttributedString *styledText = [[NSMutableAttributedString alloc] initWithAttributedString:attrString];
        
        [styledText addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:20.0f/255.0f green:41.0f/255.0f blue:75.0f/255.0f alpha:1.0f] range:authorRange];
        [styledText addAttribute:NSFontAttributeName value:[UIFont spc_mediumSystemFontOfSize:14] range:authorRange];
        
        _attributedText = styledText;
    }
    return _attributedText;
}


- (CGFloat)attributedTextHeight {
    return _attributedTextHeight;
}

- (void)refreshMetadata {
    if (![_text isEqualToString:_markupText]) {
        @try {
            NSMutableString *text = [[NSMutableString alloc] initWithString:_markupText];
            
            // Note: it may strike you as more convenient to simply examine our list of tagged user IDs and
            // find-and-replace the strings @{id1}, @{id2}, etc. with their names.
            // Convenient, sure, but also insecure, because we don't have control over usernames and
            // (as of this moment) the string "@{666}" is a perfectly valid username, allowing tag
            // injection by malicious users through name changes.
            
            // Instead, we do a single linear pass through the text to ensure we don't replace
            // the same markup more than once.  As long as the comment itself was posted by
            // a well-behaved client, it should correctly process.
            NSRange atRange = [text rangeOfString:@"@"];
            while (atRange.location != NSNotFound && atRange.location < text.length - 1) {
                NSInteger nextSearch = atRange.location + 1;
                
                char nextChar = [text characterAtIndex:(atRange.location + 1)];
                // escaped @\ ?
                if (nextChar == '\\') {
                    [text replaceCharactersInRange:NSMakeRange(atRange.location, 2) withString:@"@"];
                } else if (nextChar == '{') {
                    NSRange endRange = [text rangeOfString:@"}" options:0 range:NSMakeRange(atRange.location, text.length - atRange.location)];
                    if (endRange.location != NSNotFound) {
                        NSRange replaceRange = NSMakeRange(atRange.location, endRange.location - atRange.location + 1);
                        NSRange idRange = NSMakeRange(atRange.location+2, endRange.location - atRange.location - 2);
                        NSString *idStr = [text substringWithRange:idRange];
                        NSString *userName = nil;
                        for (int i = 0; i < _taggedUserIds.count; i++) {
                            NSObject *taggedId = _taggedUserIds[i];
                            NSString *taggedIdStr;
                            if ([taggedId isKindOfClass:[NSString class]]) {
                                taggedIdStr = (NSString *)taggedId;
                            } else {
                                taggedIdStr = [NSString stringWithFormat:@"%d", [((NSNumber *)taggedId) intValue]];
                            }
                            if ([taggedIdStr isEqualToString:idStr]) {
                                userName = _taggedUserNames[i];
                            }
                        }
                        if (userName) {
                            [text replaceCharactersInRange:replaceRange withString:userName];
                            nextSearch = atRange.location + userName.length;
                        }
                    }
                }
                
                atRange = [text rangeOfString:@"@" options:0 range:NSMakeRange(nextSearch, text.length - nextSearch)];
            }
            
            _text = [NSString stringWithString:text];
        }
        @catch (NSException *e) {
            // no change
        }
    }
    
    _attributedTextHeight = 0;
    _attributedText = nil;
    [self attributedText];
}


#pragma mark - Comparing comments

- (BOOL)isEqual:(id)object {
    if (object == self)
        return YES;
    if (!object || ![object isKindOfClass:[self class]])
        return NO;
    return [self isEqualToComment:object];
}

- (BOOL)isEqualToComment:(Comment *)comment {
    if (self == comment)
        return YES;
    if (self.recordID != comment.recordID)
        return NO;
    return YES;
}

- (NSUInteger)hash {
    NSUInteger hash = 0;
    hash += [@([self recordID]) hash];
    return hash;
}

@end
