//
//  Workout.swift
//  Chronic
//
//  Created by Ace Green on 9/4/16.
//  Copyright © 2016 Ace Green. All rights reserved.
//

import UIKit
import Foundation
import HealthKit
import ChronicKit

public class Workout {
    
    enum WorkoutType: String {
        case routine
        case run
        case quickTimer
    }
    
    enum WorkoutState {
        case preRun
        case active
        case paused
        case completed
    }
    
    var name: String!
    
    var totalTime: Int = 0

    var timeRemaining: Int = 0
    var timeElapsed: Int = 0
    
    var kiloCalories: Double = 0.0
    var distance: Double = 0.0
    var pace: Double = 0.0
    
    var workoutActivityType: HKWorkoutActivityType
    var workoutType: WorkoutType
    var workoutState: WorkoutState

    var routineStages = [[String:Any]]()
    var currentTimerDict = [String:Any]()
    
    var routineIndex: Int = 0
    var routineStartDate: Date!
    var routineEndDate: Date!
    
    let routineModel: RoutineModel?
    var nsUserActivity: NSUserActivity?
    
    var mapImage: UIImage?
    
    var searchDescription: String {
        let totalTimeString = Functions.timeStringFrom(time: self.totalTime)
        return "Total Time: \(totalTimeString)"
    }
    
    init(workoutActivityType: HKWorkoutActivityType, workoutType: WorkoutType, workoutState: WorkoutState = .preRun, routineModel: RoutineModel? = nil) {
        
        self.workoutActivityType = workoutActivityType
        self.workoutType = workoutType
        self.workoutState = workoutState
        self.routineModel = routineModel
        
        switch self.workoutType {
        case .quickTimer:
            self.name = "Chronic Quick Timer"
            (self.routineStages, self.totalTime) = Functions.makeRoutineArray(routine: nil)
        case .routine:
            self.name = routineModel?.name
            (self.routineStages, self.totalTime) = Functions.makeRoutineArray(routine: routineModel)
        case .run:
            self.name = "Chronic Run"
        }
    }
}
