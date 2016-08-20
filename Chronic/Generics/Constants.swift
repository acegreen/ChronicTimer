
//
//  Constants.swift
//  Chronic
//
//  Created by Ace Green on 2015-10-08.
//  Copyright © 2015 Ace Green. All rights reserved.
//

import Foundation
import UIKit
import HealthKit
import CoreData
import MobileCoreServices
import SystemConfiguration
import WatchConnectivity
import AVFoundation
import UserNotifications
import ReachabilitySwift

class Constants {
    
    static let current = UIDevice.current
    static let bundleIdentifier = Bundle.main.bundleIdentifier
    static let infoDict = Bundle.main.infoDictionary
    static let AppVersion = infoDict!["CFBundleShortVersionString"]!
    static let BundleVersion = infoDict!["CFBundleVersion"]!
    
    static let reachability = Reachability()
    
    static let app = UIApplication.shared
    static let appDel: AppDelegate = Constants.app.delegate as! AppDelegate
    static let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        
    static let payloadShort = "Version: \(AppVersion) (\(BundleVersion)) \n Copyright © 2015"
    
    static let payload = [ "BundleID" : infoDict!["CFBundleIdentifier"]!,
                    "AppVersion" : AppVersion,
                    "BundleVersion" : BundleVersion,
                    "DeviceModel" : current.model,
                    "SystemName" : current.systemName,
                    "SystemVersion" : current.systemVersion ]
    
    static let iTunesID: UInt = 980247998
    static let appTitle: String = "Chronic"
    static let appLink: String = "https://itunes.apple.com/us/app/chronic/id980247998?ls=1&mt=8"
    static let appURL = URL(string: "https://itunes.apple.com/us/app/chronic/id980247998?ls=1&mt=8")
    static let appReviewURL = URL(string: "itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=980247998")
    static let appEmail: String = "ChronicTimer@gmail.com"
    
    static let application = UIApplication.shared
    static let settingsURL = URL(string: UIApplicationOpenSettingsURLString)
    static let receiptURL = Bundle.main.appStoreReceiptURL
    
    static let countryCode = Locale.current.localizedString(forIdentifier: "countryCode")!
    static let currentCalendar = Calendar.current
    
    static let emailDiagnosticInfo = Array(payload.keys).reduce("", { (input, key) -> String in
        return "\(input)\r\n\(key): \(payload[key]!)</br>"
    })
    
    static let chronicColor: UIColor = UIColor(red: 92/255, green: 92/255, blue: 102/255, alpha: 1.0)
    static let chronicGreen: UIColor = UIColor(red: 0/255, green: 255/255, blue: 0/255, alpha: 1.0)
    
    static let defaultPrefsFile: URL = Bundle.main.url(forResource: "DefaultPreferences", withExtension: "plist")!
    static let defaultPrefs: NSDictionary = NSDictionary(contentsOf: defaultPrefsFile)!
    
    static let context = DataAccess.sharedInstance.managedObjectContext
    static let routineEntity = NSEntityDescription.entity(forEntityName: "Routines", in: context)
    static let exerciseEntity = NSEntityDescription.entity(forEntityName: "Exercises", in: context)
    
    static var timerSound: String!
    static var timerVolume: Float!
    static var enableDeviceSleepState: Bool!
    static var runInBackgroundState: Bool!
    static var notificationReminderState: Bool!
    
    static var QuickTimerTime: Int = 60
    
    static let keychain = Keychain(service: "AG.Chronic")
    
    static let proVersionKey: String = "chronic.iap.proversion"
    static let proVersionKeyValue: String = "IUVx6S48yUg2OPmS"
    static var keychainProVersionString: String?
    
    static let removeAdsKey: String = "chronic.iap.removeads"
    static let removeAdsKeyValue: String = "k2%Cv6lwoYMrMMkN"
    static var keychainRemoveAdsString: String?
    
    static let iapUltimatePackageKey: String = "chronic.iap.ultimate"
    static let donate99Key: String = "chronic.iap.donate0.99"
    
    static let kiipMomentId:String = "Chronic_workout_complete"
    
    static let userDefaults: UserDefaults = UserDefaults.standard
    
    static let healtKitAuthorized: Bool = false
    
    static var warmUpExercise: ExerciseModel!
    static var roundExercise: ExerciseModel!
    static var restExercise: ExerciseModel!
    static var coolDownExercise: ExerciseModel!
    
    static let okAlertAction: UIAlertAction = UIAlertAction(title: "Ok", style: .default, handler:{ (ACTION :UIAlertAction!) in })
    
    static let settingsAlertAction: UIAlertAction = UIAlertAction(title: "Settings", style: .default, handler: { (ACTION: UIAlertAction!) in
        
        UIApplication.shared.openURL(settingsURL!)
        
    })
    
    static let cancelAlertAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel, handler:{ (ACTION :UIAlertAction!) in })
    
    static let quickTimerCompleteImage: UIImage = UIImage(named: "timer")!
    static let routineCompleteImage: UIImage = UIImage(named: "workout")!
    static let runCompleteImage: UIImage = UIImage(named: "runner")!
    
    static let emptyRoutineTableIcon: UIImage = UIImage(named: "emptyRoutineTableIcon")!
    
    static var soundlocation: URL!
    static var player = AVAudioPlayer()
    static var soundError: NSError? = nil
    static let synthesizer = AVSpeechSynthesizer()
    
    static var decryptDictionary : Dictionary<String, String> = [
        "/" : "Of",
    ]
    
    static var wcSession: WCSession!
    
    enum WorkoutType {
        case routine
        case run
        case quickTimer
    }
    
    enum WorkoutEventType {
        case preRun
        case active
        case paused
        case completed
    }
    
    enum DistanceType {
        case miles
        case kilometers
    }
    
    enum NotificationIdentifier: String {
        case ReminderIdentifier, WorkoutIdentifier
        
        func key() -> String {
            switch self {
            case .ReminderIdentifier:
                return "REMINDER_CATEGORY"
            case .WorkoutIdentifier:
                return "WORKOUT_CATEGORY"
            }
        }
    }
}
