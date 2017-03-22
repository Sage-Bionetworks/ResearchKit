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


#import "ORKOrderedTask+ORKPredefinedSurvey.h"

#import "ORKOrderedTask_Private.h"

#import "ORKAnswerFormat_Internal.h"
#import "ORKCompletionStep.h"
#import "ORKInstructionStep.h"
#import "ORKQuestionStep.h"

#import "ORKHelpers_Internal.h"


@implementation ORKOrderedTask (ORKPredefinedSurvey)

#pragma mark - moodSurvey

NSString *const ORKMoodSurveyCustomQuestionStepIdentifier = @"mood.custom";
NSString *const ORKMoodSurveyClarityQuestionStepIdentifier = @"mood.clarity";
NSString *const ORKMoodSurveyOverallQuestionStepIdentifier = @"mood.overall";
NSString *const ORKMoodSurveySleepQuestionStepIdentifier = @"mood.sleep";
NSString *const ORKMoodSurveyExerciseQuestionStepIdentifier = @"mood.exercise";
NSString *const ORKMoodSurveyPainQuestionStepIdentifier = @"mood.pain";

+ (ORKOrderedTask *)moodSurveyWithIdentifier:(NSString *)identifier
                      intendedUseDescription:(nullable NSString *)intendedUseDescription
                                   frequency:(ORKMoodSurveyFrequency)frequency
                          customQuestionText:(nullable NSString*)customQuestionText
                                     options:(ORKPredefinedTaskOption)options {
    
    NSMutableArray *steps = [NSMutableArray new];
    
    
    if (!(options & ORKPredefinedTaskOptionExcludeInstructions)) {
        ORKInstructionStep *step = [[ORKInstructionStep alloc] initWithIdentifier:ORKInstruction0StepIdentifier];
        step.title = (frequency == ORKMoodSurveyFrequencyDaily) ?
        ORKLocalizedString(@"MOOD_SURVEY_INTRO_DAILY_TITLE", nil) :
        ORKLocalizedString(@"MOOD_SURVEY_INTRO_WEEKLY_TITLE", nil);
        NSString *defaultDescription = (frequency == ORKMoodSurveyFrequencyDaily) ?
        ORKLocalizedString(@"MOOD_SURVEY_INTRO_DAILY_TEXT", nil) :
        ORKLocalizedString(@"MOOD_SURVEY_INTRO_WEEKLY_TEXT", nil);
        step.text = intendedUseDescription ?: defaultDescription;
        step.detailText = ORKLocalizedString(@"MOOD_SURVEY_INTRO_DETAIL", nil);
        ORKStepArrayAddStep(steps, step);
    }
    
    if (customQuestionText != nil) {
        ORKAnswerFormat *format = [[ORKMoodScaleAnswerFormat alloc] initWithMoodQuestionType:ORKMoodQuestionTypeCustom];
        ORKQuestionStep *step = [ORKQuestionStep questionStepWithIdentifier:ORKMoodSurveyCustomQuestionStepIdentifier
                                                                      title:customQuestionText
                                                                     answer:format];
        ORKStepArrayAddStep(steps, step);
    }
    
    {   // Clarity
        NSString *prompt = (frequency == ORKMoodSurveyFrequencyDaily) ?
        ORKLocalizedString(@"MOOD_CLARITY_DAILY_PROMPT", nil) :
        ORKLocalizedString(@"MOOD_CLARITY_WEEKLY_PROMPT", nil);
        
        ORKAnswerFormat *format = [[ORKMoodScaleAnswerFormat alloc] initWithMoodQuestionType:ORKMoodQuestionTypeClarity];
        ORKQuestionStep *step = [ORKQuestionStep questionStepWithIdentifier:ORKMoodSurveyClarityQuestionStepIdentifier
                                                                      title:prompt
                                                                     answer:format];
        ORKStepArrayAddStep(steps, step);
    }
    
    {   // Overall
        NSString *prompt = (frequency == ORKMoodSurveyFrequencyDaily) ?
        ORKLocalizedString(@"MOOD_OVERALL_DAILY_PROMPT", nil) :
        ORKLocalizedString(@"MOOD_OVERALL_WEEKLY_PROMPT", nil);
        
        ORKAnswerFormat *format = [[ORKMoodScaleAnswerFormat alloc] initWithMoodQuestionType:ORKMoodQuestionTypeOverall];
        ORKQuestionStep *step = [ORKQuestionStep questionStepWithIdentifier:ORKMoodSurveyOverallQuestionStepIdentifier
                                                                      title:prompt
                                                                     answer:format];
        ORKStepArrayAddStep(steps, step);
    }
    
    {   // Pain
        NSString *prompt = (frequency == ORKMoodSurveyFrequencyDaily) ?
        ORKLocalizedString(@"MOOD_PAIN_DAILY_PROMPT", nil) :
        ORKLocalizedString(@"MOOD_PAIN_WEEKLY_PROMPT", nil);
        
        ORKAnswerFormat *format = [[ORKMoodScaleAnswerFormat alloc] initWithMoodQuestionType:ORKMoodQuestionTypePain];
        ORKQuestionStep *step = [ORKQuestionStep questionStepWithIdentifier:ORKMoodSurveyPainQuestionStepIdentifier
                                                                      title:prompt
                                                                     answer:format];
        ORKStepArrayAddStep(steps, step);
    }
    
    {   // Sleep
        NSString *prompt = (frequency == ORKMoodSurveyFrequencyDaily) ?
        ORKLocalizedString(@"MOOD_SLEEP_DAILY_PROMPT", nil) :
        ORKLocalizedString(@"MOOD_SLEEP_WEEKLY_PROMPT", nil);
        
        ORKAnswerFormat *format = [[ORKMoodScaleAnswerFormat alloc] initWithMoodQuestionType:ORKMoodQuestionTypeSleep];
        ORKQuestionStep *step = [ORKQuestionStep questionStepWithIdentifier:ORKMoodSurveySleepQuestionStepIdentifier
                                                                      title:prompt
                                                                     answer:format];
        ORKStepArrayAddStep(steps, step);
    }
    
    {   // Excercise
        NSString *prompt = (frequency == ORKMoodSurveyFrequencyDaily) ?
        ORKLocalizedString(@"MOOD_EXERCISE_DAILY_PROMPT", nil) :
        ORKLocalizedString(@"MOOD_EXERCISE_WEEKLY_PROMPT", nil);
        
        ORKAnswerFormat *format = [[ORKMoodScaleAnswerFormat alloc] initWithMoodQuestionType:ORKMoodQuestionTypeExcercise];
        ORKQuestionStep *step = [ORKQuestionStep questionStepWithIdentifier:ORKMoodSurveyExerciseQuestionStepIdentifier
                                                                      title:prompt
                                                                     answer:format];
        ORKStepArrayAddStep(steps, step);
    }
    
    if (!(options & ORKPredefinedTaskOptionExcludeConclusion)) {
        ORKInstructionStep *step = [self makeCompletionStep];
        ORKStepArrayAddStep(steps, step);
    }
    
    ORKOrderedTask *task = [[ORKOrderedTask alloc] initWithIdentifier:identifier steps:[steps copy]];
    
    return task;
}

@end
