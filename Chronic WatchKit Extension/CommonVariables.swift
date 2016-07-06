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

var userDefaults: UserDefaults = UserDefaults.standard
let defaultPrefsFile: URL = Bundle.main.urlForResource("DefaultPreferences", withExtension: "plist")!
let defaultPrefs: NSDictionary = NSDictionary(contentsOf: defaultPrefsFile)!

let bundleIdentifier = Bundle.main.bundleIdentifier

let keychain = Keychain(service: "AG.Chronic")

var proVersionKey: String = "chronic.iap.proversion"
var proVersionKeyValue: String = "IUVx6S48yUg2OPmS"
var keychainProVersionString: String?

var removeAdsKey: String = "chronic.iap.removeads"
var removeAdsKeyValue: String = "k2%Cv6lwoYMrMMkN"
var keychainRemoveAdsString: String?

var selectedRoutine: AnyObject!

var Routines: [NSManagedObject]!

var timerSoundSwitchState:Bool = true
var enableDeviceSleepState:Bool = false
var pauseInBackgroundState: Bool = false

var QuickTimerTime: Double = 60.0

let context = WatchDataAccess.sharedInstance.managedObjectContext
let routineEntity = NSEntityDescription.entity(forEntityName: "Routines", in: context)
let exerciseEntity = NSEntityDescription.entity(forEntityName: "Exercises", in: context)

var warmUpExercise: ExerciseModel!
var roundExercise: ExerciseModel!
var restExercise: ExerciseModel!
var coolDownExercise: ExerciseModel!

@available(iOS 9.0, *)
var wcSession: WCSession!

enum distanceType {
    case miles
    case kilometers
}

public enum NotificationCategory: String {
    case ReminderCategory, WorkoutCategory
    
    public func key() -> String {
        switch self {
        case .ReminderCategory:
            return "REMINDER_CATEGORY"
        case .WorkoutCategory:
            return "WORKOUT_CATEGORY"
        }
    }
}
