//
//  CommonVariables.swift
//  Chronic
//
//  Created by Ace Green on 2015-10-08.
//  Copyright © 2015 Ace Green. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import HealthKit
import WatchConnectivity

var userDefaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()
let defaultPrefsFile: NSURL = NSBundle.mainBundle().URLForResource("DefaultPreferences", withExtension: "plist")!
let defaultPrefs: NSDictionary = NSDictionary(contentsOfURL: defaultPrefsFile)!

let bundleIdentifier = NSBundle.mainBundle().bundleIdentifier

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
let routineEntity = NSEntityDescription.entityForName("Routines", inManagedObjectContext: context)
let exerciseEntity = NSEntityDescription.entityForName("Exercises", inManagedObjectContext: context)

var warmUpExercise: ExerciseModel!
var roundExercise: ExerciseModel!
var restExercise: ExerciseModel!
var coolDownExercise: ExerciseModel!

@available(iOS 9.0, *)
var wcSession: WCSession!

enum distanceType {
    case Miles
    case Kilometers
}