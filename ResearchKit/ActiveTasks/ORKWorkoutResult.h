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


#import <ResearchKit/ORKResult.h>


NS_ASSUME_NONNULL_BEGIN

@class ORKDevice;

/**
 An `ORKWorkoutResult` contains information about the results of running the workout step.
 */
ORK_CLASS_AVAILABLE
@interface ORKWorkoutResult : ORKResult

/**
 The error (if any) when trying to connect to the watch.
 */
@property (nonatomic, copy, nullable) NSError *error;

/**
 The device information for the Apple Watch (if any) used during this workout.
 */
@property (nonatomic, copy, nullable) ORKDevice *device;

@end


/**
 The `ORKDevice` represents a serializable representation of an `HKDevice`.
 */
ORK_CLASS_AVAILABLE
@interface ORKDevice : NSObject <NSCopying, NSSecureCoding>

/*!
 @property      name
 @abstract      The name of the receiver.
 @discussion    The user-facing name, such as the one displayed in the Bluetooth Settings for a BLE device.
 */
@property (nonatomic, readonly, nullable) NSString *name;

/*!
 @property      manufacturer
 @abstract      The manufacturer of the receiver.
 */
@property (nonatomic, readonly, nullable) NSString *manufacturer;

/*!
 @property      model
 @abstract      The model of the receiver.
 */
@property (nonatomic, readonly, nullable) NSString *model;

/*!
 @property      hardwareVersion
 @abstract      The hardware revision of the receiver.
 */
@property (nonatomic, readonly, nullable) NSString *hardwareVersion;

/*!
 @property      softwareVersion
 @abstract      The software revision of the receiver.
 */
@property (nonatomic, readonly, nullable) NSString *softwareVersion;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 Returns a new device initialized from an `HKDevice`
 
 @param healthKitDevice `HKDevice` to copy values from
 @return                A new device.
 */
- (instancetype)initWithDevice:(HKDevice *)healthKitDevice;

/**
 Returns a new device initialized with the properties of this object
 
 @param name    The name of the device
 @param manufacturer    The manufacturer of the device
 @param model   The model of the device
 @param hardwareVersion The hardware version of the device
 @param softwareVersion The software version of the device
 @return                A new device.
 */
- (instancetype)initWithName:(nullable NSString *)name
                manufacturer:(nullable NSString *)manufacturer
                       model:(nullable NSString *)model
             hardwareVersion:(nullable NSString *)hardwareVersion
             softwareVersion:(nullable NSString *)softwareVersion NS_DESIGNATED_INITIALIZER;

/**
 Returns a new device initialized from data in the given unarchiver.
 
 @param aDecoder    Coder from which to initialize the device.
 
 @return A new device.
 */
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
