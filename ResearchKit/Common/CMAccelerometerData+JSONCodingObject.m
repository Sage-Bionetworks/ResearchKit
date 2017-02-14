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


#import "CMAccelerometerData+JSONCodingObject.h"

#import "ORKHelpers_Internal.h"


@implementation CMAccelerometerData (ORKJSONDictionary)

- (NSDictionary<NSString *, id> *)ork_jsonCodingObject {
    NSDictionary *dictionary = @{@"timestamp": [NSDecimalNumber numberWithDouble:self.timestamp],
                                 @"x": [NSDecimalNumber numberWithDouble:self.acceleration.x],
                                 @"y": [NSDecimalNumber numberWithDouble:self.acceleration.y],
                                 @"z": [NSDecimalNumber numberWithDouble:self.acceleration.z]
                                 };
    return dictionary;
}

@end


@implementation ORKAccelerometerData

- (NSDictionary<NSString *, id> *)ork_jsonCodingObject {
    NSDictionary *dictionary = @{@"timestamp": [NSDecimalNumber numberWithDouble:self.timestamp],
                                 @"x": [NSDecimalNumber numberWithDouble:self.acceleration.x],
                                 @"y": [NSDecimalNumber numberWithDouble:self.acceleration.y],
                                 @"z": [NSDecimalNumber numberWithDouble:self.acceleration.z]
                                 };
    return dictionary;
}

- (void)ork_commonInit:(NSDictionary<NSString *, id> *)codingObject {
    _timestamp = [codingObject[@"timestamp"] doubleValue];
    _acceleration.x = [codingObject[@"x"] doubleValue];
    _acceleration.y = [codingObject[@"y"] doubleValue];
    _acceleration.z = [codingObject[@"z"] doubleValue];
}

- (instancetype)init {
    return [self initWithCodingObject:@{ @"timestamp" : @(0) }];
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
