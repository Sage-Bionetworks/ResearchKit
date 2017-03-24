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
open class ORKWorkoutConnector: NSObject, HKWorkoutSessionDelegate {
    
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
     Workout state for tracking startup/shutdown
    */
    public var workoutState: ORKWorkoutState {
        guard let sessionState = self.workoutSession?.state else { return ORKWorkoutState.notStarted }
        switch sessionState {
        case .notStarted, .running:
            return _workoutState
        case .ended:
            return .ended
        case .paused:
            return .paused
        }
    }
    fileprivate var _workoutState: ORKWorkoutState = .notStarted

    /**
     Should the connector send messages to the phone?
     */
    public var startedFromPhone = false
    
    /**
     Should the connector timeout after a given duration? Default = 15 minutes.
     */
    public var workoutDuration: TimeInterval = 15.0 * 60.0 {
        didSet {
            if workoutDuration > 0 {
                startTimer()
            } else {
                stopTimer()
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
    
    fileprivate var totalEnergyBurned = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: 0)
    fileprivate var totalDistance = HKQuantity(unit: HKUnit.meter(), doubleValue: 0)
    fileprivate var currentHeartRate: HKQuantitySample?
    fileprivate var startingHeartRate: HKQuantitySample?
    fileprivate var activeDataQueries = [HKQuery]()
    fileprivate var workoutEvents = [HKWorkoutEvent]()
    fileprivate var timer: Timer?
    
    
    // MARK: Workout session handling - override these methods to implement custom handling
    
    /**
     Start the workout with the given configuration.
     
     @param workoutConfiguration    The configuration for the workout
     */
    public func startWorkout(with workoutConfiguration:HKWorkoutConfiguration) {
        guard _workoutSession == nil else { return }
        
        _workoutState = .starting
        ORKPhoneConnector.shared.workoutConnector = self
        
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
    public func stopWorkout() {
        guard let session = _workoutSession, session.state != .ended else { return }
        
        debug_print("CALLED: stopWorkout()")
        _workoutState = .stopping
        
        // End the Workout Session
        _workoutEndDate = Date()
        healthStore.end(session)
    }
    
    private func createAndSaveWorkout(_ session: HKWorkoutSession) {
        
        debug_print("CALLED: createAndSaveWorkout(\(session))")

        _workoutState = .ended
        
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
        
        healthStore.save(workout) { (success, error) in
            if success, let samples = self.workoutSamples {
                self.healthStore.add(samples, to: workout) { (_, _) in
                    self.sendFinishedMessage(with: workout)
                }
            } else {
                if (error != nil) {
                    print("Failed to save workout: \(error)")
                }
                self.sendFinishedMessage(with: workout)
            }
        }
    }
    
    private func sendFinishedMessage(with workout: HKWorkout) {
        
        debug_print("CALLED: sendFinishedMessage(workout: \(workout))")
        
        _workoutState = .notStarted
        ORKPhoneConnector.shared.workoutConnector = nil
        ORKPhoneConnector.shared.send(message: ORKWorkoutMessage(workoutState: .ended))

        DispatchQueue.main.async {
            self._workoutSession = nil
            self.delegate?.workoutConnector(self, didEndWorkout: workout)
        }
    }
    
    private func process(samples: [HKSample], quantityTypeIdentifier: HKQuantityTypeIdentifier) {
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
    
    private func handleError(_ error: Error) {
        print("ERROR: Workout session did fail with error: \(error)")
        
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
    
    private func startAccumulatingData(startDate: Date) {
        for identifier in queryIdentifiers {
            startQuery(quantityTypeIdentifier: identifier)
        }
        if workoutDuration > 0 {
            startTimer()
        }
        
        DispatchQueue.main.async {
            guard let session = self._workoutSession else { return }
            self.delegate?.workoutConnector(self, didStartWorkout: session.workoutConfiguration)
        }
    }
    
    private func stopAccumulatingData() {
        for query in activeDataQueries {
            healthStore.stop(query)
        }
        activeDataQueries.removeAll()
        stopTimer()
    }
    
    private func startQuery(quantityTypeIdentifier: HKQuantityTypeIdentifier) {
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
            guard let strongSelf = self, let querySamples = samples else { return }
            strongSelf.process(samples: querySamples, quantityTypeIdentifier: quantityTypeIdentifier)
        }
        checkWorkoutDuration()
    }
    
    
    // MARK: Duration timer
    
    fileprivate var startTime = ProcessInfo().systemUptime
    
    func startTimer() {
        startTime = ProcessInfo().systemUptime
        DispatchQueue.main.async {
            self.timer?.invalidate()
            self.timer = Timer.scheduledTimer(timeInterval: 1,
                                         target: self,
                                         selector: #selector(self.timerDidFire),
                                         userInfo: nil,
                                         repeats: true)
        }
    }
    
    func timerDidFire(timer: Timer) {
        checkWorkoutDuration()
    }
    
    func checkWorkoutDuration() {
        DispatchQueue.main.async {
            let duration = ProcessInfo().systemUptime - self.startTime
            if (self.workoutState == .running) && (self.workoutDuration > 0) && (duration > self.workoutDuration) {
                self.stopWorkout()
            }
        }
    }
    
    func stopTimer() {
        DispatchQueue.main.async {
            self.timer?.invalidate()
            self.timer = nil
        }
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
            _workoutState = .running
            send(message: ORKWorkoutMessage(workoutState: .running))
            startAccumulatingData(startDate: workoutStartDate)
            
        case .ended:
            stopAccumulatingData()
            createAndSaveWorkout(workoutSession)
            break
            
        default:
            break
        }
    }
    
    
    // MARK: Message communication with phone.
    
    func send(message: ORKWorkoutMessage) {
        ORKPhoneConnector.shared.workoutConnector = self
        ORKPhoneConnector.shared.send(message: message)
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
                WKInterfaceDevice.current().play(.notification)
                
            case ORKWorkoutCommand.startMoving:
                WKInterfaceDevice.current().play(.notification)
                
            case ORKWorkoutCommand.stopMoving:
                WKInterfaceDevice.current().play(.notification)
                
            default: break
            }
        }
        
        // Pass all instructions to the delegate
        self.delegate?.workoutConnector(self, didReceiveMessage: workoutMessage)
        
        // Send reply
        let replyMessage = ORKWorkoutMessage(identifier: workoutMessage.identifier)
        replyMessage.workoutState = self.workoutState
        replyHandler?(replyMessage.dictionaryRepresentation())
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
