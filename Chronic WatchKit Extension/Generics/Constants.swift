//
//  CommonVariables.swift
//  Chronic Watch Extension
//
//  Created by Ace Green on 2015-10-08.
//  Copyright © 2015 Ace Green. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import HealthKit
import WatchConnectivity

class Constants {
    
    static let userDefaults: UserDefaults = UserDefaults.standard
    static let defaultPrefsFile: URL = Bundle.main.url(forResource: "DefaultPreferences", withExtension: "plist")!
    static let defaultPrefs: NSDictionary = NSDictionary(contentsOf: defaultPrefsFile)!
    
    static let bundleIdentifier = Bundle.main.bundleIdentifier
    
    static let keychain = Keychain(service: "AG.Chronic")
    
    static let proVersionKey: String = "chronic.iap.proversion"
    static let proVersionKeyValue: String = "IUVx6S48yUg2OPmS"
    static var keychainProVersionString: String?
    
    static let removeAdsKey: String = "chronic.iap.removeads"
    static let removeAdsKeyValue: String = "k2%Cv6lwoYMrMMkN"
    static var keychainRemoveAdsString: String?
    
    static var timerSoundSwitchState:Bool = true
    static var enableDeviceSleepState:Bool = false
    static var pauseInBackgroundState: Bool = false
    
    static let context = WatchDataAccess.sharedInstance.managedObjectContext
    static let routineEntity = NSEntityDescription.entity(forEntityName: "Routines", in: context)
    static let exerciseEntity = NSEntityDescription.entity(forEntityName: "Exercises", in: context)
    
    static var Routines: [NSManagedObject]!
    static var selectedRoutine: AnyObject!
    static var warmUpExercise: ExerciseModel!
    static var roundExercise: ExerciseModel!
    static var restExercise: ExerciseModel!
    static var coolDownExercise: ExerciseModel!
    static var QuickTimerTime: Double = 60.0

    static var wcSession: WCSession!
    
    enum DistanceType {
        case miles
        case kilometers
    }
    
    enum NotificationCategory: String {
        case ReminderCategory, WorkoutCategory
        
        func key() -> String {
            switch self {
            case .ReminderCategory:
                return "REMINDER_CATEGORY"
            case .WorkoutCategory:
                return "WORKOUT_CATEGORY"
            }
        }
    }
    
}
