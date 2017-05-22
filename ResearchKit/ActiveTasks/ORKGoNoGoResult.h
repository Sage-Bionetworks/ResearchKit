/*
 Copyright (c) 2017, Roland Rabien. All rights reserved.
 
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

@class ORKGoNoGoSample;

/**
 The `ORKGoNoGoResult` class represents the result of a single successful attempt within an ORKGoNoGoStep.
 
 The `timestamp` property is equal to the value of systemUptime (in NSProcessInfo) when the stimulus occurred.
 Each entry of motion data in this file contains a time interval which may be directly compared to timestamp in order to determine the elapsed time since the stimulus.
 
 The fileResult property references the motion data recorded from the beginning of the attempt until the threshold acceleration was reached.
 Using the time taken to reach the threshold acceleration as the reaction time of a participant will yield a rather crude measurement. Rather, you should devise your
 own method using the data recorded to obtain an accurate approximation of the true reaction time. Still, the time is provided in time to threshold.
 
 A reaction time result is typically generated by the framework as the task proceeds. When the task
 completes, it may be appropriate to serialize the sample for transmission to a server
 or to immediately perform analysis on it.
 */
ORK_CLASS_AVAILABLE
@interface ORKGoNoGoResult: ORKResult

/**
 The value of systemUptime (in NSProcessInfo) when the stimulus occurred.
 */
@property (nonatomic, assign) NSTimeInterval timestamp;

/**
 Time from when the stimulus occurred to the threshold being reached.
 */
@property (nonatomic, assign) NSTimeInterval timeToThreshold;

/**
 YES if a go test and NO if a no go test
 */
@property (nonatomic, assign) BOOL go;

/**
 Set to YES if the incorrect response is given i.e shaken for no go test or not shaken for a go test
 */
@property (nonatomic, assign) BOOL incorrect;

/**
 An array of collected samples, in which each item is an `ORKGoNoGoSample`
 object that represents a go-no-go sample.
 */
@property (nonatomic, copy, nullable) NSArray<ORKGoNoGoSample*> *samples;

@end

/**
 The `ORKGoNoGoSample` class represents a single reading from the accelerometer.
 
 The gonogo sample object records the time and magnitude of the acceleration.
 A gonogo sample is included in an `ORKGoNoGoResult` object, and is recorded by the
 step view controller for the corresponding task.
 */
ORK_CLASS_AVAILABLE
@interface ORKGoNoGoSample : NSObject <NSCopying, NSSecureCoding>

/**
 A relative timestamp indicating the time of the accelerometer event.
 
 The timestamp is relative to the time the stimulus was displayed.
 */
@property (nonatomic, assign) NSTimeInterval timestamp;

/**
 Magnitude of the acceleration event.
 */
@property (nonatomic, assign) double vectorMagnitude;

@end

NS_ASSUME_NONNULL_END

