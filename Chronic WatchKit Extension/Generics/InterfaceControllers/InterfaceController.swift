//
//  InterfaceController.swift
//  Boxer Timer WatchKit Extension
//
//  Created by Ahmed E on 21/02/15.
//  Copyright (c) 2015 Ace Green. All rights reserved.
//

import WatchKit
import Foundation
import HealthKit
import UserNotifications

class InterfaceController: WKInterfaceController, HKWorkoutSessionDelegate {
    
    var workoutType = Constants.WorkoutType.quickTimer
    var workoutState = Constants.WorkoutEventType.preRun
    
    let workoutActivityType: HKWorkoutActivityType = HKWorkoutActivityType.crossTraining
    var anchor = HKQueryAnchor(fromValue: Int(HKAnchoredObjectQueryNoAnchor))
    
    var routineArray = [[String:AnyObject]]()
    var currentTimerDict = [String:AnyObject]()
    var routineTotalTime = Int()
    var selectedRoutine: Any!
    var routineIndex: Int = 0
    
    var routineStartDate: Date!
    var routineEndDate: Date!
    
    var time: Int = 0
    var timeRemaining: Int = 0
    var timeElapsed: Int = 0
    
    var soundlocation = NSURL()
    var localNotification: UNNotification!
    
    var heartRateQuery: HKQuery?
    
    @IBOutlet var mainGroup: WKInterfaceGroup!
    @IBOutlet var countDownGroup: WKInterfaceGroup!
    @IBOutlet var heartRateGroup: WKInterfaceGroup!
    
    @IBOutlet var RoutineStateLabel: WKInterfaceLabel!

    @IBOutlet var CountDownLabel: WKInterfaceLabel!
    
    @IBOutlet var timeRemainingLabel: WKInterfaceLabel!
    
    @IBOutlet var timeElapsedLabel: WKInterfaceLabel!
    
    @IBOutlet var heart: WKInterfaceImage!
    @IBOutlet var heartRateLabel: WKInterfaceLabel!
    
    @IBAction func PlayButtonPressed() {
        
        if routineArray.count != 0 && !Constants.timer.isValid {
            
            if workoutState == .preRun {
                
                playFeedback("Routine Begin")
                
                // Set routine start time
                routineStartDate = Date()
                print("start time \(routineStartDate)")
                
                // Start workout session
                Functions.startWorkSession(delegateInterfaceController: self, workoutActivityType: self.workoutActivityType)
                
            } else {
                Functions.resumeWorkSession()
            }
            
            startTimer()
            workoutState = Constants.WorkoutEventType.active
        }
    }
    
    @IBAction func PauseButtonPressed() {
        
        Constants.timer.invalidate()
        
        workoutState = Constants.WorkoutEventType.pause
        
        Functions.pauseWorkSession()
    }
    
    @IBAction func StopButtonPressed() {
        
        // End workout session if running
        Functions.endWorkoutSession()
        
        if workoutState == .active || workoutState == .pause || workoutState == .complete {
            
            // Set end time
            routineEndDate = Date()
            print("end time \(routineEndDate)")
            
            // Check to save workout
            checkSaveWorkout()
        }
        
        setToInitialState()
        changeStage()
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        selectedRoutine = context
        
        if selectedRoutine is RoutineModel {
            
            workoutType = .routine
            
            (routineArray, routineTotalTime) = Functions.makeRoutineArray(routine: selectedRoutine as? RoutineModel)
            
        } else {
            
            workoutType = .quickTimer
            
            (routineArray, routineTotalTime) = Functions.makeRoutineArray(routine: nil)
        }
        
//        // MARK: Disable heart rate
//        if !Functions.isProFeaturesUpgradePurchased() {
//            hideHeartRateGroup()
//        }
        
        setToInitialState()
        changeStage()
    }
    
    deinit {
        
        // Set initial state
        setToInitialState()
        
        print("deinit")
    }
    
    //Function to start exercise timer
    func startTimer() {
        Constants.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(InterfaceController.countDown) , userInfo: nil, repeats: true)
    }
    
    //Timer Function
    func countDown() {
        
        time -= 1
        timeRemaining -= 1
        timeElapsed += 1
        
        changeLabels()
        
        if time < 4 && time > 0 {
            
            playFeedback("Tick")
            
        } else if time <= 0 {
            
            // If the current timer ends
            
            if routineIndex == routineArray.count - 1 {
                
                completeWorkout()
                
            } else {
                
                routineIndex += 1
                
                Constants.timer.invalidate()
                
                changeStage()
                
                //Let's go to next round, So increase these variables and start new timer
                playFeedback(currentTimerDict["Name"] as! String)
                
                startTimer()
                
            }
            
            return
        }
    }
    
    //Function to change the state of routine, based on the currentTimerDict Value
    func changeStage() {
        
        if routineArray.count != 0 {
            
            currentTimerDict = routineArray[routineIndex]
            
            time = currentTimerDict["Time"] as! Int
            
            changeLabels()
            changeStageLabelColor()
            
        }
    }
    
    //Function to set the view to initial stage
    func setToInitialState() {
    
        // Invalidate timer if running
        Constants.timer.invalidate()
        
        // End workout session if running
        Functions.endWorkoutSession()
        
        routineIndex = 0
        timeRemaining = routineTotalTime
        timeElapsed = 0
    
        workoutState = Constants.WorkoutEventType.preRun
        
        changeLabels()
    }
    
    func changeLabels() {
        
        //self.setTitle(routineName)
        RoutineStateLabel.setText(currentTimerDict["Name"] as? String)
        CountDownLabel.setText(Functions.timeStringFrom(time: Int(time)))
        timeRemainingLabel.setText(Functions.timeStringFrom(time: Int(timeRemaining)))
        timeElapsedLabel.setText(Functions.timeStringFrom(time: Int(timeElapsed)))
    }
    
    func changeStageLabelColor() {
        
        var stageColor: UIColor!
    
        if let currentTimerDictColor = currentTimerDict["Color"] as? Data {
            
            stageColor = (NSKeyedUnarchiver.unarchiveObject(with: currentTimerDictColor) as? UIColor)!
        }

        mainGroup.setBackgroundColor(stageColor)
        //RoutineStateLabel.setTextColor(stageColor ?? UIColor.white)
    }
    
    func playFeedback (_ type: String) {
        
        var hapticType: WKHapticType!
        
        switch type {
            
        case "Routine Begin":
            
            hapticType = WKHapticType.start
            
        case "Routine End":
            
            hapticType = WKHapticType.success
            
        case "Tick":
            
            hapticType = WKHapticType.click
            
        default:
            
            hapticType = WKHapticType.directionUp
            
        }
        
        WKInterfaceDevice.current().play(hapticType)
    }
    
    func completeWorkout() {
        
        // Mark routine as completed
        workoutState = Constants.WorkoutEventType.complete
        
        //Congrats you've completed workout
        playFeedback("Routine End")
        
        // Set Alert if in background
        if WKExtension.shared().applicationState == WKApplicationState.background {
            
            var alertTitle: String!
            var alertBody: String!
            
            switch workoutType {
            case .quickTimer:
                alertTitle = NSLocalizedString("Notification Timer Text", comment: "")
                alertBody = NSLocalizedString("Notification Timer subText", comment: "")
            case .routine, .run:
                alertTitle = NSLocalizedString("Notification Workout Text", comment: "")
                alertBody = NSLocalizedString("Notification Workout subText", comment: "")
            }
            
            // Schedule workoutCompleteLocalNotification
            let notificationContent = UNMutableNotificationContent()
            notificationContent.title = alertTitle
            notificationContent.body = alertBody
            let notificaitonSound = UNNotificationSound.default()
            notificationContent.sound = notificaitonSound
            
            let request = UNNotificationRequest(identifier: Constants.NotificationCategory.WorkoutCategory.key(), content: notificationContent, trigger: nil)
            
            // Schedule the notification.
            let center = UNUserNotificationCenter.current()
            center.add(request) { (error) in
                print(error)
            }
        }
        
        // Stop time, save workout & reset environment
        StopButtonPressed()
    }
    
    func checkSaveWorkout() {
    
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        if selectedRoutine is RoutineModel {
            
            if workoutState == .complete {
                Functions.saveWorkout(interfaceController: self, workoutActivityType: workoutActivityType, startDate: self.routineStartDate, endDate: self.routineEndDate, kiloCalories: nil, distance: nil)
            } else {
                promptToSaveWorkout()
            }
            
        } else {
            promptToSaveWorkout()
        }
    }
    
    func promptToSaveWorkout() {
        
        let yesAction = WKAlertAction(title: NSLocalizedString("Yes", comment: ""), style: WKAlertActionStyle.default, handler: { () -> Void in
            
            Functions.saveWorkout(interfaceController: self, workoutActivityType: self.workoutActivityType, startDate: self.routineStartDate, endDate: self.routineEndDate, kiloCalories: nil, distance: nil)
        })
        
        let noAction = WKAlertAction(title: NSLocalizedString("No", comment: ""), style: WKAlertActionStyle.default, handler: { })
        
        self.presentAlert(withTitle: NSLocalizedString("Alert: Save Workout Question Title Text", comment: ""), message: NSLocalizedString("Alert: Save Workout Question Subtitle Text", comment: ""), preferredStyle: WKAlertControllerStyle.actionSheet, actions: [yesAction, noAction])
    }
    
    // Heart rate stuff
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        switch toState {
        case .running:
            workoutDidStart(date)
        case .ended:
            workoutDidEnd(date)
        default:
            print("state \(toState.hashValue)")
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("workout session failed: \(error)")
    }
    
    func workoutDidStart(_ date : Date) {
        
        heartRateQuery = createHeartRateStreamingQuery()
        
        if let query = heartRateQuery {
             HealthKitHelper.sharedInstance.healthKitStore.execute(query)
        } else {
            heartRateLabel.setText("Cannot start")
        }
    }
    
    func workoutDidEnd(_ date : Date) {
        
        if let query = heartRateQuery {
            HealthKitHelper.sharedInstance.healthKitStore.stop(query)
            heartRateLabel.setText("---")
        } else {
            heartRateLabel.setText("Cannot stop")
        }
    }
    
    func createHeartRateStreamingQuery() -> HKQuery? {
        // adding predicate will not work
        // let predicate = HKQuery.predicateForSamplesWithStartDate(workoutStartDate, endDate: nil, options: HKQueryOptions.None)
        
        guard let quantityType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate) else { return nil }
        
        let heartRateQuery = HKAnchoredObjectQuery(type: quantityType, predicate: nil, anchor: anchor, limit: Int(HKObjectQueryNoLimit)) { (query, sampleObjects, deletedObjects, newAnchor, error) -> Void in
            guard let newAnchor = newAnchor else { return }
            self.anchor = newAnchor
            self.updateHeartRate(sampleObjects)
        }
        
        heartRateQuery.updateHandler = {(query, samples, deleteObjects, newAnchor, error) -> Void in
            self.anchor = newAnchor!
            self.updateHeartRate(samples)
        }
        return heartRateQuery
    }
    
    func updateHeartRate(_ samples: [HKSample]?) {
        guard let heartRateSamples = samples as? [HKQuantitySample] else {return}
        
        DispatchQueue.main.async {
            guard let sample = heartRateSamples.first else{return}
            let value = sample.quantity.doubleValue( for: HealthKitHelper.sharedInstance.heartRateUnit)
            self.heartRateLabel.setText(String(Int(value)))
            
            // retrieve source from sample
            //let name = sample.sourceRevision.source.name
            self.animateHeart()
        }
    }
    
    func animateHeart() {
        
        self.animate(withDuration: 0.5) {
            self.heart.setWidth(20)
            self.heart.setHeight(20)
        }
        
        let when = DispatchTime.now() + Double(Int64(0.5 * double_t(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        let queue = DispatchQueue.global(qos: .default)
        queue.asyncAfter(deadline: when, execute: {
            DispatchQueue.main.async(execute: {
                self.animate(withDuration: 0.5, animations: {
                    self.heart.setWidth(15)
                    self.heart.setHeight(15)
                })
            })
        })
    }
    
    func hideHeartRateGroup() {
        
        heartRateGroup.setHidden(true)
        heartRateGroup.setHeight(0)
    }
}
