//
//  extraFunctions.swift
//  Chronic
//
//  Created by Ace Green on 2015-03-24.
//  Copyright (c) 2015 Ace Green. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import HealthKit
import WatchConnectivity

func timeStringFrom(time: Int) -> String {
    
    let HoursLeft = time/3600
    let MinutesLeft = (time%3600)/60
    let SecondsLeft = (((time%3600)%60)%60)
    
    if HoursLeft == 0 {
        return String(format:"%.2d:%.2d", MinutesLeft, SecondsLeft)
    } else {
        return String(format:"%2d:%.2d:%.2d", HoursLeft, MinutesLeft, SecondsLeft)
    }
}

//MARK: - Core Data Function
func insertCoreDataObject(appContext: [String : AnyObject]) {
    
    let routineName = appContext["routineName"]
    let routineType = appContext["routineType"]
    let routineStage = appContext["routineStage"]
    
    let exerciseSet = NSMutableOrderedSet()
    
    let newRoutine = RoutineModel(entity: routineEntity!, insertInto: context)
    
    for stage in 0 ..< routineStage!.count {
        
        let currentStageDict = routineStage![stage] as! [String:AnyObject]
        
        let newExercise = ExerciseModel(entity: exerciseEntity!, insertInto: context)
        
        newExercise.exerciseName = currentStageDict["Name"] as? String
        newExercise.exerciseTime = currentStageDict["Time"] as? Int
        
        newExercise.exerciseNumberOfRounds = 1
        
        newExercise.exerciseColor = currentStageDict["Color"]
        
        newExercise.exerciseToRoutine = newRoutine
        
        exerciseSet.add(newExercise)
        
    }
    
    newRoutine.routineToExcercise = exerciseSet
    
    newRoutine.name = routineName! as? String
    newRoutine.selectedRoutine = true
    newRoutine.date = Date()
    
    newRoutine.tableDisplayOrder = 1
    
    newRoutine.type = routineType! as? String
    
    let (_, totalTime) = makeRoutineArray(routine: newRoutine)
    
    newRoutine.totalRoutineTime = totalTime
    
    do {
        
        // save into CoreData
        try context.save()
        
        NotificationCenter.default.post(name: "willActivate" as NSNotification.Name, object: nil)
        
    } catch let error as NSError {
        
        print("Fetch failed: \(error.localizedDescription)")
        
        abort()
    }
    
    // print(newRoutine)
    
}

func modifyCoreDataObject(appContext: [String : AnyObject]) {
    
    let routineName = appContext["routineName"] as! String
    let routineStage = appContext["routineStage"]
    
    let exerciseSet = NSMutableOrderedSet()
    
    let existingRoutinePredicate: Predicate = Predicate(format:  "name == %@", routineName)
    
    if let existingRoutine = WatchDataAccess.sharedInstance.GetRoutines(predicate: existingRoutinePredicate)!.first {
        
        for stage in 0 ..< routineStage!.count {
            
            let currentStageDict = routineStage![stage] as! [String:AnyObject]
            
            let newExercise = ExerciseModel(entity: exerciseEntity!, insertInto: context)
            
            newExercise.exerciseName = currentStageDict["Name"] as? String
            newExercise.exerciseTime = currentStageDict["Time"] as? Int
            
            newExercise.exerciseNumberOfRounds = 1
            
            newExercise.exerciseColor = currentStageDict["Color"]
            
            newExercise.exerciseToRoutine = existingRoutine
            
            exerciseSet.add(newExercise)
            
        }
        
        existingRoutine.routineToExcercise = exerciseSet
        
        existingRoutine.selectedRoutine = true
        existingRoutine.date = Date()
        
        let (_, totalTime) = makeRoutineArray(routine: existingRoutine)
        
        existingRoutine.totalRoutineTime = totalTime
        
        do {
            
            // save into CoreData
            try context.save()
            
            NotificationCenter.default.post(name: "willActivate" as NSNotification.Name, object: nil)
            
        } catch let error as NSError {
            
            print("Fetch failed: \(error.localizedDescription)")
            
            abort()
        }
        
    } else {
        
        insertCoreDataObject(appContext: appContext)
    }
}

func deleteCoreDataObject(appContext: [String : AnyObject]) {
    
    let routineName = appContext["routineName"] as! String
    
    let existingRoutinePredicate: Predicate = Predicate(format:  "name == %@", routineName)
    
    let existingRoutine = WatchDataAccess.sharedInstance.GetRoutines(predicate: existingRoutinePredicate)!.first
    
    if existingRoutine != nil {
        
        context.delete(existingRoutine!)
        
        do {
            
            // save into CoreData
            try context.save()
            
            NotificationCenter.default.post(name: "willActivate" as NSNotification.Name, object: nil)
            
        } catch let error as NSError {
            
            print("Fetch failed: \(error.localizedDescription)")
            
            abort()
        }
    }
}

//MARK: -Exercise Function
func makeRoutineArray(routine: RoutineModel?) -> ([[String:AnyObject]], Int) {
    
    let stagesArray = NSMutableArray()
    var totalTime = 0
    
    if routine != nil {
        
        var customeExerciseDictionary = [String:AnyObject]()

        let routineExercises = routine!.routineToExcercise?.array as! [ExerciseModel]
        let type:String = routine!.type!
        
        if type == "Custom" || type == "Circuit"  {
            
            for exercise in routineExercises {
                
                for _ in 1...(exercise.exerciseNumberOfRounds as Int) {
                    
                    if exercise.exerciseTime as Int > 0 {
                        
                        //Exercise Name & Time
                        customeExerciseDictionary["Name"] = exercise.exerciseName
                        customeExerciseDictionary["Time"] = exercise.exerciseTime
                        customeExerciseDictionary["Color"] = exercise.exerciseColor
                        
                        totalTime += customeExerciseDictionary["Time"] as! Int
                        
                        stagesArray.add(customeExerciseDictionary)
                    }
                }
            }
        }
        
    } else {
        
        var quickTimerDictionary = [String:AnyObject]()
        
        // Quick Timer Time
        quickTimerDictionary["Name"] = NSLocalizedString("Quick Timer", comment: "")
        quickTimerDictionary["Time"] = QuickTimerTime
        quickTimerDictionary["Color"] = NSKeyedArchiver.archivedData(withRootObject: UIColor.orange())
        
        totalTime += quickTimerDictionary["Time"] as! Int
        
        stagesArray.add(quickTimerDictionary)
        
    }
    
    print(stagesArray, totalTime)
    return (stagesArray as AnyObject as! [[String:AnyObject]], totalTime)
}

func removeAdsUpgradePurchased() -> Bool {
    
    guard keychainRemoveAdsString == removeAdsKeyValue else {
        return false
    }
    
    return true
}

func proFeaturesUpgradePurchased() -> Bool {
    
    guard keychainProVersionString == proVersionKeyValue else {
        return false
    }
    
    return true
}

//@available(iOSApplicationExtension 9.0, *)
//func startWorkoutSession(activityType: HKWorkoutActivityType, locationType: HKWorkoutSessionLocationType) {
//    
//    let workoutSession: HKWorkoutSession = HKWorkoutSession()
//    
//    healthKitStore.startWorkoutSession(workoutSession) {
//        success, error in
//        
//        if error != nil {
//            print("startWorkoutSession \(error)\n")
//        }
//    }
//}
