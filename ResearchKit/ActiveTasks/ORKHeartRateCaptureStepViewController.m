/*
 Copyright (c) 2017, Sage Bionetworks. All rights reserved.
 
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


#import "ORKHeartRateCaptureStepViewController_Internal.h"

#import "ORKHeartRateCaptureStep.h"
#import "ORKWorkoutStep.h"

#import "ORKActiveStepView.h"
#import "ORKCustomStepView_Internal.h"
#import "ORKStepHeaderView_Internal.h"

#import "ORKActiveStepViewController_Internal.h"
#import "ORKNavigationContainerView_Internal.h"
#import "ORKStepViewController_Internal.h"

#import "ORKActiveStep.h"
#import "ORKActiveStepTimer.h"
#import "ORKHealthQuantityTypeRecorder.h"

#import "ORKResult.h"

#import "ORKCodingObjects.h"
#import "ORKHelpers_Internal.h"
#import "ORKSkin.h"

@import WatchConnectivity;

@implementation ORKHeartRateCaptureStepViewController {
    NSTimeInterval _runtime;
    NSMutableArray<HKQuantitySample *> *_heartRateSamples;
    CGFloat _heartRate;
    BOOL _hasWatchSample;
    ORKHeartRateCameraRecorder *_cameraRecorder;
}

- (ORKHeartRateCaptureStep *)captureStep {
    if ([self.step isKindOfClass:[ORKHeartRateCaptureStep class]]) {
        return (ORKHeartRateCaptureStep *)self.step;
    }
    return nil;
}

- (void)recordersDidChange {
    [super recordersDidChange];
    
    for (ORKRecorder *recorder in self.recorders) {
        if ([recorder isKindOfClass:[ORKHeartRateCameraRecorder class]]) {
            _cameraRecorder = (ORKHeartRateCameraRecorder *)recorder;
        }
    }
}

- (BOOL)usesCamera {
    return YES;
}

- (NSTimeInterval)stepDuration {
    NSTimeInterval const timeout = self.usesWatch ? 60.0 : 30.0;
    return MAX(timeout, [self captureStep].stepDuration);
}

- (NSTimeInterval)minimumDuration {
    NSTimeInterval const min = 20.0;
    return MAX(min, [self captureStep].minimumDuration);
}

- (void)countDownTimerFired:(ORKActiveStepTimer *)timer finished:(BOOL)finished {
    _runtime = timer.runtime;
    if (![self continueIfReady]) {
        // Only call super if not stopping
        [super countDownTimerFired:timer finished:finished];
    }
}

- (BOOL)continueIfReady {
    CGFloat heartRate = 0.0;
    if ((_runtime >= [self minimumDuration]) &&
        ((heartRate = [self calculateHeartRate]) > 0.1) &&
        (!self.usesWatch || _hasWatchSample)) {
        
        // Set heartrate and finish
        _heartRate = heartRate;
        
        [self finish];
        return YES;
    }
    return NO;
}

- (CGFloat)calculateHeartRate {
    
    NSInteger count = self.usesCamera ? 5 : 2;
    
    if (_heartRateSamples.count < count ) {
        return 0.0;
    }
    
    NSArray<HKQuantitySample *> *samples = [_heartRateSamples copy];
    HKUnit *unit = [HKUnit bpmUnit];
    CGFloat total = 0;
    NSMutableArray<NSNumber *> *values = [NSMutableArray new];
    for (NSInteger ii = _heartRateSamples.count - count; ii < _heartRateSamples.count; ii++) {
        CGFloat value = [[samples[ii] quantity] doubleValueForUnit:unit];
        [values addObject:@(value)];
        total += value;
    }
    
    CGFloat mean = total / count;
    total = 0;
    for (NSNumber *num in values) {
        CGFloat diff = [num doubleValue] - mean;
        total += diff * diff;
    }
    CGFloat std = sqrt(total / count);
    
    CGFloat const ORKAllowedStandardDeviation = 5.0;
    if (std < ORKAllowedStandardDeviation) {
        return mean;
    } else {
        return 0.0;
    }
}

- (ORKStepResult *)result {
    ORKStepResult *result = [super result];
    
    NSMutableArray *results = [result.results mutableCopy];
    
    if (_heartRate > 0) {
        ORKNumericQuestionResult *heartRateResult = [[ORKNumericQuestionResult alloc] initWithIdentifier:ORKWorkoutResultIdentifierHeartRate];
        heartRateResult.numericAnswer = @(_heartRate);
        [results addObject:heartRateResult];
    }
    
    result.results = results;
    
    return result;
}

- (void)updateHeartRateWithQuantity:(HKQuantitySample *)quantity unit:(HKUnit *)unit {
    [super updateHeartRateWithQuantity:quantity unit:unit];
    if (!quantity) {
        return;
    }
    
    // Check if we can continue
    if (!_heartRateSamples) {
        _heartRateSamples = [NSMutableArray new];
    }
    [_heartRateSamples addObject:quantity];
    
    [self continueIfReady];
}

- (void)addHeathRecorderQuantitySamples:(NSArray<HKQuantitySample *> *)samples quantityTypeIdentifier:(NSString *)quantityTypeIdentifier {
    if ([quantityTypeIdentifier isEqualToString:HKQuantityTypeIdentifierHeartRate]) {
        
        // Add the samples to the camera logger
        [_cameraRecorder addWatchSamples:samples];
        
        // Continue if we have enough data
        HKQuantitySample *sample = [samples lastObject];
        _hasWatchSample = (sample.device != nil);
        [self continueIfReady];
    }
}

#pragma mark - ORKHeartRateCameraRecorderDelegate

- (void)heartRateDidUpdate:(ORKHeartRateCameraRecorder *)recorder sample:(HKQuantitySample *)sample {
    [self updateHeartRateWithQuantity:sample unit:[HKUnit bpmUnit]];
}

@end
