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

open class ORKCardioWorkoutInterfaceController: WKInterfaceController, ORKWorkoutConnectorDelegate {
    
    public static let name = "WorkoutInterfaceController"
    
    public let formatter = ORKWorkoutFormatter()
    public let connector = ORKWorkoutConnector()
    
    public var summaryControllerName = ORKSummaryInterfaceController.name
    
    public var walkingDuration: TimeInterval = 2 * 60 // DO NOT COMMIT!!! 6 * 60
    public var isInitialState: Bool = true;
    
    // MARK: IBOutlets
    
    @IBOutlet public var titleLabel: WKInterfaceLabel?
    @IBOutlet public var heartRateLabel: WKInterfaceLabel?
    @IBOutlet public var distanceLabel: WKInterfaceLabel?
    @IBOutlet var durationTimer: WKInterfaceTimer?
    
    // MARK: IBActions
    
    @IBAction open func didTapStopButton() {
        connector.stopWorkout()
    }
    
    // MARK: Awake from nib
    
    override open func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        titleLabel?.setText(formatter.localizedString(withKey: "HEARTRATE_MONITOR_CAMERA_STAND_STILL_WATCH"))
        heartRateLabel?.setText("")
        distanceLabel?.setText("")
        
        connector.delegate = self
        
        // setup permissions and start the workout
        if let workoutConfiguration = context as? HKWorkoutConfiguration {
            // start the workout with a phone connection
            connector.startedFromPhone = true
            connector.startWorkout(with: workoutConfiguration)
            
        } else {
            // Create workout configuration
            let workoutConfiguration = HKWorkoutConfiguration()
            workoutConfiguration.activityType = .walking
            workoutConfiguration.locationType = .outdoor
            
            // Start the workout
            isInitialState = true
            connector.startWorkout(with: workoutConfiguration)
        }
    }
    
    // MARK: ORKWorkoutConnectorDelegate
    
    open func workoutConnector(_ workoutConnector: ORKWorkoutConnector, didStartWorkout configuration:HKWorkoutConfiguration) {
        heartRateLabel?.setText("--")
        distanceLabel?.setText("--")
        
        durationTimer?.setDate(Date())
        durationTimer?.start()
    }
    
    open func workoutConnector(_ workoutConnector: ORKWorkoutConnector, didEndWorkout workout:HKWorkout) {
        durationTimer?.stop()
        WKInterfaceController.reloadRootControllers(withNames: [summaryControllerName], contexts: [workout])
    }
    
    open func workoutConnector(_ workoutConnector: ORKWorkoutConnector, didReceiveMessage message:ORKWorkoutMessage) {
        guard let instructionMessage = message as? ORKInstructionWorkoutMessage else { return }
        if let instruction = instructionMessage.instruction {
            titleLabel?.setText(instruction)
            let stepDuration = instructionMessage.stepDuration
            let date = instructionMessage.timestamp.addingTimeInterval(stepDuration)
            durationTimer?.setDate(date)
            durationTimer?.start()
        }
    }
    
    open func workoutConnector(_ workoutConnector: ORKWorkoutConnector, didUpdateTotalDistance totalDistance:HKQuantity) {
        distanceLabel?.setText(formatter.formatted(withDistance: totalDistance))
    }
    
    open func workoutConnector(_ workoutConnector: ORKWorkoutConnector, didUpdateHeartRate heartRate:HKQuantity) {
        if (!connector.startedFromPhone && isInitialState) {
            isInitialState = false
            titleLabel?.setText(formatter.localizedString(withKey: "FITNESS_WALK_INSTRUCTION_WATCH"))
            connector.workoutDuration = walkingDuration
            durationTimer?.setDate(Date(timeIntervalSinceNow: connector.workoutDuration))
            durationTimer?.start()
        }
        heartRateLabel?.setText(formatter.formatted(withHeartRate: heartRate))
    }
}
