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


#import "CMDeviceMotion+ORKJSONDictionary.h"


@implementation CMDeviceMotion (ORKJSONDictionary)

- (NSDictionary *)ork_JSONDictionary {
    return [self ork_JSONDictionaryWithTimestamp:self.timestamp consolidated:NO];
}

- (NSDictionary *)ork_JSONDictionaryWithTimestamp:(NSTimeInterval)timestamp consolidated:(BOOL)consolidated {
    CMQuaternion attitude = self.attitude.quaternion;
    CMRotationRate rotationRate = self.rotationRate;
    CMAcceleration gravity = self.gravity;
    CMAcceleration userAccel = self.userAcceleration;
    CMCalibratedMagneticField field = self.magneticField;
    
    if (!consolidated) {
    NSDictionary *dictionary = @{@"timestamp": [NSDecimalNumber numberWithDouble:timestamp],
                                 @"attitude": @{
                                         @"x": [NSDecimalNumber numberWithDouble:attitude.x],
                                         @"y": [NSDecimalNumber numberWithDouble:attitude.y],
                                         @"z": [NSDecimalNumber numberWithDouble:attitude.z],
                                         @"w": [NSDecimalNumber numberWithDouble:attitude.w]
                                         },
                                 @"rotationRate": @{
                                         @"x": [NSDecimalNumber numberWithDouble:rotationRate.x],
                                         @"y": [NSDecimalNumber numberWithDouble:rotationRate.y],
                                         @"z": [NSDecimalNumber numberWithDouble:rotationRate.z]
                                         },
                                 @"gravity": @{
                                         @"x": [NSDecimalNumber numberWithDouble:gravity.x],
                                         @"y": [NSDecimalNumber numberWithDouble:gravity.y],
                                         @"z": [NSDecimalNumber numberWithDouble:gravity.z]
                                         },
                                 @"userAcceleration": @{
                                         @"x": [NSDecimalNumber numberWithDouble:userAccel.x],
                                         @"y": [NSDecimalNumber numberWithDouble:userAccel.y],
                                         @"z": [NSDecimalNumber numberWithDouble:userAccel.z]
                                         },
                                 @"magneticField": @{
                                         @"x": [NSDecimalNumber numberWithDouble:field.field.x],
                                         @"y": [NSDecimalNumber numberWithDouble:field.field.y],
                                         @"z": [NSDecimalNumber numberWithDouble:field.field.z],
                                         @"accuracy": [NSDecimalNumber numberWithDouble:field.accuracy]
                                         }
                                 };
        return dictionary;
        
    } else {
        // The schema should flatten the data into a consolidated format
        NSDictionary *dictionary = @{@"timestamp": [NSDecimalNumber numberWithDouble:timestamp],
                                     @"attitude_x": [NSDecimalNumber numberWithDouble:attitude.x],
                                     @"attitude_y": [NSDecimalNumber numberWithDouble:attitude.y],
                                     @"attitude_z": [NSDecimalNumber numberWithDouble:attitude.z],
                                     @"attitude_w": [NSDecimalNumber numberWithDouble:attitude.w],
                                     @"rotationRate_x": [NSDecimalNumber numberWithDouble:rotationRate.x],
                                     @"rotationRate_y": [NSDecimalNumber numberWithDouble:rotationRate.y],
                                     @"rotationRate_z": [NSDecimalNumber numberWithDouble:rotationRate.z],
                                     @"gravity_x": [NSDecimalNumber numberWithDouble:gravity.x],
                                     @"gravity_y": [NSDecimalNumber numberWithDouble:gravity.y],
                                     @"gravity_z": [NSDecimalNumber numberWithDouble:gravity.z],
                                     @"userAcceleration_x": [NSDecimalNumber numberWithDouble:userAccel.x],
                                     @"userAcceleration_y": [NSDecimalNumber numberWithDouble:userAccel.y],
                                     @"userAcceleration_z": [NSDecimalNumber numberWithDouble:userAccel.z],
                                     @"magneticField_x": [NSDecimalNumber numberWithDouble:field.field.x],
                                     @"magneticField_y": [NSDecimalNumber numberWithDouble:field.field.y],
                                     @"magneticField_z": [NSDecimalNumber numberWithDouble:field.field.z],
                                     @"magneticField_accuracy": [NSDecimalNumber numberWithDouble:field.accuracy]
                                     };
        return dictionary;
    }
}

@end
