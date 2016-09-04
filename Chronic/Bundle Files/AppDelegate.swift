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
import LaunchKit
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, WCSessionDelegate, iRateDelegate {
    
    var backgroundTask: UIBackgroundTaskIdentifier!
    
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
    
    override class func initialize() {
        setupSARate()
    }
    
    class func setupSARate() {
        
        //configure
        SARate.sharedInstance().minAppStoreRaiting = 4
        SARate.sharedInstance().eventsUntilPrompt = 5
        SARate.sharedInstance().daysUntilPrompt = 5
        SARate.sharedInstance().remindPeriod = 0
        
        SARate.sharedInstance().email = Constants.appEmail
        SARate.sharedInstance().emailSubject = "Chronic Feedback/Bug"
        SARate.sharedInstance().emailText = "Hello Chronic Team, </br> </br> </br> </br> </br> - - - - - - - - - - - - - - - - - - - - - </br>" + Constants.emailDiagnosticInfo
        
        SARate.sharedInstance().previewMode = false
        SARate.sharedInstance().verboseLogging = false
        SARate.sharedInstance().promptAtLaunch = false
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        // setup user defaults
        setupUserDefaults()
        
        // Set idelTimerDisabled accordingly
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
        
        // Setup Crashlytics
        Fabric.with([Crashlytics.self, MoPub.self])
        
        // Initalize Facebook
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        
        // Initalize LaunchKit
        LaunchKit.launch(withToken: "FYwLCkgJpT_r8kEp1O_-PSg-UnhaD3B7PMPxkG5qIIfq")
        LaunchKit.sharedInstance().debugAlwaysPresentAppReleaseNotes = true
        LaunchKit.sharedInstance().debugAppUserIsAlwaysSuper = true
        
        // Initialize Rollout
        Rollout.setup(withKey: "56932e164e1e847211ffe9ee")
        
        // Register for Google App Indexing
        //GSDAppIndexing.sharedInstance().registerApp(iTunesID)
        
        // Setup WCSession
        if (WCSession.isSupported()) {
            Constants.wcSession = WCSession.default()
            Constants.wcSession.delegate = self
            Constants.wcSession.activate()
        }
        
        // Setup sound mixing so that app can make sound when music is playing from another app
        UIApplication.shared.beginReceivingRemoteControlEvents()
        do {
            
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with: AVAudioSessionCategoryOptions.mixWithOthers)
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
        if application.applicationState != UIApplicationState.background {
            // Track an app open here if we launch with a push, unless
            // "content_available" was used to trigger a background push (introduced in iOS 7).
            // In that case, we skip tracking here to avoid double counting the app-open.
            
            let preBackgroundPush = !application.responds(to: #selector(getter: UIApplication.backgroundRefreshStatus))
            let oldPushHandlerOnly = !self.responds(to: #selector(UIApplicationDelegate.application(_:didReceiveRemoteNotification:fetchCompletionHandler:)))
            var pushPayload = false
            if let options = launchOptions {
                pushPayload = options[UIApplicationLaunchOptionsKey.remoteNotification] != nil
            }
            if (preBackgroundPush || oldPushHandlerOnly || pushPayload) {
                PFAnalytics.trackAppOpened(launchOptions: launchOptions)
            }
        }
        
        // Request upgrade products
        IAPHelper.sharedInstance.requestProducts(displayAlert: false, nil)
        
        // increment event count
        SARate.sharedInstance().eventCount += 1
        print("eventCount", SARate.sharedInstance().eventCount)
        
        // load storyboard
        if !Constants.userDefaults.bool(forKey: "ONBOARDING_SHOWN") {
            Functions.loadOnboardingInterface()
        } else {
            Functions.loadMainInterface()
        }
        
        return true
    }
    
    // func depracted iOS9 - needs to be replaced by func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any?) -> Bool {
    
        switch url.scheme {
            
        case "chronic"?:
            
            return true
            
        case "fb1691125951168014"?:
            
            return FBSDKApplicationDelegate.sharedInstance().application(application, open: url, sourceApplication: sourceApplication, annotation: annotation)
            
        default:
            
            return false
        }
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Swift.Void) -> Bool {
        
        if userActivity.activityType == CSSearchableItemActionType {
            
            if let uniqueIdentifier = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String {
                
                let uniqueIdentifierPredicate: NSPredicate = NSPredicate(format: "name = %@", uniqueIdentifier)
                
                do {
                    
                    guard let routineSelectedInSpotlight = try DataAccess.sharedInstance.GetRoutines(uniqueIdentifierPredicate).first else { return false }
                    
                    let timerViewController = Constants.mainStoryboard.instantiateViewController(withIdentifier: "TimerViewController") as! TimerViewController
                    timerViewController.initializeRoutine(with: routineSelectedInSpotlight)
                    
                    let rootViewController = Constants.appDel.window?.rootViewController
                    if rootViewController?.presentedViewController != nil {
                        rootViewController?.dismiss(animated: true, completion: nil)
                    }
                    
                    rootViewController?.present(timerViewController, animated: true, completion: nil)
                    
                    // Mark correct routine as selected
                    
                    let routineMarkedSelected = Functions.getSelectedRoutine()
                    
                    if routineMarkedSelected != nil && routineMarkedSelected?.name != uniqueIdentifier {
                        
                        routineMarkedSelected!.selectedRoutine = false
                        
                    }
                    
                    routineSelectedInSpotlight.selectedRoutine = true
                    
                } catch {
                    // TO-DO: HANDLE ERROR
                }
            }
        }
        
        return true
    }
    
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        let handledShhortcutItem = self.handleShortcutItem(shortcutItem)
        completionHandler(handledShhortcutItem)
    }
    
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
        if application.applicationState == UIApplicationState.inactive {
            PFAnalytics.trackAppOpened(withRemoteNotificationPayload: userInfo)
        }
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        
        if Constants.runInBackgroundState == true {
            backgroundTask = UIApplication.shared.beginBackgroundTask(expirationHandler: {})
        }
        
        // Register for Push Notitications
        NotificationHelper.registerForPushNotifications()
        
        print("app entered background mode")
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        if backgroundTask != nil {
            
            UIApplication.shared.endBackgroundTask(backgroundTask)
            
            backgroundTask = nil
        }
        
        // Track Facebook events
        FBSDKAppEvents.activateApp()
        
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
    
    // MARK: - iRateDelegate Functions
    
    func iRateDidOpenAppStore() {
        
        Functions.markFeedbackGiven()
        
        // log rating event
        Answers.logRating(nil,
                          contentName: "Chronic Rated",
                          contentType: "Rate",
                          contentId: nil,
                          customAttributes: ["Installation ID": PFInstallation.current()?.installationId ?? "", "Country Code": Constants.countryCode, "App Version": Constants.AppVersion])
    }
    
    func iRateDidDetectAppUpdate() {
        
        SARate.sharedInstance().eventCount = 0
        Constants.userDefaults.set(false, forKey: "FEEDBACK_GIVEN")
    }
    
    // MARK: - Shortcut Handling
    
    @available(iOS 9.0, *)
    func handleShortcutItem(_ shortcutItem: UIApplicationShortcutItem) -> Bool {
        
        guard ShortcutIdentifier(fullType: shortcutItem.type) != nil else { return false }
        guard let shortcutType = shortcutItem.type as String? else { return false }
        
        let timerViewController = Constants.mainStoryboard.instantiateViewController(withIdentifier: "TimerViewController") as! TimerViewController
        
        let rootViewController = Constants.appDel.window?.rootViewController
        if rootViewController?.presentedViewController != nil {
            rootViewController?.dismiss(animated: true, completion: nil)
        }
        
        switch (shortcutType) {
            
        case ShortcutIdentifier.Run.type:
            
            timerViewController.initializeRunner()
            rootViewController?.present(timerViewController, animated: true, completion: nil)
        
            return true
            
        case ShortcutIdentifier.QT.type:
            
            timerViewController.initializeQuickTimer()
            rootViewController?.present(timerViewController, animated: true, completion: nil)
            
            return true
            
        case ShortcutIdentifier.Dynamic.type:
            
            guard let selectedRoutine = Functions.getRoutine(shortcutItem.localizedTitle) else { return false }
                
            timerViewController.initializeRoutine(with: selectedRoutine)
            rootViewController?.present(timerViewController, animated: true, completion: nil)
            //timerViewController.play()
            
            return true
            
        default:
            return false
        }
        
    }
    
    // MARK: - Setup User Defaults
    
    func setupUserDefaults() {
        
        Constants.userDefaults.register(defaults: Constants.defaultPrefs as! [String : AnyObject])
        
        // Enable/Disable Timer Sound based on timerSound
        Constants.timerSound = Constants.userDefaults.string(forKey: "TIMER_SOUND")
        
        // Set Timer Volume based on timerVolume
        Constants.timerVolume = Constants.userDefaults.float(forKey: "TIMER_VOLUME")
        
        // Enable/Disable display sleep based on enableDeviceSleepState flag
        Constants.enableDeviceSleepState = Constants.userDefaults.bool(forKey: "ENABLE_DEVICE_SLEEP") as Bool
        
        // Enable/Disable background tasks based on runInBackgroundState flag
        Constants.runInBackgroundState = Constants.userDefaults.bool(forKey: "RUN_IN_BACKGROUND") as Bool
        
        // Enable/Disable notification reminders based on notificationReminderState flag
        Constants.notificationReminderState = Constants.userDefaults.bool(forKey: "NOTIFICATION_REMINDER_ENABLED") as Bool
    }
}

