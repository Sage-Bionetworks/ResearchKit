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


import Foundation
import HealthKit

/**
 `ORKWorkoutUtilities` is a utility object for converting various enums and identifiers
 that are used by an `HKWorkout`.
 */
@objc
public final class ORKWorkoutUtilities: NSObject {
    
    /**
     Utility method for converting a workout event type to a `NSString` that can be used
     by Objective-c classes.
     
     @param workoutEventType    The `HKWorkoutEventType` to convert
     
     @return                    The identifier for this event type
    */
    @objc(identifierForWorkoutEventType:)
    public class func identifier(for workoutEventType:HKWorkoutEventType) -> String? {
        return workoutEventType.identifier
    }
    
    /**
     Utility method for converting an identifier to an `NSInteger` that maps to the
     `HKWorkoutEventType`. Returns `0` if undefined.
     
     @param identifier    The identifier to convert
     
     @return              The `rawValue` for the `HKWorkoutEventType` enum
     */
    @objc(workoutEventTypeForIdentifier:)
    public class func workoutEventType(for identifier:String) -> Int {
        guard let type = HKWorkoutEventType(identifier: identifier) else {
            return 0
        }
        return type.rawValue
    }
    
    /**
     Utility method for converting a workout location type to a `NSString` that can be used
     by Objective-c classes.
     
     @param locationType        The `HKWorkoutSessionLocationType` to convert
     
     @return                    The identifier for this event type
     */
    @available(iOS 10.0, *)
    @available(watchOS 3.0, *)
    @objc(identifierForWorkoutSessionLocationType:)
    public class func identifier(for locationType:HKWorkoutSessionLocationType) -> String? {
        return locationType.identifier
    }
    
    /**
     Utility method for converting an identifier to an `NSInteger` that maps to the
     `HKWorkoutSessionLocationType`. Returns `HKWorkoutSessionLocationTypeUnknown` if undefined.
     
     @param identifier    The identifier to convert
     
     @return              The `rawValue` for the `HKWorkoutSessionLocationType` enum
     */
    @available(iOS 10.0, *)
    @available(watchOS 3.0, *)
    @objc(workoutSessionLocationTypeForIdentifier:)
    public class func workoutLocationType(for identifier:String) -> Int {
        let type = HKWorkoutSessionLocationType(identifier: identifier)
        return type.rawValue
    }
    
    /**
     Utility method for converting a workout activity type to a `NSString` that can be used
     by Objective-c classes.
     
     @param workoutActivityType The `HKWorkoutActivityType` to convert
     
     @return                    The identifier for this event type
     */
    @objc(identifierForWorkoutActivityType:)
    public class func identifier(for workoutActivityType:HKWorkoutActivityType) -> String? {
        return workoutActivityType.identifier
    }
    
    /**
     Utility method for converting an identifier to an `NSInteger` that maps to the
     `HKWorkoutActivityType`. Returns `HKWorkoutActivityTypeOther` if undefined.
     
     @param identifier    The identifier to convert
     @return              The `rawValue` for the `HKWorkoutActivityType` enum
     */
    @objc(workoutActivityTypeForIdentifier:)
    public class func workoutActivityType(for identifier:String) -> UInt {
        let type = HKWorkoutActivityType(identifier: identifier)
        return type.rawValue
    }
    
    /**
     List of the distance types to be measured and their associated preferred unit.
     */
    open static let supportedDistanceTypeIdentifiers : [HKQuantityTypeIdentifier] = {
        var types: [HKQuantityTypeIdentifier] = [.distanceWalkingRunning,
                                                 .distanceCycling]
        if #available(iOS 10.0, *), #available(watchOS 3.0, *){
            types.append(.distanceSwimming)
            types.append(.distanceWheelchair)
        }
        return types
    }()
    
    /**
     List of `HKQuantityTypeIdentifier` to include by default for a given configuration.
     
     @param  workoutConfiguration   The workout configuration
     
     @return                        List of identifiers
    */
    @available(iOS 10.0, *)
    @available(watchOS 3.0, *)
    @objc(queryIdentifiersForWorkoutConfiguration:)
    open class func queryIdentifiers(for workoutConfiguration: HKWorkoutConfiguration) -> [HKQuantityTypeIdentifier] {
        
        var queryIds: [HKQuantityTypeIdentifier] = [HKQuantityTypeIdentifier.activeEnergyBurned,
                                                    HKQuantityTypeIdentifier.heartRate]
        
        switch workoutConfiguration.activityType {
        case .crossTraining, .crossCountrySkiing, .golf, .hiking, .running, .walking:
            queryIds.append(.distanceWalkingRunning)
        case .cycling:
            queryIds.append(.distanceCycling)
        case .swimming:
            queryIds.append(.distanceSwimming)
        case .wheelchairWalkPace, .wheelchairRunPace:
            queryIds.append(.distanceWheelchair)
        default:
            break
        }
        
        return queryIds
    }
    
    /**
     Using the workout events to check for pause/resume, calculate the duration of the workout.
     
     @param     workoutEvents   The array of workout events (Optional)
     @param     startDate       The start date of the workout (Optional)
     @param     endDate         The end date of the workout (Optional)
     
     @return    Calculated duration
     */
    open class func computeDurationOfWorkout(withEvents workoutEvents: [HKWorkoutEvent]?, startDate: Date?, endDate: Date?) -> TimeInterval {
        var duration = 0.0
        
        if var lastDate = startDate {
            var paused = false
            
            if let events = workoutEvents {
                for event in events {
                    switch event.type {
                    case .pause:
                        duration += event.date.timeIntervalSince(lastDate)
                        paused = true
                        
                    case .resume:
                        lastDate = event.date
                        paused = false
                        
                    default:
                        continue
                    }
                }
            }
            
            if !paused {
                if let end = endDate {
                    duration += end.timeIntervalSince(lastDate)
                } else {
                    duration += NSDate().timeIntervalSince(lastDate)
                }
            }
        }
        
        return duration
    }
}

func debug_print(_ message: String) {
    #if DEBUG
        print(message)
    #endif
}

public extension HKWorkoutActivityType {
    
    /**
     Initializer that uses an `identifier` string.
     
     @param identifier    The identifier to convert
     @return              An `HKWorkoutActivityType`. Default = `.other`
     */
    public init(identifier: String) {
        guard let idx = ORKWorkoutActivityTypeIdentifiers.index(of: identifier),
            let type = HKWorkoutActivityType(rawValue: UInt(idx) + 1)
            else {
                self = .other
                return
        }
        self = type
    }
    
    /**
     String identifier for this enum value.
     */
    public var identifier: String {
        let idx = self.rawValue
        guard idx >= 1 && idx <= UInt(ORKWorkoutActivityTypeIdentifiers.count) else {
            return "other"
        }
        return ORKWorkoutActivityTypeIdentifiers[Int(idx) - 1]
    }
}

public extension HKWorkoutEventType {
    
    /**
     Initializer that uses an `identifier` string.
     
     @param identifier    The identifier to convert
     @return              An `HKWorkoutEventType` or `nil` if undefined
     */
    public init?(identifier: String) {
        guard let idx = ORKWorkoutEventTypeIdentifiers.index(of: identifier),
            let type = HKWorkoutEventType(rawValue: idx + 1) else {
                return nil
        }
        self = type
    }
    
    /**
     String identifier for this enum value.
    */
    public var identifier: String {
        let idx = self.rawValue
        guard idx >= 1 && idx <= ORKWorkoutEventTypeIdentifiers.count else {
            return "other"
        }
        return ORKWorkoutEventTypeIdentifiers[idx - 1]
    }
}

@available(iOS 10.0, *)
@available(watchOS 3.0, *)
public extension HKWorkoutSessionLocationType {
    
    /**
     Initializer that uses an `identifier` string.
     
     @param identifier    The identifier to convert
     @return              An `HKWorkoutSessionLocationType`. Default = `.unknown`
     */
    public init(identifier: String) {
        guard let idx = ORKWorkoutSessionLocationTypeIdentifiers.index(of: identifier),
            let type = HKWorkoutSessionLocationType(rawValue: Int(idx) + 1)
            else {
                self = .unknown
                return
        }
        self = type
    }
    
    /**
     String identifier for this enum value.
     */
    public var identifier: String {
        let idx = self.rawValue
        guard idx >= 1 && idx <= ORKWorkoutSessionLocationTypeIdentifiers.count else {
            return ORKWorkoutSessionLocationTypeIdentifiers[0]
        }
        return ORKWorkoutSessionLocationTypeIdentifiers[idx - 1]
    }
    
}

// MARK: Identifier map

fileprivate let ORKWorkoutActivityTypeIdentifiers = [   "americanFootball",
                                                        "archery",
                                                        "australianFootball",
                                                        "badminton",
                                                        "baseball",
                                                        "basketball",
                                                        "bowling",
                                                        "boxing",
                                                        "climbing",
                                                        "cricket",
                                                        "crossTraining",
                                                        "curling",
                                                        "cycling",
                                                        "dance",
                                                        "danceInspiredTraining",
                                                        "elliptical",
                                                        "equestrianSports",
                                                        "fencing",
                                                        "fishing",
                                                        "functionalStrengthTraining",
                                                        "golf",
                                                        "gymnastics",
                                                        "handball",
                                                        "hiking",
                                                        "hockey",
                                                        "hunting",
                                                        "lacrosse",
                                                        "martialArts",
                                                        "mindAndBody",
                                                        "mixedMetabolicCardioTraining",
                                                        "paddleSports",
                                                        "play",
                                                        "preparationAndRecovery",
                                                        "racquetball",
                                                        "rowing",
                                                        "rugby",
                                                        "running",
                                                        "sailing",
                                                        "skatingSports",
                                                        "snowSports",
                                                        "soccer",
                                                        "softball",
                                                        "squash",
                                                        "stairClimbing",
                                                        "surfingSports",
                                                        "swimming",
                                                        "tableTennis",
                                                        "tennis",
                                                        "trackAndField",
                                                        "traditionalStrengthTraining",
                                                        "volleyball",
                                                        "walking",
                                                        "waterFitness",
                                                        "waterPolo",
                                                        "waterSports",
                                                        "wrestling",
                                                        "yoga",
                                                        "barre",
                                                        "coreTraining",
                                                        "crossCountrySkiing",
                                                        "downhillSkiing",
                                                        "flexibility",
                                                        "highIntensityIntervalTraining",
                                                        "jumpRope",
                                                        "kickboxing",
                                                        "pilates",
                                                        "snowboarding",
                                                        "stairs",
                                                        "stepTraining",
                                                        "wheelchairWalkPace",
                                                        "wheelchairRunPace"]

fileprivate let ORKWorkoutEventTypeIdentifiers = ["pause",
                                                  "resume",
                                                  "lap",
                                                  "marker",
                                                  "motionPaused",
                                                  "motionResumed"]

fileprivate let ORKWorkoutSessionLocationTypeIdentifiers = ["unknown",
                                                            "indoor",
                                                            "outdoor"]

