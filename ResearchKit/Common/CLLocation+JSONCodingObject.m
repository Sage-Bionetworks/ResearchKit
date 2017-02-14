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


#import "CLLocation+JSONCodingObject.h"

#import "ORKHelpers_Internal.h"

double DegreesToRadians(double degrees) {return degrees * M_PI / 180.0;};
double RadiansToDegrees(double radians) {return radians * 180.0/M_PI;};

@implementation CLLocation (ORKJSONCodingObject)

- (NSDictionary *)ork_jsonCodingObject {
    return [self ork_jsonCodingObjectWithRelativeDistanceOnly:NO previous:nil];
}

- (NSDictionary *)ork_jsonCodingObjectWithRelativeDistanceOnly:(BOOL)relativeDistanceOnly previous:(nullable CLLocation *)previous {
    CLLocationCoordinate2D coord = self.coordinate;
    CLLocationDistance altitude = self.altitude;
    CLLocationAccuracy horizAccuracy = self.horizontalAccuracy;
    CLLocationAccuracy vertAccuracy = self.verticalAccuracy;
    CLLocationDirection course = self.course;
    CLLocationSpeed speed = self.speed;
    NSDate *timestamp = self.timestamp;
    CLFloor *floor = self.floor;
    
    NSMutableDictionary *dictionary = [@{@"timestamp": ORKStringFromDateISO8601(timestamp)} mutableCopy];
    
    if (horizAccuracy >= 0) {
        if (relativeDistanceOnly) {
            BOOL validPrevious = (previous != nil) && (previous.horizontalAccuracy >= 0);
            CLLocationDistance distance = validPrevious ? [self distanceFromLocation:previous] : 0;
            CLLocationDirection bearing = validPrevious ? [self bearingFromLocation:previous] : 0;
            dictionary[@"distance"] = [NSDecimalNumber numberWithDouble:distance];
            dictionary[@"bearing"] = [NSDecimalNumber numberWithDouble:bearing];
        } else {
            dictionary[@"coordinate"] = @{ @"latitude": [NSDecimalNumber numberWithDouble:coord.latitude],
                                           @"longitude": [NSDecimalNumber numberWithDouble:coord.longitude]};
        }
        dictionary[@"horizontalAccuracy"] = [NSDecimalNumber numberWithDouble:horizAccuracy];
    }
    if (vertAccuracy >= 0) {
        dictionary[@"altitude"] = [NSDecimalNumber numberWithDouble:altitude];
        dictionary[@"verticalAccuracy"] = [NSDecimalNumber numberWithDouble:vertAccuracy];
    }
    if (course >= 0) {
        dictionary[@"course"] = [NSDecimalNumber numberWithDouble:course];
    }
    if (speed >= 0) {
        dictionary[@"speed"] = [NSDecimalNumber numberWithDouble:speed];
    }
    if (floor) {
        dictionary[@"floor"] = @(floor.level);
    }

    return dictionary;
}

- (double)bearingFromLocation:(CLLocation *)previousLocation {
    
    double lat1 = DegreesToRadians(previousLocation.coordinate.latitude);
    double lon1 = DegreesToRadians(previousLocation.coordinate.longitude);
    
    double lat2 = DegreesToRadians(self.coordinate.latitude);
    double lon2 = DegreesToRadians(self.coordinate.longitude);
    
    double dLon = lon2 - lon1;
    
    double y = sin(dLon) * cos(lat2);
    double x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
    double radiansBearing = atan2(y, x);
    
    if(radiansBearing < 0.0) {
        radiansBearing += 2 * M_PI;
    }

    return RadiansToDegrees(radiansBearing);
}

@end


@implementation ORKRelativeLocation

- (NSDictionary *)ork_jsonCodingObject {
    
    NSMutableDictionary *codingObject = [@{@"timestamp": ORKStringFromDateISO8601(self.timestamp)} mutableCopy];
    
    if (self.horizontalAccuracy >= 0) {
        codingObject[@"distance"] = [NSDecimalNumber numberWithDouble:self.distance];
        codingObject[@"bearing"] = [NSDecimalNumber numberWithDouble:self.bearing];
        codingObject[@"horizontalAccuracy"] = [NSDecimalNumber numberWithDouble:self.horizontalAccuracy];
    }
    if (self.verticalAccuracy >= 0) {
        codingObject[@"altitude"] = [NSDecimalNumber numberWithDouble:self.altitude];
        codingObject[@"verticalAccuracy"] = [NSDecimalNumber numberWithDouble:self.verticalAccuracy];
    }
    if (self.course >= 0) {
        codingObject[@"course"] = [NSDecimalNumber numberWithDouble:self.course];
    }
    if (self.speed >= 0) {
        codingObject[@"speed"] = [NSDecimalNumber numberWithDouble:self.speed];
    }
    if (self.isValidFloorLevel) {
        codingObject[@"floor"] = @(self.floorLevel);
    }
    
    return codingObject;
}

- (void)ork_commonInit:(NSDictionary<NSString *, id> *)codingObject {
    
    _timestamp = ORKDateFromStringISO8601(codingObject[@"timestamp"]);
    
    NSNumber *horizontalAccuracy = codingObject[@"horizontalAccuracy"];
    _horizontalAccuracy = [horizontalAccuracy isKindOfClass:[NSNumber class]] ? [horizontalAccuracy doubleValue] : -1;
    _distance = [codingObject[@"distance"] doubleValue];
    _bearing = [codingObject[@"bearing"] doubleValue];
    
    NSNumber *verticalAccuracy = codingObject[@"verticalAccuracy"];
    _verticalAccuracy = [verticalAccuracy isKindOfClass:[NSNumber class]] ? [verticalAccuracy doubleValue] : -1;
    _altitude = [codingObject[@"altitude"] doubleValue];
    
    NSNumber *course = codingObject[@"course"];
    _course = [course isKindOfClass:[NSNumber class]] ? [course doubleValue] : -1;
    
    NSNumber *speed = codingObject[@"speed"];
    _speed = [speed isKindOfClass:[NSNumber class]] ? [speed doubleValue] : -1;
    
    NSNumber *floor = codingObject[@"floor"];
    _floorLevel = [floor doubleValue];
    _isValidFloorLevel = (floor != nil);
}

- (instancetype)init {
    return [self initWithCodingObject:@{ @"timestamp" : ORKStringFromDateISO8601([NSDate date]) }];
}

- (instancetype)initWithCodingObject:(NSDictionary<NSString *, id> *)codingObject {
    self = [super init];
    if (self) {
        [self ork_commonInit:codingObject];
    }
    return self;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    return [[[self class] allocWithZone:zone] initWithCodingObject:[self ork_jsonCodingObject]];
}

- (BOOL)isEqual:(id)object {
    if ([self class] != [object class]) {
        return NO;
    }
    __typeof(self) castObject = object;
    return [[self ork_jsonCodingObject] isEqual:[castObject ork_jsonCodingObject]];
}

- (NSUInteger)hash {
    // Ignore the task reference - it's not part of the content of the step.
    return [[self ork_jsonCodingObject] hash];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ %@", [super description], [self ork_jsonCodingObject]];
}


@end

