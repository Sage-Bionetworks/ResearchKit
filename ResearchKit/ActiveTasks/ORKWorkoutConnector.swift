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

import WatchConnectivity
import WatchKit
import HealthKit
import Foundation


/**
 The `ORKWorkoutConnectorDelegate` can be used to send delegate messages back to the controller 
 WCInterfaceController.
 */
@objc
@available(watchOS 3.0, *)
public protocol ORKWorkoutConnectorDelegate: class, NSObjectProtocol {
    
    /**
     Called when a workout is successfully started.
     
     @param workoutConnector    The calling workout connector
     @param configuration       The workout configuration for the workout session to start
     */
    @objc(workoutConnector:didStartWorkout:)
    func workoutConnector(_ workoutConnector: ORKWorkoutConnector, didStartWorkout configuration:HKWorkoutConfiguration)
    
    /**
     Called when a workout ended. This object includes the `HKWorkout` object describing this workout.
     
     @param workoutConnector    The calling workout connector
     @param workout             The workout object
     */
    @objc(workoutConnector:didEndWorkout:)
    func workoutConnector(_ workoutConnector: ORKWorkoutConnector, didEndWorkout workout:HKWorkout)
    
    /**
     Called when a message is received from the paired phone.
     
     @param workoutConnector    The calling workout connector
     @param message             The message object
     */
    @objc(workoutConnector:didReceiveMessage:)
    func workoutConnector(_ workoutConnector: ORKWorkoutConnector, didReceiveMessage message:ORKWorkoutMessage)
    
    /**
     Called when the workout state is paused.
     
     @param workoutConnector    The calling workout connector
     */
    @objc(workoutConnectorDidPause:)
    optional func workoutConnectorDidPause(_ workoutConnector: ORKWorkoutConnector)
    
    /**
     Called when the workout state is resumed.
     
     @param workoutConnector    The calling workout connector
     */
    @objc(workoutConnectorDidResume:)
    optional func workoutConnectorDidResume(_ workoutConnector: ORKWorkoutConnector)
    
    /**
     Called when the total energy burned is updated.
     
     @param workoutConnector    The calling workout connector
     @param totalEnergyBurned   The total energy burned (calories)
     */
    @objc(workoutConnector:didUpdateTotalEnergyBurned:)
    optional func workoutConnector(_ workoutConnector: ORKWorkoutConnector, didUpdateTotalEnergyBurned totalEnergyBurned:HKQuantity)
    
    /**
     Called when the total distance is updated.
     
     @param workoutConnector    The calling workout connector
     @param totalDistance       The total distance
     */
    @objc(workoutConnector:didUpdateTotalDistance:)
    optional func workoutConnector(_ workoutConnector: ORKWorkoutConnector, didUpdateTotalDistance totalDistance:HKQuantity)
    
    /**
     Called when the heart rate is updated.
     
     @param workoutConnector    The calling workout connector
     @param heartRate           The heart rate
     */
    @objc(workoutConnector:didUpdateHeartRate:)
    optional func workoutConnector(_ workoutConnector: ORKWorkoutConnector, didUpdateHeartRate heartRate:HKQuantity)
}

/**
 The `ORKWorkoutConnector` can be used to run a workout as well as to communicate with the paired
 phone. To use this, create a watch app and use this to run a workout and optionally to communicate
 with a phone that is running a fitness test.
 */
@objc
@available(watchOS 3.0, *)
open class ORKWorkoutConnector: NSObject, HKWorkoutSessionDelegate, WCSessionDelegate {
    
    /**
     The callback delegate.
     */
    public weak var delegate: ORKWorkoutConnectorDelegate?
    
    // MARK: Properties
    
    /**
     Health store instance for this workout.
     */
    public let healthStore = HKHealthStore()
    
    /**
     Workout session started using this controller.
     */
    public var workoutSession : HKWorkoutSession? {
        return _workoutSession
    }
    fileprivate var _workoutSession : HKWorkoutSession?
    
    /**
     Watch Connectivity Session
    */
    public var connectivitySession: WCSession? {
        return _connectivitySession
    }
    private var _connectivitySession: WCSession?
    
    /**
     Should the connector send messages to the phone?
     */
    public var startedFromPhone = false
    
    /**
     Should the connector timeout after a given duration?
     */
    public var workoutDuration: TimeInterval = 0 {
        didSet {
            if workoutDuration > 0 && timer == nil && _workoutSession != nil {
                startTimer()
            }
        }
    }
    
    /**
     Start date for this workout session
     */
    public var workoutStartDate : Date {
        return _workoutStartDate
    }
    fileprivate var _workoutStartDate = Date()
    
    /**
     End date for this workout session
     */
    public var workoutEndDate : Date {
        return _workoutEndDate ?? Date()
    }
    fileprivate var _workoutEndDate : Date?
    
    /**
     Whether or not the current workout is paused
     */
    public var isPaused: Bool {
        return _isPaused
    }
    fileprivate var _isPaused = false
    
    /**
     List of query identifiers for this workout session. By default, these are set during
     `start()` to the list returned by the function `queryIdentifiers(for activityType:HKWorkoutActivityType)`
     */
    open var queryIdentifiers: [HKQuantityTypeIdentifier] = []
    
    /**
     Distance type being measured for this workout.
     */
    public var distanceTypeIdentifier: HKQuantityTypeIdentifier? {
        for queryIdentifier in queryIdentifiers {
            if ORKWorkoutUtilities.supportedDistanceTypeIdentifiers.contains(queryIdentifier) {
                return queryIdentifier
            }
        }
        return nil
    }
    
    // MARK: Internal tracking
    
    var totalEnergyBurned = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: 0)
    var totalDistance = HKQuantity(unit: HKUnit.meter(), doubleValue: 0)
    var currentHeartRate: HKQuantitySample?
    var startingHeartRate: HKQuantitySample?
    var activeDataQueries = [HKQuery]()
    var workoutEvents = [HKWorkoutEvent]()
    var timer: Timer?
    
    // MARK: Workout session handling - override these methods to implement custom handling
    
    /**
     Start the workout with the given configuration.
     
     @param workoutConfiguration    The configuration for the workout
     */
    open func startWorkout(with workoutConfiguration:HKWorkoutConfiguration) {
        guard _workoutSession == nil else { return }
        
        _connectivitySession = WCSession.default()
        _connectivitySession?.delegate = self
        
        // Update the query identifiers (but only if they are not already set up
        if queryIdentifiers.count == 0 {
            queryIdentifiers = ORKWorkoutUtilities.queryIdentifiers(for: workoutConfiguration)
        }
        
        // Check if the watch has permission to run the workout
        let readTypes: [HKSampleType] = self.queryIdentifiers.mapAndFilter({ HKObjectType.quantityType(forIdentifier: $0) })
        let writeTypes = readTypes.appending(HKObjectType.workoutType())
        
        healthStore.requestAuthorization(toShare: Set(writeTypes), read: Set(readTypes)) { [weak self] (success, error) -> Void in
            if success {
                self?.finishStartingWorkout(workoutConfiguration)
            } else if error != nil {
                self?.handleError(error!)
            }
        }
    }
    
    private func finishStartingWorkout(_ workoutConfiguration: HKWorkoutConfiguration) {
        do {
            // Instantiate the workout session
            _workoutSession = try HKWorkoutSession(configuration: workoutConfiguration)
            _workoutSession?.delegate = self
            
            // Start the session
            _workoutStartDate = Date()
            healthStore.start(_workoutSession!)
            
        } catch let error {
            handleError(error)
        }
    }
    
    /**
     Stop the workout.
     */
    open func stopWorkout() {
        guard let session = _workoutSession, session.state != .ended else { return }
        
        // End the Workout Session
        _workoutEndDate = Date()
        healthStore.end(session)
    }
    
    func createAndSaveWorkout(_ session: HKWorkoutSession) {
        
        // Create and save a workout sample
        let configuration = session.workoutConfiguration
        let isIndoor = (configuration.locationType == .indoor) as NSNumber
        
        let workout = HKWorkout(activityType: configuration.activityType,
                                start: workoutStartDate,
                                end: workoutEndDate,
                                workoutEvents: workoutEvents,
                                totalEnergyBurned: totalEnergyBurned,
                                totalDistance: totalDistance,
                                metadata: [HKMetadataKeyIndoorWorkout:isIndoor]);
        
        healthStore.save(workout) { success, _ in
            if success, let samples = self.workoutSamples {
                self.healthStore.add(samples, to: workout) { (success: Bool, error: Error?) in
                    DispatchQueue.main.sync {
                        if success {
                            self.send(message: ORKWorkoutMessage(workoutState: .ended),
                                      replyHandler: { (_) in
                                        self.messagesToSend.removeAll()
                            },
                                      errorHandler: { (_) in
                                self.messagesToSend.removeAll()
                            })
                            self.delegate?.workoutConnector(self, didEndWorkout: workout)
                        }
                        else {
                            self.handleError(error!)
                        }
                        
                    }
                }
            }
        }
    }
    
    func process(samples: [HKSample], quantityTypeIdentifier: HKQuantityTypeIdentifier) {
        guard let quantitySamples = samples as? [HKQuantitySample] else { return }
        for sample in quantitySamples {
            if ORKWorkoutUtilities.supportedDistanceTypeIdentifiers.contains(quantityTypeIdentifier) {
                let newMeters = sample.quantity.doubleValue(for: HKUnit.meter())
                setTotalMeters(meters: totalMeters() + newMeters)
            }
            else if quantityTypeIdentifier == HKQuantityTypeIdentifier.activeEnergyBurned {
                let newKCal = sample.quantity.doubleValue(for: HKUnit.kilocalorie())
                setTotalCalories(calories: totalCalories() + newKCal)
            }
            else if quantityTypeIdentifier == HKQuantityTypeIdentifier.heartRate {
                setHeartRate(sample: sample)
            }
        }
        if startedFromPhone {
            let message = ORKSamplesWorkoutMessage()
            message.quantityTypeIdentifier = quantityTypeIdentifier
            message.samples = quantitySamples
            send(message: message)
        }
    }
    
    func handleError(_ error: Error) {
        #if DEBUG
        print("ERROR: Workout session did fail with error: \(error)")
        #endif
        
        // Send error message back to the phone
        send(message: ORKErrorWorkoutMessage(error: error as NSError))
    }
    
    /**
     Returns samples to include in the HKWorkout created by this workout session.
     */
    open var workoutSamples: [HKQuantitySample]? {
        
        var samples: [HKQuantitySample] = []
        
        if queryIdentifiers.contains(.activeEnergyBurned) {
            samples.append( HKQuantitySample(type: HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
                                             quantity: totalEnergyBurned,
                                             start: workoutStartDate,
                                             end: workoutEndDate))
        }

        if let identifier = distanceTypeIdentifier, let type = HKObjectType.quantityType(forIdentifier: identifier) {
            samples.append(HKQuantitySample(type: type,
                                            quantity: totalDistance,
                                            start: workoutStartDate,
                                            end: workoutEndDate))
        }

        if let startHeart = startingHeartRate {
            samples.append(startHeart)
        }

        if let endHeart = currentHeartRate {
            samples.append(endHeart)
        }
        
        return samples
    }
    
    
    // MARK: Convenience methods for calculating totals
    
    private func totalCalories() -> Double {
        return totalEnergyBurned.doubleValue(for: HKUnit.kilocalorie())
    }
    
    private func totalMeters() -> Double {
        return totalDistance.doubleValue(for: HKUnit.meter())
    }
    
    private func setTotalCalories(calories: Double) {
        totalEnergyBurned = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: calories)
        self.delegate?.workoutConnector?(self, didUpdateTotalEnergyBurned: totalDistance)
    }
    
    private func setTotalMeters(meters: Double) {
        totalDistance = HKQuantity(unit: HKUnit.meter(), doubleValue: meters)
        self.delegate?.workoutConnector?(self, didUpdateTotalDistance: totalDistance)
    }
    
    private func setHeartRate(sample: HKQuantitySample) {
        if startingHeartRate == nil {
            startingHeartRate = sample
        }
        currentHeartRate = sample
        self.delegate?.workoutConnector?(self, didUpdateHeartRate: sample.quantity)
    }

    
    // MARK: Data management
    
    func startAccumulatingData(startDate: Date) {
        for identifier in queryIdentifiers {
            startQuery(quantityTypeIdentifier: identifier)
        }
        if workoutDuration > 0 {
            startTimer()
        }
        
        DispatchQueue.main.sync {
            guard let session = _workoutSession else { return }
            self.delegate?.workoutConnector(self, didStartWorkout: session.workoutConfiguration)
        }
    }
    
    func stopAccumulatingData() {
        for query in activeDataQueries {
            healthStore.stop(query)
        }
        activeDataQueries.removeAll()
        stopTimer()
    }
    
    func pauseAccumulatingData() {
        DispatchQueue.main.sync {
            _isPaused = true
            self.delegate?.workoutConnectorDidPause?(self)
        }
    }
    
    func resumeAccumulatingData() {
        DispatchQueue.main.sync {
            _isPaused = false
            self.delegate?.workoutConnectorDidResume?(self)
        }
    }
    
    func startQuery(quantityTypeIdentifier: HKQuantityTypeIdentifier) {
        let datePredicate = HKQuery.predicateForSamples(withStart: workoutStartDate, end: nil, options: .strictStartDate)
        let devicePredicate = HKQuery.predicateForObjects(from: [HKDevice.local()])
        let queryPredicate = NSCompoundPredicate(andPredicateWithSubpredicates:[datePredicate, devicePredicate])
        
        let updateHandler: ((HKAnchoredObjectQuery, [HKSample]?, [HKDeletedObject]?, HKQueryAnchor?, Error?) -> Void) = {[weak self]  query, samples, deletedObjects, queryAnchor, error in
            self?.handleQueryResponse(samples: samples, quantityTypeIdentifier: quantityTypeIdentifier)
        }
        
        let query = HKAnchoredObjectQuery(type: HKObjectType.quantityType(forIdentifier: quantityTypeIdentifier)!,
                                          predicate: queryPredicate,
                                          anchor: nil,
                                          limit: HKObjectQueryNoLimit,
                                          resultsHandler: updateHandler)
        query.updateHandler = updateHandler
        healthStore.execute(query)
        
        activeDataQueries.append(query)
    }
    
    private func handleQueryResponse(samples: [HKSample]?, quantityTypeIdentifier: HKQuantityTypeIdentifier) {
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self, !strongSelf.isPaused, let querySamples = samples else { return }
            strongSelf.process(samples: querySamples, quantityTypeIdentifier: quantityTypeIdentifier)
        }
    }
    
    
    // MARK: Duration timer
    
    func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 5,
                                     target: self,
                                     selector: #selector(timerDidFire),
                                     userInfo: nil,
                                     repeats: true)
    }
    
    func timerDidFire(timer: Timer) {
        guard workoutDuration > 0 && _workoutSession != nil else { return }
        DispatchQueue.main.async {
            let duration = ORKWorkoutUtilities.computeDurationOfWorkout(withEvents: self.workoutEvents, startDate: self.workoutStartDate, endDate: nil)
            if duration > self.workoutDuration {
                self.stopWorkout()
            }
        }
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    

    // MARK: HKWorkoutSessionDelegate
    
    public func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        handleError(error)
    }
    
    public func workoutSession(_ workoutSession: HKWorkoutSession, didGenerate event: HKWorkoutEvent) {
        // save the message
        workoutEvents.append(event)
        
        // send the message to the phone (if available)
        send(message: ORKEventWorkoutMessage(event: event))
    }
    
    public func workoutSession(_ workoutSession: HKWorkoutSession,
                             didChangeTo toState: HKWorkoutSessionState,
                             from fromState: HKWorkoutSessionState,
                             date: Date) {
        switch toState {
        case .running:
            send(message: ORKWorkoutMessage(workoutState: .running))
            if fromState == .notStarted {
                startAccumulatingData(startDate: workoutStartDate)
            } else {
                resumeAccumulatingData()
            }
            
        case .paused:
            send(message: ORKWorkoutMessage(workoutState: .paused))
            pauseAccumulatingData()
            break
            
        case .ended:
            stopAccumulatingData()
            createAndSaveWorkout(workoutSession)
            break
            
        default:
            break
        }
    }

    
    // MARK: Watch connectivity handling
    
    private var messagesToSend = [MessageHandler]()
    
    /**
     Send a message to the phone.
     
     @param message         The dictionary with the message.
     @param replyHandler    The reply handler (or nil)
     @param errorHandler    The error handler (or nil)
    */
    open func send(message: ORKWorkoutMessage, replyHandler: (([String : Any]) -> Swift.Void)? = nil, errorHandler: ((Error) -> Swift.Void)? = nil) {
        
        #if DEBUG
            let errHandler: ((Error) -> Swift.Void)? = { (error) in
                print("Failed to send message: \(fullMessage) error: \(error)")
                errorHandler?(error)
            }
        #else
            let errHandler = errorHandler
        #endif
        
        if let wcSession = self.connectivitySession, wcSession.activationState == .activated, wcSession.isReachable {
            DispatchQueue.main.async {
                wcSession.sendMessage(message.dictionaryRepresentation(), replyHandler: replyHandler, errorHandler: errHandler)
            }
        } else {
            let session = WCSession.default()
            session.delegate = self
            session.activate()
            messagesToSend.append(MessageHandler(message: message, replyHandler: replyHandler, errorHandler: errHandler))
        }
    }
    
    func messageReceived(message: [String: Any], replyHandler: (([String : Any]) -> Swift.Void)? = nil) {
        guard let workoutMessage = ORKWorkoutMessage(message: message), workoutMessage.timestamp > workoutStartDate
        else {
            // If the timestamp is from before the workout started then ignore it.
            #if DEBUG
                print("Old message received: \(message)")
            #endif
            replyHandler?([:])
            return;
        }
        
        // Check if this is a command message and respond to the command (if applicable)
        if let session = self.workoutSession,
            let commandMessage = workoutMessage as? ORKInstructionWorkoutMessage,
            let command = commandMessage.command {
            switch(command) {
                
            case ORKWorkoutCommand.pause:
                healthStore.pause(session)
                
            case ORKWorkoutCommand.resume:
                healthStore.resumeWorkoutSession(session)
                
            case ORKWorkoutCommand.stop:
                stopWorkout()
                WKInterfaceDevice.current().play(.stop)
                
            case ORKWorkoutCommand.startMoving:
                WKInterfaceDevice.current().play(.start)
                
            case ORKWorkoutCommand.stopMoving:
                WKInterfaceDevice.current().play(.stop)
                
            default: break
            }
        }
        
        // Pass all instructions to the delegate
        self.delegate?.workoutConnector(self, didReceiveMessage: workoutMessage)
        
        // Send reply
        let replyMessage = ORKWorkoutMessage(identifier: workoutMessage.identifier)
        replyMessage.workoutState = {
            guard let sessionState = self.workoutSession?.state else { return ORKWorkoutState.notStarted }
            switch sessionState {
            case .notStarted:
                return .notStarted
            case .ended:
                return .ended
            case .running:
                return .running
            case .paused:
                return .paused
            }
        }()
        replyHandler?(replyMessage.dictionaryRepresentation())
    }
    
    private func sendPending() {
        DispatchQueue.main.async {
            if let wcSession = self.connectivitySession, wcSession.isReachable {
                for message in self.messagesToSend {
                    wcSession.sendMessage(message.message.dictionaryRepresentation(),
                                          replyHandler: message.replyHandler, errorHandler: message.errorHandler)
                }
                self.messagesToSend.removeAll()
            }
        }
    }
    
    // MARK : WCSessionDelegate
    
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if activationState == .activated {
            _connectivitySession = session
            sendPending()
        } else {
            #if DEBUG
            print("Watch connector \(session): activationDidCompleteWith: \(activationState) error: \(error)")
            #endif
        }
    }
    
    public func sessionReachabilityDidChange(_ session: WCSession) {
        #if DEBUG
        print("Watch connector \(session): sessionReachabilityDidChange")
        #endif
    }
    
    public func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            self.messageReceived(message: message)
        }
    }
    
    public func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Swift.Void) {
        DispatchQueue.main.async {
            self.messageReceived(message: message, replyHandler: replyHandler)
        }
    }
}

private class MessageHandler: NSObject {
    
    let message: ORKWorkoutMessage
    let replyHandler: (([String : Any]) -> Swift.Void)?
    let errorHandler: ((Error) -> Swift.Void)?
    
    init(message: ORKWorkoutMessage, replyHandler: (([String : Any]) -> Swift.Void)?, errorHandler: ((Error) -> Swift.Void)?) {
        self.message = message
        self.replyHandler = replyHandler
        self.errorHandler = errorHandler
        super.init()
    }
}

extension ORKWorkoutMessage {
    convenience init(workoutState: ORKWorkoutState) {
        self.init()
        self.workoutState = workoutState
    }
}

extension ORKErrorWorkoutMessage {
    convenience init(error: NSError) {
        self.init()
        self.error = error
    }
}

extension ORKEventWorkoutMessage {
    convenience init(event: HKWorkoutEvent) {
        self.init()
        self.event = event
    }
}
