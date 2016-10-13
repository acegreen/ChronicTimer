//
//  CommonVariables.swift
//  Chronic Watch Extension
//
//  Created by Ace Green on 2015-10-08.
//  Copyright © 2015 Ace Green. All rights reserved.
//

import WatchKit
import ChronicKit
import HealthKit
import WatchConnectivity

class Constants {
    
    static let currentDevice = WKInterfaceDevice.current()
    static let ext = WKExtension.shared
    
//    static let userDefaults: UserDefaults = UserDefaults.standard
//    static let defaultPrefsFile: URL = Bundle.main.url(forResource: "DefaultPreferences", withExtension: "plist")!
//    static let defaultPrefs: [String : Any] = NSDictionary(contentsOf: defaultPrefsFile) as! [String : Any]
//    static let localizedPrefsFile: URL = Bundle.main.url(forResource: "LocalizedPreferences", withExtension: "plist")!
//    static let localizedPrefs: [String : Any] = NSDictionary(contentsOf: localizedPrefsFile) as! [String : Any]
    
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
    
    static var selectedRoutine: AnyObject!
    static var warmUpExercise: ExerciseModel!
    static var roundExercise: ExerciseModel!
    static var restExercise: ExerciseModel!
    static var coolDownExercise: ExerciseModel!
    static var quickTimerTime: Int = 60

    static var timer = Timer()
    static var wcSession: WCSession!
    
    static var workoutSession: HKWorkoutSession!
    
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
