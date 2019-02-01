//
//  InterfaceController.swift
//  Chronic WatchKit Extension
//
//  Created by Ahmed E on 21/02/15.
//  Copyright (c) 2015 Ace Green. All rights reserved.
//

import WatchKit
import Foundation
import ChronicKit
import HealthKit
import UserNotifications

class InterfaceController: WKInterfaceController, HKWorkoutSessionDelegate {

    var workout: Workout!
    
    var anchor = HKQueryAnchor(fromValue: Int(HKAnchoredObjectQueryNoAnchor))
    
    var time: Int = 0
    
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
        
        if workout.routineStages.count != 0 && !Constants.timer.isValid {
            
            if workout.workoutState == .preRun {
                
                Constants.currentDevice.play(.start)
                
                // Set routine start time
                workout.routineStartDate = Date()
                print("start time \(workout.routineStartDate)")
                
                // Start workout session
                Functions.startWorkSession(delegateInterfaceController: self, workoutActivityType: workout.workoutActivityType)
                
            } else {
                Functions.resumeWorkSession()
            }
            
            startTimer()
            workout.workoutState = Workout.WorkoutState.active
        }
    }
    
    @IBAction func PauseButtonPressed() {
        
        Constants.timer.invalidate()
        
        workout.workoutState = Workout.WorkoutState.paused
        
        Functions.pauseWorkSession()
    }
    
    @IBAction func StopButtonPressed() {
        
        if workout.workoutState == .active || workout.workoutState == .paused || workout.workoutState == .completed {
            
            // Set end time
            workout.routineEndDate = Date()
            print("end time \(workout.routineEndDate)")
            
            // Check to save workout
            checkSaveWorkout()
        }
        
        setToInitialState()
        changeStage()
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        if context is RoutineModel {
            self.workout = Workout(workoutActivityType: .crossTraining, workoutType: .routine, routineModel: context as! RoutineModel?)
        } else {
            self.workout = Workout(workoutActivityType: .crossTraining, workoutType: .quickTimer)
        }
        
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
    @objc func countDown() {
        
        time -= 1
        workout.timeRemaining -= 1
        workout.timeElapsed += 1
        
        changeLabels()
        
        if time < 4 && time > 0 {
            
            Constants.currentDevice.play(.click)
            
        } else if time <= 0 {
            
            // If the current timer ends
            
            if workout.routineIndex == workout.routineStages.count - 1 {
                
                completeWorkout()
                
            } else {
                
                workout.routineIndex += 1
                
                Constants.timer.invalidate()
                
                changeStage()
                
                //Let's go to next round, So increase these variables and start new timer
                Constants.currentDevice.play(.directionUp)
                
                startTimer()
                
            }
            
            return
        }
    }
    
    //Function to change the state of routine, based on the currentTimerDict Value
    func changeStage() {
        
        if workout.routineStages.count != 0 {
            
            workout.currentTimerDict = workout.routineStages[workout.routineIndex]
            
            time = workout.currentTimerDict["Time"] as! Int
            
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
        
        workout.routineIndex = 0
        workout.timeRemaining = workout.totalTime
        workout.timeElapsed = 0
    
        workout.workoutState = Workout.WorkoutState.preRun
        
        changeLabels()
    }
    
    func changeLabels() {
        
        //self.setTitle(routineName)
        RoutineStateLabel.setText(workout.currentTimerDict["Name"] as? String)
        CountDownLabel.setText(Functions.timeStringFrom(time: Int(time)))
        timeRemainingLabel.setText(Functions.timeStringFrom(time: Int(workout.timeRemaining)))
        timeElapsedLabel.setText(Functions.timeStringFrom(time: Int(workout.timeElapsed)))
    }
    
    func changeStageLabelColor() {
        
        var stageColor: UIColor!
    
        if let currentTimerDictColor = workout.currentTimerDict["Color"] as? Data {
            
            stageColor = (NSKeyedUnarchiver.unarchiveObject(with: currentTimerDictColor) as? UIColor)!
        }

        mainGroup.setBackgroundColor(stageColor)
        //RoutineStateLabel.setTextColor(stageColor ?? UIColor.white)
    }
    
    func completeWorkout() {
        
        // Mark routine as completed
        workout.workoutState = .completed
        
        // Congrats you've completed workout
        Constants.currentDevice.play(.success)
        
        // Set Alert if in background
        if WKExtension.shared().applicationState == WKApplicationState.background {
            
            var alertTitle: String!
            var alertBody: String!
            
            switch workout.workoutType {
            case .quickTimer:
                alertTitle = NSLocalizedString("Notification Timer Text", comment: "")
                alertBody = NSLocalizedString("Notification Timer subText", comment: "")
            case .routine, .run:
                alertTitle = NSLocalizedString("Notification Workout Text", comment: "")
                alertBody = NSLocalizedString("Notification Workout subText", comment: "")
            }
            
            // Schedule workoutComplete Notification
            let notificationContent = UNMutableNotificationContent()
            notificationContent.title = alertTitle
            notificationContent.body = alertBody
            let notificaitonSound = UNNotificationSound.default
            notificationContent.sound = notificaitonSound
            
            let request = UNNotificationRequest(identifier: Constants.NotificationCategory.WorkoutCategory.key(), content: notificationContent, trigger: nil)
            
            // Schedule the notification.
            let center = UNUserNotificationCenter.current()
            center.add(request) { (error) in
                if error != nil {
                    print("notification error:", error)
                }
            }
        }
        
        // Stop time, save workout & reset environment
        StopButtonPressed()
    }
    
    func checkSaveWorkout() {
    
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        guard HealthKitHelper.sharedInstance.workoutAuthorizationStatus != HKAuthorizationStatus.notDetermined else {
            
            // Request Authorization
            HealthKitHelper.sharedInstance.authorizeHealthKit { (success,  error) -> Void in
                if success {
                    Functions.saveWorkout(interfaceController: self, workoutActivityType: self.workout.workoutActivityType, startDate: self.workout.routineStartDate, endDate: self.workout.routineEndDate, kiloCalories: nil, distance: nil)
                }
            }
            
            return
        }
        
        guard HealthKitHelper.sharedInstance.workoutAuthorizationStatus != HKAuthorizationStatus.sharingDenied else {
            
            let okAction = WKAlertAction(title: NSLocalizedString("Ok", comment: ""), style: WKAlertActionStyle.default, handler: { })
            
            self.presentAlert(withTitle: "Alert: Authorize Chronic Save Workout Title Text", message: "Alert: Authorize Chronic Save Workout Subtitle Text", preferredStyle: WKAlertControllerStyle.actionSheet, actions: [okAction])
            
            return
        }
        
        if workout.workoutType == .routine {
            
            if workout.workoutState == .completed {
                Functions.saveWorkout(interfaceController: self, workoutActivityType: workout.workoutActivityType, startDate: workout.routineStartDate, endDate: workout.routineEndDate, kiloCalories: nil, distance: nil)
            } else {
                promptToSaveWorkout()
            }
            
        } else {
            promptToSaveWorkout()
        }
    }
    
    func promptToSaveWorkout() {
        
        let yesAction = WKAlertAction(title: NSLocalizedString("Yes", comment: ""), style: WKAlertActionStyle.default, handler: { () -> Void in
            
            Functions.saveWorkout(interfaceController: self, workoutActivityType: self.workout.workoutActivityType, startDate: self.workout.routineStartDate, endDate: self.workout.routineEndDate, kiloCalories: nil, distance: nil)
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
