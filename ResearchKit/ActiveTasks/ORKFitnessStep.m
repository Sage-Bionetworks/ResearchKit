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

+ (NSArray *)recorderConfigurationsWithOptions:(ORKPredefinedRecorderOption)options
                          relativeDistanceOnly:(BOOL)relativeDistanceOnly {
    NSMutableArray *recorderConfigurations = [NSMutableArray arrayWithCapacity:5];
    if (!(ORKPredefinedRecorderOptionExcludePedometer & options)) {
        [recorderConfigurations addObject:[[ORKPedometerRecorderConfiguration alloc] initWithIdentifier:ORKPedometerRecorderIdentifier]];
    }
    if (!(ORKPredefinedRecorderOptionExcludeAccelerometer & options)) {
        [recorderConfigurations addObject:[[ORKAccelerometerRecorderConfiguration alloc] initWithIdentifier:ORKAccelerometerRecorderIdentifier
                                                                                                  frequency:100]];
    }
    if (!(ORKPredefinedRecorderOptionExcludeDeviceMotion & options)) {
        [recorderConfigurations addObject:[[ORKDeviceMotionRecorderConfiguration alloc] initWithIdentifier:ORKDeviceMotionRecorderIdentifier
                                                                                                 frequency:100]];
    }
    if (!(ORKPredefinedRecorderOptionExcludeLocation & options)) {
        ORKLocationRecorderConfiguration *locationConfig = [[ORKLocationRecorderConfiguration alloc] initWithIdentifier:ORKLocationRecorderIdentifier];
        locationConfig.relativeDistanceOnly = relativeDistanceOnly;
        [recorderConfigurations addObject:locationConfig];
    }
    if (!(ORKPredefinedRecorderOptionExcludeHeartRate & options)) {
        HKUnit *bpmUnit = [HKUnit bpmUnit];
        HKQuantityType *heartRateType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate];
        [recorderConfigurations addObject:[[ORKHealthQuantityTypeRecorderConfiguration alloc] initWithIdentifier:ORKHeartRateRecorderIdentifier
                                                                                              healthQuantityType:heartRateType unit:bpmUnit]];
    }
    return recorderConfigurations;
}

+ (instancetype)fitnessStepWithIdentifier:(NSString *)identifier walkDuration:(NSTimeInterval)walkDuration options:(ORKPredefinedRecorderOption)options relativeDistanceOnly:(BOOL)relativeDistanceOnly {
    NSDateComponentsFormatter *formatter = [ORKOrderedTask textTimeFormatter];
    ORKFitnessStep *fitnessStep = [[ORKFitnessStep alloc] initWithIdentifier:ORKFitnessWalkStepIdentifier];
    fitnessStep.stepDuration = walkDuration;
    fitnessStep.title = [NSString stringWithFormat:ORKLocalizedString(@"FITNESS_WALK_INSTRUCTION_FORMAT", nil), [formatter stringFromTimeInterval:walkDuration]];
    fitnessStep.spokenInstruction = fitnessStep.title;
    fitnessStep.recorderConfigurations = [self recorderConfigurationsWithOptions:options relativeDistanceOnly:relativeDistanceOnly];
    fitnessStep.shouldContinueOnFinish = YES;
    fitnessStep.optional = NO;
    fitnessStep.shouldStartTimerAutomatically = YES;
    fitnessStep.shouldTintImages = YES;
    fitnessStep.image = [UIImage imageNamed:@"walkingman" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
    fitnessStep.shouldVibrateOnStart = YES;
    fitnessStep.shouldPlaySoundOnStart = YES;
    fitnessStep.watchInstruction = ORKLocalizedString(@"FITNESS_WALK_INSTRUCTION_WATCH", nil);
    fitnessStep.beginCommand = ORKWorkoutCommandStartMoving;
    return fitnessStep;
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
    return step;
}

- (BOOL)startsFinished {
    return NO;
}

@end
