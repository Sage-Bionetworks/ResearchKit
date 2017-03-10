//
//  ViewController.swift
//  CardioChallenge
//
//  Copyright © 2017 Sage Bionetworks. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
// 1.  Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// 2.  Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation and/or
// other materials provided with the distribution.
//
// 3.  Neither the name of the copyright holder(s) nor the names of any contributors
// may be used to endorse or promote products derived from this software without
// specific prior written permission. No license is granted to the trademarks of
// the copyright holders even if such marks are included in this software.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

import UIKit
import ResearchKit

class ViewController: UIViewController, ORKTaskViewControllerDelegate {

    @IBAction func cardioChallegeTapped(_ sender: Any) {
        showWorkout(workoutOnly: false)
    }

    @IBAction func workoutOnlyTapped(_ sender: Any) {
        showWorkout(workoutOnly: true)
    }
    
    @IBAction func heartrateOnlyTapped(_ sender: Any) {
        let workoutStep = ORKWorkoutStep(identifier: "workout",
                                         motionSteps: [],
                                         restStep: nil,
                                         relativeDistanceOnly: false,
                                         options: [.excludeAccelerometer, .excludeDeviceMotion, .excludeLocation, .excludePedometer])
        let bpmCrossRefStep = ORKQuestionStep(identifier: "bpm_oximeter", title: "What is your heart rate using the oximeter?", answer: ORKNumericAnswerFormat(style: .integer, unit: "bpm"))
        
        
        let task = ORKOrderedTask(identifier: "heartrateOnly", steps: [workoutStep, bpmCrossRefStep])
        show(task: task);
    }
    
    func showWorkout(workoutOnly:Bool) {
        var task = ORKOrderedTask.cardioChallenge(withIdentifier: "cardioChallege",
                                                  intendedUseDescription: "This is an example of how the task works.",
                                                  walkDuration: 2 * 60,
                                                  restDuration: 30,
                                                  relativeDistanceOnly: false,
                                                  options: [])
        if (workoutOnly) {
            let workoutSteps = task.steps.filter({ $0 is ORKWorkoutStep })
            task = ORKOrderedTask(identifier: "workoutOnly", steps: workoutSteps)
        }
        show(task: task);
    }
    
    func show(task:ORKOrderedTask) {
        let taskVC = ORKTaskViewController(task: task, taskRun: nil)
        taskVC.delegate = self
        
        // Assign a directory to store `taskViewController` output.
        taskVC.outputDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        self.present(taskVC, animated: true, completion: nil)
    }
    
    func taskViewController(_ taskViewController: ORKTaskViewController, didFinishWith reason: ORKTaskViewControllerFinishReason, error: Error?) {
        
        let result = taskViewController.result
        print("Finished with \(result) and error: \(error)")
        
        taskViewController.dismiss(animated: true) { 
            let resultVC = ResultsTableViewController(style: .grouped)
            resultVC.taskResult = result
            self.navigationController?.pushViewController(resultVC, animated: true)
        }
    }

}

