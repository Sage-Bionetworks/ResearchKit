/*
 Copyright (c) 2017, Sage Bionetworks
 
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


@import UIKit;
@import AudioToolbox;
#import <ResearchKit/ORKOrderedTask.h>


@class ORKNavigableOrderedTask;

NS_ASSUME_NONNULL_BEGIN

@interface ORKOrderedTask (ORKPredefinedSurvey)

/**
 Returns a predefined survey that asks the user questions about their mood and general health.
 
 The mood survey includes questions about the daily or weekly mental and physical health status and
 includes asking about clarity of thinking, overall mood, pain, sleep and exercise. Additionally,
 the survey is setup to allow for an optional custom question that uses a similar-looking set of images
 as the other questions.
 
 @param identifier              The task identifier to use for this task, appropriate to the study.
 @param intendedUseDescription  A localized string describing the intended use of the data
 collected. If the value of this parameter is `nil`, the default
 localized text is displayed.
 @param frequency               How frequently the survey is asked (daily or weekly)
 @param customQuestionText      A localized string to use for a custom question. If `nil`, this step
 is not included.
 @param options                 Options that affect the features of the predefined task.
 
 @return An mood survey that can be presented with an `ORKTaskViewController` object.
 */
+ (ORKOrderedTask *)moodSurveyWithIdentifier:(NSString *)identifier
                      intendedUseDescription:(nullable NSString *)intendedUseDescription
                                   frequency:(ORKMoodSurveyFrequency)frequency
                          customQuestionText:(nullable NSString*)customQuestionText
                                     options:(ORKPredefinedTaskOption)options;

@end

NS_ASSUME_NONNULL_END
