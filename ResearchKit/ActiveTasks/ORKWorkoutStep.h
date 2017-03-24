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


@import Foundation;
@import HealthKit;
#import <ResearchKit/ORKDefines.h>
#import <ResearchKit/ORKPageStep.h>


NS_ASSUME_NONNULL_BEGIN

typedef NSString * ORKWorkoutResultIdentifier NS_STRING_ENUM;

/**
 Maps to an `ORKBooleanQuestionResult` with whether or not the heart rate was successfully measured.
 */
ORK_EXTERN ORKWorkoutResultIdentifier const ORKWorkoutResultIdentifierHeartRateCaptureSuccess;

/**
 Maps to an `ORKNumberQuestionResult` with the measured heart rate at the end of the step.
 */
ORK_EXTERN ORKWorkoutResultIdentifier const ORKWorkoutResultIdentifierHeartRate;

/**
 Maps to an `ORKFileResult` with the consolidated data for the workout. This includes a consolidated
 data for the motion, location, and heart rate with normalized timestamps.
 */
ORK_EXTERN ORKWorkoutResultIdentifier const ORKWorkoutResultIdentifierWorkoutData;

/**
 Maps to an `ORKFileResult` with the sample data from using the camera to measure heart rate.
 */
ORK_EXTERN ORKWorkoutResultIdentifier const ORKWorkoutResultIdentifierCameraSamples;

/**
 Maps to an `ORKBooleanQuestionResult` with a `booleanAnswer` of `YES` if the user ended the workout.
 */
ORK_EXTERN ORKWorkoutResultIdentifier const ORKWorkoutResultIdentifierUserEnded;

/**
 Maps to an `ORKNumericQuestionResult` with the `CLLocation.speed` at the end of the step.
 */
ORK_EXTERN ORKWorkoutResultIdentifier const ORKWorkoutResultIdentifierSpeed;

/**
 Maps to an `ORKBooleanQuestionResult` with whether or not the user's GPS indicates that they are outdoors.
 */
ORK_EXTERN ORKWorkoutResultIdentifier const ORKWorkoutResultIdentifierIsOutdoors;

/**
 Maps to an `ORKNumericQuestionResult` with the total distance traveled during the step.
 */
ORK_EXTERN ORKWorkoutResultIdentifier const ORKWorkoutResultIdentifierDistanceTraveled;

ORK_EXTERN NSString *const ORKWorkoutBeforeStepIdentifier ORK_AVAILABLE_DECL;
ORK_EXTERN NSString *const ORKWorkoutAfterStepIdentifier ORK_AVAILABLE_DECL;
ORK_EXTERN NSString *const ORKWorkoutCameraInstructionStepIdentifier ORK_AVAILABLE_DECL;
ORK_EXTERN NSString *const ORKWorkoutBeforeCountdownStepIdentifier ORK_AVAILABLE_DECL;
ORK_EXTERN NSString *const ORKWorkoutAfterCountdownStepIdentifier ORK_AVAILABLE_DECL;

@class ORKHeartRateCaptureStep;
@class ORKRecorderConfiguration;

/**
 The `ORKWorkoutStep` is a step that can be used to group a set of active steps to lead the user
 through a workout. 
 
 For example, this is used in the Cardio Challenge task to instruct the user to do a 6-minute walk.
 
 As a part of running this step, the `ORKWorkoutStepViewController` will attempt to start a workout
 session, provided that the user has an Apple Watch and the watch app is installed. If the user has 
 an Apple Watch, then the workout will include collecting data on the heart rate from the watch.
 
 As a part of this step, the workout will insert an `ORKHeartRateCaptureStep` before and after the 
 active steps to measure the user's heart rate before and after the workout.
 */
ORK_CLASS_AVAILABLE
HK_CLASS_AVAILABLE_IOS_WATCHOS(10_0, 3_0)
@interface ORKWorkoutStep : ORKPageStep

/**
 If provided, this is the configuration that should be sent to the watch to start the workout.
 By default, the configuration used will be for walking outdoors.
 */
@property (nonatomic, copy, nullable) HKWorkoutConfiguration *workoutConfiguration;

/**
 An array of recorder configurations that define the parameters for recorders to be
 run during a step to collect sensor or other data.
 
 If you want to collect data from sensors while the step is in progress,
 add one or more recorder configurations to the array. The active step view
 controller instantiates recorders and collates their results as children
 of the step result.
 
 The set of recorder configurations is scanned when populating the
 `requestedHealthKitTypesForReading` and `requestedPermissions` properties.
 
 See also: `ORKRecorderConfiguration` and `ORKRecorder`.
 */
@property (nonatomic, copy, nullable) NSArray<ORKRecorderConfiguration *> *recorderConfigurations;

// Method unavailable
- (instancetype)initWithIdentifier:(NSString *)identifier
                             steps:(nullable NSArray<ORKStep *> *)steps NS_UNAVAILABLE;

/**
 Returns an initialized workout step.
 
 This is the main initializer for this step. To use, include the steps that define the workout 
 instructions in the `motionSteps` parameter. Optionally, include a custom `restStep` with 
 custom text and/or duration. If included, the `restStep` will be copied with a new identifier
 and inserted before the motion steps. It will also be included after the motion steps. In this 
 way, the user's heart rate will be recorded before and after the workout by using the phone 
 camera. If `nil`, then the `restStep` will be instantiated and included using the default 
 parameters for an `ORKHeartRateCaptureStep`.
 
 If available, a workout session will also be started on user's Apple Watch. To start a workout 
 session from the Apple Watch, the application must include a watch app that implements the workout.
 
 See also: `ORKWorkoutConnector` and `ORKHeartRateCaptureStep`.
 
 @param identifier      The unique identifier for the step.
 @param motionSteps     The motion steps uses to describe the workout.
 @param restStep        Optional custom implementation of a `ORKHeartRateCaptureStep` used to capture heart rate before and after the workout.
 @param options         The predefined recorder options to exclude from this step.
 
 @return                An initialized workout step.
 */
- (instancetype)initWithIdentifier:(NSString *)identifier
                       motionSteps:(NSArray<ORKStep *> *)motionSteps
                          restStep:(nullable ORKHeartRateCaptureStep *)restStep
              relativeDistanceOnly:(BOOL)relativeDistanceOnly
                           options:(ORKPredefinedTaskOption)options NS_DESIGNATED_INITIALIZER;

/**
 Returns a workout step initialized from data in the given unarchiver.
 
 A workout step can be serialized and deserialized with `NSKeyedArchiver`. Note
 that this serialization includes strings that might need to be localized.
 
 @param aDecoder    The coder from which to initialize the ordered task.
 
 @return An initialized workout step.
 */
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
