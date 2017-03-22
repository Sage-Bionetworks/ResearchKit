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


#import "ORKWorkoutResult.h"

#import "ORKResult_Private.h"
#import "ORKHelpers_Internal.h"


@implementation ORKWorkoutResult

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORK_ENCODE_OBJ(aCoder, error);
    ORK_ENCODE_OBJ(aCoder, device);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORK_DECODE_OBJ_CLASS(aDecoder, error, NSError);
        ORK_DECODE_OBJ_CLASS(aDecoder, device, ORKDevice);
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
            ORKEqualObjects(self.error, castObject.error) &&
            ORKEqualObjects(self.device, castObject.device));
}

- (NSUInteger)hash {
    return super.hash ^ self.error.hash ^ self.device.hash;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    __typeof(self) result = [super copyWithZone:zone];
    result.error = self.error;
    result.device = self.device;
    return result;
}

- (NSString *)descriptionWithNumberOfPaddingSpaces:(NSUInteger)numberOfPaddingSpaces {
    return [NSString stringWithFormat:@"%@; device: %@; error: %@", [super descriptionPrefixWithNumberOfPaddingSpaces:numberOfPaddingSpaces], self.device, self.error];
}

@end


@implementation ORKDevice

+ (instancetype)new {
    ORKThrowMethodUnavailableException();
}

- (instancetype)init {
    ORKThrowMethodUnavailableException();
}

- (instancetype)initWithDevice:(HKDevice *)healthKitDevice {
    return [self initWithName:healthKitDevice.name
                 manufacturer:healthKitDevice.manufacturer
                        model:healthKitDevice.model
              hardwareVersion:healthKitDevice.hardwareVersion
              softwareVersion:healthKitDevice.softwareVersion];
}

- (instancetype)initWithName:(nullable NSString *)name
                manufacturer:(nullable NSString *)manufacturer
                       model:(nullable NSString *)model
             hardwareVersion:(nullable NSString *)hardwareVersion
             softwareVersion:(nullable NSString *)softwareVersion {
    self = [super init];
    if (self) {
        _name = [name copy];
        _model = [model copy];
        _manufacturer = [manufacturer copy];
        _softwareVersion = [softwareVersion copy];
        _hardwareVersion = [hardwareVersion copy];
    }
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    ORK_ENCODE_OBJ(aCoder, name);
    ORK_ENCODE_OBJ(aCoder, model);
    ORK_ENCODE_OBJ(aCoder, manufacturer);
    ORK_ENCODE_OBJ(aCoder, softwareVersion);
    ORK_ENCODE_OBJ(aCoder, hardwareVersion);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        ORK_DECODE_OBJ_CLASS(aDecoder, name, NSString);
        ORK_DECODE_OBJ_CLASS(aDecoder, model, NSString);
        ORK_DECODE_OBJ_CLASS(aDecoder, manufacturer, NSString);
        ORK_DECODE_OBJ_CLASS(aDecoder, softwareVersion, NSString);
        ORK_DECODE_OBJ_CLASS(aDecoder, hardwareVersion, NSString);
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    if ([self class] != [object class]) {
        return NO;
    }
    
    __typeof(self) castObject = object;
    return (ORKEqualObjects(self.name, castObject.name)
            && ORKEqualObjects(self.model, castObject.model)
            && ORKEqualObjects(self.manufacturer, castObject.manufacturer)
            && ORKEqualObjects(self.softwareVersion, castObject.softwareVersion)
            && ORKEqualObjects(self.hardwareVersion, castObject.hardwareVersion));
}

- (NSUInteger)hash {
    return _name.hash ^ _model.hash ^ _manufacturer.hash ^ _softwareVersion.hash ^ _hardwareVersion.hash;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    __typeof(self) device = [[[self class] allocWithZone:zone] initWithName:self.name
                                                               manufacturer:self.manufacturer
                                                                      model:self.model
                                                            hardwareVersion:self.hardwareVersion
                                                            softwareVersion:self.softwareVersion];
    return device;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"name: %@, model: %@, manufacturer: %@, softwareVersion: %@, hardwareVersion: %@", self.name, self.model, self.manufacturer, self.softwareVersion, self.hardwareVersion];
}

@end
