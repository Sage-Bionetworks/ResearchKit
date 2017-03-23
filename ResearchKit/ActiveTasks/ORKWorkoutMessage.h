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
@import Foundation;
#import <ResearchKit/ORKCodingObjects.h>


NS_ASSUME_NONNULL_BEGIN

/**
 String enum for the watch's workout session state.
 */
typedef NSString * ORKWorkoutState NS_STRING_ENUM;

ORK_EXTERN ORKWorkoutState const ORKWorkoutStateNotStarted;
ORK_EXTERN ORKWorkoutState const ORKWorkoutStateStarting;
ORK_EXTERN ORKWorkoutState const ORKWorkoutStateRunning;
ORK_EXTERN ORKWorkoutState const ORKWorkoutStateStopping;
ORK_EXTERN ORKWorkoutState const ORKWorkoutStateEnded;
ORK_EXTERN ORKWorkoutState const ORKWorkoutStatePaused;


/**
 String enum for commands to change the watch's session state.
 */
typedef NSString * ORKWorkoutCommand NS_STRING_ENUM;

ORK_EXTERN ORKWorkoutCommand const ORKWorkoutCommandStop;
ORK_EXTERN ORKWorkoutCommand const ORKWorkoutCommandPause;
ORK_EXTERN ORKWorkoutCommand const ORKWorkoutCommandResume;
ORK_EXTERN ORKWorkoutCommand const ORKWorkoutCommandStartMoving;
ORK_EXTERN ORKWorkoutCommand const ORKWorkoutCommandStopMoving;
ORK_EXTERN ORKWorkoutCommand const ORKWorkoutCommandPing;


/**
 The `ORKWorkoutMessage` is an object that can be used to transport messages to 
 and from the watch.
 */
ORK_CLASS_AVAILABLE
@interface ORKWorkoutMessage : NSObject <NSCopying, NSSecureCoding>

/**
 An identifier for the message. By default, this value is set to a UUID.
 */
@property (nonatomic, copy, readonly) NSString *identifier;

/**
 The timestamp for when the message was created.
 */
@property (nonatomic, copy, readonly) NSDate *timestamp;

/**
 Current workout session state. This is only set for messages from the watch.
 */
@property (nonatomic, copy, nullable) ORKWorkoutState workoutState;

/**
 Returns a new data object initialized with the specified identifier.
 
 @param identifier   The unique identifier
 
 @return A new data object.
 */
- (instancetype)initWithIdentifier:(NSString *)identifier NS_DESIGNATED_INITIALIZER;

/**
 Returns a new data object initialized with the specified dictionary representation.
 
 @param dictionary   The dictionary representation
 
 @return A new data object.
 */
- (instancetype)initWithDictionaryRepresentation:(NSDictionary<NSString *, id> *)dictionary NS_DESIGNATED_INITIALIZER;

/**
 Returns a new data object initialized with the specified dictionary representation.
 
 @param aDecoder    Coder from which to initialize
 
 @return A new data object.
 */
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER;

/**
 Returns a new data object initialized with the specified dictionary representation,
 including mapping to a classType.
 
 @param message   The dictionary representation
 
 @return A new data object.
 */
+ (nullable instancetype)workoutMessageWithMessage:(NSDictionary<NSString *, id> *)message;

/**
 JSON serializable dictionary representing this object.
 
 @return Dictionary representation for this data object.
 */
- (NSDictionary<NSString *, id> *)dictionaryRepresentation;

@end


/**
 `ORKInstructionWorkoutMessage` messages are sent from the phone to the watch.
 */
ORK_CLASS_AVAILABLE
@interface ORKInstructionWorkoutMessage : ORKWorkoutMessage

/**
 A localized string with the instruction to display.
 */
@property (nonatomic, copy, nullable) NSString *instruction;

/**
 A duration for the step.
 */
@property (nonatomic) NSTimeInterval stepDuration;

/**
 Command intended to tell the watch to change state.
 */
@property (nonatomic, copy, nullable) ORKWorkoutCommand command;

@end


/**
 `ORKSamplesWorkoutMessage` messages are sent from the watch when a tracked HealthKit
 value is updated.
 */
ORK_CLASS_AVAILABLE
@interface ORKSamplesWorkoutMessage : ORKWorkoutMessage

/**
 The quantity type identifier for this set of samples.
 */
@property (nonatomic, copy) HKQuantityTypeIdentifier quantityTypeIdentifier;

/**
 The samples being sent.
 */
@property (nonatomic, copy) NSArray<HKQuantitySample *> *samples;

@end


/**
 `ORKEventWorkoutMessage` messages are sent from the watch when a workout session
 event happens.
 */
ORK_CLASS_AVAILABLE
HK_CLASS_AVAILABLE_IOS_WATCHOS(10_0, 3_0)
@interface ORKEventWorkoutMessage : ORKWorkoutMessage

/**
 The event that triggered the message send.
 */
@property (nonatomic, copy) HKWorkoutEvent *event;

@end


/**
 `ORKErrorWorkoutMessage` messages are sent from the watch when a workout session
 error happens.
 */
ORK_CLASS_AVAILABLE
@interface ORKErrorWorkoutMessage : ORKWorkoutMessage

/**
 The error that triggered the message send.
 */
@property (nonatomic, copy) NSError *error;

@end


NS_ASSUME_NONNULL_END
