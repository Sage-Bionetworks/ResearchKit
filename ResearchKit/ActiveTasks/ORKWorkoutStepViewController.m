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

#import "ORKWorkoutStepViewController.h"
#import "ORKPageStepViewController_Internal.h"
#import "ORKStepViewController_Internal.h"

#import "ORKHeartRateCaptureStep.h"
#import "ORKHeartRateCaptureStepViewController_Internal.h"
#import "ORKFitnessStepViewController_Internal.h"

#import "ORKActiveStep_Internal.h"
#import "ORKHealthQuantityTypeRecorder_Internal.h"
#import "ORKPageStep_Private.h"
#import "ORKWorkoutStep_Private.h"

#import "ORKRecorder_Internal.h"

#import "ORKCodingObjects.h"
#import "ORKHelpers_Internal.h"
#import "ORKSkin.h"

typedef NS_OPTIONS(NSInteger, ORKWorkoutStepWatchState) {
    
    ORKWorkoutStepWatchStateNotStarted  = 0,
    
    ORKWorkoutStepWatchStateRunning     = 1,
    ORKWorkoutStepWatchStateStarting    = ORKWorkoutStepWatchStateRunning | 2,
    ORKWorkoutStepWatchStateStopping    = ORKWorkoutStepWatchStateRunning | 4,
    
    ORKWorkoutStepWatchStateStopped     = 8,
    ORKWorkoutStepWatchStateFailed      = ORKWorkoutStepWatchStateStopped | 16,
    ORKWorkoutStepWatchStateUserStopped = ORKWorkoutStepWatchStateStopped | 32,
    
} ORK_ENUM_AVAILABLE;

@interface ORKWorkoutStepViewController () <ORKRecorderDelegate>

@property (nonatomic, strong) ORKWorkoutMessage *pendingMessage;
@property (nonatomic, assign) ORKWorkoutStepWatchState state;

@end

@implementation ORKWorkoutStepViewController {
    
    // state management
    BOOL _started;
    BOOL _stopped;
    NSDate *_workoutStartDate;
    ORKDevice *_device;
    
    // results to add to base step
    NSArray *_results;
    
    // recorders
    NSArray *_recorders;
    NSDictionary *_healthRecorders;
}

- (ORKWorkoutStep *)workoutStep {
    return (ORKWorkoutStep *)self.step;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // Wait for animation complete
    dispatch_async(dispatch_get_main_queue(), ^{
        [self startRecorders];
    });
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // Always stop the recorders and watch
    [self stopRecorders];
}

- (void)stepViewControllerDidAppear:(ORKStepViewController *)stepViewController {
    [super stepViewControllerDidAppear:stepViewController];
    [self sendMessageForStepViewController:stepViewController isStart:YES];
}

- (void)stepViewController:(ORKStepViewController *)stepViewController didFinishWithNavigationDirection:(ORKStepViewControllerNavigationDirection)direction {
    if (direction == ORKStepViewControllerNavigationDirectionForward) {
        [self sendMessageForStepViewController:stepViewController isStart:NO];
        if ([self.workoutStep shouldStopRecordersOnFinishedWithStep:stepViewController.step]) {
            [self stopRecorders];
        }
    }
    [super stepViewController:stepViewController didFinishWithNavigationDirection:direction];
}

- (void)sendMessageForStepViewController:(ORKStepViewController *)stepViewController isStart:(BOOL)isStart {
    if (self.state != ORKWorkoutStepWatchStateRunning) {
        return;
    }
    
    // Send startup message
    ORKActiveStep *currentStep = (ORKActiveStep *)stepViewController.step;
    if ([currentStep isKindOfClass:[ORKActiveStep class]]) {
        ORKInstructionWorkoutMessage *message = isStart ? [currentStep watchStartMessage] : [currentStep watchFinishMessage];
        if (message) {
            [self sendWatchMessage:message];
        }
    }
}

- (ORKStepViewController *)stepViewControllerForStep:(ORKStep *)step {
    ORKStepViewController *stepViewController = [super stepViewControllerForStep:step];
    if ([stepViewController isKindOfClass:[ORKFitnessStepViewController class]]) {
        ((ORKFitnessStepViewController *)stepViewController).usesWatch = (self.state | ORKWorkoutStepWatchStateRunning);
    }
    return stepViewController;
}

- (ORKStep *)stepInDirection:(ORKPageNavigationDirection)delta {
    if (self.state == ORKWorkoutStepWatchStateUserStopped) {
        return nil;
    } else {
        return [super stepInDirection:delta];
    }
}

#pragma mark - Error handling

- (void)handleWatchError:(NSError *)error {
    if (self.state & ORKWorkoutStepWatchStateStopped) {
        return;
    }
    self.state = ORKWorkoutStepWatchStateFailed;
    
    // Save the error to the result set
    ORKErrorResult *errorResult = [[ORKErrorResult alloc] initWithIdentifier:ORKWorkoutResultIdentifierError];
    errorResult.error = error;
    if (self.currentStepIdentifier) {
        errorResult.userInfo = @{@"stepIdentifier" : self.currentStepIdentifier};
    }
    _results = [_results arrayByAddingObject:errorResult] ? : @[errorResult];
    
    // Forward the error message
    [[self currentStepViewController] didReceiveWatchError:error];
}

- (NSError *)workoutErrorWithCode:(WCErrorCode)code {
    NSString *localizedDescription = nil;
    switch (code) {
        case WCErrorCodeSessionNotSupported:
            localizedDescription = ORKLocalizedString(@"WATCH_SESSION_ERROR_DESCRIPTION_NOT_SUPPORTED", nil); break;
            
        case WCErrorCodeDeviceNotPaired:
            localizedDescription = ORKLocalizedString(@"WATCH_SESSION_ERROR_DESCRIPTION_NOT_PAIRED", nil); break;
            
        case WCErrorCodeWatchAppNotInstalled:
            localizedDescription = ORKLocalizedString(@"WATCH_SESSION_ERROR_DESCRIPTION_NOT_INSTALLED", nil); break;
            
        case WCErrorCodeSessionNotActivated:
            localizedDescription = ORKLocalizedString(@"WATCH_SESSION_ERROR_DESCRIPTION_NOT_ACTIVATED", nil); break;
            
        default:
            localizedDescription = ORKLocalizedString(@"WATCH_SESSION_ERROR_DESCRIPTION_NOT_REACHABLE", nil); break;
    }
    return [NSError errorWithDomain:WCErrorDomain code:code userInfo:@{NSLocalizedDescriptionKey: localizedDescription}];
}

#pragma mark - Workout startup

- (void)startWatchApp {
    if (![WCSession isSupported] || ![HKHealthStore isHealthDataAvailable]) {
        [self handleWatchError:[self workoutErrorWithCode:WCErrorCodeSessionNotSupported]];
        return;
    }
    
    self.state = ORKWorkoutStepWatchStateStarting;
    WCSession *session = [WCSession defaultSession];
    session.delegate = self;
    
    if (session.activationState == WCSessionActivationStateActivated) {
        [self watchSessionActivationCompleted:session];
    } else {
        [session activateSession];
    }
}

- (void)watchSessionActivationCompleted:(WCSession *)session {
    if (self.state == ORKWorkoutStepWatchStateRunning) {
        [self sendPendingMessages];
        return;
    } else if (!session.isPaired) {
        ORK_Log_Debug(@"Watch is not paired :%@", session);
        [self handleWatchError:[self workoutErrorWithCode:WCErrorCodeDeviceNotPaired]];
        return;
    } else if (!session.isWatchAppInstalled) {
        ORK_Log_Debug(@"Watch app is not installed :%@", session);
        [self handleWatchError:[self workoutErrorWithCode:WCErrorCodeWatchAppNotInstalled]];
        return;
    }

    _workoutStartDate = [NSDate date];
    __block HKHealthStore *healthStore = [HKHealthStore new];
    ORKWeakTypeOf(self) weakSelf = self;
    [healthStore startWatchAppWithWorkoutConfiguration:self.workoutStep.workoutConfiguration completion:^(BOOL success, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf handleStartAppComplete:success error:error];
        });
        
        // Clear self-ref.
        healthStore = nil;
    }];
}

- (void)handleStartAppComplete:(BOOL)success error:(NSError *)error {
    if (success) {
        ORK_Log_Debug(@"Health workout session started");
        self.state = ORKWorkoutStepWatchStateRunning;
        
        // Send startup message
        [self sendMessageForStepViewController:[self currentStepViewController] isStart:YES];
    } else {
        ORK_Log_Error(@"Health access: error=%@", error);
        [self handleWatchError:error];
    }
}

#pragma mark - message management

- (void)sendWatchMessage:(ORKInstructionWorkoutMessage *)message {
    if (![[NSThread currentThread] isMainThread]) {
        ORKWeakTypeOf(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf sendWatchMessage:message];
        });
        return;
    }
    
    // Check the current state and only continue if the state is running
    if (self.state != ORKWorkoutStepWatchStateRunning) {
        return;
    }
    
    // If this is a message to stop the workout then call this controller's version of that
    // message instead of just putting the message in the queue
    if ([message.command isEqualToString:ORKWorkoutCommandStop]) {
        self.state = ORKWorkoutStepWatchStateStopping;
    }
    
    // Set the pending message and call method to
    self.pendingMessage = message;
    [self sendPendingMessages];
}

- (void)sendPendingMessages {
    
    if (![[NSThread currentThread] isMainThread]) {
        ORKWeakTypeOf(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf sendPendingMessages];
        });
        return;
    }
    
    // If not in a running state or there is no pending message then return
    if (((self.state & ORKWorkoutStepWatchStateRunning) == 0) || (self.pendingMessage == nil)) {
        return;
    }
    
    WCSession *session = [WCSession defaultSession];
    if ((session.activationState == WCSessionActivationStateActivated) && session.isReachable) {
        
        // Copy the dictionary and clear the pending message
        NSDictionary *message = [self.pendingMessage dictionaryRepresentation];
        self.pendingMessage = nil;
        if (self.state == ORKWorkoutStepWatchStateStopping) {
            self.state = ORKWorkoutStepWatchStateStopped;
        }
        
        // send the message
        ORKWeakTypeOf(self) weakSelf = self;
        [session sendMessage:message
                replyHandler:nil
                errorHandler:^(NSError * _Nonnull error) {
                    ORK_Log_Error(@"Failed to send watch message: %@", error);
                    [weakSelf handleWatchError:error];
                }];
        
    } else if (session.activationState == WCSessionActivationStateActivated) {
        ORKWeakTypeOf(self) weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf sendPendingMessages];
        });
        
    } else {
        [session activateSession];
    }
}

- (NSDictionary *)forwardWatchMessage:(NSDictionary<NSString *, id> *)msg {
        
    ORKWorkoutMessage *workoutMessage = [ORKWorkoutMessage workoutMessageWithMessage:msg];
    
    if (!workoutMessage || !_workoutStartDate) {
        ORK_Log_Debug(@"Message received while workout session is not active or missing timestamp: %@", msg);
        return @{};
    }
    
    if ([workoutMessage.timestamp compare:_workoutStartDate] == NSOrderedAscending) {
        ORK_Log_Debug(@"Ignoring watch session old message: %@", msg);
        return @{};
    }
    
    if ([workoutMessage.workoutState isEqualToString:ORKWorkoutStateEnded]) {
        if (self.state == ORKWorkoutStepWatchStateRunning) {
            // If this is a stop message that was received in response to the user stopping the
            // workout from the watch, then add the event to the result set
            self.state = ORKWorkoutStepWatchStateUserStopped;
            ORKBooleanQuestionResult *boolResult = [[ORKBooleanQuestionResult alloc] initWithIdentifier:ORKWorkoutResultIdentifierUserEnded];
            boolResult.booleanAnswer = @YES;
            boolResult.startDate = workoutMessage.timestamp;
            _results = [_results arrayByAddingObject:boolResult] ? : @[boolResult];
        }
        
        // Unassign self as delegate
        [WCSession defaultSession].delegate = nil;
    }
    
    if ([workoutMessage isKindOfClass:[ORKSamplesWorkoutMessage class]]) {
        ORKSamplesWorkoutMessage *samplesMessage = (ORKSamplesWorkoutMessage *)workoutMessage;
        [self addHeathRecorderQuantitySamples: samplesMessage.samples
                       quantityTypeIdentifier: samplesMessage.quantityTypeIdentifier];
    }
    
    ORK_Log_Debug(@"Watch session did recieve message: %@", message);
    [self.currentStepViewController didReceiveWatchMessage:workoutMessage];
    
    ORKWorkoutMessage *replyMessage = [[ORKWorkoutMessage alloc] initWithIdentifier:workoutMessage.identifier];
    return [replyMessage dictionaryRepresentation];
}

- (void)stopWatchWorkout {
    if (self.state & ORKWorkoutStepWatchStateStopped) {
        return;
    }

    ORKInstructionWorkoutMessage *message = [[ORKInstructionWorkoutMessage alloc] initWithIdentifier:self.step.identifier];
    message.command = ORKWorkoutCommandStop;
    [self sendWatchMessage:message];
}

- (void)addHeathRecorderQuantitySamples:(NSArray<HKQuantitySample *> *)samples
                 quantityTypeIdentifier:(NSString *)quantityTypeIdentifier {
    if (_stopped) {
        return;
    }
    
    ORKHealthQuantityTypeRecorder *recorder = _healthRecorders[quantityTypeIdentifier];
    [recorder addQuantitySamples:samples];
    
    if ([quantityTypeIdentifier isEqualToString:HKQuantityTypeIdentifierHeartRate] && !_device) {
        HKQuantitySample *sample = [samples lastObject];
        if (sample.device) {
            _device = [[ORKDevice alloc] initWithDevice:sample.device];
        }
    }
}

#pragma mark - WCSessionDelegate

- (void)session:(WCSession *)session activationDidCompleteWithState:(WCSessionActivationState)activationState error:(nullable NSError *)error {
    ORKWeakTypeOf(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (activationState == WCSessionActivationStateActivated) {
            ORK_Log_Debug(@"Watch session did become active: %@", session);
            [weakSelf watchSessionActivationCompleted:session];
        } else {
            ORK_Log_Error(@"Watch failed to activate: %@", error);
            [weakSelf handleWatchError:error];
        }
    });
}

- (void)sessionDidBecomeInactive:(WCSession *)session {
    ORK_Log_Debug(@"Watch session did become inactive: %@", session);
}

- (void)sessionDidDeactivate:(WCSession *)session {
    ORK_Log_Debug(@"Watch session did deactivate: %@", session);
}

- (void)sessionWatchStateDidChange:(WCSession *)session {
    ORK_Log_Debug(@"Watch session state changed: %@", session);
}

- (void)sessionReachabilityDidChange:(WCSession *)session {
    ORK_Log_Debug(@"Watch session reachablility changed: %@ %@", session, session.isReachable ? @"reachable" : @"not reachable");
}

- (void)session:(WCSession *)session didReceiveMessage:(NSDictionary<NSString *, id> *)message {
    ORKWeakTypeOf(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf forwardWatchMessage:message];
    });
}

- (void)session:(WCSession *)session didReceiveMessage:(NSDictionary<NSString *, id> *)message replyHandler:(void(^)(NSDictionary<NSString *, id> *replyMessage))replyHandler {
    ORKWeakTypeOf(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *reply = [weakSelf forwardWatchMessage:message];
        replyHandler(reply);
    });
}

#pragma mark - ORKRecorderDelegate

- (void)recorder:(ORKRecorder *)recorder didCompleteWithResult:(ORKResult *)result {
    _results = [_results arrayByAddingObject:result] ? : @[result];
    [self notifyDelegateOnResultChange];
}

- (void)recorder:(ORKRecorder *)recorder didFailWithError:(NSError *)error {
    if (error) {
        ORKStrongTypeOf(self.delegate) strongDelegate = self.delegate;
        if ([strongDelegate respondsToSelector:@selector(stepViewController:recorder:didFailWithError:)]) {
            [strongDelegate stepViewController:self recorder:recorder didFailWithError:error];
        }
        
        // If the recorder returns an error indicating that file write failed, and the output directory was nil,
        // we consider it a fatal error and fail the step. Otherwise, developers might be confused to get
        // no output, just because they did not set an output directory.
        if ([error.domain isEqualToString:NSCocoaErrorDomain] &&
            error.code == NSFileWriteInvalidFileNameError &&
            self.outputDirectory == nil) {
            [strongDelegate stepViewControllerDidFail:self withError:error];
        }
    }
}

#pragma mark - Recorder management

- (ORKStepResult *)result {
    ORKStepResult *sResult = [super result];
    if (_results) {
        sResult.results = [sResult.results arrayByAddingObjectsFromArray:_results] ? : _results;
    }
    
    if (_device) {
        ORKDeviceResult *deviceResult = [[ORKDeviceResult alloc] initWithIdentifier:ORKWorkoutResultIdentifierDevice];
        deviceResult.device = _device;
        sResult.results = [sResult.results arrayByAddingObject:deviceResult] ? : @[deviceResult];
    }
    
    return sResult;
}

- (void)prepareRecorders {
    if (_recorders) {
        return;
    }
    
    // Stop any existing recorders
    NSMutableArray *recorders = [NSMutableArray new];
    NSMutableDictionary *healthRecorders = [NSMutableDictionary new];
    
    for (ORKRecorderConfiguration * provider in self.workoutStep.recorderConfigurations) {
        // If the outputDirectory is nil, recorders which require one will generate an error.
        // We start them anyway, because we don't know which recorders will require an outputDirectory.
        ORKRecorder *recorder = [provider recorderForStep:self.step
                                          outputDirectory:self.outputDirectory];
        recorder.configuration = provider;
        recorder.delegate = self;
        
        [recorders addObject:recorder];
        
        if ([recorder isKindOfClass:[ORKHealthQuantityTypeRecorder class]]) {
            ORKHealthQuantityTypeRecorder *healthRecorder = (ORKHealthQuantityTypeRecorder *)recorder;
            healthRecorders[healthRecorder.quantityType.identifier] = healthRecorder;
        }
    }
    _recorders = recorders;
    _healthRecorders = healthRecorders;
}

- (void)setOutputDirectory:(NSURL *)outputDirectory {
    [super setOutputDirectory:outputDirectory];
    [self prepareRecorders];
}

- (void)startRecorders {
    if (_started) {
        return;
    }
    _started = YES;
    
    // Start recorders
    for (ORKRecorder *recorder in _recorders) {
        [recorder viewController:self willStartStepWithView:self.view];
        [recorder start];
    }
    [self startWatchApp];
}

- (void)stopRecorders {
    if (_stopped) {
        return;
    }
    _stopped = YES;
    
    [self stopWatchWorkout];
    for (ORKRecorder *recorder in _recorders) {
        [recorder stop];
    }
}

@end
