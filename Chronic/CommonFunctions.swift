//
//  CommonFunctions.swift
//  Chronic
//
//  Created by Ace Green on 2015-03-24.
//  Copyright (c) 2015 Ace Green. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import CoreSpotlight
import MobileCoreServices
import SystemConfiguration
import AVFoundation
import WatchConnectivity
import SDVersion
import AMPopTip

// MARK: -Exercise Function

func makeRoutineArray(routine: RoutineModel?) -> ([[String:AnyObject]], Int) {
    
    let stagesArray = NSMutableArray()
    var totalTime = 0
    
    if routine != nil {
        
        var customeExerciseDictionary = [String:AnyObject]()
        var warmUpDictionary = [String:AnyObject]()
        var roundDictionary = [String:AnyObject]()
        var restDictionary = [String:AnyObject]()
        var coolDownDictionary = [String:AnyObject]()
        
        let routineExercises = routine!.routineToExcercise?.array as! [ExerciseModel]
        
        let type:String = routine!.type!
        
        if type == "Custom" {
            
            for exercise in routineExercises {
                
                for var number = 1; number <= exercise.exerciseNumberOfRounds; number += 1 {
                    
                    if exercise.exerciseTime > 0 {
                        
                        //Exercise Name & Time
                        
                        customeExerciseDictionary["Name"] = exercise.exerciseName
                        
                        if exercise.exerciseNumberOfRounds > 1 {
                            customeExerciseDictionary["Interval"] = "\(number) / \(exercise.exerciseNumberOfRounds)"
                        }
                        
                        customeExerciseDictionary["Time"] = exercise.exerciseTime
                        customeExerciseDictionary["Color"] = exercise.exerciseColor
                        
                        totalTime += customeExerciseDictionary["Time"] as! Int
                        
                        stagesArray.addObject(customeExerciseDictionary)
                    }
                }
            }
            
        } else if type == "Circuit" {
            
            warmUpExercise = routineExercises[0]
            roundExercise = routineExercises[1]
            restExercise = routineExercises[2]
            coolDownExercise = routineExercises[3]
            
            if warmUpExercise.exerciseTime > 0 {
                
                //Warmup
                warmUpDictionary["Name"] = warmUpExercise.exerciseName
                warmUpDictionary["Time"] = warmUpExercise.exerciseTime
                warmUpDictionary["Color"] = warmUpExercise.exerciseColor
                
                totalTime += warmUpDictionary["Time"] as! Int
                
                stagesArray.addObject(warmUpDictionary)
                
            }
            
            for i in 1...Int(roundExercise.exerciseNumberOfRounds) {
                    
                if roundExercise.exerciseTime > 0 {
                    
                    //Round Time
                    
                    roundDictionary["Name"] = roundExercise.exerciseName
                    
                    if roundExercise.exerciseNumberOfRounds > 1 {
                        roundDictionary["Interval"] = "\(i) / \(roundExercise.exerciseNumberOfRounds)"
                    }
                    
                    roundDictionary["Time"] = roundExercise.exerciseTime
                    roundDictionary["Color"] = roundExercise.exerciseColor
                    
                    totalTime += roundDictionary["Time"] as! Int
                    
                    stagesArray.addObject(roundDictionary)
                    
                }
                
                if restExercise.exerciseTime > 0 {
                    
                    //Rest Time
                    
                    restDictionary["Name"] = restExercise.exerciseName
                    
                    if restExercise.exerciseNumberOfRounds > 1 {
                        restDictionary["Interval"] = "\(i) / \(restExercise.exerciseNumberOfRounds)"
                    }
                    restDictionary["Time"] = restExercise.exerciseTime
                    restDictionary["Color"] = restExercise.exerciseColor
                    
                    totalTime += restDictionary["Time"] as! Int
                    
                    stagesArray.addObject(restDictionary)
                    
                }
            }
            
            if coolDownExercise.exerciseTime > 0 {
                
                // Cool Down Time
                coolDownDictionary["Name"] = coolDownExercise.exerciseName
                coolDownDictionary["Time"] = coolDownExercise.exerciseTime
                coolDownDictionary["Color"] = coolDownExercise.exerciseColor
                
                totalTime += coolDownDictionary["Time"] as! Int
                
                stagesArray.addObject(coolDownDictionary)
                
            }
        }
        
    } else {
        
        var quickTimerDictionary = [String:AnyObject]()
        
        // Quick Timer Time
        quickTimerDictionary["Name"] = NSLocalizedString("Quick Timer", comment: "")
        quickTimerDictionary["Time"] = QuickTimerTime
        quickTimerDictionary["Color"] = NSKeyedArchiver.archivedDataWithRootObject(UIColor.orangeColor())
        
        totalTime += quickTimerDictionary["Time"] as! Int
        
        stagesArray.addObject(quickTimerDictionary)
        
    }
    
    // print(stagesArray, totalTime)
    return (stagesArray as AnyObject as! [[String:AnyObject]], totalTime)
}

func setSelectedRoutine(routine: RoutineModel, completion: (result: Bool) -> Void) {
        
    routine.setValue(true, forKey: "selectedRoutine")

    updateDynamicAction(with: routine)
    
    saveContext( { (save) -> Void in
        
        if (save == true) {
            
            print("selectedRoutine attribute updated")
            completion(result: true)
            
        } else {
            
            print("Didnt save data")
            completion(result: false)
            
        }
        
    })
}

func deselectSelectedRoutine() {
    
    let selecredRoutinePredicate: NSPredicate = NSPredicate(format: "selectedRoutine == true")
    
    guard let routineMarkedSelected = DataAccess.sharedInstance.GetRoutines(selecredRoutinePredicate)!.first as? RoutineModel else { return }
    
    routineMarkedSelected.selectedRoutine = false
    
    saveContext( { (save) -> Void in
        
        if save == true {
            
            UIApplication.sharedApplication().shortcutItems = nil
        }
    })
}

func getRoutine(withName withName: String) -> RoutineModel? {
    
    let existingRoutinePredicate: NSPredicate = NSPredicate(format: "name == %@", withName)
    
    return DataAccess.sharedInstance.GetRoutines(existingRoutinePredicate)?.first as? RoutineModel
}

func getSelectedRoutine() -> RoutineModel? {
    
    let selecredRoutinePredicate: NSPredicate = NSPredicate(format: "selectedRoutine == true")
    
    return (DataAccess.sharedInstance.GetRoutines(selecredRoutinePredicate)?.first as? RoutineModel)
}

func saveContext(completion: (save: Bool) -> Void) {
    
    do {
        
        try context.save()
        
        completion(save: true)
        
    } catch let error as NSError {
        
        print("Fetch failed: \(error.localizedDescription)")
        
        completion(save: false)
    }
    
}

@available(iOS 9.0, *)
func updateDynamicAction(with routine: RoutineModel) {
        
        let type = NSBundle.mainBundle().bundleIdentifier! + ".Dynamic"
        let shortcutIconType = UIApplicationShortcutIconType.Play
        let icon = UIApplicationShortcutIcon(type: shortcutIconType)
        
        let dynamicShortcut = UIApplicationShortcutItem(type: type, localizedTitle: routine.name, localizedSubtitle: nil, icon: icon, userInfo: nil)
        UIApplication.sharedApplication().shortcutItems = [dynamicShortcut]
}

func xDaysFromNow (numberOfDays: Int) -> NSDate {
    
    let dayComponent: NSDateComponents = NSDateComponents()
    dayComponent.day = numberOfDays
    
    let calendar:NSCalendar = NSCalendar.currentCalendar()
    
    return calendar.dateByAddingComponents(dayComponent, toDate: NSDate(), options: NSCalendarOptions(rawValue: 0))!
    
}

func isConnectedToNetwork() -> Bool {
    
    var zeroAddress = sockaddr_in()
    zeroAddress.sin_len = UInt8(sizeofValue(zeroAddress))
    zeroAddress.sin_family = sa_family_t(AF_INET)
    
    let defaultRouteReachability = withUnsafePointer(&zeroAddress) {
        SCNetworkReachabilityCreateWithAddress(nil, UnsafePointer($0))
    }
    var flags = SCNetworkReachabilityFlags.ConnectionAutomatic
    
    if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
        return false
    }
    
    let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
    let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
    return (isReachable && !needsConnection)
}

@available(iOS 9.0, *)
func addToSpotlight (title: String, contentDescription: String, uniqueIdentifier: String, domainIdentifier: String) {
    
    let attributeSet:CSSearchableItemAttributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeText as String)
    attributeSet.title = title
    attributeSet.contentDescription = contentDescription
    
    let searchableItem = CSSearchableItem(uniqueIdentifier: uniqueIdentifier, domainIdentifier: domainIdentifier, attributeSet: attributeSet)
    
    CSSearchableIndex.defaultSearchableIndex().indexSearchableItems([searchableItem]) { (error) -> Void in
        
        if let error = error {
            print("Deindexing error: \(error.localizedDescription)")
        } else {
            print("Search item successfully indexed!")
        }
    }
    
}

@available(iOS 9.0, *)
func deleteFromSpotlight(uniqueIdentifier: String) {
    
    CSSearchableIndex.defaultSearchableIndex().deleteSearchableItemsWithIdentifiers([uniqueIdentifier]) { (error: NSError?) -> Void in
        
        if let error = error {
            print("Deindexing error: \(error.localizedDescription)")
        } else {
            print("Search item successfully removed!")
        }
    }
}

@available(iOS 9.0, *)
func sendContextToAppleWatch(context: AnyObject) {
    
    guard (WCSession.isSupported()) else { return }
    
    guard wcSession.watchAppInstalled else { return }
    
    // KEEP THOSE TWO GUARD STATEMENTS SEPARTED
    
    if !wcSession.paired {
        
        SweetAlert().showAlert(NSLocalizedString("Alert: WCSession Paired Error Title Text", comment: ""), subTitle: NSLocalizedString("Alert: WCSession Paired Error Subtitle Text", comment: ""), style: AlertStyle.Warning, dismissTime: nil)
    }
    
    do {
        
        try wcSession.updateApplicationContext(context as! [String : AnyObject])
        
        print("Context sent")
        
    } catch let error as NSError {
        
        print("Updating the context failed: " + error.localizedDescription)
    }
}

func timeComponentsFrom(time time: Int) -> (HoursLeft: Int, MinutesLeft: Int, SecondsLeft: Int) {
    
    let HoursLeft = time/3600
    let MinutesLeft = (time%3600)/60
    let SecondsLeft = (((time%3600)%60)%60)
    
    return (HoursLeft, MinutesLeft, SecondsLeft)
    
}

func timeComponentsFrom(string string: String) -> (HoursLeft: Int, MinutesLeft: Int, SecondsLeft: Int) {
    
    var components = string.componentsSeparatedByString(":")
    
    var hoursComponent: Int! = 0
    var minutesComponent: Int! = 0
    var secondsComponent: Int! = 0
    
    if components.count == 3 {
        
        hoursComponent = Int(components[0].stringByReplacingOccurrencesOfString(" ", withString: ""))!
        minutesComponent = Int(components[1])!
        secondsComponent = Int(components[2])
        
    } else {
        
        minutesComponent = Int(components[0])
        secondsComponent = Int(components[1])
    }
    
    return (hoursComponent,minutesComponent,secondsComponent)
    
}

func timeStringFrom(time time: Int, type: String) -> String {
    
    let (HoursLeft,MinutesLeft,SecondsLeft) = timeComponentsFrom(time: time)
    
    if type == "Routine" {
        
        if HoursLeft == 0 {
            return String(format:"%.2d:%.2d", MinutesLeft, SecondsLeft)
        } else {
            return String(format:"%2d:%.2d:%.2d", HoursLeft, MinutesLeft, SecondsLeft)
        }
        
    } else {
        
        return String(format:"%2d:%.2d:%.2d", HoursLeft, MinutesLeft, SecondsLeft)
        
    }
}

func timeFromTimeComponents (hoursComponent hoursComponent:Int, minutesComponent:Int,secondsComponent:Int) -> Int {
    
    return (hoursComponent * 3600) + (minutesComponent * 60) + (secondsComponent)
    
}

func displayAlert(title: String, message: String, Action1:UIAlertAction?, Action2:UIAlertAction?) -> UIAlertController {
    
    let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
    
    if Action1 != nil {
        
        alert.addAction(Action1!)
    }
    
    if Action2 != nil {
        
        alert.addAction(Action2!)
    }
    
    return alert
}

func loadPlayer(sound: String, ext: String) {
    
    // Load Sound
    soundlocation = NSBundle.mainBundle().URLForResource(sound, withExtension: ext)!
    
    do {
        
        // Play Sound
        player = try AVAudioPlayer(contentsOfURL: soundlocation)
        player.volume = timerVolume
        player.play()
        
    } catch let error as NSError {
        
        print("Fetch failed: \(error.localizedDescription)")
    }
}

func textToSpeech(text: String) {
    
    let myUtterance = AVSpeechUtterance(string: decryptString(text, dict: decryptDictionary))
    myUtterance.rate = 0.3
    myUtterance.volume = timerVolume
    synthesizer.speakUtterance(myUtterance)
}

func decryptString (var string: String, dict: Dictionary<String, String>) -> String {
    
    for (key, value) in dict {
        
        string = string.stringByReplacingOccurrencesOfString("\(key)", withString: value)
        
    }
    
    return string
}

func stopSoundsOrSpeech() {
    
    if player.playing {
        
        player.stop()
        
    }
    
    if synthesizer.speaking {
        
        synthesizer.stopSpeakingAtBoundary(AVSpeechBoundary.Immediate)
    }
    
}

func checkDevice() {
    
    if SDiOSVersion.deviceVersion() == .iPadPro {

        circleWidth = 880
        
    } else {
        
        circleWidth = 660
    }
    
}

func markFeedbackGiven() {
    
    userDefaults.setBool(true, forKey: "FEEDBACK_GIVEN")
    userDefaults.synchronize()
    
    NSNotificationCenter.defaultCenter().postNotificationName("HideStarButton", object: nil)

}

class TextField: UITextField {
    
    override func canPerformAction(action: Selector, withSender sender: AnyObject?) -> Bool {
        
        UIMenuController.sharedMenuController().menuVisible = false
        
        print("performaction")
        if action == #selector(NSObject.paste(_:)) {
            print("no paste")
            return false
        }
        return super.canPerformAction(action, withSender:sender)
    }
}

func showPopTipOnceForKey(key: String, userDefaults: NSUserDefaults, popTipText text: String, inView view: UIView, fromFrame frame: CGRect, direction: AMPopTipDirection = .Down, color: UIColor = .darkGrayColor()) -> AMPopTip? {
    if (!userDefaults.boolForKey(key)) {
        userDefaults.setBool(true, forKey: key)
        userDefaults.synchronize()
        AMPopTip.appearance().popoverColor = color
        AMPopTip.appearance().offset = 10
        AMPopTip.appearance().edgeMargin = 5
        let popTip = AMPopTip()
        popTip.showText(text, direction: direction, maxWidth: 250, inView: view, fromFrame: frame)
        popTip.actionAnimation = AMPopTipActionAnimation.Bounce
        popTip.shouldDismissOnTapOutside = false
    
        return popTip
    }
    
    return nil
}

func screenShotMethod(view: UIView) -> UIImage {
    //Create the UIImage
    UIGraphicsBeginImageContextWithOptions(view.frame.size, true, 0.0)
    view.layer.renderInContext(UIGraphicsGetCurrentContext()!)
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return image
}

func removeAdsUpgradePurchased() -> Bool {
    
    guard keychainRemoveAdsString == removeAdsKeyValue else {
        return false
    }
    return true
}

func proFeaturesUpgradePurchased() -> Bool {
    
    guard keychainProVersionString == proVersionKeyValue else {
        return false
    }
    return true
}