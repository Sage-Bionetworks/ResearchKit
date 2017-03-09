/*
 Copyright (c) 2015, Apple Inc. All rights reserved.
 Copyright (c) 2017, Sage Bionetworks.
 
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


@import CoreLocation;
#import <ResearchKit/ORKTypes.h>


NS_ASSUME_NONNULL_BEGIN

@interface CLLocation (ORKJSONCodingObject)

/**
 Convert the location to a json coding object.
 
 @return    JSON object
 */
- (NSDictionary<NSString *, id> *)ork_jsonCodingObject;

/**
 Convert the location to a json coding object.
 
 @param     relativeDistanceOnly    Encode the distance and bearing rather than the latitude and longitude
 @param     previous                Previous location
 @return    JSON object
 */
- (NSDictionary<NSString *, id> *)ork_jsonCodingObjectWithRelativeDistanceOnly:(BOOL)relativeDistanceOnly previous:(nullable CLLocation *)previous;

@end

/**
 A `ORKRelativeLocation` object that can be created from a `CLLocation` or `CLLocation` json
 coding object.
 */
ORK_CLASS_AVAILABLE
@interface ORKRelativeLocation : NSObject <NSCopying>

/**
 Distance travelled since the previous measurement was taken.
 */
@property (nonatomic) CLLocationDistance distance;

/**
 Returns bearing for the distance travelled since the previous measurement was taken.
 
 Range: 0.0 - 359.9 degrees, 0 being true North
 */
@property (nonatomic) CLLocationDirection bearing;

/**
 Returns the altitude of the location. Can be positive (above sea level) or negative (below sea level).
 */
@property (nonatomic) CLLocationDistance altitude;

/**
 Returns the horizontal accuracy of the location. Negative if the lateral location is invalid.
 */
@property (nonatomic) CLLocationAccuracy horizontalAccuracy;

/**
 Returns the vertical accuracy of the location. Negative if the altitude is invalid.
 */
@property (nonatomic) CLLocationAccuracy verticalAccuracy;

/**
 Returns the course of the location in degrees true North. Negative if course is invalid.
 
 Range: 0.0 - 359.9 degrees, 0 being true North
 */
@property (nonatomic) CLLocationDirection course;

/**
 Returns the speed of the location in m/s. Negative if speed is invalid.
 */
@property (nonatomic) CLLocationSpeed speed;

/**
 Returns the timestamp when this location was determined.
 */
@property (nonatomic, copy) NSDate *timestamp;

/**
 This is a logical representation that will vary on definition from building-to-building.
 Floor 0 will always represent the floor designated as "ground".
 This number may be negative to designate floors below the ground floor
 and positive to indicate floors above the ground floor.
 It is not intended to match any numbering that might actually be used in the building.
 It is erroneous to use as an estimate of altitude.
 */
@property (nonatomic) NSInteger floorLevel;

/**
 Returns whether or not the floor level is valid. If the floor is unknown, then this will 
 be `false` and the `floorLevel` should be ignored.
 */
@property (nonatomic) BOOL isValidFloorLevel;

/**
 Returns a new relative location from the json coding object returned by encoding the `CLLocation`.
 
 @param codingObject    The coding object to use to initialize the relative location object.
 
 @return A new relative location object.
 */
- (instancetype)initWithCodingObject:(NSDictionary<NSString *, id> *)codingObject NS_DESIGNATED_INITIALIZER;

/**
 Convert the relative location to a json coding object.
 
 @return    JSON object
 */
- (NSDictionary<NSString *, id> *)ork_jsonCodingObject;

@end

NS_ASSUME_NONNULL_END
