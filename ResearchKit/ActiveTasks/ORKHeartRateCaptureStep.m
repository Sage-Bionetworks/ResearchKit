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


#import "ORKHeartRateCaptureStep.h"

#import "ORKHeartRateCaptureStepViewController.h"

#import "ORKStep_Private.h"
#import "ORKWorkoutStep_Private.h"
#import "ORKFitnessStep_Internal.h"
#import "ORKRecorder.h"

#import "ORKHelpers_Internal.h"


@implementation ORKHeartRateCaptureStep

- (instancetype)initWithIdentifier:(NSString*)identifier {
    self = [super initWithIdentifier:identifier];
    if (self) {
        
        self.shouldStartTimerAutomatically = YES;
        self.shouldContinueOnFinish = YES;
        self.optional = NO;
        self.shouldStartTimerAutomatically = YES;
        self.shouldVibrateOnStart = YES;
        self.shouldPlaySoundOnStart = YES;
        self.shouldPlaySoundOnFinish = YES;
        self.shouldVibrateOnFinish = YES;
        self.beginCommand = ORKWorkoutCommandStopMoving;
        self.standingStill = YES;
        self.beforeWorkout = YES;
        
        self.title = ORKLocalizedString(@"HEARTRATE_MONITOR_CAMERA_STAND_STILL_TITLE", nil);
        self.text = ORKLocalizedString(@"HEARTRATE_MONITOR_CAMERA_CONTINUE_TEXT", nil);
        self.watchInstruction = ORKLocalizedString(@"FITNESS_STAND_INSTRUCTION_WATCH", nil);
        
        ORKHeartRateCameraRecorderConfiguration *cameraRecorder = [[ORKHeartRateCameraRecorderConfiguration alloc] initWithIdentifier:ORKWorkoutResultIdentifierCameraSamples];
        self.recorderConfigurations = @[cameraRecorder];
    }
    return self;
}

- (ORKInstructionWorkoutMessage *)watchStartMessage {
    ORKInstructionWorkoutMessage *message = [super watchStartMessage];
    if (self.minimumDuration < self.stepDuration) {
        // If the minimum duration is less than the step duration then this is a count up step
        // that will move forward as soon as the heart rate is captured.
        message.stepDuration = 0.0;
    }
    return message;
}

- (Class)stepViewControllerClass {
    return [ORKHeartRateCaptureStepViewController class];
}

- (void)validateParameters {
    [super ork_superValidateParameters];
    
    BOOL hasCamera = NO;    
    for (ORKRecorderConfiguration *config in self.recorderConfigurations) {
        if ([config isKindOfClass:[ORKHeartRateCameraRecorderConfiguration class]]) {
            hasCamera = YES;
            break;
        }
    }
    
    if (!hasCamera) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"The ORKHeartRateCameraRecorderConfiguration is required when using the camera" userInfo:nil];
    }
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORK_DECODE_DOUBLE(aDecoder, minimumDuration);
        ORK_DECODE_BOOL(aDecoder, beforeWorkout);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORK_ENCODE_DOUBLE(aCoder, minimumDuration);
    ORK_ENCODE_BOOL(aCoder, beforeWorkout);
}

- (instancetype)copyWithZone:(NSZone *)zone {
    __typeof(self) step = [super copyWithZone:zone];
    step.minimumDuration = self.minimumDuration;
    step.beforeWorkout = self.beforeWorkout;
    return step;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame &&
            (self.beforeWorkout == castObject.beforeWorkout) &&
            (self.minimumDuration == castObject.minimumDuration));
}

- (NSUInteger)hash {
    return [super hash] ^ (NSInteger)self.minimumDuration ^ (NSInteger)self.beforeWorkout;
}

@end
