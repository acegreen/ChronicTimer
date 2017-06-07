//
//  Functions.swift
//  Chronic
//
//  Created by Ace Green on 2015-03-24.
//  Copyright (c) 2015 Ace Green. All rights reserved.
//

import Foundation
import UIKit
import ChronicKit
import CoreData
import CoreSpotlight
import MobileCoreServices
import SystemConfiguration
import AVFoundation
import WatchConnectivity
import AMPopTip
import MZFormSheetPresentationController
import Whisper

class Functions {
    
    // MARK: -Exercise Function
    
    class func makeRoutineArray(routine: RoutineModel?) -> ([[String:Any]], Int) {
        
        let stagesArray = NSMutableArray()
        var totalTime = 0
        
        if routine != nil {
            
            let routineExercises = routine!.routineToExcercise?.array as! [ExerciseModel]
            
            let type:String = routine!.type!
            
            if type == "Custom" {
                
                for exercise in routineExercises {
                    
                    var customeExerciseDictionary = [String:Any]()
                    
                    for number in 1...(exercise.exerciseNumberOfRounds as Int) {
                        
                        if exercise.exerciseTime as Int > 0 {
                            
                            //Exercise Name & Time
                            
                            customeExerciseDictionary["Name"] = exercise.exerciseName
                            
                            if exercise.exerciseNumberOfRounds as Int > 1 {
                                customeExerciseDictionary["Interval"] = "\(number) / \(exercise.exerciseNumberOfRounds!)"
                            }
                            
                            customeExerciseDictionary["Time"] = exercise.exerciseTime
                            customeExerciseDictionary["Color"] = exercise.exerciseColor
                            
                            totalTime += customeExerciseDictionary["Time"] as! Int
                            
                            stagesArray.add(customeExerciseDictionary)
                        }
                    }
                }
                
            } else if type == "Circuit" {
                
                var warmUpDictionary = [String:Any]()
                var roundDictionary = [String:Any]()
                var restDictionary = [String:Any]()
                var coolDownDictionary = [String:Any]()
                
                Constants.warmUpExercise = routineExercises[0]
                Constants.roundExercise = routineExercises[1]
                Constants.restExercise = routineExercises[2]
                Constants.coolDownExercise = routineExercises[3]
                
                if Constants.warmUpExercise.exerciseTime as Int > 0 {
                    
                    //Warmup
                    warmUpDictionary["Name"] = Constants.warmUpExercise.exerciseName
                    warmUpDictionary["Time"] = Constants.warmUpExercise.exerciseTime
                    warmUpDictionary["Color"] = Constants.warmUpExercise.exerciseColor
                    
                    totalTime += warmUpDictionary["Time"] as! Int
                    
                    stagesArray.add(warmUpDictionary)
                    
                }
                
                for i in 1...Int(Constants.roundExercise.exerciseNumberOfRounds) {
                    
                    if Constants.roundExercise.exerciseTime as Int > 0 {
                        
                        //Round Time
                        roundDictionary["Name"] = Constants.roundExercise.exerciseName
                        
                        if Constants.roundExercise.exerciseNumberOfRounds as Int > 1 {
                            roundDictionary["Interval"] = "\(i) / \(Constants.roundExercise.exerciseNumberOfRounds!)"
                        }
                        
                        roundDictionary["Time"] = Constants.roundExercise.exerciseTime
                        roundDictionary["Color"] = Constants.roundExercise.exerciseColor
                        
                        totalTime += roundDictionary["Time"] as! Int
                        
                        stagesArray.add(roundDictionary)
                        
                    }
                    
                    if Constants.restExercise.exerciseTime as Int > 0 {
                        
                        //Rest Time
                        restDictionary["Name"] = Constants.restExercise.exerciseName
                        
                        if Constants.restExercise.exerciseNumberOfRounds as Int > 1 {
                            restDictionary["Interval"] = "\(i) / \(Constants.restExercise.exerciseNumberOfRounds!)"
                        }
                        restDictionary["Time"] = Constants.restExercise.exerciseTime
                        restDictionary["Color"] = Constants.restExercise.exerciseColor
                        
                        totalTime += restDictionary["Time"] as! Int
                        
                        stagesArray.add(restDictionary)
                        
                    }
                }
                
                if Constants.coolDownExercise.exerciseTime as Int > 0 {
                    
                    // Cool Down Time
                    coolDownDictionary["Name"] = Constants.coolDownExercise.exerciseName
                    coolDownDictionary["Time"] = Constants.coolDownExercise.exerciseTime
                    coolDownDictionary["Color"] = Constants.coolDownExercise.exerciseColor
                    
                    totalTime += coolDownDictionary["Time"] as! Int
                    
                    stagesArray.add(coolDownDictionary)
                    
                }
            }
            
        } else {
            
            var quickTimerDictionary = [String:Any]()
            
            // Quick Timer Time
            quickTimerDictionary["Name"] = NSLocalizedString("Quick Timer", comment: "")
            quickTimerDictionary["Time"] = Constants.QuickTimerTime
            quickTimerDictionary["Color"] = NSKeyedArchiver.archivedData(withRootObject: UIColor.orange)
            
            totalTime += quickTimerDictionary["Time"] as! Int
            
            stagesArray.add(quickTimerDictionary)
            
        }
        
        print(stagesArray, totalTime)
        return (stagesArray as Any as! [[String:Any]], totalTime)
    }
    
    class func setSelectedRoutine(_ routine: RoutineModel, completion: (_ result: Bool) -> Void) {
        
        routine.selectedRoutine = true
        
        updateDynamicAction(with: routine)
        
        saveContext( { (save) -> Void in
            
            if (save == true) {
                
                print("selectedRoutine attribute updated")
                completion(true)
                
            } else {
                
                print("Didnt save data")
                completion(false)
                
            }
            
        })
    }
    
    class func deselectSelectedRoutine() {
        
        let routineMarkedSelected = DataAccess.sharedInstance.fetchSelectedRoutine()
        routineMarkedSelected?.selectedRoutine = false
        
        saveContext( { (save) -> Void in
            
            if save == true {
                
                UIApplication.shared.shortcutItems = nil
            }
        })
    }
    
    class func saveContext(_ completion: (_ didSave: Bool) -> Void) {
        
        do {
            
            try DataAccess.context.save()
            
            completion(true)
            
        } catch let error as NSError {
            
            print("Fetch failed: \(error.localizedDescription)")
            
            completion(false)
        }
        
    }
    
    @available(iOS 9.0, *)
    class func updateDynamicAction(with routine: RoutineModel) {
        
        let type = Bundle.main.bundleIdentifier! + ".Dynamic"
        let shortcutIconType = UIApplicationShortcutIconType.play
        let icon = UIApplicationShortcutIcon(type: shortcutIconType)
        
        let dynamicShortcut = UIApplicationShortcutItem(type: type, localizedTitle: routine.name, localizedSubtitle: nil, icon: icon, userInfo: nil)
        UIApplication.shared.shortcutItems = [dynamicShortcut]
    }
    
    class func xDaysFromNow (_ numberOfDays: Int) -> Date {
        
        var dayComponent: DateComponents = DateComponents()
        dayComponent.day = numberOfDays
        
        return Constants.currentCalendar.date(byAdding: dayComponent, to: Date())!
    }
    
    @available(iOS 9.0, *)
    class func createNSUserActivity(workout: Workout, domainIdentifier: String) {
                
        let attributeSet:CSSearchableItemAttributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeImage as String)
        attributeSet.contentDescription = workout.searchDescription
        //    attributeSet.thumbnailData = image
        attributeSet.relatedUniqueIdentifier = workout.name
        
        let activity = NSUserActivity(activityType: domainIdentifier)
        activity.title = workout.name
        activity.keywords = NSSet(array: [workout.name, "Workout", "Timer"]) as! Set<String>
        activity.userInfo = ["name": workout.name]
        activity.contentAttributeSet = attributeSet
        
        activity.requiredUserInfoKeys = NSSet(array: ["name"]) as! Set<String>
        activity.isEligibleForSearch = true
        activity.isEligibleForPublicIndexing = true
        workout.nsUserActivity = activity
        activity.becomeCurrent()
        
        print("NSUserActivity created")
    }
    
    @available(iOS 9.0, *)
    class func addToSpotlight (routine: RoutineModel, domainIdentifier: String) {
        
        let attributeSet:CSSearchableItemAttributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeText as String)
        attributeSet.title = routine.name
        attributeSet.contentDescription = routine.searchDescription
        
        let searchableItem = CSSearchableItem(uniqueIdentifier: routine.name, domainIdentifier: domainIdentifier, attributeSet: attributeSet)
        
        CSSearchableIndex.default().indexSearchableItems([searchableItem]) { (error) -> Void in
            
            if let error = error {
                print("Deindexing error: \(error.localizedDescription)")
            } else {
                print("Search item successfully indexed!")
            }
        }
        
    }
    
    @available(iOS 9.0, *)
    class func deleteFromSpotlight(_ uniqueIdentifier: String) {
        
        CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: [uniqueIdentifier]) { (error: Error?) -> Void in
            
            if let error = error {
                print("Deindexing error: \(error.localizedDescription)")
            } else {
                print("Search item successfully removed!")
            }
        }
    }
    
    @available(iOS 9.0, *)
    class func sendContextToAppleWatch(_ context: Any) {
        
        guard (WCSession.isSupported()) else { return }
        
        guard Constants.wcSession.isWatchAppInstalled else { return }
        
        // KEEP THOSE TWO GUARD STATEMENTS SEPARTED
        
        if !Constants.wcSession.isPaired {
            
            SweetAlert().showAlert(NSLocalizedString("Alert: WCSession Paired Error Title Text", comment: ""), subTitle: NSLocalizedString("Alert: WCSession Paired Error Subtitle Text", comment: ""), style: AlertStyle.warning, dismissTime: nil)
        }
        
        do {
            
            try Constants.wcSession.updateApplicationContext(context as! [String : Any])
            
            print("Context sent")
            
        } catch let error as NSError {
            
            print("Updating the context failed: " + error.localizedDescription)
        }
    }
    
    class func timeFromTimeComponents (hoursComponent: Int, minutesComponent: Int, secondsComponent: Int) -> Int {
        
        return (hoursComponent * 3600) + (minutesComponent * 60) + (secondsComponent)
    }
    
    class func timeComponentsFrom(time: Int) -> (HoursLeft: Int, MinutesLeft: Int, SecondsLeft: Int) {
        
        let HoursLeft = time/3600
        let MinutesLeft = (time%3600)/60
        let SecondsLeft = (((time%3600)%60)%60)
        
        return (HoursLeft, MinutesLeft, SecondsLeft)
    }
    
    class func timeComponentsFrom(string: String) -> (HoursLeft: Int, MinutesLeft: Int, SecondsLeft: Int) {
        
        var components = string.components(separatedBy: ":")
        
        var hoursComponent: Int! = 0
        var minutesComponent: Int! = 0
        var secondsComponent: Int! = 0
        
        if components.count == 3 {
            
            hoursComponent = Int(components[0].replacingOccurrences(of: " ", with: ""))!
            minutesComponent = Int(components[1])!
            secondsComponent = Int(components[2])
            
        } else {
            
            minutesComponent = Int(components[0])
            secondsComponent = Int(components[1])
        }
        
        return (hoursComponent,minutesComponent,secondsComponent)
    }
    
    class func timeStringFrom(time: Int) -> String {
        
        let (hoursLeft, minutesLeft, secondsLeft) = timeComponentsFrom(time: time)
        
        if hoursLeft == 0 {
            return String(format:"%.2d:%.2d", minutesLeft, secondsLeft)
        } else {
            return String(format:"%2d:%.2d:%.2d", hoursLeft, minutesLeft, secondsLeft)
        }
    }
    
    class func timeRemainingString(from time: Int) -> String {
        
        let dateNow = Date()
        let date = Date(timeIntervalSinceNow: TimeInterval(time))
        
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .spellOut
        formatter.includesTimeRemainingPhrase = true
        formatter.maximumUnitCount = 0
        formatter.allowedUnits = [.hour, .minute, .second]
        
        return formatter.string(from: dateNow, to: date) ?? ""
    }
    
    class func displayAlert(_ title: String, message: String, Action1: UIAlertAction?, Action2: UIAlertAction?) -> UIAlertController {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        if Action1 != nil {
            
            alert.addAction(Action1!)
        }
        
        if Action2 != nil {
            
            alert.addAction(Action2!)
        }
        
        return alert
    }
    
    class func loadPlayer(_ sound: String, ext: String) {
        
        // Load Soundlocation
        let soundlocation = Bundle.main.url(forResource: sound, withExtension: ext)!
        
        do {
            
            // Play Sound
            Constants.player = try AVAudioPlayer(contentsOf: soundlocation)
            Constants.player.volume = Constants.timerVolume
            Constants.player.play()
            
        } catch let error as NSError {
            
            print("Fetch failed: \(error.localizedDescription)")
        }
    }
    
    class func textToSpeech(_ text: String, volumeOn: Bool = true) {
        
        let myUtterance = AVSpeechUtterance(string: decryptString(text, dict: Constants.decryptDictionary))
        myUtterance.rate = 0.3
        
        if volumeOn {
            myUtterance.volume = Constants.timerVolume
        } else {
            myUtterance.volume = 0
        }
        
        Constants.synthesizer.speak(myUtterance)
    }
    
    class func decryptString (_ string: String, dict: Dictionary<String, String>) -> String {
        
        var string = string
        
        for (key, value) in dict {
            
            string = string.replacingOccurrences(of: "\(key)", with: value)
            
        }
        
        return string
    }
    
    class func stopSoundsOrSpeech() {
        
        if Constants.player.isPlaying {
            Constants.player.stop()
        }
        
        if Constants.synthesizer.isSpeaking {
            
            Constants.synthesizer.stopSpeaking(at: AVSpeechBoundary.immediate)
        }
        
    }
    
    //class func checkDevice() {
    //
    //    if SDiOSVersion.deviceVersion() == .iPadPro12Dot9Inch || SDiOSVersion.deviceVersion() == .iPadPro9Dot7Inch {
    //
    //        Constants.circleWidth = 880
    //
    //    } else {
    //
    //        Constants.circleWidth = 660
    //    }
    //
    //}
    
    class func markFeedbackGiven() {
        
        Constants.userDefaults.set(true, forKey: "FEEDBACK_GIVEN")
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: "HideStarButton"), object: nil)
    }
    
    class func showPopTipOnceForKey(_ key: String, userDefaults: UserDefaults, popTipText text: String, inView view: UIView, fromFrame frame: CGRect, direction: AMPopTipDirection = .down, color: UIColor = .darkGray) -> AMPopTip? {
        if (!userDefaults.bool(forKey: key)) {
            userDefaults.set(true, forKey: key)
            AMPopTip.appearance().popoverColor = color
            AMPopTip.appearance().offset = 10
            AMPopTip.appearance().edgeMargin = 5
            let popTip = AMPopTip()
            popTip.showText(text, direction: direction, maxWidth: 250, in: view, fromFrame: frame)
            popTip.actionAnimation = AMPopTipActionAnimation.bounce
            popTip.shouldDismissOnTapOutside = false
            
            return popTip
        }
        
        return nil
    }
    
    class func screenShotMethod(_ view: UIView) -> UIImage {
        //Create the UIImage
        UIGraphicsBeginImageContextWithOptions(view.frame.size, true, 0.0)
        view.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image!
    }
    
    // MARK: Generic Question Bool Functions
    
    class func isConnectedToNetwork() -> Bool {
        if Constants.reachability?.currentReachabilityStatus == .notReachable {
            return false
        } else {
            return true
        }
    }
    
    class func isRemoveAdsUpgradePurchased() -> Bool {
        
        guard Constants.keychainRemoveAdsString == Constants.removeAdsKeyValue else {
            return false
        }
        return true
    }
    
    class func isProFeaturesUpgradePurchased() -> Bool {
        
        guard Constants.keychainProVersionString == Constants.proVersionKeyValue else {
            return false
        }
        return true
    }
    
    // MARK: - Setup storyboards
    
    class func loadOnboardingInterface() {
        let storyboard = UIStoryboard(name: "Onboarding", bundle: nil)
        if let controller = storyboard.instantiateInitialViewController() {
            Constants.appDel.window?.rootViewController = controller
        }
    }
    
    class func loadMainInterface() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let controller = storyboard.instantiateInitialViewController() {
            Constants.appDel.window?.rootViewController = controller
        }
    }
    
    // MARK: - Presenting Stuff
    
    class func presentWhisper(with title: String) {
        
        guard let navigationController = UIApplication.topViewController()?.navigationController else { return }
        
        let message = Message(title: title, backgroundColor: Constants.chronicGreen)
        
        // Show and hide a message after delay
        show(whisper: message, to: navigationController, action: .show)
        
        // Hide a message
        hide(whisperFrom: navigationController, after: 5)
    }
    
    class func presentFeedback() {
        
        let navigationViewController = Constants.feedbackStoryboard.instantiateViewController(withIdentifier: "FeedbackNavigationController") as! UINavigationController
        let bubbleTransitionDelegate = BubbleTransitionDelegate()
        navigationViewController.transitioningDelegate = bubbleTransitionDelegate
        navigationViewController.modalPresentationStyle = .custom
        
        UIApplication.topViewController()?.present(navigationViewController, animated: true, completion: nil)
    }
    
    class func presentShareCard(lastWorkout: Workout) {
        
        //        guard workout.totalTime >= 60 else { return }
        
        let viewController = Constants.shareWorkoutStoryboard.instantiateViewController(withIdentifier: "ShareWorkoutViewController") as! ShareWorkoutViewController
        viewController.workout = lastWorkout
        
        let formSheetController = MZFormSheetPresentationViewController(contentViewController: viewController)
        
        formSheetController.contentViewControllerTransitionStyle = .slideAndBounceFromLeft
        formSheetController.presentationController?.shouldCenterVertically = true
        formSheetController.presentationController?.shouldUseMotionEffect = true
//        formSheetController.presentationController?.isTransparentTouchEnabled = true
        formSheetController.presentationController?.shouldDismissOnBackgroundViewTap = true
        formSheetController.presentationController?.contentViewSize = CGSize(width: 350, height: 450)
        
        UIApplication.topViewController()?.present(formSheetController, animated: true, completion: nil)
    }
}
