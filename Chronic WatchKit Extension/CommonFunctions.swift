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

func timeStringFrom(time time: Int) -> String {
    
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
    
    let newRoutine = RoutineModel(entity: routineEntity!, insertIntoManagedObjectContext: context)
    
    for var stage = 0; stage < routineStage!.count; stage++ {
        
        let currentStageDict = routineStage!.objectAtIndex(stage) as! [String:AnyObject]
        
        let newExercise = ExerciseModel(entity: exerciseEntity!, insertIntoManagedObjectContext: context)
        
        newExercise.exerciseName = currentStageDict["Name"] as? String
        newExercise.exerciseTime = currentStageDict["Time"] as? Int
        
        newExercise.exerciseNumberOfRounds = 1
        
        newExercise.exerciseColor = currentStageDict["Color"]
        
        newExercise.exerciseToRoutine = newRoutine
        
        exerciseSet.addObject(newExercise)
        
    }
    
    newRoutine.routineToExcercise = exerciseSet
    
    newRoutine.name = routineName! as? String
    newRoutine.selectedRoutine = true
    newRoutine.date = NSDate()
    
    newRoutine.tableDisplayOrder = 1
    
    newRoutine.type = routineType! as? String
    
    let (_, totalTime) = makeRoutineArray(newRoutine)
    
    newRoutine.totalRoutineTime = totalTime
    
    do {
        
        // save into CoreData
        try context.save()
        
        NSNotificationCenter.defaultCenter().postNotificationName("willActivate", object: nil)
        
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
    
    let existingRoutinePredicate: NSPredicate = NSPredicate(format:  "name == %@", routineName)
    
    if let existingRoutine = WatchDataAccess.sharedInstance.GetRoutines(existingRoutinePredicate)!.first as? RoutineModel {
        
        for var stage = 0; stage < routineStage!.count; stage++ {
            
            let currentStageDict = routineStage!.objectAtIndex(stage) as! [String:AnyObject]
            
            let newExercise = ExerciseModel(entity: exerciseEntity!, insertIntoManagedObjectContext: context)
            
            newExercise.exerciseName = currentStageDict["Name"] as? String
            newExercise.exerciseTime = currentStageDict["Time"] as? Int
            
            newExercise.exerciseNumberOfRounds = 1
            
            newExercise.exerciseColor = currentStageDict["Color"]
            
            newExercise.exerciseToRoutine = existingRoutine
            
            exerciseSet.addObject(newExercise)
            
        }
        
        existingRoutine.routineToExcercise = exerciseSet
        
        existingRoutine.selectedRoutine = true
        existingRoutine.date = NSDate()
        
        let (_, totalTime) = makeRoutineArray(existingRoutine)
        
        existingRoutine.totalRoutineTime = totalTime
        
        do {
            
            // save into CoreData
            try context.save()
            
            NSNotificationCenter.defaultCenter().postNotificationName("willActivate", object: nil)
            
        } catch let error as NSError {
            
            print("Fetch failed: \(error.localizedDescription)")
            
            abort()
        }
        
    } else {
        
        insertCoreDataObject(appContext)
    }
}

func deleteCoreDataObject(appContext: [String : AnyObject]) {
    
    let routineName = appContext["routineName"] as! String
    
    let existingRoutinePredicate: NSPredicate = NSPredicate(format:  "name == %@", routineName)
    
    let existingRoutine = WatchDataAccess.sharedInstance.GetRoutines(existingRoutinePredicate)!.first as? RoutineModel
    
    if existingRoutine != nil {
        
        context.deleteObject(existingRoutine!)
        
        do {
            
            // save into CoreData
            try context.save()
            
            NSNotificationCenter.defaultCenter().postNotificationName("willActivate", object: nil)
            
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
                
                for var number = 1; number <= exercise.exerciseNumberOfRounds as Int; number += 1 {
                    
                    if exercise.exerciseTime as Int > 0 {
                        
                        //Exercise Name & Time
                        customeExerciseDictionary["Name"] = exercise.exerciseName
                        customeExerciseDictionary["Time"] = exercise.exerciseTime
                        customeExerciseDictionary["Color"] = exercise.exerciseColor
                        
                        totalTime += customeExerciseDictionary["Time"] as! Int
                        
                        stagesArray.addObject(customeExerciseDictionary)
                    }
                }
            }
        }
        
    } else {
        
        var quickTimerDictionary = [String:AnyObject]()
        
        // Quick Timer Time
        quickTimerDictionary["Name"] = NSLocalizedString("Quick Timer", comment: "")
        quickTimerDictionary["Time"] = QuickTimerTime
        quickTimerDictionary["Color"] = NSKeyedArchiver.archivedDataWithRootObject(UIColor.orangeColor())
        
        totalTime += quickTimerDictionary["Time"] as! Int
        
        stagesArray.addObject(quickTimerDictionary)
        
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