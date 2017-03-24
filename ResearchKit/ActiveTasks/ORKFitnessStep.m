/*
 Copyright (c) 2015, Apple Inc. All rights reserved.
 
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


#import "ORKFitnessStep.h"

#import "ORKFitnessStepViewController.h"

#import "ORKCodingObjects.h"
#import "ORKDefines.h"
#import "ORKHelpers_Internal.h"
#import "ORKOrderedTask_Private.h"
#import "ORKRecorder.h"
#import "ORKStep_Private.h"

@implementation ORKFitnessStep

+ (NSArray *)recorderConfigurationsWithOptions:(ORKPredefinedTaskOption)options
                          relativeDistanceOnly:(BOOL)relativeDistanceOnly
                                 standingStill:(BOOL)standingStill {
    NSMutableArray *recorderConfigurations = [NSMutableArray arrayWithCapacity:5];
    if (!(ORKPredefinedTaskOptionExcludePedometer & options)) {
        [recorderConfigurations addObject:[[ORKPedometerRecorderConfiguration alloc] initWithIdentifier:ORKPedometerRecorderIdentifier]];
    }
    if (!(ORKPredefinedTaskOptionExcludeAccelerometer & options)) {
        [recorderConfigurations addObject:[[ORKAccelerometerRecorderConfiguration alloc] initWithIdentifier:ORKAccelerometerRecorderIdentifier
                                                                                                  frequency:100]];
    }
    if (!(ORKPredefinedTaskOptionExcludeDeviceMotion & options)) {
        [recorderConfigurations addObject:[[ORKDeviceMotionRecorderConfiguration alloc] initWithIdentifier:ORKDeviceMotionRecorderIdentifier
                                                                                                 frequency:100]];
    }
    if (!(ORKPredefinedTaskOptionExcludeLocation & options)) {
        ORKLocationRecorderConfiguration *locationConfig = [[ORKLocationRecorderConfiguration alloc] initWithIdentifier:ORKLocationRecorderIdentifier];
        locationConfig.relativeDistanceOnly = relativeDistanceOnly;
        locationConfig.standingStill = standingStill;
        [recorderConfigurations addObject:locationConfig];
    }
    if (!(ORKPredefinedTaskOptionExcludeHeartRate & options)) {
        HKUnit *bpmUnit = [HKUnit bpmUnit];
        HKQuantityType *heartRateType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate];
        [recorderConfigurations addObject:[[ORKHealthQuantityTypeRecorderConfiguration alloc] initWithIdentifier:ORKHeartRateRecorderIdentifier
                                                                                              healthQuantityType:heartRateType unit:bpmUnit]];
    }
    return recorderConfigurations;
}

+ (Class)stepViewControllerClass {
    return [ORKFitnessStepViewController class];
}

- (instancetype)initWithIdentifier:(NSString *)identifier {
    self = [super initWithIdentifier:identifier];
    if (self) {
        self.shouldShowDefaultTimer = NO;
    }
    return self;
}

- (void)ork_superValidateParameters {
    [super validateParameters];
}

- (void)validateParameters {
    [self ork_superValidateParameters];
    
    NSTimeInterval const ORKFitnessStepMinimumDuration = 5.0;
    
    if (self.stepDuration < ORKFitnessStepMinimumDuration) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"rest duration cannot be shorter than %@ seconds.", @(ORKFitnessStepMinimumDuration)]  userInfo:nil];
    }
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORKFitnessStep *step = [super copyWithZone:zone];
    step.standingStill = self.standingStill;
    return step;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    ORK_DECODE_BOOL(aDecoder, standingStill);
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORK_ENCODE_BOOL(aCoder, standingStill);
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (NSUInteger)hash {
    return super.hash ^ self.standingStill;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return isParentSame &&
    (self.standingStill == castObject.standingStill);
}

- (BOOL)startsFinished {
    return NO;
}

@end
