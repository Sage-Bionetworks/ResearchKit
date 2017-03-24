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


#import "CLLocation+ORKJSONDictionary.h"

#import "ORKHelpers_Internal.h"


double DegreesToRadians(double degrees) {return degrees * M_PI / 180.0;};
double RadiansToDegrees(double radians) {return radians * 180.0 / M_PI;};

@implementation CLLocation (ORKJSONDictionary)

- (NSDictionary *)ork_JSONDictionary {
    return [self ork_JSONDictionaryWithRelativeDistanceOnly:NO previous:nil timestamp:nil];
}

- (NSDictionary<NSString *, id> *)ork_JSONDictionaryWithRelativeDistanceOnly:(BOOL)relativeDistanceOnly previous:(nullable CLLocation *)previous timestamp:(id)timestamp {
    
    CLLocationCoordinate2D coord = self.coordinate;
    CLLocationDistance altitude = self.altitude;
    CLLocationAccuracy horizAccuracy = self.horizontalAccuracy;
    CLLocationAccuracy vertAccuracy = self.verticalAccuracy;
    CLLocationDirection course = self.course;
    CLLocationSpeed speed = self.speed;
    CLFloor *floor = self.floor;
    
    if (!timestamp) {
        timestamp = ORKStringFromDateISO8601(self.timestamp);
    }
    NSMutableDictionary *dictionary = [@{@"timestamp": timestamp} mutableCopy];
    
    if (horizAccuracy >= 0) {
        BOOL validPrevious = (previous != nil) && (previous.horizontalAccuracy >= 0);
        CLLocationDistance relativeDistance = validPrevious ? [self distanceFromLocation:previous] : 0;
        CLLocationDirection bearing = validPrevious ? [self bearingFromLocation:previous] : 0;
        dictionary[@"relativeDistance"] = [NSDecimalNumber numberWithDouble:relativeDistance];
        dictionary[@"relativeBearing"] = [NSDecimalNumber numberWithDouble:bearing];
        if (!relativeDistanceOnly) {
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

- (CLLocationDirection)bearingFromLocation:(CLLocation *)previousLocation {
    
    double lat1 = DegreesToRadians(previousLocation.coordinate.latitude);
    double lon1 = DegreesToRadians(previousLocation.coordinate.longitude);
    
    double lat2 = DegreesToRadians(self.coordinate.latitude);
    double lon2 = DegreesToRadians(self.coordinate.longitude);
    
    double dLon = lon2 - lon1;
    
    double y = sin(dLon) * cos(lat2);
    double x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
    double radiansBearing = atan2(y, x);
    
    if (radiansBearing < 0.0) {
        radiansBearing += 2 * M_PI;
    }

    return RadiansToDegrees(radiansBearing);
}

@end

