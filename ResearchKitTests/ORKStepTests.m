/*
 Copyright (c) 2015, Ricardo Sánchez-Sáez.
 
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


@import XCTest;
@import HealthKit;
@import ResearchKit.Private;


@interface ORKStepTests : XCTestCase

@end

@interface TestStep : ORKStep

@property (nonatomic) ORKPermissionMask requestedPermissions;
@property (nonatomic, copy, nullable) NSSet<HKObjectType *> *requestedHealthKitTypesForReading;
@property (nonatomic, copy, nullable) NSSet<HKObjectType *> *requestedHealthKitTypesForWriting;

@end


@implementation ORKStepTests

- (void)testFormStep {
    // Test duplicate form step identifier validation
    ORKFormStep *formStep = [[ORKFormStep alloc] initWithIdentifier:@"form" title:@"Form" text:@"Form test"];
    NSMutableArray *items = [NSMutableArray new];
    
    ORKFormItem *item = nil;
    item = [[ORKFormItem alloc] initWithIdentifier:@"formItem1"
                                              text:@"formItem1"
                                      answerFormat:[ORKNumericAnswerFormat decimalAnswerFormatWithUnit:nil]];
    [items addObject:item];

    item = [[ORKFormItem alloc] initWithIdentifier:@"formItem2"
                                              text:@"formItem2"
                                      answerFormat:[ORKNumericAnswerFormat decimalAnswerFormatWithUnit:nil]];
    [items addObject:item];

    [formStep setFormItems:items];
    XCTAssertNoThrow([formStep validateParameters]);

    item = [[ORKFormItem alloc] initWithIdentifier:@"formItem2"
                                              text:@"formItem2"
                                      answerFormat:[ORKNumericAnswerFormat decimalAnswerFormatWithUnit:nil]];
    [items addObject:item];

    [formStep setFormItems:items];
    XCTAssertThrows([formStep validateParameters]);
}

- (void)testReactionTimeStep {
    ORKReactionTimeStep *validReactionTimeStep = [[ORKReactionTimeStep alloc] initWithIdentifier:@"ReactionTimeStep"];
    
    validReactionTimeStep.maximumStimulusInterval = 8;
    validReactionTimeStep.minimumStimulusInterval = 4;
    validReactionTimeStep.thresholdAcceleration = 0.5;
    validReactionTimeStep.numberOfAttempts = 3;
    validReactionTimeStep.timeout = 10;

    XCTAssertNoThrow([validReactionTimeStep validateParameters]);
    
    ORKReactionTimeStep *reactionTimeStep = [validReactionTimeStep copy];
    XCTAssertEqualObjects(reactionTimeStep, validReactionTimeStep);

    // minimumStimulusInterval cannot be zero or less
    reactionTimeStep = [validReactionTimeStep copy];
    validReactionTimeStep.minimumStimulusInterval = 0;
    XCTAssertThrows([validReactionTimeStep validateParameters]);

    // minimumStimulusInterval cannot be higher than maximumStimulusInterval
    reactionTimeStep = [validReactionTimeStep copy];
    validReactionTimeStep.maximumStimulusInterval = 8;
    validReactionTimeStep.minimumStimulusInterval = 10;
    XCTAssertThrows([validReactionTimeStep validateParameters]);

    // thresholdAcceleration cannot be zero or less
    reactionTimeStep = [validReactionTimeStep copy];
    validReactionTimeStep.thresholdAcceleration = 0;
    XCTAssertThrows([validReactionTimeStep validateParameters]);

    // timeout cannot be zero or less
    reactionTimeStep = [validReactionTimeStep copy];
    validReactionTimeStep.timeout = 0;
    XCTAssertThrows([validReactionTimeStep validateParameters]);

    // numberOfAttempts cannot be zero or less
    reactionTimeStep = [validReactionTimeStep copy];
    validReactionTimeStep.numberOfAttempts = 0;
    XCTAssertThrows([validReactionTimeStep validateParameters]);
}

- (void)testPageResult {
    
    NSArray *steps = @[[[ORKStep alloc] initWithIdentifier:@"step1"],
                       [[ORKStep alloc] initWithIdentifier:@"step2"],
                       [[ORKStep alloc] initWithIdentifier:@"step3"],
                       ];
    ORKPageStep *pageStep = [[ORKPageStep alloc] initWithIdentifier:@"pageStep" steps:steps];
    
    ORKChoiceQuestionResult *step1Result1 = [[ORKChoiceQuestionResult alloc] initWithIdentifier:@"step1.result1"];
    step1Result1.choiceAnswers = @[@(1)];
    ORKChoiceQuestionResult *step1Result2 = [[ORKChoiceQuestionResult alloc] initWithIdentifier:@"step1.result2"];
    step1Result2.choiceAnswers = @[@(2)];
    ORKChoiceQuestionResult *step2Result1 = [[ORKChoiceQuestionResult alloc] initWithIdentifier:@"step2.result1"];
    step2Result1.choiceAnswers = @[@(3)];
    
    ORKStepResult *inputResult = [[ORKStepResult alloc] initWithStepIdentifier:@"pageStep"
                                                                       results:@[step1Result1, step1Result2, step2Result1]];
    
    ORKPageResult *pageResult = [[ORKPageResult alloc] initWithPageStep:pageStep stepResult:inputResult];
    
    // Check steps going forward
    ORKStep *step1 = [pageStep stepAfterStepWithIdentifier:nil withResult:pageResult];
    XCTAssertNotNil(step1);
    XCTAssertEqualObjects(step1.identifier, @"step1");
    
    ORKStep *step2 = [pageStep stepAfterStepWithIdentifier:@"step1" withResult:pageResult];
    XCTAssertNotNil(step2);
    XCTAssertEqualObjects(step2.identifier, @"step2");
    
    ORKStep *step3 = [pageStep stepAfterStepWithIdentifier:@"step2" withResult:pageResult];
    XCTAssertNotNil(step3);
    XCTAssertEqualObjects(step3.identifier, @"step3");
    
    ORKStep *step4 = [pageStep stepAfterStepWithIdentifier:@"step3" withResult:pageResult];
    XCTAssertNil(step4);
    
    // Check steps going backward
    ORKStep *backStep2 = [pageStep stepBeforeStepWithIdentifier:@"step3" withResult:pageResult];
    XCTAssertEqualObjects(backStep2, step2);
    
    ORKStep *backStep1 = [pageStep stepBeforeStepWithIdentifier:@"step2" withResult:pageResult];
    XCTAssertEqualObjects(backStep1, step1);
    
    ORKStep *backStepNil = [pageStep stepBeforeStepWithIdentifier:@"step1" withResult:pageResult];
    XCTAssertNil(backStepNil);
    
    // Check identifier
    XCTAssertEqualObjects([pageStep stepWithIdentifier:@"step1"], step1);
    XCTAssertEqualObjects([pageStep stepWithIdentifier:@"step2"], step2);
    XCTAssertEqualObjects([pageStep stepWithIdentifier:@"step3"], step3);
}

- (void)testPageStep_Permissions {
    
    TestStep *step1 = [[TestStep alloc] initWithIdentifier:@"step1"];
    step1.requestedPermissions = ORKPermissionCamera | ORKPermissionCoreLocation;
    step1.requestedHealthKitTypesForWriting = [NSSet setWithArray:@[
                                                                    [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate],
                                                                    [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass]]];
    
    TestStep *step2 = [[TestStep alloc] initWithIdentifier:@"step2"];
    step2.requestedHealthKitTypesForReading = [NSSet setWithArray:@[
                                                                    [HKObjectType characteristicTypeForIdentifier:HKCharacteristicTypeIdentifierDateOfBirth],
                                                                    [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeight]]];
    step2.requestedHealthKitTypesForWriting = [NSSet setWithArray:@[
                                                                    [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeight],
                                                                    [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass]]];
    
    TestStep *step3 = [[TestStep alloc] initWithIdentifier:@"step3"];
    step3.requestedPermissions = ORKPermissionCoreMotionActivity | ORKPermissionAudioRecording | ORKPermissionCoreLocation;
    step3.requestedHealthKitTypesForReading = [NSSet setWithArray:@[
                                                                    [HKObjectType characteristicTypeForIdentifier:HKCharacteristicTypeIdentifierBiologicalSex],
                                                                    [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeight]]];
    
    ORKPageStep *pageStep = [[ORKPageStep alloc] initWithIdentifier:@"pageStep" steps:@[step1, step2, step3]];
    
    ORKPermissionMask expectedPermissions = ORKPermissionCamera | ORKPermissionCoreLocation | ORKPermissionCoreMotionActivity | ORKPermissionAudioRecording;
    XCTAssertEqual(pageStep.requestedPermissions, expectedPermissions);
    
    NSSet *expectedReadingTypes = [NSSet setWithArray:@[
                                                        [HKObjectType characteristicTypeForIdentifier:HKCharacteristicTypeIdentifierDateOfBirth],
                                                        [HKObjectType characteristicTypeForIdentifier:HKCharacteristicTypeIdentifierBiologicalSex],
                                                        [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeight]]];
    XCTAssertEqualObjects(pageStep.requestedHealthKitTypesForReading, expectedReadingTypes);
    
    NSSet *expectedWritingTypes = [NSSet setWithArray:@[
                                                        [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate],
                                                        [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeight],
                                                        [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass]]];
    XCTAssertEqualObjects(pageStep.requestedHealthKitTypesForWriting, expectedWritingTypes);
}

- (void)testWorkoutStep {
    
    TestStep *hkStep = [[TestStep alloc] initWithIdentifier:@"hk"];
    hkStep.requestedHealthKitTypesForReading = [NSSet setWithArray:@[
                                                                    [HKObjectType characteristicTypeForIdentifier:HKCharacteristicTypeIdentifierDateOfBirth],
                                                                    [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeight]]];
    hkStep.requestedHealthKitTypesForWriting = [NSSet setWithArray:@[
                                                                    [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeight],
                                                                    [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass]]];
    
    TestStep *audioStep = [[TestStep alloc] initWithIdentifier:@"audio"];
    audioStep.requestedPermissions = ORKPermissionAudioRecording;
    
    ORKWorkoutStep *workoutStep = [[ORKWorkoutStep alloc] initWithIdentifier:@"test"
                                                                 motionSteps:@[hkStep, audioStep]
                                                                    restStep:nil
                                                        relativeDistanceOnly:YES
                                                                     options: ORKPredefinedTaskOptionExcludeDeviceMotion | ORKPredefinedTaskOptionExcludeAccelerometer];
    
    // Check the defaults
    XCTAssertEqual(workoutStep.workoutConfiguration.activityType, HKWorkoutActivityTypeWalking);
    XCTAssertEqual(workoutStep.workoutConfiguration.locationType, HKWorkoutSessionLocationTypeOutdoor);
    
    // With the default configuration, check the expected permissions
    ORKPermissionMask expectedPermissions = ORKPermissionAudioRecording | ORKPermissionCoreMotionActivity | ORKPermissionCamera | ORKPermissionCoreLocation;
    XCTAssertEqual(workoutStep.requestedPermissions, expectedPermissions);
    
    NSSet *expectedReading = [NSSet setWithArray:@[
                                                   [HKObjectType characteristicTypeForIdentifier:HKCharacteristicTypeIdentifierDateOfBirth],
                                                   [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeight],
                                                   [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate],
                                                   [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierActiveEnergyBurned],
                                                   [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceWalkingRunning],
                                                   [HKObjectType workoutType]]];
    XCTAssertEqualObjects(workoutStep.requestedHealthKitTypesForReading, expectedReading);
    
    NSSet *expectedWriting = [NSSet setWithArray:@[
                                                 [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeight],
                                                 [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass],
                                                 [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate],
                                                 [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierActiveEnergyBurned],
                                                 [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceWalkingRunning],
                                                 [HKObjectType workoutType]]];
    XCTAssertEqualObjects(workoutStep.requestedHealthKitTypesForWriting, expectedWriting);
    
    // Check that the location recorder config uses relative distance only
    ORKLocationRecorderConfiguration *locationConfig = (ORKLocationRecorderConfiguration *)[[workoutStep.recorderConfigurations filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id  _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        return [evaluatedObject isKindOfClass:[ORKLocationRecorderConfiguration class]];
    }]] firstObject];
    XCTAssertNotNil(locationConfig);
    XCTAssertTrue(locationConfig.relativeDistanceOnly);
    
    // Check that the pedometer is included
    ORKPedometerRecorderConfiguration *pedConfig = (ORKPedometerRecorderConfiguration *)[[workoutStep.recorderConfigurations filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id  _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        return [evaluatedObject isKindOfClass:[ORKPedometerRecorderConfiguration class]];
    }]] firstObject];
    XCTAssertNotNil(pedConfig);
    
    // Check that the heart rate capture step is included twice, before and after motion steps
    ORKHeartRateCaptureStep *beforeStep = (ORKHeartRateCaptureStep *)[workoutStep stepWithIdentifier:ORKWorkoutBeforeStepIdentifier];
    XCTAssertNotNil(beforeStep);
    XCTAssertTrue([beforeStep isKindOfClass:[ORKHeartRateCaptureStep class]]);
    XCTAssertEqual(beforeStep.minimumDuration, 0);
    XCTAssertEqual(beforeStep.stepDuration, 0);
    XCTAssertTrue(beforeStep.isBeforeWorkout);
    
    ORKStep *motionStep = [workoutStep stepWithIdentifier:@"audio"];
    XCTAssertNotNil(motionStep);
    
    ORKHeartRateCaptureStep *afterStep = (ORKHeartRateCaptureStep *)[workoutStep stepWithIdentifier:ORKWorkoutAfterStepIdentifier];
    XCTAssertNotNil(afterStep);
    XCTAssertTrue([afterStep isKindOfClass:[ORKHeartRateCaptureStep class]]);
    XCTAssertFalse(afterStep.isBeforeWorkout);
    
    XCTAssertLessThan([workoutStep.pageTask indexOfStep:beforeStep], [workoutStep.pageTask indexOfStep:motionStep]);
    XCTAssertLessThan([workoutStep.pageTask indexOfStep:motionStep], [workoutStep.pageTask indexOfStep:afterStep]);
}

@end

@implementation TestStep

@synthesize requestedPermissions;
@synthesize requestedHealthKitTypesForReading;
@synthesize requestedHealthKitTypesForWriting;

- (id)copyWithZone:(NSZone *)zone {
    __typeof(self) copy = [super copyWithZone:zone];
    copy.requestedPermissions = self.requestedPermissions;
    copy.requestedHealthKitTypesForWriting = self.requestedHealthKitTypesForWriting;
    copy.requestedHealthKitTypesForReading = self.requestedHealthKitTypesForReading;
    return copy;
}

@end


