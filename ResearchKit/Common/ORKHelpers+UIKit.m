/*
 Copyright (c) 2015, Apple Inc. All rights reserved.
 Copyright (c) 2015-2016, Ricardo Sanchez-Saez.
 Copyright (c) 2017, Sage Bionetworks.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 1.  Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2.  Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.
 
 3.  Neither the name of the copyright holder(s) nor the names of any contributors
 may be used to endorse or promote products derived from this software without
 specific prior written permission. No license is granted to the trademarks of
 the copyright holders even if such marks are included in this software.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


#import "ORKHelpers+UIKit.h"
#import "ORKHelpers_Internal.h"
#import "ORKSkin.h"
#import "ORKTypes.h"

@import CoreText;

CGFloat ORKExpectedLabelHeight(UILabel *label) {
    CGSize expectedLabelSize = [label.text boundingRectWithSize:CGSizeMake(label.frame.size.width, CGFLOAT_MAX)
                                                        options:NSStringDrawingUsesLineFragmentOrigin
                                                     attributes:@{ NSFontAttributeName : label.font }
                                                        context:nil].size;
    return expectedLabelSize.height;
}

void ORKAdjustHeightForLabel(UILabel *label) {
    CGRect rect = label.frame;
    rect.size.height = ORKExpectedLabelHeight(label);
    label.frame = rect;
}

void ORKEnableAutoLayoutForViews(NSArray *views) {
    [views enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [(UIView *)obj setTranslatesAutoresizingMaskIntoConstraints:NO];
    }];
}

UIFontDescriptor *ORKFontDescriptorForLightStylisticAlternative(UIFontDescriptor *descriptor) {
    UIFontDescriptor *fontDescriptor = [descriptor
                                        fontDescriptorByAddingAttributes:
                                        @{ UIFontDescriptorFeatureSettingsAttribute: @[
                                                   @{ UIFontFeatureTypeIdentifierKey: @(kCharacterAlternativesType),
                                                      UIFontFeatureSelectorIdentifierKey: @(1) }]}];
    return fontDescriptor;
}

UIFont *ORKTimeFontForSize(CGFloat size) {
    UIFontDescriptor *fontDescriptor = [ORKLightFontWithSize(size) fontDescriptor];
    fontDescriptor = ORKFontDescriptorForLightStylisticAlternative(fontDescriptor);
    UIFont *font = [UIFont fontWithDescriptor:fontDescriptor size:0];
    return font;
}

BOOL ORKWantsWideContentMargins(UIScreen *screen) {
    
    if (screen != [UIScreen mainScreen]) {
        return NO;
    }
    
    // If our screen's minimum dimension is bigger than a fixed threshold,
    // decide to use wide content margins. This is less restrictive than UIKit,
    // but a good enough approximation.
    CGRect screenRect = screen.bounds;
    CGFloat minDimension = MIN(screenRect.size.width, screenRect.size.height);
    BOOL isWideScreenFormat = (minDimension > 375.);
    
    return isWideScreenFormat;
}

#define ORK_LAYOUT_MARGIN_WIDTH_THIN_BEZEL_REGULAR 20.0
#define ORK_LAYOUT_MARGIN_WIDTH_THIN_BEZEL_COMPACT 16.0
#define ORK_LAYOUT_MARGIN_WIDTH_REGULAR_BEZEL 15.0

CGFloat ORKTableViewLeftMargin(UITableView *tableView) {
    if (ORKWantsWideContentMargins(tableView.window.screen)) {
        if (CGRectGetWidth(tableView.frame) > 320.0) {
            return ORK_LAYOUT_MARGIN_WIDTH_THIN_BEZEL_REGULAR;
            
        } else {
            return ORK_LAYOUT_MARGIN_WIDTH_THIN_BEZEL_COMPACT;
        }
    } else {
        // Probably should be ORK_LAYOUT_MARGIN_WIDTH_REGULAR_BEZEL
        return ORK_LAYOUT_MARGIN_WIDTH_THIN_BEZEL_COMPACT;
    }
}

UIFont *ORKThinFontWithSize(CGFloat size) {
    UIFont *font = nil;
    if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){.majorVersion = 8, .minorVersion = 2, .patchVersion = 0}]) {
        font = [UIFont systemFontOfSize:size weight:UIFontWeightThin];
    } else {
        font = [UIFont fontWithName:@".HelveticaNeueInterface-Thin" size:size];
        if (!font) {
            font = [UIFont systemFontOfSize:size];
        }
    }
    return font;
}

UIFont *ORKMediumFontWithSize(CGFloat size) {
    UIFont *font = nil;
    if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){.majorVersion = 8, .minorVersion = 2, .patchVersion = 0}]) {
        font = [UIFont systemFontOfSize:size weight:UIFontWeightMedium];
    } else {
        font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:size];
        if (!font) {
            font = [UIFont systemFontOfSize:size];
        }
    }
    return font;
}

UIFont *ORKLightFontWithSize(CGFloat size) {
    UIFont *font = nil;
    if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){.majorVersion = 8, .minorVersion = 2, .patchVersion = 0}]) {
        font = [UIFont systemFontOfSize:size weight:UIFontWeightLight];
    } else {
        font = [UIFont fontWithName:@".HelveticaNeueInterface-Light" size:size];
        if (!font) {
            font = [UIFont systemFontOfSize:size];
        }
    }
    return font;
}

void ORKRemoveConstraintsForRemovedViews(NSMutableArray *constraints, NSArray *removedViews) {
    for (NSLayoutConstraint *constraint in [constraints copy]) {
        for (UIView *view in removedViews) {
            if (constraint.firstItem == view || constraint.secondItem == view) {
                [constraints removeObject:constraint];
            }
        }
    }
}

const double ORKDoubleInvalidValue = DBL_MAX;

const CGFloat ORKCGFloatInvalidValue = CGFLOAT_MAX;

void ORKAdjustPageViewControllerNavigationDirectionForRTL(UIPageViewControllerNavigationDirection *direction) {
    if ([UIApplication sharedApplication].userInterfaceLayoutDirection == UIUserInterfaceLayoutDirectionRightToLeft) {
        *direction = (*direction == UIPageViewControllerNavigationDirectionForward) ? UIPageViewControllerNavigationDirectionReverse : UIPageViewControllerNavigationDirectionForward;
    }
}

ORK_INLINE CGFloat ORKCGFloor(CGFloat value) {
    if (sizeof(value) == sizeof(float)) {
        return (CGFloat)floorf((float)value);
    } else {
        return (CGFloat)floor((double)value);
    }
}

ORK_INLINE CGFloat ORKAdjustToScale(CGFloat (adjustFunction)(CGFloat), CGFloat value, CGFloat scale) {
    if (scale == 0) {
        static CGFloat screenScale = 1.0;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            screenScale = [UIScreen mainScreen].scale;
        });
        scale = screenScale;
    }
    if (scale == 1.0) {
        return adjustFunction(value);
    } else {
        return adjustFunction(value * scale) / scale;
    }
}

CGFloat ORKFloorToViewScale(CGFloat value, UIView *view) {
    return ORKAdjustToScale(ORKCGFloor, value, view.contentScaleFactor);
}
