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

- (void)testORKAccelerometerData {
    
    NSTimeInterval timestamp = 5.0;
    double x = 1.0;
    double y = 2.0;
    double z = 3.0;

    NSDictionary *codingObject = @{@"timestamp": [NSDecimalNumber numberWithDouble:timestamp],
                                   @"x": [NSDecimalNumber numberWithDouble:x],
                                   @"y": [NSDecimalNumber numberWithDouble:y],
                                   @"z": [NSDecimalNumber numberWithDouble:z]};
    
    ORKAccelerometerData *output = [[ORKAccelerometerData alloc] initWithCodingObject:codingObject];
    XCTAssertNotNil(output);
    XCTAssertEqual(output.timestamp, timestamp);
    XCTAssertEqual(output.acceleration.x, x);
    XCTAssertEqual(output.acceleration.y, y);
    XCTAssertEqual(output.acceleration.z, z);
    
    NSDictionary *outputDict = [output ork_jsonCodingObject];
    XCTAssertEqualObjects(outputDict, codingObject);
}

- (void)testORKRelativeLocation {
    
    CLLocationDistance distance = 123.067;
    CLLocationDirection bearing = 56.2;
    CLLocationDistance altitude = 23.63;
    CLLocationAccuracy horizontalAccuracy = 1.0;
    CLLocationAccuracy verticalAccuracy = 2.0;
    CLLocationDirection course = 290.0;
    CLLocationSpeed speed = 55.0;
    NSDate *timestamp = [NSDate date];
    NSInteger floorLevel = 5;
    
    NSDictionary *dict1 = @{@"timestamp": ORKStringFromDateISO8601(timestamp)};
    
    ORKRelativeLocation *loc1 = [[ORKRelativeLocation alloc] initWithCodingObject:dict1];
    XCTAssertEqualWithAccuracy(loc1.timestamp.timeIntervalSinceNow, timestamp.timeIntervalSinceNow, 0.001);
    XCTAssertLessThan(loc1.horizontalAccuracy, 0.0);
    XCTAssertLessThan(loc1.verticalAccuracy, 0.0);
    XCTAssertLessThan(loc1.course, 0.0);
    XCTAssertLessThan(loc1.speed, 0.0);
    XCTAssertFalse(loc1.isValidFloorLevel);

    NSMutableDictionary *dict2 = [dict1 mutableCopy];
    dict2[@"distance"] = @(distance);
    dict2[@"bearing"] = @(bearing);
    dict2[@"altitude"] = @(altitude);
    dict2[@"horizontalAccuracy"] = @(horizontalAccuracy);
    dict2[@"verticalAccuracy"] = @(verticalAccuracy);
    dict2[@"course"] = @(course);
    dict2[@"speed"] = @(speed);
    dict2[@"floor"] = @(floorLevel);
    
    ORKRelativeLocation *loc2 = [[ORKRelativeLocation alloc] initWithCodingObject:dict2];
    XCTAssertEqualWithAccuracy(loc2.timestamp.timeIntervalSinceNow, timestamp.timeIntervalSinceNow, 0.001);
    XCTAssertEqualWithAccuracy(loc2.distance, distance, 0.00001);
    XCTAssertEqualWithAccuracy(loc2.bearing, bearing, 0.00001);
    XCTAssertEqualWithAccuracy(loc2.horizontalAccuracy, horizontalAccuracy, 0.00001);
    XCTAssertEqualWithAccuracy(loc2.verticalAccuracy, verticalAccuracy, 0.00001);
    XCTAssertEqualWithAccuracy(loc2.course, course, 0.00001);
    XCTAssertEqualWithAccuracy(loc2.speed, speed, 0.00001);
    XCTAssertEqual(loc2.floorLevel, floorLevel);
    XCTAssertTrue(loc2.isValidFloorLevel);
}


@end
