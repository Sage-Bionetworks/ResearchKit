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


#import "ORKPermissionsValidator.h"

NSString * const ORK_NSMotionUsageDescription = @"NSMotionUsageDescription";
NSString * const ORK_NSMicrophoneUsageDescription = @"NSMicrophoneUsageDescription";
NSString * const ORK_NSLocationWhenInUseUsageDescription = @"NSLocationWhenInUseUsageDescription";
NSString * const ORK_NSLocationAlwaysUsageDescription = @"NSLocationAlwaysUsageDescription";
NSString * const ORK_NSCameraUsageDescription = @"NSCameraUsageDescription";
NSString * const ORK_NSHealthShareUsageDescription = @"NSHealthShareUsageDescription";
NSString * const ORK_NSHealthUpdateUsageDescription = @"NSHealthUpdateUsageDescription";

@implementation ORKPermissionsValidator

+ (NSString *)findBundleKey:(NSString*)key error:(NSError **)error {
    
    // Look for the string in the info.plist and if not found then return error
    NSDictionary *info = [[NSBundle mainBundle] localizedInfoDictionary] ? : [[NSBundle mainBundle] infoDictionary];
    NSString *str = info[key];
    
    // Create the error if not found
    if (![str isKindOfClass:[NSString class]] && error) {
        NSString *reason = [NSString stringWithFormat:@"Missing required Info.plist key: %@", key];
        NSString *description = [NSString stringWithFormat:@"'%@' is a required key for the authorizations you have requested. See https://developer.apple.com/library/content/documentation/General/Reference/InfoPlistKeyReference/Articles/CocoaKeys.html", key];
        *error = [NSError errorWithDomain:NSCocoaErrorDomain code:1 userInfo:@{NSLocalizedFailureReasonErrorKey : reason,
                                                                               NSLocalizedDescriptionKey : description}];
        str = nil;
    }
    
    return str;
}

+ (BOOL)validatePermissions:(ORKPermissionMask)permissions
                 writeTypes:(nullable NSSet<HKSampleType *> *)typesToWrite
                  readTypes:(nullable NSSet<HKObjectType *> *)typesToRead
                      error:(NSError **)error {
    
    // NOTE: if statements are intentionally nested for clarity where if the permission isn't
    // included, then don't look for the key in the Info.plist (or any other validation that may
    // be useful to include here)
    
    if ((permissions & ORKPermissionCoreMotionActivity) ||
        (permissions & ORKPermissionCoreMotionAccelerometer)) {
        if (![self findBundleKey:ORK_NSMotionUsageDescription error:error]) {
            return NO;
        }
    }
    
    if ((permissions & ORKPermissionAudioRecording)) {
        if (![self findBundleKey:ORK_NSMicrophoneUsageDescription error:error]) {
            return NO;
        }
    }
    
    if ((permissions & ORKPermissionCoreLocation)) {
        if (![self findBundleKey:ORK_NSLocationWhenInUseUsageDescription error:error] &&
            ![self findBundleKey:ORK_NSLocationAlwaysUsageDescription error:error]) {
            return NO;
        }
    }

    if ((permissions & ORKPermissionCamera)) {
        if (![self findBundleKey:ORK_NSCameraUsageDescription error:error]) {
            return NO;
        }
    }
    
    if (typesToRead) {
        if (![self findBundleKey:ORK_NSHealthShareUsageDescription error:error]) {
            return NO;
        }
    }
    
    if (typesToWrite) {
        if (![self findBundleKey:ORK_NSHealthUpdateUsageDescription error:error]) {
            return NO;
        }
    }
    
    return YES;
}

@end
