//
//  STTweetLabel.h
//  STTweetLabel
//
//  Created by Sebastien Thiebaud on 09/29/13.
//  Copyright (c) 2013 Sebastien Thiebaud. All rights reserved.
//

typedef enum {
    STTweetHandle = 0,
    STTweetHashtag,
    STTweetLink,
    STTweetAnnotation
} STTweetHotWord;

extern NSString * STTweetAnnotationHotWord;

@interface STTweetLabel : UILabel

@property (nonatomic, strong) NSArray *validProtocols;
@property (nonatomic, assign) BOOL leftToRight;
@property (nonatomic, assign) BOOL textSelectable;
@property (nonatomic, strong) UIColor *selectionColor;
@property (nonatomic, copy) void (^detectionBlock)(STTweetHotWord hotWord, NSString *string, NSString *protocol, NSRange range);

@property (nonatomic, assign) BOOL detectHotWords;
@property (nonatomic, assign) BOOL detectHashTags;


- (void)setAttributes:(NSDictionary *)attributes;
- (void)setAttributes:(NSDictionary *)attributes hotWord:(STTweetHotWord)hotWord;

- (NSDictionary *)attributes;
- (NSDictionary *)attributesForHotWord:(STTweetHotWord)hotWord;

- (CGSize)suggestedFrameSizeToFitEntireStringConstraintedToWidth:(CGFloat)width;

@end
