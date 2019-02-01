//
//  Functions.swift
//  Chronic
//
//  Created by Ace Green on 2015-03-24.
//  Copyright (c) 2015 Ace Green. All rights reserved.
//

import Foundation
import WatchKit
import CoreData
import ChronicKit
import HealthKit
import WatchConnectivity

class Functions {
    
    class func timeStringFrom(time: Int) -> String {
        
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
    class func insertCoreDataObject(appContext: [String : Any]) {
        
        let routineName = appContext["routineName"]
        let routineType = appContext["routineType"]
        let routineStage = appContext["routineStage"] as! [[String: Any]]
        
        let exerciseSet = NSMutableOrderedSet()
        
        let newRoutine = RoutineModel(entity: WatchDataAccess.routineEntity!, insertInto: WatchDataAccess.context)
        
        for stage in 0 ..< routineStage.count {
            
            let currentStageDict = routineStage[stage]
            
            let newExercise = ExerciseModel(entity: WatchDataAccess.exerciseEntity!, insertInto: WatchDataAccess.context)
            
            newExercise.exerciseName = currentStageDict["Name"] as? String
            newExercise.exerciseTime = currentStageDict["Time"] as! NSNumber
            
            newExercise.exerciseNumberOfRounds = 1
            
            newExercise.exerciseColor = currentStageDict["Color"] as! NSData
            
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
        
        newRoutine.totalRoutineTime = totalTime as NSNumber
        
        do {
            
            // save into CoreData
            try WatchDataAccess.context.save()
            
            NotificationCenter.default.post(name: NSNotification.Name("willActivate"), object: nil)
            
        } catch let error as NSError {
            
            print("Fetch failed: \(error.localizedDescription)")
            
            abort()
        }
        
        // print(newRoutine)
        
    }
    
    class func modifyCoreDataObject(appContext: [String : Any]) {
        
        let routineName = appContext["routineName"] as! String
        let routineStage = appContext["routineStage"] as! [[String: Any]]
        
        let exerciseSet = NSMutableOrderedSet()
        
        if let existingRoutine = WatchDataAccess.sharedInstance.fetchRoutine(with: routineName) {
            
            for stage in 0 ..< routineStage.count {
                
                let currentStageDict = routineStage[stage]
                
                let newExercise = ExerciseModel(entity: WatchDataAccess.exerciseEntity!, insertInto: WatchDataAccess.context)
                
                newExercise.exerciseName = currentStageDict["Name"] as? String
                newExercise.exerciseTime = currentStageDict["Time"] as! NSNumber
                
                newExercise.exerciseNumberOfRounds = 1
                
                newExercise.exerciseColor = currentStageDict["Color"] as! NSData
                
                newExercise.exerciseToRoutine = existingRoutine
                
                exerciseSet.add(newExercise)
                
            }
            
            existingRoutine.routineToExcercise = exerciseSet
            
            existingRoutine.selectedRoutine = true
            existingRoutine.date = Date()
            
            let (_, totalTime) = makeRoutineArray(routine: existingRoutine)
            
            existingRoutine.totalRoutineTime = totalTime as NSNumber
            
            do {
                
                // save into CoreData
                try WatchDataAccess.context.save()
                
                NotificationCenter.default.post(name: NSNotification.Name("willActivate"), object: nil)
                
            } catch let error as NSError {
                
                print("Fetch failed: \(error.localizedDescription)")
                
                abort()
            }
            
        } else {
            insertCoreDataObject(appContext: appContext)
        }
    }
    
    class func deleteCoreDataObject(appContext: [String : Any]) {
        
        let routineName = appContext["routineName"] as! String
        
        let existingRoutine = WatchDataAccess.sharedInstance.fetchRoutine(with: routineName)
        
        if existingRoutine != nil {
            
            WatchDataAccess.context.delete(existingRoutine!)
            
            do {
                
                // save into CoreData
                try WatchDataAccess.context.save()
                
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "willActivate"), object: nil)
                
            } catch let error as NSError {
                
                print("Fetch failed: \(error.localizedDescription)")
                
                abort()
            }
        }
    }
    
    //MARK: -Exercise Function
    class func makeRoutineArray(routine: RoutineModel?) -> ([[String:Any]], Int) {
        
        let stagesArray = NSMutableArray()
        var totalTime = 0
        
        if routine != nil {
            
            let routineExercises = routine!.routineToExcercise?.array as! [ExerciseModel]
            let type:String = routine!.type!
            
            if type == "Custom" || type == "Circuit"  {
                
                for exercise in routineExercises {
                    
                    var customeExerciseDictionary = [String: Any]()
                    
                    for _ in 1...(exercise.exerciseNumberOfRounds as! Int) {
                        
                        if exercise.exerciseTime as! Int > 0 {
                            
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
            
            var quickTimerDictionary = [String: Any]()
            
            // Quick Timer Time
            quickTimerDictionary["Name"] = NSLocalizedString("Quick Timer", comment: "")
            quickTimerDictionary["Time"] = Constants.quickTimerTime
            quickTimerDictionary["Color"] = NSKeyedArchiver.archivedData(withRootObject: UIColor.orange)
            
            totalTime += quickTimerDictionary["Time"] as! Int
            
            stagesArray.add(quickTimerDictionary)
            
        }
        
        print(stagesArray, totalTime)
        return (stagesArray as AnyObject as! [[String:AnyObject]], totalTime)
    }
    
    class func isRemoveAdsUpgradePurchased() -> Bool {
        
        guard Constants.keychainRemoveAdsString == Constants.removeAdsKeyValue else {
            return false
        }
        
        return true
    }
    
    class func isProFeaturesUpgradePurchased() -> Bool {
        
        guard Constants.keychainProVersionString == Constants.proVersionKeyValue else {
            return false
        }
        
        return true
    }
    
//    class func createWorkSession<T: HKWorkoutSessionDelegate>(delegateInterfaceController: T, workoutActivityType: HKWorkoutActivityType) -> HKWorkoutSession? {
//        
//        
//    }
    
    // MARK: Workout session functions
    class func startWorkSession<T: HKWorkoutSessionDelegate>(delegateInterfaceController: T, workoutActivityType: HKWorkoutActivityType) {
        
        guard Constants.workoutSession == nil else { return }
        
        do {
            
            // Start HKWorkoutSession
            let workoutSessionConfiguration = HKWorkoutConfiguration()
            workoutSessionConfiguration.activityType = workoutActivityType
            workoutSessionConfiguration.locationType = .unknown
            
            Constants.workoutSession = try HKWorkoutSession(configuration: workoutSessionConfiguration)
            
            Constants.workoutSession.delegate = delegateInterfaceController
            
            guard Constants.workoutSession.state == .notStarted else { return }
            HealthKitHelper.sharedInstance.healthKitStore.start(Constants.workoutSession)
            
            print("Workout session started")
            
        } catch {
            print(error)
        }
    }
    
    class func pauseWorkSession() {
        
        guard Constants.workoutSession != nil else { return }
        guard Constants.workoutSession.state == .running else { return }
        
        HealthKitHelper.sharedInstance.healthKitStore.pause(Constants.workoutSession)
        
        print("Workout session paused")
    }
    
    class func resumeWorkSession() {
        
        guard Constants.workoutSession != nil else { return }
        guard Constants.workoutSession.state == .paused else { return }
        
        HealthKitHelper.sharedInstance.healthKitStore.resumeWorkoutSession(Constants.workoutSession)
        
        print("Workout session resumed")
    }
    
    class func endWorkoutSession() {
        
        guard Constants.workoutSession != nil else { return }
        guard Constants.workoutSession.state == .running else { return }
        
        HealthKitHelper.sharedInstance.healthKitStore.end(Constants.workoutSession)
        
        Constants.workoutSession.delegate = nil
        Constants.workoutSession = nil
        
        print("Workout session ended")
    }
    
    class func saveWorkout(interfaceController: WKInterfaceController, workoutActivityType: HKWorkoutActivityType, startDate: Date, endDate: Date, kiloCalories: Double?, distance: Double?) {
        
        // Add workout to HealthKit if available
        HealthKitHelper.sharedInstance.saveRunningWorkout(workoutActivityType: workoutActivityType, startDate: startDate, endDate: endDate, kiloCalories: kiloCalories, distance: distance, completion: { (success, error) -> Void in
            
            if success {
                
                print("Workout saved!")
                
            } else if error != nil {
                
                print("\(error)")
            }
            
            return
        })
    }
    
    //@available(iOSApplicationExtension 9.0, *)
    //class func startWorkoutSession(activityType: HKWorkoutActivityType, locationType: HKWorkoutSessionLocationType) {
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
}
