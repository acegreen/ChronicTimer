//
//  HealthKitHelper.swift
//  Chronic
//
//  Created by Ace Green on 2015-12-14.
//  Copyright © 2015 Ace Green. All rights reserved.
//

import UIKit
import HealthKit

public class HealthKitHelper {

    static let sharedInstance = HealthKitHelper()
    let healthKitStore = HKHealthStore()
    
    let heartRateUnit = HKUnit(from: "count/min")
    let workoutType = HKObjectType.workoutType()

    var distanceUnit:distanceType = .kilometers
    
    func authorizeHealthKit(_ completion: ((success:Bool, error:NSError?) -> Void)!) {
        
        guard let HeartRateQuantityType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate) else {
            //displayNotAllowed()
            return
        }
        
        // 1. Set the types you want to read from HK Store
        let healthKitTypesToRead: Set<HKObjectType> = [
            HKObjectType.workoutType(),
            HeartRateQuantityType
            ]
        // 2. Set the types you want to write to HK Store
        let healthKitTypesToWrite: Set<HKSampleType> = [
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.distanceWalkingRunning)!,
            HKQuantityType.workoutType()
            ]
        
        // 3. If the store is not available (for instance, iPad) return an error and don't go on.
        if !HKHealthStore.isHealthDataAvailable() {
            
            let error = NSError(domain: "com.AGChronic.healthkit", code: 2, userInfo: [NSLocalizedDescriptionKey:"HealthKit is not available in this Device"])
            
            if completion != nil {
                
                completion(success:false, error:error)
            }
            
            return
        }
        
        // 4.  Request HealthKit authorization
        healthKitStore.requestAuthorization(toShare: healthKitTypesToWrite, read: healthKitTypesToRead) { (success, error) -> Void in
            
            if completion != nil {
                
                completion(success:success,error:error)
            }
        }
    }
    
    func readProfile() -> ( age:Int?,  biologicalsex:HKBiologicalSexObject?, bloodtype:HKBloodTypeObject?) {
        
        var age:Int?
        var biologicalSex:HKBiologicalSexObject?
        var bloodType:HKBloodTypeObject?
        
        // 1. Request birthday and calculate age
        do {
            
            let birthDay = try healthKitStore.dateOfBirthComponents()
            let birthDayDate = birthDay.date
            
            let today = Date()
            //let calendar = NSCalendar.currentCalendar()
            let differenceComponents = Calendar.current().components(Calendar.Unit.year, from: birthDayDate!, to: today, options: Calendar.Options(rawValue: 0))
            age = differenceComponents.year
            
        } catch let error as NSError {
            // failure
            print("Fetch failed: \(error.localizedDescription)")
        }
        
        // 2. Read biological sex
        do {
            
            biologicalSex = try healthKitStore.biologicalSex()
            
        } catch let error as NSError {
            
            print("Fetch failed: \(error.localizedDescription)")
            
        }
        
        // 3. Read blood type
        do {
            
            bloodType = try healthKitStore.bloodType()
            
        } catch let error as NSError {
            
            print("Fetch failed: \(error.localizedDescription)")
        }
        
        // 4. Return the information read in a tuple
        return (age, biologicalSex, bloodType)
        
    }
    
    func readMostRecentSample(_ sampleType:HKSampleType , completion: ((HKSample?, NSError?) -> Void)!) {
        
        // 1. Build the Predicate
        let past = Date.distantPast as Date
        let now   = Date()
        let mostRecentPredicate = HKQuery.predicateForSamples(withStart: past, end:now, options: HKQueryOptions())
        
        // 2. Build the sort descriptor to return the samples in descending order
        let sortDescriptor = SortDescriptor(key:HKSampleSortIdentifierStartDate, ascending: false)
        // 3. we want to limit the number of samples returned by the query to just 1 (the most recent)
        let limit = 1
        
        // 4. Build samples query
        let sampleQuery = HKSampleQuery(sampleType: sampleType, predicate: mostRecentPredicate, limit: limit, sortDescriptors: [sortDescriptor])
            { (sampleQuery, results, error ) -> Void in
                
                if error != nil {
                    completion(nil,error)
                    return;
                }
                
                // Get the first sample
                let mostRecentSample = results!.first as? HKQuantitySample
                
                // Execute the completion closure
                if completion != nil {
                    completion(mostRecentSample,nil)
                }
        }
        // 5. Execute the Query
        healthKitStore.execute(sampleQuery)
    }
    
    func saveBMISample(_ bmi:Double, date:Date) {
        
        // 1. Create a BMI Sample
        let bmiType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMassIndex)
        let bmiQuantity = HKQuantity(unit: HKUnit.count(), doubleValue: bmi)
        let bmiSample = HKQuantitySample(type: bmiType!, quantity: bmiQuantity, start: date, end: date)
        
        // 2. Save the sample in the store
        healthKitStore.save(bmiSample, withCompletion: { (success, error) -> Void in
            if error != nil {
                
                print("Error saving BMI sample: \(error!.localizedDescription)")
                
            } else {
                
                print("BMI sample saved successfully!")
            }
        })
    }
    
    func saveRunningWorkout(_ type: HKWorkoutActivityType, startDate:Date , endDate:Date, kiloCalories:Double?, distance:Double?, completion: ( (Bool, NSError?) -> Void)!) {
 
        // 1. Set the Unit type
        var hkUnit = HKUnit.meter()
        if distanceUnit == .miles {
            hkUnit = HKUnit.mile()
        }
        
        var distanceQuantity: HKQuantity?
        if let distance = distance {
            // 2. Create quantities for the distance and energy burned
            distanceQuantity = HKQuantity(unit: hkUnit, doubleValue: distance)
        }
        
        var caloriesQuantity: HKQuantity?
        if let kiloCalories = kiloCalories {
            caloriesQuantity = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: kiloCalories)
        }
        
        //let caloriesQuantity = HKQuantity(unit: HKUnit.kilocalorieUnit(), doubleValue: kiloCalories)
        
        // 3. Save Running Workout
        let workout = HKWorkout(activityType: HKWorkoutActivityType.crossTraining, start: startDate, end: endDate, duration: abs(endDate.timeIntervalSince(startDate)), totalEnergyBurned: nil, totalDistance: distanceQuantity, metadata: nil)
        
        healthKitStore.save(workout, withCompletion: { (success, error) -> Void in
            if( error != nil  ) {
                // Error saving the workout
                completion(success,error)
            }
            else {
                // Workout saved
                
                if distanceQuantity != nil {
                    let distanceSample = HKQuantitySample(type: HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.distanceWalkingRunning)!, quantity: distanceQuantity!, start: startDate, end: endDate)
                    
                    self.healthKitStore.add([distanceSample], to: workout, completion: { (success, error ) -> Void in
                        completion(success, error)
                    })
                }
                
                if caloriesQuantity != nil {
                    let caloriesSample = HKQuantitySample(type: HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.activeEnergyBurned)!, quantity: caloriesQuantity!, start: startDate, end: endDate)

                    self.healthKitStore.add([caloriesSample], to: workout, completion: { (success, error ) -> Void in
                        completion(success, error)
                    })
                }
            }
        })
    }
}
