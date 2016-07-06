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

func makeRoutineArray(_ routine: RoutineModel?) -> ([[String:AnyObject]], Int) {
    
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
                
                for number in 1...(exercise.exerciseNumberOfRounds as Int) {
                    
                    if exercise.exerciseTime as Int > 0 {
                        
                        //Exercise Name & Time
                        
                        customeExerciseDictionary["Name"] = exercise.exerciseName
                        
                        if exercise.exerciseNumberOfRounds as Int > 1 {
                            customeExerciseDictionary["Interval"] = "\(number) / \(exercise.exerciseNumberOfRounds)"
                        }
                        
                        customeExerciseDictionary["Time"] = exercise.exerciseTime
                        customeExerciseDictionary["Color"] = exercise.exerciseColor
                        
                        totalTime += customeExerciseDictionary["Time"] as! Int
                        
                        stagesArray.add(customeExerciseDictionary)
                    }
                }
            }
            
        } else if type == "Circuit" {
            
            warmUpExercise = routineExercises[0]
            roundExercise = routineExercises[1]
            restExercise = routineExercises[2]
            coolDownExercise = routineExercises[3]
            
            if warmUpExercise.exerciseTime as Int > 0 {
                
                //Warmup
                warmUpDictionary["Name"] = warmUpExercise.exerciseName
                warmUpDictionary["Time"] = warmUpExercise.exerciseTime
                warmUpDictionary["Color"] = warmUpExercise.exerciseColor
                
                totalTime += warmUpDictionary["Time"] as! Int
                
                stagesArray.add(warmUpDictionary)
                
            }
            
            for i in 1...Int(roundExercise.exerciseNumberOfRounds) {
                    
                if roundExercise.exerciseTime as Int > 0 {
                    
                    //Round Time
                    
                    roundDictionary["Name"] = roundExercise.exerciseName
                    
                    if roundExercise.exerciseNumberOfRounds as Int > 1 {
                        roundDictionary["Interval"] = "\(i) / \(roundExercise.exerciseNumberOfRounds)"
                    }
                    
                    roundDictionary["Time"] = roundExercise.exerciseTime
                    roundDictionary["Color"] = roundExercise.exerciseColor
                    
                    totalTime += roundDictionary["Time"] as! Int
                    
                    stagesArray.add(roundDictionary)
                    
                }
                
                if restExercise.exerciseTime as Int > 0 {
                    
                    //Rest Time
                    
                    restDictionary["Name"] = restExercise.exerciseName
                    
                    if restExercise.exerciseNumberOfRounds as Int > 1 {
                        restDictionary["Interval"] = "\(i) / \(restExercise.exerciseNumberOfRounds)"
                    }
                    restDictionary["Time"] = restExercise.exerciseTime
                    restDictionary["Color"] = restExercise.exerciseColor
                    
                    totalTime += restDictionary["Time"] as! Int
                    
                    stagesArray.add(restDictionary)
                    
                }
            }
            
            if coolDownExercise.exerciseTime as Int > 0 {
                
                // Cool Down Time
                coolDownDictionary["Name"] = coolDownExercise.exerciseName
                coolDownDictionary["Time"] = coolDownExercise.exerciseTime
                coolDownDictionary["Color"] = coolDownExercise.exerciseColor
                
                totalTime += coolDownDictionary["Time"] as! Int
                
                stagesArray.add(coolDownDictionary)
                
            }
        }
        
    } else {
        
        var quickTimerDictionary = [String:AnyObject]()
        
        // Quick Timer Time
        quickTimerDictionary["Name"] = NSLocalizedString("Quick Timer", comment: "")
        quickTimerDictionary["Time"] = QuickTimerTime
        quickTimerDictionary["Color"] = NSKeyedArchiver.archivedData(withRootObject: UIColor.orange())
        
        totalTime += quickTimerDictionary["Time"] as! Int
        
        stagesArray.add(quickTimerDictionary)
        
    }
    
    // print(stagesArray, totalTime)
    return (stagesArray as AnyObject as! [[String:AnyObject]], totalTime)
}

func setSelectedRoutine(_ routine: RoutineModel, completion: (result: Bool) -> Void) {
        
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
    
    let selectedRoutinePredicate: Predicate = Predicate(format: "selectedRoutine == true")
    
    do {
        
        let routineMarkedSelected = try DataAccess.sharedInstance.GetRoutines(selectedRoutinePredicate).first
        
        routineMarkedSelected?.selectedRoutine = false
        
        saveContext( { (save) -> Void in
            
            if save == true {
                
                UIApplication.shared().shortcutItems = nil
            }
        })
        
    } catch {
        // TO-DO: HANDLE ERROR
    }
}

func getRoutine(_ withName: String) -> RoutineModel? {
    
    let existingRoutinePredicate: Predicate = Predicate(format: "name == %@", withName)
        
    do {
        
        return try DataAccess.sharedInstance.GetRoutines(existingRoutinePredicate).first
        
    } catch {
        // TO-DO: HANDLE ERROR
        return nil
    }
}

func getSelectedRoutine() -> RoutineModel? {
    
    let selectedRoutinePredicate: Predicate = Predicate(format: "selectedRoutine == true")
    
    do {
        
        return try DataAccess.sharedInstance.GetRoutines(selectedRoutinePredicate).first
        
    } catch {
        // TO-DO: HANDLE ERROR
        return nil
    }
}

func saveContext(_ completion: (save: Bool) -> Void) {
    
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
        
        let type = Bundle.main.bundleIdentifier! + ".Dynamic"
        let shortcutIconType = UIApplicationShortcutIconType.play
        let icon = UIApplicationShortcutIcon(type: shortcutIconType)
        
        let dynamicShortcut = UIApplicationShortcutItem(type: type, localizedTitle: routine.name, localizedSubtitle: nil, icon: icon, userInfo: nil)
        UIApplication.shared().shortcutItems = [dynamicShortcut]
}

func xDaysFromNow (_ numberOfDays: Int) -> Date {
    
    var dayComponent: DateComponents = DateComponents()
    dayComponent.day = numberOfDays
    
    let calendar:Calendar = Calendar.current
    
    return calendar.date(byAdding: dayComponent, to: Date(), options: Calendar.Options(rawValue: 0))!
    
}

func isConnectedToNetwork() -> Bool {
    
    var zeroAddress = sockaddr_in()
    zeroAddress.sin_len = UInt8(sizeofValue(zeroAddress))
    zeroAddress.sin_family = sa_family_t(AF_INET)
    
    let defaultRouteReachability = withUnsafePointer(&zeroAddress) {
        SCNetworkReachabilityCreateWithAddress(nil, UnsafePointer($0))
    }
    var flags = SCNetworkReachabilityFlags.connectionAutomatic
    
    if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
        return false
    }
    
    let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
    let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
    return (isReachable && !needsConnection)
}

@available(iOS 9.0, *)
func addToSpotlight (_ title: String, contentDescription: String, uniqueIdentifier: String, domainIdentifier: String) {
    
    let attributeSet:CSSearchableItemAttributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeText as String)
    attributeSet.title = title
    attributeSet.contentDescription = contentDescription
    
    let searchableItem = CSSearchableItem(uniqueIdentifier: uniqueIdentifier, domainIdentifier: domainIdentifier, attributeSet: attributeSet)
    
    CSSearchableIndex.default().indexSearchableItems([searchableItem]) { (error) -> Void in
        
        if let error = error {
            print("Deindexing error: \(error.localizedDescription)")
        } else {
            print("Search item successfully indexed!")
        }
    }
    
}

@available(iOS 9.0, *)
func deleteFromSpotlight(_ uniqueIdentifier: String) {
    
    CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: [uniqueIdentifier]) { (error: NSError?) -> Void in
        
        if let error = error {
            print("Deindexing error: \(error.localizedDescription)")
        } else {
            print("Search item successfully removed!")
        }
    }
}

@available(iOS 9.0, *)
func sendContextToAppleWatch(_ context: AnyObject) {
    
    guard (WCSession.isSupported()) else { return }
    
    guard wcSession.isWatchAppInstalled else { return }
    
    // KEEP THOSE TWO GUARD STATEMENTS SEPARTED
    
    if !wcSession.isPaired {
        
        SweetAlert().showAlert(NSLocalizedString("Alert: WCSession Paired Error Title Text", comment: ""), subTitle: NSLocalizedString("Alert: WCSession Paired Error Subtitle Text", comment: ""), style: AlertStyle.warning, dismissTime: nil)
    }
    
    do {
        
        try wcSession.updateApplicationContext(context as! [String : AnyObject])
        
        print("Context sent")
        
    } catch let error as NSError {
        
        print("Updating the context failed: " + error.localizedDescription)
    }
}

func timeComponentsFrom(time: Int) -> (HoursLeft: Int, MinutesLeft: Int, SecondsLeft: Int) {
    
    let HoursLeft = time/3600
    let MinutesLeft = (time%3600)/60
    let SecondsLeft = (((time%3600)%60)%60)
    
    return (HoursLeft, MinutesLeft, SecondsLeft)
    
}

func timeComponentsFrom(string: String) -> (HoursLeft: Int, MinutesLeft: Int, SecondsLeft: Int) {
    
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

func timeStringFrom(time: Int, type: String) -> String {
    
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

func timeFromTimeComponents (hoursComponent:Int, minutesComponent:Int,secondsComponent:Int) -> Int {
    
    return (hoursComponent * 3600) + (minutesComponent * 60) + (secondsComponent)
    
}

func displayAlert(_ title: String, message: String, Action1:UIAlertAction?, Action2:UIAlertAction?) -> UIAlertController {
    
    let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
    
    if Action1 != nil {
        
        alert.addAction(Action1!)
    }
    
    if Action2 != nil {
        
        alert.addAction(Action2!)
    }
    
    return alert
}

func loadPlayer(_ sound: String, ext: String) {
    
    // Load Sound
    soundlocation = Bundle.main.urlForResource(sound, withExtension: ext)!
    
    do {
        
        // Play Sound
        player = try AVAudioPlayer(contentsOf: soundlocation as URL)
        player.volume = timerVolume
        player.play()
        
    } catch let error as NSError {
        
        print("Fetch failed: \(error.localizedDescription)")
    }
}

func textToSpeech(_ text: String) {
    
    let myUtterance = AVSpeechUtterance(string: decryptString(text, dict: decryptDictionary))
    myUtterance.rate = 0.3
    myUtterance.volume = timerVolume
    synthesizer.speak(myUtterance)
}

func decryptString (_ string: String, dict: Dictionary<String, String>) -> String {
    var string = string
    
    for (key, value) in dict {
        
        string = string.replacingOccurrences(of: "\(key)", with: value)
        
    }
    
    return string
}

func stopSoundsOrSpeech() {
    
    if player.isPlaying {
        
        player.stop()
        
    }
    
    if synthesizer.isSpeaking {
        
        synthesizer.stopSpeaking(at: AVSpeechBoundary.immediate)
    }
    
}

func checkDevice() {
    
    if SDiOSVersion.deviceVersion() == .iPadPro12Dot9Inch || SDiOSVersion.deviceVersion() == .iPadPro9Dot7Inch {

        circleWidth = 880
        
    } else {
        
        circleWidth = 660
    }
    
}

func markFeedbackGiven() {
    
    userDefaults.set(true, forKey: "FEEDBACK_GIVEN")
    
    NotificationCenter.default.post(name: Notification.Name(rawValue: "HideStarButton"), object: nil)

}

class TextField: UITextField {
    
    override func canPerformAction(_ action: Selector, withSender sender: AnyObject?) -> Bool {
        
        UIMenuController.shared().isMenuVisible = false
        
        print("performaction")
        if action == #selector(NSObject.paste(_:)) {
            print("no paste")
            return false
        }
        return super.canPerformAction(action, withSender:sender)
    }
}

func showPopTipOnceForKey(_ key: String, userDefaults: UserDefaults, popTipText text: String, inView view: UIView, fromFrame frame: CGRect, direction: AMPopTipDirection = .down, color: UIColor = .darkGray()) -> AMPopTip? {
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

func screenShotMethod(_ view: UIView) -> UIImage {
    //Create the UIImage
    UIGraphicsBeginImageContextWithOptions(view.frame.size, true, 0.0)
    view.layer.render(in: UIGraphicsGetCurrentContext()!)
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return image!
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
