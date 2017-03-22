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


#import "HKQuantitySample+JSONCodingObject.h"

#import "ORKCodingObjects.h"

#import "ORKHelpers_Internal.h"

#import <ResearchKit/ResearchKit-Swift.h>


static NSString *const HKSampleIdentifierKey = @"type"; // For compatibility with Health XML export
static NSString *const HKSampleStartDateKey = @"startDate";
static NSString *const HKSampleEndDateKey = @"endDate";
static NSString *const HKSampleValue = @"value";
static NSString *const HKMetadataKey = @"metadata";
static NSString *const HKDeviceKey = @"device";
static NSString *const HKUnitKey = @"unit";

@implementation  HKUnit (ORKJSONCodingObject)

+ (HKUnit *)ork_encodingUnitForQuantityType:(HKQuantityType *)quantityType {
    
    NSArray *unitTypes = @[[HKUnit gramUnit],
                           [HKUnit meterUnit],
                           [HKUnit literUnit],
                           [HKUnit pascalUnit],
                           [HKUnit secondUnit],
                           [HKUnit jouleUnit],
                           [HKUnit kelvinUnit],
                           [HKUnit siemenUnit],
                           [HKUnit countUnit],
                           [HKUnit percentUnit],
                           [HKUnit bpmUnit]
                           ];
    for (HKUnit *unit in unitTypes) {
        if ([quantityType isCompatibleWithUnit:unit]) {
            return unit;
        }
    }
    return [HKUnit unitFromString:@""];
}

@end


@implementation HKQuantitySample (ORKJSONCodingObject)

/**
 Convert the quantity sample into a coded object that can be passed from the watch to the phone
 using the `sendMessage:` method.
 
 @return A dictionary with the properties of the error
 */
- (NSDictionary<NSString *, id> *)ork_jsonCodingObject {
    
    NSMutableDictionary *codingObject = [NSMutableDictionary new];
    codingObject[HKSampleIdentifierKey] = self.quantityType.identifier;
    codingObject[HKSampleStartDateKey] = ORKStringFromDateISO8601(self.startDate);
    codingObject[HKSampleEndDateKey] = ORKStringFromDateISO8601(self.endDate);
    
    HKUnit *unit = [HKUnit ork_encodingUnitForQuantityType: self.quantityType];
    codingObject[HKUnitKey] = unit.unitString;
    codingObject[HKSampleValue] = @([self.quantity doubleValueForUnit:unit]);
    
    if (self.device) {
        codingObject[HKDeviceKey] = [self.device ork_jsonCodingObject];
    }
    if (self.metadata) {
        codingObject[HKMetadataKey] = self.metadata;
    }
    
    return [codingObject copy];
}

+ (nullable instancetype)quantitySampleWithCodingObject:(NSDictionary<NSString *, id> *)codingObject {
    
    NSString *quantityTypeIdentifier = codingObject[HKSampleIdentifierKey];
    NSString *startDateString = codingObject[HKSampleStartDateKey];
    NSString *endDateString = codingObject[HKSampleEndDateKey];
    NSString *unitString = codingObject[HKUnitKey];
    NSNumber *quantityValue = codingObject[HKSampleValue];
    NSDictionary<NSString *, id> *deviceCodingObject = codingObject[HKDeviceKey];
    NSDictionary<NSString *, id> *metadata = codingObject[HKMetadataKey];
    
    if (![quantityTypeIdentifier isKindOfClass:[NSString class]] ||
        ![startDateString isKindOfClass:[NSString class]] ||
        ![endDateString isKindOfClass:[NSString class]] ||
        ![quantityValue isKindOfClass:[NSNumber class]] ||
        ![unitString isKindOfClass:[unitString class]]) {
        return nil;
    }
    
    HKQuantityType *quantityType = [HKObjectType quantityTypeForIdentifier:quantityTypeIdentifier];
    HKUnit *unit = [HKUnit unitFromString:unitString];
    HKQuantity *quantity = [HKQuantity quantityWithUnit:unit doubleValue:[quantityValue doubleValue]];
    HKDevice *device = (deviceCodingObject != nil) ? [HKDevice deviceWithCodingObject:deviceCodingObject] : nil;
    
    return [self quantitySampleWithType:quantityType
                               quantity:quantity
                              startDate:ORKDateFromStringISO8601(startDateString)
                                endDate:ORKDateFromStringISO8601(endDateString)
                                 device:device
                               metadata:metadata];
}

+ (NSArray<HKQuantitySample *> *)quantitySamplesWithArray:(NSArray *)codingObjects {
    NSMutableArray *samples = [NSMutableArray new];
    for (NSDictionary *obj in codingObjects) {
        [samples addObject:[self quantitySampleWithCodingObject:obj]];
    }
    return [samples copy];
}

@end
