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
import Fabric
import Crashlytics
import MoPub
import Parse
import ParseFacebookUtilsV4
import CNPPopupController
import LaunchKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, WCSessionDelegate, iRateDelegate {
    
    var backgroundTask: UIBackgroundTaskIdentifier!
    
    var window: UIWindow?
    
    enum ShortcutIdentifier: String {
        
        case Run
        case QT
        case Dynamic
        
        init?(fullType: String) {
            
            guard let last = fullType.componentsSeparatedByString(".").last else {return nil}
            self.init(rawValue: last)
        }
        
        var type: String {
            
            return NSBundle.mainBundle().bundleIdentifier! + ".\(self.rawValue)"
        }
        
    }
    
    override class func initialize() {
        
        setupSARate()
        
    }
    
    class func setupSARate() {
        
        //configure
        SARate.sharedInstance().minAppStoreRaiting = 4
        SARate.sharedInstance().eventsUntilPrompt = 5
        SARate.sharedInstance().daysUntilPrompt = 5
        SARate.sharedInstance().remindPeriod = 0
        
        SARate.sharedInstance().email = appEmail
        SARate.sharedInstance().emailSubject = "Chronic Feedback/Bug"
        SARate.sharedInstance().emailText = "Hello Chronic Team, </br> </br> </br> </br> </br> - - - - - - - - - - - - - - - - - - - - - </br>" + emailDiagnosticInfo
        
        SARate.sharedInstance().previewMode = false
        SARate.sharedInstance().verboseLogging = false
        SARate.sharedInstance().promptAtLaunch = false
    }
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        // setup user defaults
        setupUserDefaults()
        
        // Get Routines from database
        Routines = DataAccess.sharedInstance.GetRoutines(nil) as! [RoutineModel]
        
        // Set idelTimerDisabled accordingly
        UIApplication.sharedApplication().idleTimerDisabled = !enableDeviceSleepState
        
        // Check for pro version purchase
        keychainProVersionString = keychain[proVersionKey]
        //print("keychainProVersionString \(keychainProVersionString)")
        
        // Check for remove ads purchase
        keychainRemoveAdsString  = keychain[removeAdsKey]
        //print("keychainRemoveAdsString \(keychainRemoveAdsString)")
        
        // Initialize Parse
        let configuration = ParseClientConfiguration {
            $0.applicationId = "Dyoh5fwgntEeU7pVGNWVQVpikIDMX2nIXVflX9oi"
            $0.clientKey = ""
            $0.server = "http://159.203.62.182:1337/parse"
        }
        Parse.initializeWithConfiguration(configuration)
        
        // Setup Crashlytics
        Fabric.with([Crashlytics.self, MoPub.self])
        
        // Initalize Facebook
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        
        // Initalize LaunchKit
        LaunchKit.launchWithToken("FYwLCkgJpT_r8kEp1O_-PSg-UnhaD3B7PMPxkG5qIIfq")
        LaunchKit.sharedInstance().debugAlwaysPresentAppReleaseNotes = true
        LaunchKit.sharedInstance().debugAppUserIsAlwaysSuper = true
        
        // Initialize Rollout
        #if DEBUG
            Rollout.setupWithKey("56932e164e1e847211ffe9ee", developmentDevice: true)
        #else
            Rollout.setupWithKey("56932e164e1e847211ffe9ee", developmentDevice: false)
        #endif
        
        // Register for Google App Indexing
        //GSDAppIndexing.sharedInstance().registerApp(iTunesID)
        
        // Setup WCSession
        if (WCSession.isSupported()) {
            wcSession = WCSession.defaultSession()
            wcSession.delegate = self
            wcSession.activateSession()
        }
        
        // Setup sound mixing so that app can make sound when music is playing from another app
        UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
        do {
            
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, withOptions: AVAudioSessionCategoryOptions.MixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
            
        } catch let error as NSError {
            
            print("Fetch failed: \(error.localizedDescription)")
            
        } catch {
            // This shouldn't be necessary, but the compiler complains about
            //  exhaustiveness. Maybe an early beta seed bug.
            print("Encountered an unknown error \(error)")
        }
        
        // Setup General Appearance (TintColor in UITabBarController not kicking in) 
        UITabBar.appearance().tintColor = chronicGreen
        
        // Track Push Notitications
        if application.applicationState != UIApplicationState.Background {
            // Track an app open here if we launch with a push, unless
            // "content_available" was used to trigger a background push (introduced in iOS 7).
            // In that case, we skip tracking here to avoid double counting the app-open.
            
            let preBackgroundPush = !application.respondsToSelector(Selector("backgroundRefreshStatus"))
            let oldPushHandlerOnly = !self.respondsToSelector(#selector(UIApplicationDelegate.application(_:didReceiveRemoteNotification:fetchCompletionHandler:)))
            var pushPayload = false
            if let options = launchOptions {
                pushPayload = options[UIApplicationLaunchOptionsRemoteNotificationKey] != nil
            }
            if (preBackgroundPush || oldPushHandlerOnly || pushPayload) {
                PFAnalytics.trackAppOpenedWithLaunchOptions(launchOptions)
            }
        }
        
        // increment event count
        SARate.sharedInstance().eventCount += 1
        print("eventCount", SARate.sharedInstance().eventCount)
        
        return true
    }
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        
        switch url.scheme {
            
        case "chronic":
            
            return true
            
        case "fb1691125951168014":
            
            return FBSDKApplicationDelegate.sharedInstance().application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation)
            
        default:
            
            return false
        }
    }
    
    func application(application: UIApplication, continueUserActivity userActivity: NSUserActivity, restorationHandler: ([AnyObject]?) -> Void) -> Bool {
        
        if userActivity.activityType == CSSearchableItemActionType {
            
            if let uniqueIdentifier = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String {
                
                let uniqueIdentifierPredicate: NSPredicate = NSPredicate(format: "name = %@", uniqueIdentifier)
                
                let routineSelectedInSpotlight = DataAccess.sharedInstance.GetRoutines(uniqueIdentifierPredicate)!.first as! RoutineModel
                
                let timerViewController = mainStoryboard.instantiateViewControllerWithIdentifier("TimerViewController") as! TimerViewController
                timerViewController.initializeRoutine(with: routineSelectedInSpotlight)
                
                let rootViewController = appDel.window?.rootViewController
                if rootViewController?.presentedViewController != nil {
                    rootViewController?.dismissViewControllerAnimated(true, completion: nil)
                }
                
                rootViewController?.presentViewController(timerViewController, animated: true, completion: nil)
                
                // Mark correct routine as selected
                
                let routineMarkedSelected = getSelectedRoutine()
                
                if routineMarkedSelected != nil && routineMarkedSelected?.name != uniqueIdentifier {
                    
                    routineMarkedSelected!.selectedRoutine = false
                    
                }
                    
                routineSelectedInSpotlight.selectedRoutine = true
            }
        }
        
        return true
    }
    
    @available(iOS 9.0, *)
    func application(application: UIApplication, performActionForShortcutItem shortcutItem: UIApplicationShortcutItem, completionHandler: (Bool) -> Void) {
        
        let handledShhortcutItem = self.handleShortcutItem(shortcutItem)
        completionHandler(handledShhortcutItem)
        
    }
    
    func application(application: UIApplication, didRegisterUserNotificationSettings notificationSettings: UIUserNotificationSettings) {
        
        guard userDefaults.boolForKey("NOTIFICATION_REMINDER_ENABLED") == true else { return }
        if NotificationHelper.checkScheduledNotificationsForNotificationWith(NotificationCategory.ReminderCategory.key()) == nil {
            NotificationHelper.scheduleNotification(NotificationHelper.reminderDate, repeatInterval: NotificationHelper.getNSCalendarUnit(NotificationHelper.interval), alertTitle: appTitle, alertBody:  NSLocalizedString("Reminder Notification Text",comment: ""), sound: "Boxing.wav", category: NotificationCategory.ReminderCategory.key())
        }
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        
        let currentInstallation: PFInstallation = PFInstallation.currentInstallation()
        currentInstallation.setDeviceTokenFromData(deviceToken)
        currentInstallation.saveInBackground()
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        
        if error.code == 3010 {
            
            print("Push notifications are not supported in the iOS Simulator.")
            
        } else {
            
            print("application:didFailToRegisterForRemoteNotificationsWithError: %@", error)
        }
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        
        // Handle received remote notification
        PFPush.handlePush(userInfo)
        if application.applicationState == UIApplicationState.Inactive {
            PFAnalytics.trackAppOpenedWithRemoteNotificationPayload(userInfo)
        }
    }
    
    func applicationWillResignActive(application: UIApplication) {
        
        //        let vc = storyboard.instantiateViewControllerWithIdentifier("ViewController") as! ViewController
        //
        //        guard vc.workoutState == .Run || vc.workoutState == .Pause else { return }
        //
        //        if let settings = UIApplication.sharedApplication().currentUserNotificationSettings() {
        //
        //            if settings.types.contains([.None]) {
        //
        //                let notificationSweetAlert = SweetAlert()
        //
        //                notificationSweetAlert.showAlert(NSLocalizedString("Alert: Workout Running Question Title Text", comment: ""), subTitle: NSLocalizedString("Alert: Workout Running Question Subtitle Text", comment: ""), style: AlertStyle.Warning, dismissTime: nil, buttonTitle: NSLocalizedString("Cancel", comment: ""), buttonColor:UIColor.colorFromRGB(0xD0D0D0) , otherButtonTitle:NSLocalizedString("Settings", comment: ""), otherButtonColor: UIColor.colorFromRGB(0xAEDEF4)) { (isOtherButton) -> Void in
        //
        //                    notificationSweetAlert.closeAlertDismissButton()
        //
        //                    if !isOtherButton {
        //
        //                        UIApplication.sharedApplication().openURL(settingsURL!)
        //                    }
        //                }
        //            }
        //        }
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        
        if runInBackgroundState == true {
            backgroundTask = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler({})
        }
        
        // Register for Push Notitications
        if application.respondsToSelector(#selector(UIApplication.registerUserNotificationSettings(_:))) {
            let userNotificationTypes: UIUserNotificationType = [.Alert, .Badge, .Sound]
            let settings = UIUserNotificationSettings(forTypes: userNotificationTypes, categories: nil)
            application.registerUserNotificationSettings(settings)
            application.registerForRemoteNotifications()
            
        } else {
            
            application.registerForRemoteNotifications()
        }
        
        print("app entered background mode")
        
    }
    
    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        if backgroundTask != nil {
            
            UIApplication.sharedApplication().endBackgroundTask(backgroundTask)
            
            backgroundTask = nil
            
        }
        
        // Track Facebook events
        FBSDKAppEvents.activateApp()
        
        // Clear Parse Push badges
        NotificationHelper.resetAppBadgePush()
        
        // Clear workoutCompleteLocalNotification
        NotificationHelper.unscheduleNotifications(NotificationCategory.WorkoutCategory.key())
    }
    
    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        saveContext { (save) -> Void in
        }
    }
    
    // MARK: - WCSessionDelegate
    
    @available(iOS 9.0, *)
    func sessionWatchStateDidChange(session: WCSession) {
        print(#function)
        print(session)
        print("reachable:\(session.reachable)")
    }
    
    // MARK: - iRateDelegate Functions
    
    func iRateDidOpenAppStore() {
        
        markFeedbackGiven()
        
        // log rating event
        Answers.logRating(nil,
                          contentName: "Chronic rated",
                          contentType: "rate",
                          contentId: nil,
                          customAttributes: ["Installation ID":PFInstallation.currentInstallation().installationId, "Country Code": countryCode, "App Version": AppVersion])
    }
    
    func iRateDidDetectAppUpdate() {
        
        SARate.sharedInstance().eventCount = 0
        userDefaults.setBool(false, forKey: "FEEDBACK_GIVEN")
        userDefaults.synchronize()
    }
    
    // MARK: - Shortcut Handling
    
    @available(iOS 9.0, *)
    func handleShortcutItem(shortcutItem: UIApplicationShortcutItem) -> Bool {
        
        guard ShortcutIdentifier(fullType: shortcutItem.type) != nil else { return false }
        guard let shortcutType = shortcutItem.type as String? else { return false }
        
        let timerViewController = mainStoryboard.instantiateViewControllerWithIdentifier("TimerViewController") as! TimerViewController
        
        let rootViewController = appDel.window?.rootViewController
        if rootViewController?.presentedViewController != nil {
            rootViewController?.dismissViewControllerAnimated(true, completion: nil)
        }
        
        switch (shortcutType) {
            
        case ShortcutIdentifier.Run.type:
            
            timerViewController.initializeRunner()
            rootViewController?.presentViewController(timerViewController, animated: true, completion: nil)
        
            return true
            
        case ShortcutIdentifier.QT.type:
            
            timerViewController.initializeQuickTimer()
            rootViewController?.presentViewController(timerViewController, animated: true, completion: nil)
            
            return true
            
        case ShortcutIdentifier.Dynamic.type:
            
            guard let selectedRoutine = getRoutine(withName: shortcutItem.localizedTitle) else { return false }
                
            timerViewController.initializeRoutine(with: selectedRoutine)
            rootViewController?.presentViewController(timerViewController, animated: true, completion: nil)
            //timerViewController.play()
            
            return true
            
        default:
            return false
        }
        
    }
    
    // MARK: - Setup User Defaults
    
    func setupUserDefaults() {
        
        userDefaults.registerDefaults(defaultPrefs as! [String : AnyObject])
        
        // Enable/Disable Timer Sound based on timerSound
        timerSound = userDefaults.stringForKey("TIMER_SOUND")
        
        // Set Timer Volume based on timerVolume
        timerVolume = userDefaults.floatForKey("TIMER_VOLUME")
        
        // Enable/Disable display sleep based on enableDeviceSleepState flag
        enableDeviceSleepState = userDefaults.boolForKey("ENABLE_DEVICE_SLEEP") as Bool
        
        // Enable/Disable background tasks based on runInBackgroundState flag
        runInBackgroundState = userDefaults.boolForKey("RUN_IN_BACKGROUND") as Bool
        
        // Enable/Disable notification reminders based on notificationReminderState flag
        notificationReminderState = userDefaults.boolForKey("NOTIFICATION_REMINDER_ENABLED") as Bool
    }
    
    // MARK: - Setup storyboards
    
    func loadOnboardingInterface() {
        let storyboard = UIStoryboard(name: "Onboarding", bundle: nil)
        if let controller = storyboard.instantiateInitialViewController() {
            self.window?.rootViewController = controller
        }
    }
    
    func loadMainInterface() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let controller = storyboard.instantiateInitialViewController() {
            self.window?.rootViewController = controller
        }
    }
}

