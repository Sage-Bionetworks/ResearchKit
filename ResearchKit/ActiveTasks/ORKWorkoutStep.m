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


#import "ORKWorkoutStep_Private.h"

#import "ORKWorkoutStepViewController.h"

#import "ORKCountdownStep.h"
#import "ORKFitnessStep_Internal.h"
#import "ORKHeartRateCaptureStep.h"
#import "ORKLocationRecorder.h"
#import "ORKOrderedTask_Private.h"
#import "ORKPageStep_Private.h"
#import "ORKRecorder_Private.h"
#import "ORKResult_Private.h"
#import "ORKStep_Private.h"
#import "ORKHelpers_Internal.h"

#import <ResearchKit/ResearchKit-Swift.h>


NSString *const ORKWorkoutBeforeStepIdentifier = @"heartRate.before";
NSString *const ORKWorkoutAfterStepIdentifier = @"heartRate.after";
NSString *const ORKWorkoutCameraInstructionStepIdentifier = @"heartRate.cameraInstruction";
NSString *const ORKWorkoutBeforeCountdownStepIdentifier = @"heartRate.before.countdown";
NSString *const ORKWorkoutAfterCountdownStepIdentifier = @"heartRate.after.countdown";
NSString *const ORKWorkoutOutdoorInstructionStepIdentifier = @"outdoor.instruction";

NSString *const ORKHeartRateMonitorDeviceNameKey = @"heartRateDeviceNameKey";

ORKWorkoutResultIdentifier const ORKWorkoutResultIdentifierHeartRateCaptureSuccess = @"heartRateSuccess";
ORKWorkoutResultIdentifier const ORKWorkoutResultIdentifierHeartRate = @"heartRateMeasurement";
ORKWorkoutResultIdentifier const ORKWorkoutResultIdentifierWorkoutData = @"workoutData";
ORKWorkoutResultIdentifier const ORKWorkoutResultIdentifierCameraSamples = @"cameraHeartRate";
ORKWorkoutResultIdentifier const ORKWorkoutResultIdentifierUserEnded = @"userEndedWorkout";
ORKWorkoutResultIdentifier const ORKWorkoutResultIdentifierSpeed = @"speed";
ORKWorkoutResultIdentifier const ORKWorkoutResultIdentifierIsOutdoors = @"outdoors";
ORKWorkoutResultIdentifier const ORKWorkoutResultIdentifierDistanceTraveled = @"distance";

@implementation ORKWorkoutStep

- (instancetype)initWithIdentifier:(NSString *)identifier steps:(NSArray<ORKStep *> *)steps {
    ORKThrowMethodUnavailableException();
}

- (instancetype)initWithIdentifier:(NSString *)identifier pageTask:(ORKOrderedTask *)task {
    return [super initWithIdentifier:identifier pageTask:task];
}

- (instancetype)initWithIdentifier:(NSString*)identifier {
    return [super initWithIdentifier:identifier pageTask:[[ORKOrderedTask alloc] initWithIdentifier:identifier steps:nil]];
}

- (instancetype)initWithIdentifier:(NSString *)identifier
                       motionSteps:(NSArray<ORKStep *> *)motionSteps
                          restStep:(nullable ORKHeartRateCaptureStep *)restStep
              relativeDistanceOnly:(BOOL)relativeDistanceOnly
                           options:(ORKPredefinedTaskOption)options {
    
    // Add step for the camera instruction
    ORKHeartRateCameraInstructionStep *instructionStep = [[ORKHeartRateCameraInstructionStep alloc] initWithIdentifier:ORKWorkoutCameraInstructionStepIdentifier];
    
    // If the rest step is nil then set as a default
    if (!restStep) {
        restStep = [[ORKHeartRateCaptureStep alloc] initWithIdentifier:ORKWorkoutAfterStepIdentifier];
    }
    
    // Add countdown to heart rate measuring
    ORKCountdownStep *countBeforeStep = [[ORKCountdownStep alloc] initWithIdentifier:ORKWorkoutBeforeCountdownStepIdentifier];
    countBeforeStep.stepDuration = 5.0;
    countBeforeStep.title = restStep.title;
    countBeforeStep.text = ORKLocalizedString(@"HEARTRATE_MONITOR_CAMERA_INITIAL_TEXT", nil);
    countBeforeStep.spokenInstruction = ORKLocalizedString(@"HEARTRATE_MONITOR_CAMERA_SPOKEN", nil);
    countBeforeStep.watchInstruction = restStep.watchInstruction;
    countBeforeStep.beginCommand = ORKWorkoutCommandStopMoving;
    ORKCountdownStep *countAfterStep = [countBeforeStep copyWithIdentifier:ORKWorkoutAfterCountdownStepIdentifier];
    
    // Remove the watch instruction from the rest step since it is copied to the countdown
    restStep.watchInstruction = nil;
    if ([restStep.beginCommand isEqualToString:countBeforeStep.beginCommand]) {
        restStep.beginCommand = nil;
    }
    
    // Set the before step - Before step only runs until heart rate is captured and watch is connected
    // (if applicable)
    ORKHeartRateCaptureStep *beforeStep = [restStep copyWithIdentifier:ORKWorkoutBeforeStepIdentifier];
    beforeStep.minimumDuration = 0.0;
    beforeStep.stepDuration = 0.0;
    beforeStep.endCommand = nil;
    beforeStep.beforeWorkout = YES;
    
    // At the end of the rest step, send command to stop the watch
    restStep.endCommand = ORKWorkoutCommandStop;
    restStep.beforeWorkout = NO;
    
    // setup the steps
    NSMutableArray *steps = [[NSMutableArray alloc] init];
    [steps addObject:instructionStep];
    if (motionSteps.count > 0) {
        // Only if there are motion steps should the before step be added
        // This allows a workout step to be created that just measures heart rate
        [steps addObject:countBeforeStep];
        [steps addObject:beforeStep];
        [steps addObjectsFromArray:motionSteps];
    }
    [steps addObject:countAfterStep];
    [steps addObject:restStep];
    
    self = [super initWithIdentifier:identifier steps:steps];
    if (self) {

        // default workout is outdoor walking
        _workoutConfiguration = [[HKWorkoutConfiguration alloc] init];
        _workoutConfiguration.activityType = HKWorkoutActivityTypeWalking;
        _workoutConfiguration.locationType = HKWorkoutSessionLocationTypeOutdoor;
        
        // If the heart rate isn't excluded then add that recorder
        _recorderConfigurations = [ORKFitnessStep recorderConfigurationsWithOptions:options
                                                               relativeDistanceOnly:relativeDistanceOnly
                                                                      standingStill:YES];
    }
    return self;
}

- (Class)stepViewControllerClass {
    return [ORKWorkoutStepViewController class];
}

- (ORKStep *)stepAfterStepWithIdentifier:(NSString *)identifier withResult:(ORKTaskResult *)result {
    ORKStepResult *stepResult = [result stepResultForStepIdentifier:identifier];
    if ([identifier isEqualToString:ORKWorkoutOutdoorInstructionStepIdentifier]) {
        NSString *nextIdentifier = [[(ORKChoiceQuestionResult *)[stepResult.results firstObject] choiceAnswers] firstObject];
        return [self.pageTask stepWithIdentifier:(nextIdentifier ? : ORKWorkoutBeforeCountdownStepIdentifier)];
    } else {
        ORKStep *nextStep = [super stepAfterStepWithIdentifier:identifier withResult:result];
        if ((self.workoutConfiguration.locationType == HKWorkoutSessionLocationTypeOutdoor) &&
            [identifier isEqualToString:ORKWorkoutBeforeStepIdentifier]) {
            // If this is an outdoor workout and the accuracy indicates that the user is indoors
            // then instruct them to move outdoors.
            ORKBooleanQuestionResult *outdoorsResult = (ORKBooleanQuestionResult *)[stepResult resultForIdentifier:ORKWorkoutResultIdentifierIsOutdoors];
            if ((outdoorsResult != nil) && ![outdoorsResult.booleanAnswer boolValue]) {
                return [self createOutdoorsInstructionStepWithNextStep:nextStep];
            }
        }
        return nextStep;
    }
}

- (ORKStep *)stepBeforeStepWithIdentifier:(NSString *)identifier withResult:(ORKTaskResult *)result {
    // Cannot go back
    return nil;
}

- (BOOL)allowsBackNavigation {
    return NO;
}

- (BOOL)shouldStopRecordersOnFinishedWithStep:(ORKStep *)step {
    return [step.identifier isEqualToString:[self.steps lastObject].identifier];
}

- (ORKQuestionStep *)createOutdoorsInstructionStepWithNextStep:(ORKStep *)nextStep {
    
    ORKTextChoice *choice1 = [ORKTextChoice choiceWithText:ORKLocalizedString(@"CARDIO_OUTDOOR_ALREADY_OUTSIDE", nil)
                                                     value:nextStep.identifier];
    ORKTextChoice *choice2 = [ORKTextChoice choiceWithText:ORKLocalizedString(@"CARDIO_OUTDOOR_CONTINUE", nil)
                                                     value:ORKWorkoutBeforeCountdownStepIdentifier];
    ORKAnswerFormat *format = [ORKAnswerFormat choiceAnswerFormatWithStyle:ORKChoiceAnswerStyleSingleChoice
                                                               textChoices:@[choice1, choice2]];
    
    ORKQuestionStep *step = [ORKQuestionStep questionStepWithIdentifier:ORKWorkoutOutdoorInstructionStepIdentifier
                                                                  title:ORKLocalizedString(@"CARDIO_OUTDOOR_INSTRUCTION_TITLE", nil)
                                                                   text:ORKLocalizedString(@"CARDIO_OUTDOOR_INSTRUCTION_TEXT", nil)
                                                                 answer:format];
    step.useSurveyMode = YES;
    step.optional = NO;
    return step;
}

#pragma mark - Encoding, Copying and Equality

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORK_DECODE_OBJ_ARRAY(aDecoder, recorderConfigurations, ORKRecorderConfiguration);
        ORK_DECODE_OBJ_CLASS(aDecoder, workoutConfiguration, HKWorkoutConfiguration);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORK_ENCODE_OBJ(aCoder, recorderConfigurations);
    ORK_ENCODE_OBJ(aCoder, workoutConfiguration);
}

- (id)copyWithZone:(NSZone *)zone {
    __typeof(self) step = [super copyWithZone:zone];
    step.recorderConfigurations = self.recorderConfigurations;
    step.workoutConfiguration = self.workoutConfiguration;
    return step;
}

- (NSUInteger)hash {
    return [super hash] ^ self.recorderConfigurations.hash ^ self.workoutConfiguration.hash;
}

- (BOOL)isEqual:(id)object {
    __typeof(self) castObject = object;
    
    return ([super isEqual:object]
            && ORKEqualObjects(self.recorderConfigurations, castObject.recorderConfigurations)
            && ORKEqualObjects(self.workoutConfiguration, castObject.workoutConfiguration));
}

#pragma mark - Permissions

- (ORKPermissionMask)requestedPermissions {
    ORKPermissionMask mask = [super requestedPermissions];
    for (ORKRecorderConfiguration *config in self.recorderConfigurations) {
        mask |= [config requestedPermissionMask];
    }
    return mask;
}

- (NSSet *)requestedHealthKitTypesForReading {
    NSSet *parentSet = [super requestedHealthKitTypesForReading];
    NSMutableSet *set = [self workoutHealthKitTypes];
    [set unionSet:parentSet];
    return [set copy];
}

- (NSSet *)requestedHealthKitTypesForWriting {
    NSSet *parentSet = [super requestedHealthKitTypesForWriting];
    NSMutableSet *set = [self workoutHealthKitTypes];
    [set unionSet:parentSet];
    return [set copy];
}

- (NSMutableSet *)workoutHealthKitTypes {
    NSMutableSet *set = [NSMutableSet new];
    NSArray *queryIds = [ORKWorkoutUtilities queryIdentifiersForWorkoutConfiguration:self.workoutConfiguration];
    for (NSString *queryId in queryIds) {
        HKObjectType *quantityType = [HKObjectType quantityTypeForIdentifier:queryId];
        if (quantityType) {
            [set addObject:quantityType];
        }
    }
    [set addObject:[HKObjectType workoutType]];
    return set;
}


#pragma mark - Stored device name

+ (NSString *)defaultDeviceName {
    return [self storedDeviceName] ? : ORKLocalizedString(@"HEARTRATE_MONITOR_DEVICE_APPLE_WATCH", nil);
}

+ (NSString *)storedDeviceName {
    return [[NSUserDefaults standardUserDefaults] objectForKey:ORKHeartRateMonitorDeviceNameKey];
}

+ (void)setStoredDeviceName:(NSString *)storedDeviceName {
    [[NSUserDefaults standardUserDefaults] setObject:storedDeviceName forKey:ORKHeartRateMonitorDeviceNameKey];
}

@end
