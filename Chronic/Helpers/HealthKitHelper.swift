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
    
    let heartRateUnit = HKUnit(fromString: "count/min")
    let workoutType = HKObjectType.workoutType()

    var distanceUnit:distanceType = .Kilometers
    
    func authorizeHealthKit(completion: ((success:Bool, error:NSError!) -> Void)!) {
        
        guard let HeartRateQuantityType = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate) else {
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
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierActiveEnergyBurned)!,
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDistanceWalkingRunning)!,
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
        healthKitStore.requestAuthorizationToShareTypes(healthKitTypesToWrite, readTypes: healthKitTypesToRead) { (success, error) -> Void in
            
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
            
            let birthDay = try healthKitStore.dateOfBirth()
            
            let today = NSDate()
            //let calendar = NSCalendar.currentCalendar()
            let differenceComponents = NSCalendar.currentCalendar().components(NSCalendarUnit.Year, fromDate: birthDay, toDate: today, options: NSCalendarOptions(rawValue: 0))
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
    
    func readMostRecentSample(sampleType:HKSampleType , completion: ((HKSample!, NSError!) -> Void)!) {
        
        // 1. Build the Predicate
        let past = NSDate.distantPast() as NSDate
        let now   = NSDate()
        let mostRecentPredicate = HKQuery.predicateForSamplesWithStartDate(past, endDate:now, options: .None)
        
        // 2. Build the sort descriptor to return the samples in descending order
        let sortDescriptor = NSSortDescriptor(key:HKSampleSortIdentifierStartDate, ascending: false)
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
        healthKitStore.executeQuery(sampleQuery)
    }
    
    func saveBMISample(bmi:Double, date:NSDate) {
        
        // 1. Create a BMI Sample
        let bmiType = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMassIndex)
        let bmiQuantity = HKQuantity(unit: HKUnit.countUnit(), doubleValue: bmi)
        let bmiSample = HKQuantitySample(type: bmiType!, quantity: bmiQuantity, startDate: date, endDate: date)
        
        // 2. Save the sample in the store
        healthKitStore.saveObject(bmiSample, withCompletion: { (success, error) -> Void in
            if error != nil {
                
                print("Error saving BMI sample: \(error!.localizedDescription)")
                
            } else {
                
                print("BMI sample saved successfully!")
            }
        })
    }
    
    func saveRunningWorkout(type: HKWorkoutActivityType, startDate:NSDate , endDate:NSDate, kiloCalories:Double?, distance:Double?, completion: ( (Bool, NSError!) -> Void)!) {
 
        // 1. Set the Unit type
        var hkUnit = HKUnit.meterUnit()
        if distanceUnit == .Miles {
            hkUnit = HKUnit.mileUnit()
        }
        
        var distanceQuantity: HKQuantity?
        if let distance = distance {
            // 2. Create quantities for the distance and energy burned
            distanceQuantity = HKQuantity(unit: hkUnit, doubleValue: distance)
        }
        
        var caloriesQuantity: HKQuantity?
        if let kiloCalories = kiloCalories {
            caloriesQuantity = HKQuantity(unit: HKUnit.kilocalorieUnit(), doubleValue: kiloCalories)
        }
        
        //let caloriesQuantity = HKQuantity(unit: HKUnit.kilocalorieUnit(), doubleValue: kiloCalories)
        
        // 3. Save Running Workout
        let workout = HKWorkout(activityType: HKWorkoutActivityType.CrossTraining, startDate: startDate, endDate: endDate, duration: abs(endDate.timeIntervalSinceDate(startDate)), totalEnergyBurned: nil, totalDistance: distanceQuantity, metadata: nil)
        
        healthKitStore.saveObject(workout, withCompletion: { (success, error) -> Void in
            if( error != nil  ) {
                // Error saving the workout
                completion(success,error)
            }
            else {
                // Workout saved
                
                if distanceQuantity != nil {
                    let distanceSample = HKQuantitySample(type: HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDistanceWalkingRunning)!, quantity: distanceQuantity!, startDate: startDate, endDate: endDate)
                    
                    self.healthKitStore.addSamples([distanceSample], toWorkout: workout, completion: { (success, error ) -> Void in
                        completion(success, error)
                    })
                }
                
                if caloriesQuantity != nil {
                    let caloriesSample = HKQuantitySample(type: HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierActiveEnergyBurned)!, quantity: caloriesQuantity!, startDate: startDate, endDate: endDate)

                    self.healthKitStore.addSamples([caloriesSample], toWorkout: workout, completion: { (success, error ) -> Void in
                        completion(success, error)
                    })
                }
            }
        })
    }
}
