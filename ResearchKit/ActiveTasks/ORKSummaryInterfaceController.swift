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

import WatchKit
import HealthKit

open class ORKSummaryInterfaceController: WKInterfaceController {
    
    public static let name = "SummaryInterfaceController"
    
    // MARK: Properties
    
    open var startControllerName = ORKStartInterfaceController.name
    
    open var workout: HKWorkout?
    
    open let formatter = ORKWorkoutFormatter()
    
    // MARK: IB Outlets
    
    @IBOutlet public var workoutLabel: WKInterfaceLabel?
    @IBOutlet public var durationLabel: WKInterfaceLabel?
    @IBOutlet public var caloriesLabel: WKInterfaceLabel?
    @IBOutlet public var distanceLabel: WKInterfaceLabel?
    
    // MARK: Interface Controller Overrides
    
    override open func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        self.workout = context as? HKWorkout
    }
    
    override open func willActivate() {
        super.willActivate()
        
        guard let workout = workout else { return }
        
        workoutLabel?.setText(formatter.localizedString(withKey: "CARDIO_WATCH_SUMMARY_TITLE"))

        if let totalEnergyBurned = workout.totalEnergyBurned {
            caloriesLabel?.setText(formatter.formatted(withEnergy: totalEnergyBurned))
        }
        if let totalDistance = workout.totalDistance {
            distanceLabel?.setText(formatter.formatted(withDistance: totalDistance))
        }
        
        let duration = ORKWorkoutUtilities.computeDurationOfWorkout(withEvents: workout.workoutEvents, startDate: workout.startDate, endDate: workout.endDate)
        durationLabel?.setText(formatter.formatted(withDuration: duration))
    }
    
    @IBAction open func didTapDoneButton() {
        WKInterfaceController.reloadRootControllers(withNames: [startControllerName], contexts: nil)
    }

}
