
//
//  CommonVariables.swift
//  Chronic
//
//  Created by Ace Green on 2015-10-08.
//  Copyright © 2015 Ace Green. All rights reserved.
//

import Foundation
import UIKit
import HealthKit
import CoreData
import CoreSpotlight
import MobileCoreServices
import SystemConfiguration
import AVFoundation
import WatchConnectivity

let current = UIDevice.current()
let bundleIdentifier = Bundle.main().bundleIdentifier
let infoDict = Bundle.main().infoDictionary
let AppVersion = infoDict!["CFBundleShortVersionString"]!
let BundleVersion = infoDict!["CFBundleVersion"]!

let app = UIApplication.shared()
let appDel:AppDelegate = app.delegate as! AppDelegate
let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)

let payloadShort = "Version: \(AppVersion) (\(BundleVersion)) \n Copyright © 2015"

let payload = [ "BundleID" : infoDict!["CFBundleIdentifier"]!,
    "AppVersion" : AppVersion,
    "BundleVersion" : BundleVersion,
    "DeviceModel" : current.model,
    "SystemName" : current.systemName,
    "SystemVersion" : current.systemVersion ]

let iTunesID: UInt = 980247998
let appTitle: String = "Chronic"
let appLink: String = "https://itunes.apple.com/us/app/chronic/id980247998?ls=1&mt=8"
let appURL = URL(string: "https://itunes.apple.com/us/app/chronic/id980247998?ls=1&mt=8")
let appReviewURL = URL(string: "itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=980247998")
let appEmail: String = "ChronicTimer@gmail.com"

let application = UIApplication.shared()
let settingsURL = URL(string: UIApplicationOpenSettingsURLString)
let receiptURL = Bundle.main().appStoreReceiptURL

let countryCode = Locale.current().object(forKey: Locale.Key.countryCode) as! String
let currentCalendar = Calendar.current()

let emailDiagnosticInfo = Array(payload.keys).reduce("", combine: { (input, key) -> String in
    return "\(input)\r\n\(key): \(payload[key]!)</br>"
})

let chronicColor: UIColor = UIColor(red: 92/255, green: 92/255, blue: 102/255, alpha: 1.0)
let chronicGreen: UIColor = UIColor(red: 0/255, green: 255/255, blue: 0/255, alpha: 1.0)

let defaultPrefsFile: URL = Bundle.main().urlForResource("DefaultPreferences", withExtension: "plist")!
let defaultPrefs: NSDictionary = NSDictionary(contentsOf: defaultPrefsFile)!

var Routines: [RoutineModel]!

let context = DataAccess.sharedInstance.managedObjectContext
let routineEntity = NSEntityDescription.entity(forEntityName: "Routines", in: context)
let exerciseEntity = NSEntityDescription.entity(forEntityName: "Exercises", in: context)

var timerSound: String!
var timerVolume: Float!
var enableDeviceSleepState: Bool!
var runInBackgroundState: Bool!
var notificationReminderState: Bool!

let keychain = Keychain(service: "AG.Chronic")

var proVersionKey: String = "chronic.iap.proversion"
var proVersionKeyValue: String = "IUVx6S48yUg2OPmS"
var keychainProVersionString: String?

var removeAdsKey: String = "chronic.iap.removeads"
var removeAdsKeyValue: String = "k2%Cv6lwoYMrMMkN"
var keychainRemoveAdsString: String?

var iapUltimatePackageKey: String = "chronic.iap.ultimate"
var donate99Key: String = "chronic.iap.donate0.99"

var momentId:String = "Chronic_workout_complete"

var userDefaults: UserDefaults = UserDefaults.standard()

var healtKitAuthorized: Bool = false

var warmUpExercise: ExerciseModel!
var roundExercise: ExerciseModel!
var restExercise: ExerciseModel!
var coolDownExercise: ExerciseModel!

var QuickTimerTime: Double = 60.0

var circleWidth: CGFloat!

let okAlertAction = UIAlertAction(title: "Ok", style: .default, handler:{ (ACTION :UIAlertAction!)in })

let settingsAlertAction: UIAlertAction = UIAlertAction(title: "Settings", style: .default, handler: { (action: UIAlertAction!) in
    
    UIApplication.shared().openURL(settingsURL!)
    
})

let cancelAlertAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel, handler:{ (ACTION :UIAlertAction!) in })

let quickTimerCompleteImage: UIImage = UIImage(named: "timer")!
let routineCompleteImage: UIImage = UIImage(named: "workout")!
let runCompleteImage: UIImage = UIImage(named: "runner")!

let emptyTableGuyImage: UIImage = UIImage(named: "emptyTableGuy")!

var soundlocation = URL()
var player = AVAudioPlayer()
var soundError: NSError? = nil
let synthesizer = AVSpeechSynthesizer()

var decryptDictionary : Dictionary<String, String> = [
    "/" : "Of",
]

@available(iOS 9.0, *)
var wcSession: WCSession!

public enum distanceType {
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
