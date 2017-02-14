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

#import "ORKHeartRateDeviceNotFoundStep.h"

#import "ORKStep_Private.h"
#import "ORKWorkoutStep_Private.h"

#import "ORKAnswerFormat.h"
#import "ORKHelpers_Internal.h"

@implementation ORKHeartRateDeviceNotFoundStep

- (instancetype)initWithIdentifier:(NSString *)identifier
                        deviceName:(nullable NSString *)deviceName
                            result:(nullable ORKTaskResult *)taskResult {
    self = [self initWithIdentifier:identifier];
    if (self) {
        self.title = [NSString localizedStringWithFormat:ORKLocalizedString(@"HEARTRATE_MONITOR_DEVICE_NOT_FOUND_TITLE_%@", nil), deviceName];
        self.text = [NSString localizedStringWithFormat:ORKLocalizedString(@"HEARTRATE_MONITOR_DEVICE_NOT_FOUND_TEXT_%@", nil), deviceName];
        

        ORKTextChoice *useCameraChoice = [ORKTextChoice choiceWithText:ORKLocalizedString(@"HEARTRATE_MONITOR_CAMERA_INSTRUCTION_TITLE", nil) value:@YES];
        
        NSString *useWatchText = [NSString localizedStringWithFormat:
                                   ORKLocalizedString(@"HEARTRATE_MONITOR_DEVICE_NOT_FOUND_TRY_AGAIN_%@", nil), deviceName];
        ORKTextChoice *useWatchChoice = [ORKTextChoice choiceWithText:useWatchText value:@NO];
        
        self.answerFormat = [ORKAnswerFormat choiceAnswerFormatWithStyle:ORKChoiceAnswerStyleSingleChoice textChoices:
                             @[useCameraChoice, useWatchChoice]];
        self.optional = NO;
        self.useSurveyMode = NO;
    }
    return self;
}

@end
