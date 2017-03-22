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


#import "ORKFitnessStepViewController_Internal.h"

#import "ORKActiveStepTimer.h"
#import "ORKActiveStepView.h"
#import "ORKFitnessContentView.h"
#import "ORKVerticalContainerView.h"

#import "ORKStepViewController_Internal.h"

#import "ORKActiveStepViewController_Internal.h"
#import "ORKCollectionResult.h"
#import "ORKFitnessStep.h"
#import "ORKLocationRecorder.h"
#import "ORKQuestionResult.h"
#import "ORKResult.h"
#import "ORKStep_Private.h"
#import "ORKWorkoutStep_Private.h"


#import "ORKHelpers_Internal.h"

@implementation ORKFitnessStepViewController {
    NSInteger _intendedSteps;
    ORKFitnessContentView *_contentView;
    NSNumberFormatter *_hrFormatter;
    BOOL _userEndedWorkout;
}

- (instancetype)initWithStep:(ORKStep *)step {    
    self = [super initWithStep:step];
    if (self) {
        self.suspendIfInactive = NO;
    }
    return self;
}

- (ORKFitnessStep *)fitnessStep {
    return (ORKFitnessStep *)self.step;
}

- (ORKStepResult *)result {
    ORKStepResult *sResult = [super result];
    
    NSMutableArray *results = [sResult.results mutableCopy] ? : [NSMutableArray new];

    if (_userEndedWorkout) {
        ORKBooleanQuestionResult *boolResult = [[ORKBooleanQuestionResult alloc] initWithIdentifier:ORKWorkoutResultIdentifierUserEnded];
        boolResult.booleanAnswer = @YES;
        [results addObject:boolResult];
    }
    
    CLLocation *location = self.locationRecorder.mostRecentLocation;
    if (location) {
        ORKNumericQuestionResult *speedResult = [[ORKNumericQuestionResult alloc] initWithIdentifier:ORKWorkoutResultIdentifierSpeed];
        speedResult.numericAnswer = [NSDecimalNumber numberWithDouble:location.speed];
        [results addObject:speedResult];
        
        ORKBooleanQuestionResult *outdoorsResult = [[ORKBooleanQuestionResult alloc] initWithIdentifier:ORKWorkoutResultIdentifierIsOutdoors];
        outdoorsResult.booleanAnswer = @([self.locationRecorder isOutdoors]);
        [results addObject:outdoorsResult];
        
        ORKNumericQuestionResult *distanceResult = [[ORKNumericQuestionResult alloc] initWithIdentifier:ORKWorkoutResultIdentifierDistanceTraveled];
        distanceResult.numericAnswer = [NSDecimalNumber numberWithDouble:[self.locationRecorder distanceTraveled]];
        [results addObject:distanceResult];
    }
    
    sResult.results = results;
    return sResult;
}

- (void)stepDidChange {
    [super stepDidChange];
    _hrFormatter = [[NSNumberFormatter alloc] init];
    _hrFormatter.numberStyle = kCFNumberFormatterNoStyle;
    _contentView.timeLeft = self.fitnessStep.stepDuration;
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _contentView = [ORKFitnessContentView new];
    _contentView.image = self.fitnessStep.image;
    _contentView.timeLeft = self.fitnessStep.stepDuration;
    self.activeStepView.activeCustomView = _contentView;
    self.activeStepView.stepViewFillsAvailableSpace = YES;
}

- (void)updateHeartRateWithQuantity:(HKQuantitySample *)quantity unit:(HKUnit *)unit {
    if (quantity != nil) {
        _contentView.hasHeartRate = YES;
    }
    double bpm = [quantity.quantity doubleValueForUnit:unit];
    if (bpm > 0) {
        _contentView.heartRate = [_hrFormatter stringFromNumber:@(bpm)];
    } else {
        _contentView.heartRate = @"--";
    }
}

- (void)updateDistance:(double)distanceInMeters {
    _contentView.hasDistance = YES;
    _contentView.distanceInMeters = distanceInMeters;
}

- (void)recordersDidChange {
    [super recordersDidChange];
    
    ORKPedometerRecorder *pedometerRecorder = nil;
    ORKHealthQuantityTypeRecorder *heartRateRecorder = nil;
    for (ORKRecorder *recorder in self.recorders) {
        if ([recorder isKindOfClass:[ORKPedometerRecorder class]]) {
            pedometerRecorder = (ORKPedometerRecorder *)recorder;
        } else if ([recorder isKindOfClass:[ORKHealthQuantityTypeRecorder class]]) {
            ORKHealthQuantityTypeRecorder *rec1 = (ORKHealthQuantityTypeRecorder *)recorder;
            if ([[[rec1 quantityType] identifier] isEqualToString:HKQuantityTypeIdentifierHeartRate]) {
                heartRateRecorder = (ORKHealthQuantityTypeRecorder *)recorder;
            }
        } else if ([recorder isKindOfClass:[ORKLocationRecorder class]]) {
            _locationRecorder = (ORKLocationRecorder *)recorder;
        }
    }
    
    if ((heartRateRecorder == nil) && !self.usesCamera) {
        _contentView.hasHeartRate = NO;
    }
    _contentView.heartRate = @"--";
    _contentView.hasDistance = (pedometerRecorder != nil);
    _contentView.distanceInMeters = 0;
    
}

- (void)countDownTimerFired:(ORKActiveStepTimer *)timer finished:(BOOL)finished {
    _contentView.timeLeft = finished ? 0 : (timer.duration - timer.runtime);
    [super countDownTimerFired:timer finished:finished];
}

- (void)workoutStateChanged:(ORKWorkoutState)workoutState {
    [super workoutStateChanged:workoutState];
    if ([workoutState isEqualToString:ORKWorkoutStateEnded]) {
        // Workout has been ended from the watch
        _userEndedWorkout = YES;
        [self finish];
    }
}

#pragma mark - ORKHealthQuantityTypeRecorderDelegate

- (void)healthQuantityTypeRecorderDidUpdate:(ORKHealthQuantityTypeRecorder *)healthQuantityTypeRecorder {
    if (!self.usesCamera && [[healthQuantityTypeRecorder.quantityType identifier] isEqualToString:HKQuantityTypeIdentifierHeartRate]) {
        [self updateHeartRateWithQuantity:healthQuantityTypeRecorder.lastSample unit:healthQuantityTypeRecorder.unit];
    }
}

#pragma mark - ORKPedometerRecorderDelegate

- (void)pedometerRecorderDidUpdate:(ORKPedometerRecorder *)pedometerRecorder {
    double distanceInMeters = pedometerRecorder.totalDistance;
    [self updateDistance:distanceInMeters];
}

@end
