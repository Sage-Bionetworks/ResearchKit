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

#import "ORKWorkoutMessage.h"
#import <objc/runtime.h>

#import "ORKHelpers_Internal.h"

ORKWorkoutState const ORKWorkoutStateNotStarted = @"notStarted";
ORKWorkoutState const ORKWorkoutStateStarting = @"starting";
ORKWorkoutState const ORKWorkoutStateRunning = @"running";
ORKWorkoutState const ORKWorkoutStateStopping = @"stopping";
ORKWorkoutState const ORKWorkoutStateEnded = @"ended";
ORKWorkoutState const ORKWorkoutStatePaused = @"paused";

ORKWorkoutCommand const ORKWorkoutCommandStop = @"stop";
ORKWorkoutCommand const ORKWorkoutCommandPause = @"pause";
ORKWorkoutCommand const ORKWorkoutCommandResume = @"resume";
ORKWorkoutCommand const ORKWorkoutCommandStartMoving = @"startMoving";
ORKWorkoutCommand const ORKWorkoutCommandStopMoving = @"stopMoving";
ORKWorkoutCommand const ORKWorkoutCommandPing = @"ping";

NSString * const ORKClassTypeKey = @"classType";

@implementation ORKWorkoutMessage

+ (instancetype)workoutMessageWithMessage:(NSDictionary<NSString *, id> *)message {
    NSString *classType = message[ORKClassTypeKey];
    Class aClass = (classType ? NSClassFromString(classType) : nil) ? : [self class];
    return [[aClass alloc] initWithDictionaryRepresentation:message];
}

- (instancetype)init {
    return [self initWithIdentifier:[[NSUUID UUID] UUIDString]];
}

- (instancetype)initWithIdentifier:(NSString *)identifier {
    if (self = [super init]) {
        [self ork_commonInitWithIdentifier:identifier dictionaryRepresentation:nil];
    }
    return self;
}

- (instancetype)initWithDictionaryRepresentation:(NSDictionary<NSString *, id> *)dictionary {
    if (self = [super init]) {
        [self ork_commonInitWithIdentifier:nil dictionaryRepresentation:dictionary];
    }
    return self;
}

- (void)ork_commonInitWithIdentifier:(NSString *)identifier dictionaryRepresentation:(NSDictionary *)dictionary {
    
    // Iterate through the keys, check that they are the expected incoming type set if true
    for (NSString *key in [self dictionaryRepresentationKeys]) {
        id value = dictionary[key];
        if (value && ![value isKindOfClass:[NSNull class]]) {
            Class expectedClass = [self serializableClassOfPropertyNamed:key];
            if (expectedClass && [value isKindOfClass:expectedClass]) {
                [self setValue:value forKey:key];
            }
        }
    }
    
    if (_identifier == nil) {
        _identifier = identifier ? : [[NSUUID UUID] UUIDString];
    }
    if (_timestamp == nil) {
        _timestamp = [NSDate date];
    }
}

- (Class)serializableClassOfPropertyNamed:(NSString*)propertyName {
    return [NSString class];
}

- (NSDictionary<NSString *, id> *)dictionaryRepresentation {
    
    NSArray *keys = [self dictionaryRepresentationKeys];
    NSMutableDictionary *dictionary = [[self dictionaryWithValuesForKeys:[self dictionaryRepresentationKeys]] mutableCopy];
    
    // Look at the dictionary and replace the objects that are coding objects with a serialized dictionary representation
    for (NSString *key in keys) {
        id value = dictionary[key];
        if ([value isKindOfClass:[NSNull class]]) {
            [dictionary removeObjectForKey:key];
        } else if ([value isKindOfClass:[NSDate class]]) {
            dictionary[key] = ORKStringFromDateISO8601(value);
        } else if ([value respondsToSelector:@selector(ork_jsonCodingObject)]) {
            dictionary[key] = [value ork_jsonCodingObject];
        } else if ([value isKindOfClass:[NSArray class]] &&
                   [[(NSArray*)value firstObject] respondsToSelector:@selector(ork_jsonCodingObject)]) {
            NSMutableArray *array = [NSMutableArray new];
            for (id obj in (NSArray*)value) {
                [array addObject:[obj ork_jsonCodingObject]];
            }
            dictionary[key] = [array copy];
        }
    }
    
    // Add the class type
    dictionary[ORKClassTypeKey] = NSStringFromClass([self class]);
    
    return [dictionary copy];
}

- (NSArray<NSString *> *)dictionaryRepresentationKeys {
    return @[NSStringFromSelector(@selector(identifier)),
             NSStringFromSelector(@selector(timestamp)),
             NSStringFromSelector(@selector(workoutState)),
             ];
}

- (void)setValue:(id)value forKey:(NSString *)key {
    if ([key isEqualToString:NSStringFromSelector(@selector(timestamp))] &&
        [value isKindOfClass:[NSString class]]) {
        _timestamp = ORKDateFromStringISO8601(value);
    } else {
        [super setValue:value forKey:key];
    }
}

#pragma mark - NSCoding, NSCopying, Equality

- (id)copyWithZone:(NSZone *)zone {
    id copy = [[[self class] allocWithZone:zone] initWithDictionaryRepresentation:[self dictionaryRepresentation]];
    return copy;
}

- (NSUInteger)hash {
    return [[self dictionaryRepresentation] hash];
}

- (BOOL)isEqual:(id)object {
    return [self isKindOfClass:[object class]] && [[self dictionaryRepresentation] isEqualToDictionary:[object dictionaryRepresentation]];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@", [self dictionaryRepresentation]];
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        ORK_DECODE_OBJ_CLASS(aDecoder, identifier, NSString);
        ORK_DECODE_OBJ_CLASS(aDecoder, timestamp, NSDate);
        ORK_DECODE_OBJ_CLASS(aDecoder, workoutState, NSString);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    ORK_ENCODE_OBJ(aCoder, identifier);
    ORK_ENCODE_OBJ(aCoder, timestamp);
    ORK_ENCODE_OBJ(aCoder, workoutState);
}

@end

@implementation ORKInstructionWorkoutMessage

- (NSArray<NSString *> *)dictionaryRepresentationKeys {
    return [[super dictionaryRepresentationKeys] arrayByAddingObjectsFromArray:@[
                                                                                 NSStringFromSelector(@selector(instruction)),
                                                                                 NSStringFromSelector(@selector(stepDuration)),
                                                                                 NSStringFromSelector(@selector(command)),
                                                                                 ]];
}

- (Class)serializableClassOfPropertyNamed:(NSString*)propertyName {
    if ([propertyName isEqualToString:NSStringFromSelector(@selector(stepDuration))]) {
        return [NSNumber class];
    } else {
        return [super serializableClassOfPropertyNamed:propertyName];
    }
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORK_DECODE_OBJ_CLASS(aDecoder, instruction, NSString);
        ORK_DECODE_OBJ_CLASS(aDecoder, command, NSString);
        ORK_DECODE_DOUBLE(aDecoder, stepDuration);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORK_ENCODE_OBJ(aCoder, instruction);
    ORK_ENCODE_OBJ(aCoder, command);
    ORK_ENCODE_DOUBLE(aCoder, stepDuration);
}

@end

@implementation ORKSamplesWorkoutMessage

- (NSArray<NSString *> *)dictionaryRepresentationKeys {
    return [[super dictionaryRepresentationKeys] arrayByAddingObjectsFromArray:@[
                                                                                 NSStringFromSelector(@selector(quantityTypeIdentifier)),
                                                                                 NSStringFromSelector(@selector(samples)),
                                                                                 ]];
}

- (Class)serializableClassOfPropertyNamed:(NSString*)propertyName {
    if ([propertyName isEqualToString:NSStringFromSelector(@selector(samples))]) {
        return [NSArray class];
    } else {
        return [super serializableClassOfPropertyNamed:propertyName];
    }
}

- (void)setValue:(id)value forKey:(NSString *)key {
    if ([key isEqualToString:NSStringFromSelector(@selector(samples))] &&
        [[(NSArray *)value firstObject] isKindOfClass:[NSDictionary class]]) {
        _samples = [HKQuantitySample quantitySamplesWithArray:value];
    } else {
        [super setValue:value forKey:key];
    }
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORK_DECODE_OBJ_CLASS(aDecoder, quantityTypeIdentifier, NSString);
        ORK_DECODE_OBJ_ARRAY(aDecoder, samples, HKQuantitySample);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORK_ENCODE_OBJ(aCoder, quantityTypeIdentifier);
    ORK_ENCODE_OBJ(aCoder, samples);
}

@end

@implementation ORKEventWorkoutMessage

- (NSArray<NSString *> *)dictionaryRepresentationKeys {
    return [[super dictionaryRepresentationKeys] arrayByAddingObjectsFromArray:@[
                                                                                 NSStringFromSelector(@selector(event)),
                                                                                 ]];
}

- (Class)serializableClassOfPropertyNamed:(NSString*)propertyName {
    if ([propertyName isEqualToString:NSStringFromSelector(@selector(event))]) {
        return [NSDictionary class];
    } else {
        return [super serializableClassOfPropertyNamed:propertyName];
    }
}

- (void)setValue:(id)value forKey:(NSString *)key {
    if ([key isEqualToString:NSStringFromSelector(@selector(event))] &&
        [value isKindOfClass:[NSDictionary class]]) {
        _event = [HKWorkoutEvent workoutEventWithCodingObject:value];
    } else {
        [super setValue:value forKey:key];
    }
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORK_DECODE_OBJ_CLASS(aDecoder, event, HKWorkoutEvent);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORK_ENCODE_OBJ(aCoder, event);
}

@end

@implementation ORKErrorWorkoutMessage

- (NSArray<NSString *> *)dictionaryRepresentationKeys {
    return [[super dictionaryRepresentationKeys] arrayByAddingObjectsFromArray:@[
                                                                                 NSStringFromSelector(@selector(error)),
                                                                                 ]];
}

- (Class)serializableClassOfPropertyNamed:(NSString*)propertyName {
    if ([propertyName isEqualToString:NSStringFromSelector(@selector(error))]) {
        return [NSDictionary class];
    } else {
        return [super serializableClassOfPropertyNamed:propertyName];
    }
}

- (void)setValue:(id)value forKey:(NSString *)key {
    if ([key isEqualToString:NSStringFromSelector(@selector(error))] &&
        [value isKindOfClass:[NSDictionary class]]) {
        _error = [NSError errorWithCodingObject:value];
    } else {
        [super setValue:value forKey:key];
    }
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORK_DECODE_OBJ_CLASS(aDecoder, error, NSError);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORK_ENCODE_OBJ(aCoder, error);
}

@end

