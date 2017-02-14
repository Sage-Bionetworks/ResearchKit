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


@import XCTest;
@import ResearchKit;
@import HealthKit;

@interface ORKWorkoutMessageTests : XCTestCase

@end

@implementation ORKWorkoutMessageTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testORKWorkoutMessageSerialization {
    
    ORKWorkoutMessage *input = [[ORKWorkoutMessage alloc] initWithIdentifier:@"test"];
    input.workoutState = ORKWorkoutStateRunning;
    XCTAssertNotNil(input.identifier);
    XCTAssertNotNil(input.timestamp);
    
    NSDictionary *dictionary = [input dictionaryRepresentation];
    XCTAssertTrue([NSJSONSerialization isValidJSONObject:dictionary]);
    XCTAssertEqualObjects(dictionary[@"identifier"], @"test");
    XCTAssertEqualObjects(dictionary[@"workoutState"], @"running");
    XCTAssertEqualObjects(dictionary[@"classType"], @"ORKWorkoutMessage");
    XCTAssertTrue([dictionary[@"timestamp"] isKindOfClass:[NSString class]]);
    
    ORKWorkoutMessage *output = [ORKWorkoutMessage workoutMessageWithMessage:dictionary];
    XCTAssertNotNil(output);
    XCTAssertTrue([output isMemberOfClass:[input class]]);
    XCTAssertEqualObjects(input.identifier, output.identifier);
    XCTAssertEqualWithAccuracy(input.timestamp.timeIntervalSinceNow, output.timestamp.timeIntervalSinceNow, 0.001);
    XCTAssertEqualObjects(input.workoutState, output.workoutState);
    
    ORKWorkoutMessage *copy = [output copy];
    XCTAssertNotNil(copy);
    XCTAssertTrue([copy isMemberOfClass:[input class]]);
    XCTAssertEqualObjects(input.identifier, copy.identifier);
    XCTAssertEqualWithAccuracy(input.timestamp.timeIntervalSinceNow, copy.timestamp.timeIntervalSinceNow, 0.001);
    XCTAssertEqualObjects(input.workoutState, copy.workoutState);
}

- (void)testORKInstructionWorkoutMessageSerialization {
    
    ORKInstructionWorkoutMessage *input = [[ORKInstructionWorkoutMessage alloc] initWithIdentifier:@"test"];
    input.workoutState = ORKWorkoutStateRunning;
    input.instruction = @"test instruction";
    input.command = ORKWorkoutCommandStop;
    input.stepDuration = 5.0;
    
    NSDictionary *dictionary = [input dictionaryRepresentation];
    XCTAssertTrue([NSJSONSerialization isValidJSONObject:dictionary]);
    XCTAssertEqualObjects(dictionary[@"identifier"], @"test");
    XCTAssertEqualObjects(dictionary[@"workoutState"], @"running");
    XCTAssertEqualObjects(dictionary[@"classType"], @"ORKInstructionWorkoutMessage");
    XCTAssertTrue([dictionary[@"timestamp"] isKindOfClass:[NSString class]]);
    XCTAssertEqualObjects(dictionary[@"command"], ORKWorkoutCommandStop);
    XCTAssertEqualObjects(dictionary[@"instruction"], @"test instruction");
    XCTAssertEqualObjects(dictionary[@"stepDuration"], @(5.0));
    
    ORKInstructionWorkoutMessage *output = (ORKInstructionWorkoutMessage *)[ORKWorkoutMessage workoutMessageWithMessage:dictionary];
    XCTAssertNotNil(output);
    XCTAssertTrue([output isMemberOfClass:[input class]]);
    XCTAssertEqualObjects(input.identifier, output.identifier);
    XCTAssertEqualWithAccuracy(input.timestamp.timeIntervalSinceNow, output.timestamp.timeIntervalSinceNow, 0.001);
    XCTAssertEqualObjects(input.workoutState, output.workoutState);
    XCTAssertEqualObjects(input.instruction, output.instruction);
    XCTAssertEqualObjects(input.command, output.command);
    XCTAssertEqual(input.stepDuration, output.stepDuration);
    
    ORKInstructionWorkoutMessage *copy = [output copy];
    XCTAssertNotNil(copy);
    XCTAssertTrue([copy isMemberOfClass:[input class]]);
    XCTAssertEqualObjects(input.identifier, copy.identifier);
    XCTAssertEqualWithAccuracy(input.timestamp.timeIntervalSinceNow, copy.timestamp.timeIntervalSinceNow, 0.001);
    XCTAssertEqualObjects(input.workoutState, copy.workoutState);
    XCTAssertEqualObjects(input.instruction, copy.instruction);
    XCTAssertEqualObjects(input.command, copy.command);
    XCTAssertEqual(input.stepDuration, copy.stepDuration);
}

- (void)testORKSamplesWorkoutMessageSerialization {
    
    ORKSamplesWorkoutMessage *input = [[ORKSamplesWorkoutMessage alloc] initWithIdentifier:@"test"];
    input.workoutState = ORKWorkoutStateRunning;
    input.quantityTypeIdentifier = HKQuantityTypeIdentifierHeartRate;
    
    HKUnit *unit = [HKUnit bpmUnit];
    HKQuantity *quantity = [HKQuantity quantityWithUnit:unit doubleValue:80];
    HKQuantityType *quantityType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate];
    input.samples = @[ [HKQuantitySample quantitySampleWithType:quantityType
                                                               quantity:quantity
                                                              startDate:[NSDate dateWithTimeIntervalSinceNow:-2]
                                                                endDate:[NSDate dateWithTimeIntervalSinceNow:-1]]];
    
    NSDictionary *dictionary = [input dictionaryRepresentation];
    XCTAssertTrue([NSJSONSerialization isValidJSONObject:dictionary]);
    XCTAssertEqualObjects(dictionary[@"identifier"], @"test");
    XCTAssertEqualObjects(dictionary[@"workoutState"], @"running");
    XCTAssertEqualObjects(dictionary[@"classType"], @"ORKSamplesWorkoutMessage");
    XCTAssertTrue([dictionary[@"timestamp"] isKindOfClass:[NSString class]]);
    XCTAssertEqualObjects(dictionary[@"quantityTypeIdentifier"], @"HKQuantityTypeIdentifierHeartRate");
    XCTAssertNotNil(dictionary[@"samples"]);
    
    ORKSamplesWorkoutMessage *output = (ORKSamplesWorkoutMessage *)[ORKWorkoutMessage workoutMessageWithMessage:dictionary];
    XCTAssertNotNil(output);
    XCTAssertTrue([output isMemberOfClass:[input class]]);
    XCTAssertEqualObjects(input.identifier, output.identifier);
    XCTAssertEqualWithAccuracy(input.timestamp.timeIntervalSinceNow, output.timestamp.timeIntervalSinceNow, 0.001);
    XCTAssertEqualObjects(input.workoutState, output.workoutState);
    XCTAssertEqualObjects(input.quantityTypeIdentifier, output.quantityTypeIdentifier);
    
    XCTAssertEqual(input.samples.count, output.samples.count);
    HKQuantitySample *inSample = [input.samples firstObject];
    HKQuantitySample *outSample = [output.samples firstObject];
    XCTAssertEqualWithAccuracy(inSample.startDate.timeIntervalSinceNow, outSample.startDate.timeIntervalSinceNow, 0.001);
    XCTAssertEqualWithAccuracy(inSample.endDate.timeIntervalSinceNow, outSample.endDate.timeIntervalSinceNow, 0.001);
    XCTAssertEqualObjects(inSample.quantityType.identifier, outSample.quantityType.identifier);
    XCTAssertEqual([outSample.quantity doubleValueForUnit:unit], 80.0);
    
    ORKSamplesWorkoutMessage *copy = [output copy];
    XCTAssertNotNil(copy);
    XCTAssertTrue([copy isMemberOfClass:[input class]]);
    XCTAssertEqualObjects(input.identifier, copy.identifier);
    XCTAssertEqualWithAccuracy(input.timestamp.timeIntervalSinceNow, copy.timestamp.timeIntervalSinceNow, 0.001);
    XCTAssertEqualObjects(input.workoutState, copy.workoutState);
    XCTAssertEqualObjects(input.quantityTypeIdentifier, copy.quantityTypeIdentifier);
    
    XCTAssertEqual(input.samples.count, copy.samples.count);
    HKQuantitySample *cSample = [copy.samples firstObject];
    XCTAssertEqualWithAccuracy(inSample.startDate.timeIntervalSinceNow, cSample.startDate.timeIntervalSinceNow, 0.001);
    XCTAssertEqualWithAccuracy(inSample.endDate.timeIntervalSinceNow, cSample.endDate.timeIntervalSinceNow, 0.001);
    XCTAssertEqualObjects(inSample.quantityType.identifier, cSample.quantityType.identifier);
    XCTAssertEqual([cSample.quantity doubleValueForUnit:unit], 80.0);
}

- (void)testORKEventWorkoutMessageSerialization {

    if (!ORK_IOS_10_WATCHOS_3_AVAILABLE) {
        return;
    }
    
    ORKEventWorkoutMessage *input = [[ORKEventWorkoutMessage alloc] initWithIdentifier:@"test"];
    input.workoutState = ORKWorkoutStateRunning;
    input.event = [HKWorkoutEvent workoutEventWithType:HKWorkoutEventTypeResume date:[NSDate date]];
    
    NSDictionary *dictionary = [input dictionaryRepresentation];
    XCTAssertTrue([NSJSONSerialization isValidJSONObject:dictionary]);
    XCTAssertEqualObjects(dictionary[@"identifier"], @"test");
    XCTAssertEqualObjects(dictionary[@"workoutState"], @"running");
    XCTAssertEqualObjects(dictionary[@"classType"], @"ORKEventWorkoutMessage");
    XCTAssertTrue([dictionary[@"timestamp"] isKindOfClass:[NSString class]]);
    XCTAssertNotNil(dictionary[@"event"]);
    
    ORKEventWorkoutMessage *output = (ORKEventWorkoutMessage *)[ORKWorkoutMessage workoutMessageWithMessage:dictionary];
    XCTAssertNotNil(output);
    XCTAssertTrue([output isMemberOfClass:[input class]]);
    XCTAssertEqualObjects(input.identifier, output.identifier);
    XCTAssertEqualWithAccuracy(input.timestamp.timeIntervalSinceNow, output.timestamp.timeIntervalSinceNow, 0.001);
    XCTAssertEqualObjects(input.workoutState, output.workoutState);
    XCTAssertEqual(input.event.type, output.event.type);
    XCTAssertEqualWithAccuracy(input.event.date.timeIntervalSinceNow, output.event.date.timeIntervalSinceNow, 0.001);
    
    ORKEventWorkoutMessage *copy = [output copy];
    XCTAssertNotNil(copy);
    XCTAssertTrue([copy isMemberOfClass:[input class]]);
    XCTAssertEqualObjects(input.identifier, copy.identifier);
    XCTAssertEqualWithAccuracy(input.timestamp.timeIntervalSinceNow, copy.timestamp.timeIntervalSinceNow, 0.001);
    XCTAssertEqualObjects(input.workoutState, copy.workoutState);
    XCTAssertEqual(input.event.type, copy.event.type);
    XCTAssertEqualWithAccuracy(input.event.date.timeIntervalSinceNow, copy.event.date.timeIntervalSinceNow, 0.001);
}

- (void)testORKErrorWorkoutMessageSerialization {
    
    ORKErrorWorkoutMessage *input = [[ORKErrorWorkoutMessage alloc] initWithIdentifier:@"test"];
    input.workoutState = ORKWorkoutStateRunning;
    input.error = [NSError errorWithDomain:@"foo" code:1 userInfo:nil];
    
    NSDictionary *dictionary = [input dictionaryRepresentation];
    XCTAssertTrue([NSJSONSerialization isValidJSONObject:dictionary]);
    XCTAssertEqualObjects(dictionary[@"identifier"], @"test");
    XCTAssertEqualObjects(dictionary[@"workoutState"], @"running");
    XCTAssertEqualObjects(dictionary[@"classType"], @"ORKErrorWorkoutMessage");
    XCTAssertTrue([dictionary[@"timestamp"] isKindOfClass:[NSString class]]);
    XCTAssertNotNil(dictionary[@"error"]);
    
    ORKErrorWorkoutMessage *output = (ORKErrorWorkoutMessage *)[ORKWorkoutMessage workoutMessageWithMessage:dictionary];
    XCTAssertNotNil(output);
    XCTAssertTrue([output isMemberOfClass:[input class]]);
    XCTAssertEqualObjects(input.identifier, output.identifier);
    XCTAssertEqualWithAccuracy(input.timestamp.timeIntervalSinceNow, output.timestamp.timeIntervalSinceNow, 0.001);
    XCTAssertEqualObjects(input.workoutState, output.workoutState);
    XCTAssertEqual(input.error.code, output.error.code);
    XCTAssertEqualObjects(input.error.domain, output.error.domain);
    
    ORKErrorWorkoutMessage *copy = [output copy];
    XCTAssertNotNil(copy);
    XCTAssertTrue([copy isMemberOfClass:[input class]]);
    XCTAssertEqualObjects(input.identifier, copy.identifier);
    XCTAssertEqualWithAccuracy(input.timestamp.timeIntervalSinceNow, copy.timestamp.timeIntervalSinceNow, 0.001);
    XCTAssertEqualObjects(input.workoutState, copy.workoutState);
    XCTAssertEqual(input.error.code, copy.error.code);
    XCTAssertEqualObjects(input.error.domain, copy.error.domain);
}


@end
