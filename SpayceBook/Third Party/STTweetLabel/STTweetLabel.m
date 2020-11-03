//
//  STTweetLabel.m
//  STTweetLabel
//
//  Created by Sebastien Thiebaud on 09/29/13.
//  Copyright (c) 2013 Sebastien Thiebaud. All rights reserved.
//

#import "STTweetLabel.h"
#import "STTweetTextStorage.h"

#define STURLRegex @"(?i)\\b((?:[a-z][\\w-]+:(?:/{1,3}|[a-z0-9%])|www\\d{0,3}[.]|[a-z0-9.\\-]+[.][a-z]{2,4}/)(?:[^\\s()<>]+|\\(([^\\s()<>]+|(\\([^\\s()<>]+\\)))*\\))+(?:\\(([^\\s()<>]+|(\\([^\\s()<>]+\\)))*\\)|[^\\s`!()\\[\\]{};:'\".,<>?«»“”‘’]))"

#pragma mark -
#pragma mark STTweetLabel

NSString * STTweetAnnotationHotWord = @"STTweetAnnotationHotWord";

@interface STTweetLabel () <UITextViewDelegate>

@property (strong) STTweetTextStorage *textStorage;
@property (strong) NSLayoutManager *layoutManager;
@property (strong) NSTextContainer *textContainer;

@property (nonatomic, strong) NSString *cleanText;
@property (nonatomic, strong) NSAttributedString *cleanAttributedText;

@property (strong) NSMutableArray *rangesOfHotWords;

@property (nonatomic, strong) NSDictionary *attributesText;
@property (nonatomic, strong) NSDictionary *attributesHandle;
@property (nonatomic, strong) NSDictionary *attributesHashtag;
@property (nonatomic, strong) NSDictionary *attributesLink;
@property (nonatomic, strong) NSDictionary *attributesAnnotation;

@property (strong) UITextView *textView;
@property (nonatomic, assign) BOOL foundHashTags;

- (void)setupLabel;
- (void)determineHotWords;
- (void)determineLinks;
- (void)updateText;

@end

@implementation STTweetLabel {
    BOOL _isTouchesMoved;
    NSRange _selectableRange;
    int _firstCharIndex;
    CGPoint _firstTouchLocation;
}

#pragma mark -
#pragma mark Lifecycle

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        [self setupLabel];
    }
    
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setupLabel];
}

#pragma mark -
#pragma mark Responder

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    return (action == @selector(copy:));
}

- (void)copy:(id)sender {
    [[UIPasteboard generalPasteboard] setString:[_cleanText substringWithRange:_selectableRange]];
    
    @try {
        [_textStorage removeAttribute:NSBackgroundColorAttributeName range:_selectableRange];
    } @catch (NSException *exception) {
    }
}

#pragma mark -
#pragma mark Setup

- (void)setupLabel {
	// Set the basic properties
	[self setBackgroundColor:[UIColor clearColor]];
	[self setClipsToBounds:NO];
	[self setUserInteractionEnabled:YES];
	[self setNumberOfLines:0];
    
    _leftToRight = YES;
    _textSelectable = NO;
    _detectHotWords = YES;
    _detectHashTags = NO;
    _selectionColor = [UIColor colorWithWhite:0.9 alpha:1.0];
    
    _attributesText = @{NSForegroundColorAttributeName: self.textColor, NSFontAttributeName: [UIFont spc_regularSystemFontOfSize:14]};
    _attributesHandle = @{NSForegroundColorAttributeName: [UIColor redColor], NSFontAttributeName: [UIFont spc_regularSystemFontOfSize:14]};
    _attributesHashtag = @{NSForegroundColorAttributeName: [UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f], NSFontAttributeName: [UIFont spc_regularSystemFontOfSize:14]};
    _attributesLink = @{NSForegroundColorAttributeName: [[UIColor alloc] initWithRed:129.0/255.0 green:171.0/255.0 blue:193.0/255.0 alpha:1.0], NSFontAttributeName:[UIFont spc_regularSystemFontOfSize:14]};
    _attributesAnnotation =  @{NSForegroundColorAttributeName: [UIColor colorWithRed:118.0f/255.0f green:158.0f/255.0f blue:222.0f/255.0f alpha:1.0f], NSFontAttributeName: [UIFont spc_regularSystemFontOfSize:14]};
    
    self.validProtocols = @[@"http", @"https"];
    
    _layoutManager = [[NSLayoutManager alloc] init];
    _textContainer = [[NSTextContainer alloc] initWithSize:CGSizeMake(self.frame.size.width, CGFLOAT_MAX)];
    _rangesOfHotWords = [[NSMutableArray alloc] init];
    
    _textStorage = [[STTweetTextStorage alloc] init];
    [_textStorage addLayoutManager:_layoutManager];
    
    _textView = [[UITextView alloc] initWithFrame:self.bounds textContainer:_textContainer];
    _textView.delegate = self;
    _textView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    _textView.backgroundColor = [UIColor clearColor];
    _textView.textContainer.lineFragmentPadding = 0;
    _textView.textContainerInset = UIEdgeInsetsZero;
    _textView.userInteractionEnabled = NO;
    [self addSubview:_textView];
    
    [super setText:@""];
}

- (void)layoutSubviews {
    _textContainer.size = CGSizeMake(self.frame.size.width, CGFLOAT_MAX);
    if (_textView) {
        _textView.frame = self.bounds;
    }
    [super layoutSubviews];
}

#pragma mark -
#pragma mark Printing and calculating text

- (void)determineHotWords {
    // Need a text
    if (_cleanText == nil)
        return;
    
    @try {
        int textContainers = _layoutManager.textContainers.count;
        for (int i = 0; i < textContainers; i++) {
            [_layoutManager removeTextContainerAtIndex:0];
        }
    } @catch (NSException *exception) {
        // Exceptions occassionally occur here during rapid scrolling
        // of a UITableView containing STTweetLabels. The exception
        // is caused by [NSRecursiveLock dealloc] with message
        // 'deallocated while still in use'.  Since we're not using
        // that class directly here, I'm not sure the cause other than
        // that it is obviously a threading issue.  We could @synchronize
        // this block but I expect that any useful synchronization would
        // slow down table scrolls significantly.
        _layoutManager = [[NSLayoutManager alloc] init];
        _textStorage = [[STTweetTextStorage alloc] init];
        [_textStorage addLayoutManager:_layoutManager];
    }
    
    [_layoutManager addTextContainer:_textContainer];
    
    [_rangesOfHotWords removeAllObjects];
    
    // First: if the provided string contains any STTweetLabelAnnotatedHotWords, note them
    // in our hot word dictionary.
    if (_cleanAttributedText) {
        [_cleanAttributedText enumerateAttribute:STTweetAnnotationHotWord inRange:NSMakeRange(0, [_cleanAttributedText length]) options:0
        usingBlock:^(id value, NSRange range, BOOL *stop) {
            if (value == NULL) {
                return;
            }
            NSString * substitutionText = value;
            [_rangesOfHotWords addObject:@{@"hotWord": @(STTweetAnnotation), @"range": [NSValue valueWithRange:range], @"substitution": substitutionText}];
        }];
    }
    
    if (_detectHotWords) {
        NSMutableString *tmpText = [[NSMutableString alloc] initWithString:_cleanText];
        
        // Support RTL
        if (!_leftToRight) {
            tmpText = [[NSMutableString alloc] init];
            [tmpText appendString:@"\u200F"];
            [tmpText appendString:_cleanText];
        }
        
        // Define a character set for hot characters (@ handle, # hashtag)
        NSString *hotCharacters = @"@#";
        NSCharacterSet *hotCharactersSet = [NSCharacterSet characterSetWithCharactersInString:hotCharacters];
        
        // Define a character set for the complete world (determine the end of the hot word)
        NSMutableCharacterSet *validCharactersSet = [NSMutableCharacterSet alphanumericCharacterSet];
        [validCharactersSet removeCharactersInString:@"!@#$%^&*()-={[]}|;:',<>.?/"];
        [validCharactersSet addCharactersInString:@"_"];
        
        
        while ([tmpText rangeOfCharacterFromSet:hotCharactersSet].location < tmpText.length) {
            NSRange range = [tmpText rangeOfCharacterFromSet:hotCharactersSet];
            
            STTweetHotWord hotWord;

            switch ([tmpText characterAtIndex:range.location]) {
                case '@':
                    hotWord = STTweetHandle;
                    break;
                case '#':
                    hotWord = STTweetHashtag;
                    break;
                default:
                    break;
            }

            [tmpText replaceCharactersInRange:range withString:@"%"];
            // If the hot character is not preceded by a alphanumeric characater, ie email (sebastien@world.com)
            if (range.location > 0 && [tmpText characterAtIndex:range.location - 1] != ' ' && [tmpText characterAtIndex:range.location - 1] != '\n')
                continue;

            // Determine the length of the hot word
            int length = (int)range.length;
            
            while (range.location + length < tmpText.length) {
                BOOL charIsMember = [validCharactersSet characterIsMember:[tmpText characterAtIndex:range.location + length]];
                
                if (charIsMember)
                    length++;
                else
                    break;
            }
            
            // Register the hot word and its range
            if (length > 1) {
                // only register if this range is not already in the array.
                NSRange wordRange = NSMakeRange(range.location, length);
                BOOL intersections = NO;
                for (NSDictionary * hotWordDetails in _rangesOfHotWords) {
                    NSRange hotWordRange = [((NSValue *)[hotWordDetails objectForKey:@"range"]) rangeValue];
                    if (NSIntersectionRange(wordRange, hotWordRange).length > 0) {
                        intersections = YES;
                    }
                }
                if (!intersections) {
                    [_rangesOfHotWords addObject:@{@"hotWord": @(hotWord), @"range": [NSValue valueWithRange:wordRange]}];
                }
            }
        }
        
        [self determineLinks];
        _detectHashTags = NO;
    }
    
    
    self.foundHashTags = NO;
    
    if (_detectHashTags) {
        NSMutableString *tmpText = [[NSMutableString alloc] initWithString:_cleanText];
        
        // Support RTL
        if (!_leftToRight) {
            tmpText = [[NSMutableString alloc] init];
            [tmpText appendString:@"\u200F"];
            [tmpText appendString:_cleanText];
        }
        
        // Define a character set for hot characters (@ handle, # hashtag)
        NSString *hotCharacters = @"#";
        NSCharacterSet *hotCharactersSet = [NSCharacterSet characterSetWithCharactersInString:hotCharacters];
        
        // Define a character set for the complete world (determine the end of the hot word)
        NSMutableCharacterSet *validCharactersSet = [NSMutableCharacterSet alphanumericCharacterSet];
        //[validCharactersSet removeCharactersInString:@"!@#$%^&*()-={[]}|;:',<>.?/"];
        [validCharactersSet addCharactersInString:@"_?"];
        
        
        while ([tmpText rangeOfCharacterFromSet:hotCharactersSet].location < tmpText.length) {
            NSRange range = [tmpText rangeOfCharacterFromSet:hotCharactersSet];
            
            STTweetHotWord hotWord;
            
            switch ([tmpText characterAtIndex:range.location]) {
                  case '#':
                    hotWord = STTweetHashtag;
                    break;
                default:
                    break;
            }
            
            [tmpText replaceCharactersInRange:range withString:@"%"];
            // If the hot character is not preceded by a alphanumeric characater, ie email (sebastien@world.com)
            if (range.location > 0 && [tmpText characterAtIndex:range.location - 1] != ' ' && [tmpText characterAtIndex:range.location - 1] != '\n')
                continue;
            
            // Determine the length of the hot word
            int length = (int)range.length;
            
            while (range.location + length < tmpText.length) {
                BOOL charIsMember = [validCharactersSet characterIsMember:[tmpText characterAtIndex:range.location + length]];
                
                if (charIsMember)
                    length++;
                else
                    break;
            }
            
            // Register the hot word and its range
            if (length > 1) {
                // only register if this range is not already in the array.
                NSRange wordRange = NSMakeRange(range.location, length);
                BOOL intersections = NO;
                for (NSDictionary * hotWordDetails in _rangesOfHotWords) {
                    NSRange hotWordRange = [((NSValue *)[hotWordDetails objectForKey:@"range"]) rangeValue];
                    if (NSIntersectionRange(wordRange, hotWordRange).length > 0) {
                        intersections = YES;
                    }
                }
                if (!intersections) {
                    //NSLog(@"found hash tag!");
                    self.foundHashTags  = YES;
                    [_rangesOfHotWords addObject:@{@"hotWord": @(hotWord), @"range": [NSValue valueWithRange:wordRange]}];
                }
            }
        }
        
    }
    
    // Inline this call if possible
    if (_cleanAttributedText && !self.foundHashTags) {
        [_textStorage setAttributedString:_cleanAttributedText];
    } else {
        [self updateText];
    }
}

- (void)determineLinks {
    NSMutableString *tmpText = [[NSMutableString alloc] initWithString:_cleanText];

    NSError *regexError = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:STURLRegex options:0 error:&regexError];

    [regex enumerateMatchesInString:tmpText options:0 range:NSMakeRange(0, tmpText.length) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        NSString *protocol = @"http";
        NSString *link = [tmpText substringWithRange:result.range];
        NSRange protocolRange = [link rangeOfString:@"://"];
        if (protocolRange.location != NSNotFound) {
            protocol = [link substringToIndex:protocolRange.location];
        }

        if ([_validProtocols containsObject:protocol.lowercaseString]) {
            // only register if this range is not already in the array.
            NSRange wordRange = result.range;
            BOOL intersections = NO;
            for (NSDictionary * hotWordDetails in _rangesOfHotWords) {
                NSRange hotWordRange = [((NSValue *)[hotWordDetails objectForKey:@"range"]) rangeValue];
                if (NSIntersectionRange(wordRange, hotWordRange).length > 0) {
                    intersections = YES;
                }
            }
            if (!intersections) {
                [_rangesOfHotWords addObject:@{@"hotWord": @(STTweetLink), @"protocol": protocol, @"range": [NSValue valueWithRange:wordRange]}];
            }
        }
    }];
}

- (void)updateText
{
    NSAttributedString *attributedString;
    if (_cleanAttributedText && !self.foundHashTags) {
        attributedString = _cleanAttributedText;
    } else {
        NSMutableAttributedString * mutableString = [[NSMutableAttributedString alloc] initWithString:_cleanText];
        [mutableString setAttributes:_attributesText range:NSMakeRange(0, _cleanText.length)];
        
        for (NSDictionary *dictionary in _rangesOfHotWords)  {
            NSRange range = [[dictionary objectForKey:@"range"] rangeValue];
            STTweetHotWord hotWord = (STTweetHotWord)[[dictionary objectForKey:@"hotWord"] intValue];
            NSDictionary * attributes = [self attributesForHotWord:hotWord];
            if (attributes) {
                [mutableString setAttributes:attributes range:range];
            }
        }
        attributedString = [[NSAttributedString alloc] initWithAttributedString:mutableString];
    }
    
    [_textStorage setAttributedString:attributedString];
}

#pragma mark -
#pragma mark Public methods

- (CGSize)suggestedFrameSizeToFitEntireStringConstraintedToWidth:(CGFloat)width {
    if (_cleanText == nil)
        return CGSizeZero;

    return [_textView sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)];
}

#pragma mark -
#pragma mark Private methods

- (NSArray *)hotWordsList {
    return _rangesOfHotWords;
}

#pragma mark -
#pragma mark Setters

- (void)setText:(NSString *)text {
    _cleanText = text;
    _cleanAttributedText = nil;
    [self determineHotWords];
}

- (void)setValidProtocols:(NSArray *)validProtocols {
    _validProtocols = validProtocols;
    [self determineHotWords];
}

- (void)setAttributes:(NSDictionary *)attributes {
    if (!attributes[NSFontAttributeName]) {
        NSMutableDictionary *copy = [attributes mutableCopy];
        copy[NSFontAttributeName] = self.font;
        attributes = [NSDictionary dictionaryWithDictionary:copy];
    }
    
    if (!attributes[NSForegroundColorAttributeName]) {
        NSMutableDictionary *copy = [attributes mutableCopy];
        copy[NSForegroundColorAttributeName] = self.textColor;
        attributes = [NSDictionary dictionaryWithDictionary:copy];
    }

    _attributesText = attributes;
    
    [self determineHotWords];
}

- (void)setAttributes:(NSDictionary *)attributes hotWord:(STTweetHotWord)hotWord {
    if (!attributes[NSFontAttributeName]) {
        NSMutableDictionary *copy = [attributes mutableCopy];
        copy[NSFontAttributeName] = self.font;
        attributes = [NSDictionary dictionaryWithDictionary:copy];
    }
    
    if (!attributes[NSForegroundColorAttributeName]) {
        NSMutableDictionary *copy = [attributes mutableCopy];
        copy[NSForegroundColorAttributeName] = self.textColor;
        attributes = [NSDictionary dictionaryWithDictionary:copy];
    }
    
    switch (hotWord)  {
        case STTweetHandle:
            _attributesHandle = attributes;
            break;
        case STTweetHashtag:
            _attributesHashtag = attributes;
            break;
        case STTweetLink:
            _attributesLink = attributes;
            break;
        case STTweetAnnotation:
            _attributesAnnotation = attributes;
            break;
        default:
            break;
    }
    
    [self determineHotWords];
}

- (void)setLeftToRight:(BOOL)leftToRight {
    _leftToRight = leftToRight;

    [self determineHotWords];
}

- (void)setTextAlignment:(NSTextAlignment)textAlignment {
    [super setTextAlignment:textAlignment];
    _textView.textAlignment = textAlignment;
}

- (void)setDetectionBlock:(void (^)(STTweetHotWord, NSString *, NSString *, NSRange))detectionBlock {
    if (detectionBlock) {
        _detectionBlock = [detectionBlock copy];
        self.userInteractionEnabled = YES;
    } else {
        _detectionBlock = nil;
        self.userInteractionEnabled = NO;
    }
}

- (void)setAttributedText:(NSAttributedString *)attributedText {
    _cleanText = attributedText.string;
    _cleanAttributedText = attributedText;
    if (_cleanText.length > 0) {
        [self setAttributes:[attributedText attributesAtIndex:0 effectiveRange:NULL]];
    } else {
        [self setAttributes:@{}];
    }
}

#pragma mark -
#pragma mark Getters

- (NSString *)text {
    return _cleanText;
}

- (NSDictionary *)attributes {
    return _attributesText;
}

- (NSDictionary *)attributesForHotWord:(STTweetHotWord)hotWord {
    switch (hotWord) {
        case STTweetHandle:
            return _attributesHandle;
            break;
        case STTweetHashtag:
            return _attributesHashtag;
            break;
        case STTweetLink:
            return _attributesLink;
            break;
        case STTweetAnnotation:
            return _attributesAnnotation;
            break;
        default:
            break;
    }
}

- (BOOL)isLeftToRight {
    return _leftToRight;
}

#pragma mark -
#pragma mark Retrieve word after touch event

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    
    _isTouchesMoved = NO;
    
    @try {
        [_textStorage removeAttribute:NSBackgroundColorAttributeName range:_selectableRange];
    } @catch (NSException *exception) {
    }
    
    _selectableRange = NSMakeRange(0, 0);
    _firstTouchLocation = [[touches anyObject] locationInView:_textView];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesMoved:touches withEvent:event];
    
    if (!_textSelectable) {
        UIMenuController *menuController = [UIMenuController sharedMenuController];
        [menuController setMenuVisible:NO animated:YES];
        
        return;
    }
    
    _isTouchesMoved = YES;
    
    int charIndex = (int)[self charIndexAtLocation:[[touches anyObject] locationInView:_textView]];
    
    @try {
        [_textStorage removeAttribute:NSBackgroundColorAttributeName range:_selectableRange];
    } @catch (NSException *exception) {
    }
    
    if (_selectableRange.length == 0) {
        _selectableRange = NSMakeRange(charIndex, 1);
        _firstCharIndex = charIndex;
    } else if (charIndex > _firstCharIndex) {
        _selectableRange = NSMakeRange(_firstCharIndex, charIndex - _firstCharIndex + 1);
    } else if (charIndex < _firstCharIndex) {
        _firstTouchLocation = [[touches anyObject] locationInView:_textView];
        
        _selectableRange = NSMakeRange(charIndex, _firstCharIndex - charIndex);
    }
    
    @try {
        [_textStorage addAttribute:NSBackgroundColorAttributeName value:_selectionColor range:_selectableRange];
    } @catch (NSException *exception) {
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
   
    CGPoint touchLocation = [[touches anyObject] locationInView:self];

    if (_isTouchesMoved) {
        UIMenuController *menuController = [UIMenuController sharedMenuController];
        [menuController setTargetRect:CGRectMake(_firstTouchLocation.x, _firstTouchLocation.y, 1.0, 1.0) inView:self];
        [menuController setMenuVisible:YES animated:YES];
        
        [self becomeFirstResponder];

        return;
    }
    
    if (!CGRectContainsPoint(_textView.frame, touchLocation))
        return;

    NSUInteger charIndex = [self charIndexAtLocation:[[touches anyObject] locationInView:_textView]];
    
    [_rangesOfHotWords enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSRange range = [[obj objectForKey:@"range"] rangeValue];
        
        if (charIndex >= range.location && charIndex < range.location + range.length) {
            NSString * text = [obj objectForKey:@"substitution"];
            if (!text) {
                text = [_cleanText substringWithRange:range];
            }
            _detectionBlock((STTweetHotWord)[[obj objectForKey:@"hotWord"] intValue], text, [obj objectForKey:@"protocol"], range);
            
            *stop = YES;
        }
    }];
}

- (NSUInteger)charIndexAtLocation:(CGPoint)touchLocation {
    NSUInteger glyphIndex = [_layoutManager glyphIndexForPoint:touchLocation inTextContainer:_textView.textContainer];
    CGRect boundingRect = [_layoutManager boundingRectForGlyphRange:NSMakeRange(glyphIndex, 1) inTextContainer:_textView.textContainer];
    
    if (CGRectContainsPoint(boundingRect, touchLocation))
        return [_layoutManager characterIndexForGlyphAtIndex:glyphIndex];
    else
        return -1;
}

@end
