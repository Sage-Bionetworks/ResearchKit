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


#import "HKDevice+JSONCodingObject.h"

#import "ORKCodingObjects.h"


@implementation HKDevice (ORKJSONCodingObject)

- (NSDictionary<NSString *, id> *)ork_jsonCodingObject {
    return [self ork_jsonCodingObjectIncludingIdentifiers:NO];
}

- (NSDictionary<NSString *, id> *)ork_jsonCodingObjectIncludingIdentifiers:(BOOL)includingIdentifiers {
    
    NSMutableDictionary *codingObject = [NSMutableDictionary new];
    if (self.name) {
        codingObject[NSStringFromSelector(@selector(name))] = self.name;
    }
    if (self.manufacturer) {
        codingObject[NSStringFromSelector(@selector(manufacturer))] = self.manufacturer;
    }
    if (self.model) {
        codingObject[NSStringFromSelector(@selector(model))] = self.model;
    }
    if (self.hardwareVersion) {
        codingObject[NSStringFromSelector(@selector(hardwareVersion))] = self.hardwareVersion;
    }
    if (self.firmwareVersion) {
        codingObject[NSStringFromSelector(@selector(firmwareVersion))] = self.firmwareVersion;
    }
    if (self.softwareVersion) {
        codingObject[NSStringFromSelector(@selector(softwareVersion))] = self.softwareVersion;
    }
    if (includingIdentifiers && self.localIdentifier) {
        codingObject[NSStringFromSelector(@selector(localIdentifier))] = self.localIdentifier;
    }
    if (includingIdentifiers && self.UDIDeviceIdentifier) {
        codingObject[NSStringFromSelector(@selector(UDIDeviceIdentifier))] = self.UDIDeviceIdentifier;
    }
    
    return [codingObject copy];
}

+ (nullable instancetype)deviceWithCodingObject:(NSDictionary<NSString *, id> *)codingObject {
    
    NSString *name = codingObject[NSStringFromSelector(@selector(name))];
    NSString *manufacturer = codingObject[NSStringFromSelector(@selector(manufacturer))];
    NSString *model = codingObject[NSStringFromSelector(@selector(model))];
    NSString *hardwareVersion = codingObject[NSStringFromSelector(@selector(hardwareVersion))];
    NSString *firmwareVersion = codingObject[NSStringFromSelector(@selector(firmwareVersion))];
    NSString *softwareVersion = codingObject[NSStringFromSelector(@selector(softwareVersion))];
    NSString *localIdentifier = codingObject[NSStringFromSelector(@selector(localIdentifier))];
    NSString *UDIDeviceIdentifier = codingObject[NSStringFromSelector(@selector(UDIDeviceIdentifier))];
    
    return [[self alloc] initWithName:name
                         manufacturer:manufacturer
                                model:model
                      hardwareVersion:hardwareVersion
                      firmwareVersion:firmwareVersion
                      softwareVersion:softwareVersion
                      localIdentifier:localIdentifier
                  UDIDeviceIdentifier:UDIDeviceIdentifier];
}

@end
