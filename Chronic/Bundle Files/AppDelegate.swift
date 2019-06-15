//
//  AppDelegate.swift
//  Chronic
//
//  Created by Ahmed E on 08/02/15.
//  Copyright (c) 2015 Ace Green. All rights reserved.
//

import UIKit
import AVFoundation
import CoreData
import HealthKit
import CoreSpotlight
import MobileCoreServices
import WatchConnectivity
import Firebase
import MoPub
import Parse
import LaunchKit
import UserNotifications
import Intents
import Branch

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, WCSessionDelegate, WorkoutDelegate {
    
    var backgroundTask: UIBackgroundTaskIdentifier = UIBackgroundTaskIdentifier.invalid
    
    var window: UIWindow?
    
    enum ShortcutIdentifier: String {
        
        case Run
        case QT
        case Dynamic
        
        init?(fullType: String) {
            guard let last = fullType.components(separatedBy: ".").last else {return nil}
            self.init(rawValue: last)
        }
        
        var type: String {
            return Bundle.main.bundleIdentifier! + ".\(self.rawValue)"
        }
        
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // setup user defaults
        setupUserDefaults()
        
        // Set idelTimerDisabled accordingly to
        UIApplication.shared.isIdleTimerDisabled = !Constants.enableDeviceSleepState
        
        // Check for pro version purchase
        Constants.keychainProVersionString = Constants.keychain[Constants.proVersionKey]
        //print("keychainProVersionString \(keychainProVersionString)")
        
        // Check for remove ads purchase
        Constants.keychainRemoveAdsString  = Constants.keychain[Constants.removeAdsKey]
        //print("keychainRemoveAdsString \(keychainRemoveAdsString)")
        
        // Initialize Parse
        let configuration = ParseClientConfiguration {
            $0.applicationId = "Dyoh5fwgntEeU7pVGNWVQVpikIDMX2nIXVflX9oi"
            $0.clientKey = ""
            $0.server = "http://159.203.62.182:1337/parse"
        }
        Parse.initialize(with: configuration)
        if PFUser.current() == nil {
            PFUser.enableAutomaticUser()
            PFUser.current()?.saveInBackground()
        }
        
        // Initialize Firebase
        FirebaseApp.configure()
        
        // Log event
        Analytics.logEvent(AnalyticsEventAppOpen, parameters: [
            "app_version": Constants.AppVersion
        ])
        
        // Initialize MoPub
        let moPubConfig = MPMoPubConfiguration(adUnitIdForAppInitialization: Constants.moPubAdUnitID)
        MoPub.sharedInstance().initializeSdk(with: moPubConfig, completion: nil)
        
        // Initalize LaunchKit
        LaunchKit.launch(withToken: "FYwLCkgJpT_r8kEp1O_-PSg-UnhaD3B7PMPxkG5qIIfq")
        LaunchKit.sharedInstance().debugAlwaysPresentAppReleaseNotes = true
        LaunchKit.sharedInstance().debugAppUserIsAlwaysSuper = true
        
        // Initalize Branch
        let branch: Branch = Branch.getInstance()
        branch.initSession(launchOptions: launchOptions, andRegisterDeepLinkHandler: {params, error in
            if error == nil {
                // params are the deep linked params associated with the link that the user clicked -> was re-directed to this app
                // params will be empty if no data found
                // ... insert custom logic here ...
                print("params: %@", params as? [String: AnyObject] ?? {})
            }
        })
        
        // Register for Google App Indexing
        //GSDAppIndexing.sharedInstance().registerApp(iTunesID)
        
        // Setup WCSession
        if (WCSession.isSupported()) {
            Constants.wcSession = WCSession.default
            Constants.wcSession.delegate = self
            Constants.wcSession.activate()
        }
        
        // Setup sound mixing so that app can make sound when music is playing from another app
        UIApplication.shared.beginReceivingRemoteControlEvents()
        do {
            
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback, mode: AVAudioSession.Mode.default, options: AVAudioSession.CategoryOptions.mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
            
        } catch let error as NSError {
            
            print("Fetch failed: \(error.localizedDescription)")
            
        } catch {
            // This shouldn't be necessary, but the compiler complains about
            //  exhaustiveness. Maybe an early beta seed bug.
            print("Encountered an unknown error \(error)")
        }
        
        // Setup General Appearance (TintColor in UITabBarController not kicking in)
        UITabBar.appearance().tintColor = Constants.chronicGreen
        
        // Track Push Notitications
        if application.applicationState != UIApplication.State.background {
            // Track an app open here if we launch with a push, unless
            // "content_available" was used to trigger a background push (introduced in iOS 7).
            // In that case, we skip tracking here to avoid double counting the app-open.
            
            let preBackgroundPush = !application.responds(to: #selector(getter: UIApplication.backgroundRefreshStatus))
            let oldPushHandlerOnly = !self.responds(to: #selector(UIApplicationDelegate.application(_:didReceiveRemoteNotification:fetchCompletionHandler:)))
            var pushPayload = false
            if let options = launchOptions {
                pushPayload = options[UIApplication.LaunchOptionsKey.remoteNotification] != nil
            }
            if (preBackgroundPush || oldPushHandlerOnly || pushPayload) {
                PFAnalytics.trackAppOpened(launchOptions: launchOptions)
            }
        }
        
        // load storyboard
        if !Constants.userDefaults.bool(forKey: "ONBOARDING_SHOWN") {
            Functions.loadOnboardingInterface()
        } else {
            Functions.loadMainInterface()
        }
        
        // Migrate if neccessary
        let (needsMigration, _) = DataAccess.sharedInstance.checkIfMigrationRequired(oldLocationURL: DataAccess.oldLocationURL, newLocationURL: DataAccess.newLocationURL)
        if needsMigration {
            DataAccess.sharedInstance.migrateCoreDataStore(from: DataAccess.oldLocationURL, to: DataAccess.newLocationURL)
        }
        
        return true
    }
    
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        
        // pass the url to the handle deep link call
        if let branchHandled = Branch.getInstance()?.application(app, open: url, options: options), !branchHandled {
            switch url.scheme {
            case "chronic"?:
                
                return true
                
                //        case "fb1691125951168014"?:
                //
                //            return UIApplication.shared.delegate!.application(application, open: url, options: options)
                
            default:
                return false
            }
        }
        
        return false
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        
        // pass the url to the handle deep link call
        Branch.getInstance().continue(userActivity)
        
        var uniqueIdentifier: String?
        
        if userActivity.activityType == CSSearchableItemActionType {
            
            if let userInfoIdentifier = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String {
                uniqueIdentifier = userInfoIdentifier
            }
            
        } else if userActivity.activityType == NSStringFromClass(INStartWorkoutIntent.self) {
            
            if let workoutName = userActivity.userInfo?["workoutName"] as? String {
                uniqueIdentifier = workoutName
            }
        }
        
        if let uniqueIdentifier = uniqueIdentifier {
            
            guard let routineSelectedInSpotlight = DataAccess.sharedInstance.fetchRoutine(with: uniqueIdentifier) else { return false }
            
            let workoutViewController = Constants.mainStoryboard.instantiateViewController(withIdentifier: "WorkoutViewController") as! WorkoutViewController
            workoutViewController.initializeRoutine(with: routineSelectedInSpotlight)
            
            let rootViewController = Constants.appDel.window?.rootViewController
            if rootViewController?.presentedViewController != nil {
                rootViewController?.dismiss(animated: true, completion: nil)
            }
            
            rootViewController?.present(workoutViewController, animated: true, completion: nil)
            
            // Mark correct routine as selected
            
            Functions.deselectSelectedRoutine()
            
            let routineMarkedSelected = DataAccess.sharedInstance.fetchSelectedRoutine()
            if routineMarkedSelected != nil && routineMarkedSelected?.name != uniqueIdentifier {
                routineMarkedSelected!.selectedRoutine = false
            }
            
            routineSelectedInSpotlight.selectedRoutine = true
        }
        
        return true
    }
    
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        let handledShhortcutItem = self.handleShortcutItem(shortcutItem)
        completionHandler(handledShhortcutItem)
    }
    
    // MARK: - Notification Delegates
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
        if let currentInstallation: PFInstallation = PFInstallation.current() {
            currentInstallation.setDeviceTokenFrom(deviceToken)
            currentInstallation.saveInBackground()
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        
        if (error as NSError).code == 3010 {
            print("Push notifications are not supported in the iOS Simulator.")
        } else {
            print("application:didFailToRegisterForRemoteNotificationsWithError: %@", error)
        }
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        // Handle received remote notification
        PFPush.handle(userInfo)
        if application.applicationState == UIApplication.State.inactive {
            PFAnalytics.trackAppOpened(withRemoteNotificationPayload: userInfo)
        }
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        
        beginBackgroundTask()
        
        // Register for Push Notitications
        NotificationHelper.registerForPushNotifications()
        
        print("app entered background mode")
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        // End background task if it exists
        endBackgroundTask()
        
        // Clear Parse Push badges
        NotificationHelper.resetAppBadgePush()
        
        // Clear delivered notifications
        NotificationHelper.center.removeAllDeliveredNotifications()
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        Functions.saveContext { (didSave) -> Void in
        }
    }
    
    // MARK: - WCSessionDelegate
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("WCSession activationDidCompleteWith")
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("sessionDidBecomeInactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("sessionDidDeactivate")
    }
    
    func sessionWatchStateDidChange(_ session: WCSession) {
        print(#function)
        print(session)
        print("reachable:\(session.isReachable)")
    }
    
    // MARK: - Shortcut Handling
    
    @available(iOS 9.0, *)
    func handleShortcutItem(_ shortcutItem: UIApplicationShortcutItem) -> Bool {
        
        guard ShortcutIdentifier(fullType: shortcutItem.type) != nil else { return false }
        guard let shortcutType = shortcutItem.type as String? else { return false }
        
        let workoutViewController = Constants.mainStoryboard.instantiateViewController(withIdentifier: "WorkoutViewController") as! WorkoutViewController
        
        let rootViewController = Constants.appDel.window?.rootViewController
        if rootViewController?.presentedViewController != nil {
            rootViewController?.dismiss(animated: true, completion: nil)
        }
        
        switch (shortcutType) {
            
        case ShortcutIdentifier.Run.type:
            
            workoutViewController.initializeRunner()
            rootViewController?.present(workoutViewController, animated: true, completion: nil)
        
            return true
            
        case ShortcutIdentifier.QT.type:
            
            workoutViewController.initializeQuickTimer()
            rootViewController?.present(workoutViewController, animated: true, completion: nil)
            
            return true
            
        case ShortcutIdentifier.Dynamic.type:
            
            guard let selectedRoutine = DataAccess.sharedInstance.fetchRoutine(with: shortcutItem.localizedTitle) else { return false }
                
            workoutViewController.initializeRoutine(with: selectedRoutine)
            rootViewController?.present(workoutViewController, animated: true, completion: nil)
            //workoutViewController.play()
            
            return true
            
        default:
            return false
        }
        
    }
    
    // MARK: - TimeVCDelegate
    
    func workoutDidBegin(timer: Timer) {
        print("workoutDidBegin")
    }
    
    func workoutDidEnd(timer: Timer) {
        endBackgroundTask()
        
        print("workoutDidEnd")
        
        // Ask for feedback or show ad
        Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(AppDelegate.requestReview), userInfo: nil, repeats: false)
    }
    
    // MARK: - Helper Functions
    
    @objc func requestReview() {
        SKStoreReviewController.requestReview()
    }
    
    func setupUserDefaults() {
        
        // Regiter defaults
        Constants.userDefaults.register(defaults: Constants.defaultPrefs)
        Constants.userDefaults.register(defaults: Constants.localizedPrefs)
        
        // Enable/Disable Timer Sound based on timerSound
        Constants.timerSound = Constants.userDefaults.string(forKey: "TIMER_SOUND")!
        
        // Set Timer Volume based on timerVolume
        Constants.timerVolume = Constants.userDefaults.float(forKey: "TIMER_VOLUME")
        
        // Enable/Disable display sleep based on ENABLE_DEVICE_SLEEP flag
        Constants.enableDeviceSleepState = Constants.userDefaults.bool(forKey: "ENABLE_DEVICE_SLEEP") as Bool
        
        // Enable/Disable background tasks based on RUN_IN_BACKGROUND flag
        Constants.runInBackgroundState = Constants.userDefaults.bool(forKey: "RUN_IN_BACKGROUND") as Bool
        
        // Enable/Disable time remaining feedback based on TIME_REMAINING_FEEDBACK flag
        Constants.timeRemainingFeedbackState = Constants.userDefaults.bool(forKey: "TIME_REMAINING_FEEDBACK") as Bool
        
        // Set the countdown time based on countdownTime flag
        Constants.countdownTime = Constants.userDefaults.integer(forKey: "COUNTDOWN_TIME") as Int
        
        // Enable/Disable notification reminders based on notificationReminderState flag
        Constants.notificationReminderState = Constants.userDefaults.bool(forKey: "NOTIFICATION_REMINDER_ENABLED") as Bool
    }
    
    func beginBackgroundTask() {
        
        // End background task if it exists
        endBackgroundTask()
        
        if Constants.runInBackgroundState == true && Functions.isRemoveAdsUpgradePurchased() && Constants.timer.isValid {
            backgroundTask = UIApplication.shared.beginBackgroundTask(expirationHandler: {
                self.endBackgroundTask()
            })
            
            print("background task began")
        }
    }
    
    func endBackgroundTask() {
        
        guard backgroundTask != UIBackgroundTaskIdentifier.invalid else { return }
        
        UIApplication.shared.endBackgroundTask(self.backgroundTask)
        backgroundTask = UIBackgroundTaskIdentifier.invalid
        
        print("background task ended")
    }
}

