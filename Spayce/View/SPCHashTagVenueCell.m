//
//  SPCHashTagVenueCell.m
//  Spayce
//
//  Created by Christopher Taylor on 12/23/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCHashTagVenueCell.h"
#import "Asset.h"
#import "Venue.h"
#import "Memory.h"

@implementation SPCHashTagVenueCell

- (void)setImageForVenue:(Venue *)venue memoryIndex:(NSInteger)memoryIndex animated:(BOOL)animated {
    Asset * asset = nil;
    Memory *mem;
    self.isHashMem = YES;
    
    if (venue.recentHashtagMemories.count == 0 || memoryIndex >= venue.recentHashtagMemories.count) {
        asset = venue.imageAsset;
    }

    if (memoryIndex < 0) {
        memoryIndex = 0;
    }

    if (memoryIndex < venue.recentHashtagMemories.count) {
        mem = (Memory *)venue.recentHashtagMemories[memoryIndex];
    }
    
    if ([venue.recentHashtagMemories[memoryIndex] isKindOfClass:[ImageMemory class]] && ((ImageMemory *)venue.recentHashtagMemories[memoryIndex]).images.count > 0) {
        asset = ((ImageMemory *)venue.recentHashtagMemories[memoryIndex]).images[0];
    }
    if ([venue.recentHashtagMemories[memoryIndex] isKindOfClass:[VideoMemory class]] && ((VideoMemory *)venue.recentHashtagMemories[memoryIndex]).previewImages.count > 0) {
        asset = ((VideoMemory *)venue.recentHashtagMemories[memoryIndex]).previewImages[0];
    }
    
    if (asset) {
        self.gradientOverlayView.backgroundColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.32f];
        if (self.textMemView.alpha > 0) {
            [UIView animateWithDuration:.5 animations:^{
                self.textMemView.alpha = 0.0f;
            }];
        }
        
        [self loadImageWithUrl:[NSURL URLWithString:asset.imageUrlHalfSquare] resultCallback:^(UIImage *image) {
            if (venue == self.venue) {
                [self setImage:image animated:animated displayedMemoryIndex:memoryIndex];
                [self updateTimeStampForMem:mem];
            }
        } faultCallback:^(NSError *fault) {
            [self setImage:nil animated:animated displayedMemoryIndex:memoryIndex];
        }];
    }
    
    //handle text mems
    
    if ([venue.recentHashtagMemories[memoryIndex] isKindOfClass:[Memory class]] && ((Memory *)venue.recentHashtagMemories[memoryIndex]).type == MemoryTypeText) {
         
        Memory *mem = (Memory *)venue.recentHashtagMemories[memoryIndex];
        self.gradientOverlayView.backgroundColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.05f];
        CGFloat anonBadgeFinalAlpha = mem.isAnonMem ? 1.0f : 0.0f;
        
        
        if (self.imageView.image) {
            [self.imageView.layer removeAllAnimations];
            self.imageView.alpha = 1.0f;
            UIImage * oldImage = self.imageView.image;
            
            [UIView animateWithDuration:0.5f animations:^{
                self.imageView.alpha = 0.0f;
                self.textMemView.alpha = 0.0f;
                self.anonBadgeView.alpha = 0.0f;
            } completion:^(BOOL finished) {
                if (finished && self.imageView.image == oldImage) {
                    [self updateTextStyling:mem.text];
                    [self updateTimeStampForMem:mem];
                    [UIView animateWithDuration:.5 animations:^{
                        self.textMemView.alpha = 1;
                        self.venueImageDisplayedMemoryIndex = memoryIndex;
                        self.anonBadgeView.alpha = anonBadgeFinalAlpha;
                    }];
                }
            }];
        } else {
            [self.imageView.layer removeAllAnimations];
            self.imageView.alpha = 0.0f;
            [UIView animateWithDuration:0.5f animations:^{
                self.textMemView.alpha = 0.0f;
                self.anonBadgeView.alpha = 0.0f;
            } completion:^(BOOL finished) {
                if (finished) {
                    [self updateTextStyling:mem.text];
                    [self updateTimeStampForMem:mem];
                    [UIView animateWithDuration:.5 animations:^{
                        self.textMemView.alpha = 1;
                        self.venueImageDisplayedMemoryIndex = memoryIndex;
                        self.anonBadgeView.alpha = anonBadgeFinalAlpha;
                    }];
                }
            }];
        }
    }
}

- (void)setImageForMemory:(Memory *)memory animated:(BOOL)animated {
    Asset * asset = nil;
    self.isHashMem = YES;
    
    if ([memory isKindOfClass:[ImageMemory class]] && ((ImageMemory *)memory).images.count > 0) {
        asset = ((ImageMemory *)memory).images[0];
    }
    if ([memory isKindOfClass:[VideoMemory class]] && ((VideoMemory *)memory).previewImages.count > 0) {
        asset = ((VideoMemory *)memory).previewImages[0];
    }
    
    if (asset) {
        self.gradientOverlayView.backgroundColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.32f];
        if (self.textMemView.alpha > 0) {
            [UIView animateWithDuration:.5 animations:^{
                self.textMemView.alpha = 0.0f;
            }];
        }
        
        [self loadImageWithUrl:[NSURL URLWithString:asset.imageUrlHalfSquare] resultCallback:^(UIImage *image) {
            if (memory == self.memory) {
                [self setImage:image animated:animated displayedMemoryIndex:-1];
                [self updateTimeStampForMem:memory];
            }
        } faultCallback:^(NSError *fault) {
            [self setImage:nil animated:animated displayedMemoryIndex:-1];
        }];
    }
    
    //handle text mems
    
    if ([memory isKindOfClass:[Memory class]] && ((Memory *)memory).type == MemoryTypeText) {
        self.gradientOverlayView.backgroundColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.05f];
        CGFloat anonBadgeFinalAlpha = memory.isAnonMem ? 1.0f : 0.0f;
        
        
        if (self.imageView.image) {
            [self.imageView.layer removeAllAnimations];
            self.imageView.alpha = 1.0f;
            UIImage * oldImage = self.imageView.image;
            
            [UIView animateWithDuration:0.5f animations:^{
                self.imageView.alpha = 0.0f;
                self.textMemView.alpha = 0.0f;
                self.anonBadgeView.alpha = 0.0f;
            } completion:^(BOOL finished) {
                if (finished && self.imageView.image == oldImage) {
                    [self updateTextStyling:memory.text];
                    [self updateTimeStampForMem:memory];
                    [UIView animateWithDuration:.5 animations:^{
                        self.textMemView.alpha = 1;
                        self.venueImageDisplayedMemoryIndex = -1;
                        self.anonBadgeView.alpha = anonBadgeFinalAlpha;
                    }];
                }
            }];
        } else {
            [self.imageView.layer removeAllAnimations];
            self.imageView.alpha = 0.0f;
            [UIView animateWithDuration:0.5f animations:^{
                self.textMemView.alpha = 0.0f;
                self.anonBadgeView.alpha = 0.0f;
            } completion:^(BOOL finished) {
                if (finished) {
                    [self updateTextStyling:memory.text];
                    [self updateTimeStampForMem:memory];
                    [UIView animateWithDuration:.5 animations:^{
                        self.textMemView.alpha = 1;
                        self.venueImageDisplayedMemoryIndex = -1;
                        self.anonBadgeView.alpha = anonBadgeFinalAlpha;
                    }];
                }
            }];
        }
    }
}

#pragma mark - Accessors

- (Memory *)memoryDisplayed {
    if (self.memory) {
        return self.memory;
    }
    NSInteger index = self.venueImageDisplayedMemoryIndex >= 0 ? self.venueImageDisplayedMemoryIndex : self.venueImageMemoryIndex;
    if (self.venue && index >= 0 && index < self.venue.recentHashtagMemories.count) {
        return self.venue.recentHashtagMemories[index];
    }
    return nil;
}


-(BOOL)canAnimateCell{
    if (self.venue && self.venueImageMemoryIndex >= 0 && self.venue.recentHashtagMemories.count > 1) {
        return YES;
    }
    return NO;
}

-(BOOL)cycleImageAnimated:(BOOL)animated {
    if (self.venue && self.venueImageMemoryIndex >= 0 && self.venue.recentHashtagMemories.count > 1) {
        self.venueImageMemoryIndex = (self.venueImageMemoryIndex + 1) % self.venue.recentHashtagMemories.count;
        [self setImageForVenue:self.venue memoryIndex:self.venueImageMemoryIndex animated:animated];
        return YES;
    }
    return NO;
}

-(void)updateTimeStampForMem:(Memory *)mem {
    NSDictionary *timeDistanceAttributes = @{ NSForegroundColorAttributeName : [UIColor whiteColor],
                                              NSFontAttributeName : [UIFont spc_boldSystemFontOfSize:8.0f] };
    
    NSString *timeDistanceText = mem.timeElapsed;
    if (timeDistanceText) {
        self.timeDistanceDetailLabel.attributedText = [[NSAttributedString alloc] initWithString:timeDistanceText attributes:timeDistanceAttributes];
    }
    [self layoutDetailRow];
}

-(void)updateTextStyling:(NSString *)newText; {
    
    self.textMemLbl.font = [UIFont spc_regularSystemFontOfSize:16];
    self.textMemLbl.textAlignment = NSTextAlignmentLeft;
    self.textMemLbl.text = newText;
    
    if (newText.length < 30) {
        self.textMemLbl.textAlignment = NSTextAlignmentCenter;
        self.textMemLbl.font = [UIFont fontWithName:@"AvenirNext-DemiBold" size:16];
    }
    
    if (newText.length < 12) {
        self.textMemLbl.font = [UIFont fontWithName:@"AvenirNext-Bold" size:16];
    }
}

@end
