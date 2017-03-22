/*
 Copyright (c) 2017, Roland Rabien. All rights reserved.
 
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


#import "ORKGoNoGoResult.h"

#import "ORKResult_Private.h"
#import "ORKHelpers_Internal.h"


@implementation ORKGoNoGoResult

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORK_ENCODE_DOUBLE(aCoder, timestamp);
    ORK_ENCODE_DOUBLE(aCoder, timeToThreshold);
    ORK_ENCODE_BOOL(aCoder, go);
    ORK_ENCODE_BOOL(aCoder, incorrect);
    ORK_ENCODE_OBJ(aCoder, samples);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORK_DECODE_DOUBLE(aDecoder, timestamp);
        ORK_DECODE_DOUBLE(aDecoder, timeToThreshold);
        ORK_DECODE_BOOL(aDecoder, go);
        ORK_DECODE_BOOL(aDecoder, incorrect);
        ORK_DECODE_OBJ_ARRAY(aDecoder, samples, ORKGoNoGoSample);
    }
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame &&
            (self.timestamp == castObject.timestamp) &&
            (self.timeToThreshold == castObject.timeToThreshold) &&
            (self.go == castObject.go) &&
            (self.incorrect == castObject.incorrect) &&
            ORKEqualObjects(self.samples, castObject.samples));
}

- (NSUInteger)hash {
    return super.hash ^ [NSNumber numberWithDouble:self.timestamp].hash ^ self.go ^ self.incorrect ^ self.samples.hash;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORKGoNoGoResult *result = [super copyWithZone:zone];
    result.timestamp = self.timestamp;
    result.timeToThreshold = self.timeToThreshold;
    result.go = self.go;
    result.incorrect = self.incorrect;
    result.samples = [self.samples copy];
    return result;
}

- (NSString *)descriptionWithNumberOfPaddingSpaces:(NSUInteger)numberOfPaddingSpaces {
    return [NSString stringWithFormat:@"%@; go: %@; error: %@; timestamp: %f; timeToThreshold: %f; %@", [self descriptionPrefixWithNumberOfPaddingSpaces:numberOfPaddingSpaces], self.go ? @"YES" : @"NO", self.incorrect ? @"YES" : @"NO", self.timestamp, self.timeToThreshold, self.descriptionSuffix];
}

@end


@implementation ORKGoNoGoSample

- (void)encodeWithCoder:(NSCoder *)aCoder {
    ORK_ENCODE_DOUBLE(aCoder, timestamp);
    ORK_ENCODE_DOUBLE(aCoder, vectorMagnitude);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        ORK_DECODE_DOUBLE(aDecoder, timestamp);
        ORK_DECODE_DOUBLE(aDecoder, vectorMagnitude);
    }
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (BOOL)isEqual:(id)object {
    if ([self class] != [object class]) {
        return NO;
    }
    
    __typeof(self) castObject = object;
    
    return ((self.timestamp == castObject.timestamp) &&
            (self.vectorMagnitude == castObject.vectorMagnitude));
}

- (NSUInteger)hash {
    return super.hash ^ [NSNumber numberWithDouble:self.timestamp].hash ^ [NSNumber numberWithDouble:self.vectorMagnitude].hash;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORKGoNoGoSample *result = [[[self class] allocWithZone:zone] init];
    result.timestamp = self.timestamp;
    result.vectorMagnitude = self.vectorMagnitude;
    return result;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p; timestamp: %.03f; magnitude: %.03f;>", self.class.description, self, self.timestamp, self.vectorMagnitude];
}

@end
