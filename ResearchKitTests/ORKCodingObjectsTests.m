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


#import <XCTest/XCTest.h>

@import ResearchKit;
@import HealthKit;

@interface ORKCodingObjectsTests : XCTestCase

@end

@implementation ORKCodingObjectsTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testHKDeviceCoding {
    HKDevice *input = [[HKDevice alloc] initWithName:@"device"
                                         manufacturer:@"foo"
                                                model:@"bar"
                                      hardwareVersion:@"1"
                                      firmwareVersion:@"2"
                                      softwareVersion:@"3"
                                      localIdentifier:nil
                                  UDIDeviceIdentifier:nil];
    
    NSDictionary *json = [input ork_jsonCodingObject];
    XCTAssertEqualObjects(json[@"name"], @"device");
    XCTAssertEqualObjects(json[@"manufacturer"], @"foo");
    XCTAssertEqualObjects(json[@"model"], @"bar");
    XCTAssertEqualObjects(json[@"hardwareVersion"], @"1");
    XCTAssertEqualObjects(json[@"firmwareVersion"], @"2");
    XCTAssertEqualObjects(json[@"softwareVersion"], @"3");
    
    HKDevice *output = [HKDevice deviceWithCodingObject:json];
    XCTAssertEqualObjects(input, output);
}

- (void)testHKWorkoutConfigurationCoding {
    HKWorkoutConfiguration *input = [[HKWorkoutConfiguration alloc] init];
    input.locationType = HKWorkoutSessionLocationTypeOutdoor;
    input.activityType = HKWorkoutActivityTypeBarre;
    
    NSDictionary *json = [input ork_jsonCodingObject];
    XCTAssertEqualObjects(json[@"locationType"], @"outdoor");
    XCTAssertEqualObjects(json[@"activityType"], @"barre");

    HKWorkoutConfiguration *output = [HKWorkoutConfiguration workoutConfigurationWithCodingObject:json];
    XCTAssertEqualObjects(input, output);
}

- (void)testHKQuantitySample {
    HKUnit *unit = [HKUnit bpmUnit];
    HKQuantity *quantity = [HKQuantity quantityWithUnit:unit doubleValue:80];
    HKQuantityType *quantityType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate];
    HKQuantitySample *input = [HKQuantitySample quantitySampleWithType:quantityType
                                                       quantity:quantity
                                                      startDate:[NSDate dateWithTimeIntervalSinceNow:-2]
                                                        endDate:[NSDate dateWithTimeIntervalSinceNow:-1]];
    
    NSDictionary *json = [input ork_jsonCodingObject];
    XCTAssertEqualObjects(json[@"type"], @"HKQuantityTypeIdentifierHeartRate");
    XCTAssertTrue([json[@"startDate"] isKindOfClass:[NSString class]]);
    XCTAssertTrue([json[@"endDate"] isKindOfClass:[NSString class]]);
    XCTAssertTrue([json[@"value"] isKindOfClass:[NSNumber class]]);
    XCTAssertTrue([json[@"unit"] isKindOfClass:[NSString class]]);

    HKQuantitySample *output = [HKQuantitySample quantitySampleWithCodingObject:json];
    XCTAssertEqualObjects(input.quantity, output.quantity);
    XCTAssertEqualObjects(input.quantityType, output.quantityType);
    XCTAssertEqualWithAccuracy([input.startDate timeIntervalSinceReferenceDate], [output.startDate timeIntervalSinceReferenceDate], 0.001);
    XCTAssertEqualWithAccuracy([input.endDate timeIntervalSinceReferenceDate], [output.endDate timeIntervalSinceReferenceDate], 0.001);
}

@end
