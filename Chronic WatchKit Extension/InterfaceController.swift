//
//  InterfaceController.swift
//  Boxer Timer WatchKit Extension
//
//  Created by Ahmed E on 21/02/15.
//  Copyright (c) 2015 Ace Green. All rights reserved.
//

import UIKit
import WatchKit
import Foundation
import HealthKit

class InterfaceController: WKInterfaceController, HKWorkoutSessionDelegate {
    
    enum WorkoutEventType {
        case PreRun
        case Run
        case Pause
        case Complete
    }
    
    var workoutState = WorkoutEventType.Complete
    
    var countDownTimer = NSTimer()
    var timer: Int = 0
    
    var routineArray = [[String:AnyObject]]()
    var currentTimerDict = [String:AnyObject]()
    var routineTotalTime = Int()
    var selectedRoutine: AnyObject!
    var routineIndex: Int = 0
    
    var routineStartDate: NSDate!
    var routineEndDate: NSDate!
    
    var timeRemaining: Int = 0
    var timeElapsed: Int = 0
    
    var soundlocation = NSURL()
    var localNotification: UILocalNotification!
    
    let workoutAuthorizationStatus = HealthKitHelper.sharedInstance.healthKitStore.authorizationStatusForType(HealthKitHelper.sharedInstance.workoutType)
    var workoutSession: HKWorkoutSession!
    var workoutActivityType: HKWorkoutActivityType = HKWorkoutActivityType.CrossTraining
    var anchor = HKQueryAnchor(fromValue: Int(HKAnchoredObjectQueryNoAnchor))
    
    @IBOutlet var RoutineStateLabel: WKInterfaceLabel!
    
    @IBOutlet var countDownGroup: WKInterfaceGroup!
    @IBOutlet var CountDownLabel: WKInterfaceLabel!
    
    @IBOutlet var timeRemainingLabel: WKInterfaceLabel!
    
    @IBOutlet var timeElapsedLabel: WKInterfaceLabel!
    
    @IBOutlet var heartRateGroup: WKInterfaceGroup!
    @IBOutlet var heart: WKInterfaceImage!
    @IBOutlet var label: WKInterfaceLabel!
    
    @IBAction func PlayButtonPressed() {
        
        if routineArray.count != 0 && !countDownTimer.valid {
            
            if workoutState == .PreRun {
                
                playFeedback("Routine Begin")
                
                // Set routine start time
                routineStartDate = NSDate()
                print("start time \(routineStartDate)")
                
                // Start workout session
                startWorkSession()
                
            }
            
            startTimer()
            workoutState = WorkoutEventType.Run
        }
    }
    
    @IBAction func PauseButtonPressed() {
        
        countDownTimer.invalidate()
        
        workoutState = WorkoutEventType.Pause
    }
    
    @IBAction func StopButtonPressed() {
        
        if workoutState == .Run || workoutState == .Pause || workoutState == .Complete {

            // Set end time
            routineEndDate = NSDate()
            print("end time \(routineEndDate)")
            
            // End workout session if running
            endWorkoutSession()
            
        }
        
        if workoutState == .Run || workoutState == .Pause || workoutState == .Complete {
            checkSaveWorkout()
        }
        
        setToInitialState()
        changeStage()
    }
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        selectedRoutine = context
        
        if selectedRoutine.isKindOfClass(RoutineModel) {
            
            (routineArray, routineTotalTime) = makeRoutineArray(selectedRoutine as? RoutineModel)
            
        } else {
            
            (routineArray, routineTotalTime) = makeRoutineArray(nil)
        }
        
        if !proFeaturesUpgradePurchased() {
            
            hideHeartRateGroup()
        }
        
        setToInitialState()
        changeStage()
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        if workoutState == WorkoutEventType.Run {
            checkRoutineProgress(routineStartDate)
        }
    }
    
    deinit {
    
        print("deinit")
        
        // End workout session if running
        endWorkoutSession()
    }
    
    //Function to start exercise time
    func startTimer() {
        
        countDownTimer.invalidate()
        
        if !countDownTimer.valid {
            
            countDownTimer = NSTimer .scheduledTimerWithTimeInterval(1, target: self, selector: #selector(InterfaceController.countDown) , userInfo: nil, repeats: true)
            
        }
        
    }
    
    //Timer Function
    func countDown() {
        
        timer -= 1
        timeRemaining -= 1
        timeElapsed += 1
        
        changeLabels()
        
        if timer < 4 && timer > 0 {
            
            playFeedback("Tick")
            
        } else if timer <= 0 {
            
            // If the current timer ends
            
            if routineIndex == routineArray.count - 1 {
                
                completeWorkout()
                
            } else {
                
                routineIndex += 1
                
                countDownTimer.invalidate()
                
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
            
            timer = currentTimerDict["Time"] as! Int
            
            changeLabels()
            changeStageLabelColor()
            
        }
        
        //To enable buttons
        if routineIndex > 0 {
            
            //PreviousButton.enabled = true
            
        }
        
        if routineIndex < routineArray.count {
            
            //NextButton.enabled = true
            
        }
        
    }
    
    //Function to set the view to initial stage
    func setToInitialState() {
    
        countDownTimer.invalidate()
        
        routineIndex = 0
        timeRemaining = routineTotalTime
        timeElapsed = 0
    
        workoutState = WorkoutEventType.PreRun
        
    }
    
    func checkRoutineProgress(dateSinceStart: NSDate) {
        
        print("checking routine status")
        
        let timeElapsedSinceRoutineStart = -Int((dateSinceStart.timeIntervalSinceNow))
        var totalStageTime = 0
        
        if timeElapsedSinceRoutineStart < routineTotalTime {
            
            for (index, _) in routineArray.enumerate() {
                
                currentTimerDict = routineArray[index]
                totalStageTime += currentTimerDict["Time"] as! Int
                
                if timeElapsedSinceRoutineStart > totalStageTime {
                    
                    print("timeElapsedSinceRoutineStart is past \(currentTimerDict)")
                    
                    timer = 0
                    
                } else {
                    
                    timer = Int(totalStageTime - timeElapsedSinceRoutineStart)
                    timeRemaining = routineTotalTime - timeElapsedSinceRoutineStart
                    timeElapsed = timeElapsedSinceRoutineStart
                    routineIndex = index
                    
                    print(timer)
                    print(timeRemaining)
                    print(timeElapsed)
                    
                    changeLabels()
                    changeStageLabelColor()
                    
                    startTimer()
                    
                    break
                }
            }
            
        } else {
            completeWorkoutInBackground()
        }
    }
    
    func changeLabels() {
        
        //self.setTitle(routineName)
        RoutineStateLabel.setText(currentTimerDict["Name"] as? String)
        CountDownLabel.setText(timeStringFrom(time: Int(timer)))
        timeRemainingLabel.setText(timeStringFrom(time: Int(timeRemaining)))
        timeElapsedLabel.setText(timeStringFrom(time: Int(timeElapsed)))
        
    }
    
    func changeStageLabelColor() {
        
        var stageColor: UIColor!
    
        if let currentTimerDictColor = currentTimerDict["Color"] as? NSData {
            
            stageColor = (NSKeyedUnarchiver.unarchiveObjectWithData(currentTimerDictColor) as? UIColor)!
        }

        RoutineStateLabel.setTextColor(stageColor ?? UIColor.greenColor())
    }
    
    func playFeedback (type: String) {
        
        var hapticType: WKHapticType!
        
        switch type {
            
        case "Routine Begin":
            
            hapticType = WKHapticType.Start
            
        case "Routine End":
            
            hapticType = WKHapticType.Success
            
        case "Tick":
            
            hapticType = WKHapticType.Click
            
        default:
            
            hapticType = WKHapticType.DirectionUp
            
        }
        
        WKInterfaceDevice.currentDevice().playHaptic(hapticType)
    }
    
    func completeWorkout() {
        
        // Mark routine as completed
        workoutState = WorkoutEventType.Complete
        
        //Congrats you've completed workout
        playFeedback("Routine End")
        
        // Stop time, save workout & reset environment
        StopButtonPressed()
    }
    
    func completeWorkoutInBackground() {
        
        // Mark routine as completed
        workoutState = WorkoutEventType.Complete
        
        //Congrats you've completed workout
        playFeedback("Routine End")
        
        // Setup environment
        if workoutState == .Run || workoutState == .Pause || workoutState == .Complete {
            
            // Set end time
            routineEndDate = routineStartDate.dateByAddingTimeInterval(NSTimeInterval(routineTotalTime))
            print("end time \(routineEndDate)")
            
        }
        
        if workoutState != .PreRun {
            checkSaveWorkout()
        }
        
        // End workout session if running
        endWorkoutSession()
        
        setToInitialState()
        changeStage()
    }
    
    func checkSaveWorkout() {
    
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        if selectedRoutine.isKindOfClass(RoutineModel) {
            
            if workoutState == .Complete {
                
                saveWorkout()
                
            } else {
                promptToSaveWorkout()
            }
            
        } else {
            promptToSaveWorkout()
        }
    }
    
    func promptToSaveWorkout() {
        
        let yesAction = WKAlertAction(title: NSLocalizedString("Yes", comment: ""), style: WKAlertActionStyle.Default, handler: { () -> Void in
            
            self.saveWorkout()
            
        })
        
        let noAction = WKAlertAction(title: NSLocalizedString("No", comment: ""), style: WKAlertActionStyle.Default, handler: { })
        
        self.presentAlertControllerWithTitle(NSLocalizedString("Alert: Save Workout Question Title Text", comment: ""), message: NSLocalizedString("Alert: Save Workout Question Subtitle Text", comment: ""), preferredStyle: WKAlertControllerStyle.ActionSheet, actions: [yesAction, noAction])
    }
    
    func saveWorkout() {
        
        guard workoutAuthorizationStatus != HKAuthorizationStatus.NotDetermined else {
            
            // Request Authorization
            HealthKitHelper.sharedInstance.authorizeHealthKit { (success,  error) -> Void in
                
                if success {
                    
                    self.saveWorkout()
                }
            }
            
            return
        }
        
        guard workoutAuthorizationStatus != HKAuthorizationStatus.SharingDenied else {
            
            let okAction = WKAlertAction(title: NSLocalizedString("Ok", comment: ""), style: WKAlertActionStyle.Default, handler: { })
            
            self.presentAlertControllerWithTitle("Alert: Authorize Chronic Save Workout Title Text", message: "Alert: Authorize Chronic Save Workout Subtitle Text", preferredStyle: WKAlertControllerStyle.ActionSheet, actions: [okAction])
            
            return
        }
        
        guard self.routineStartDate != nil && self.routineEndDate != nil else { return }
        
        // Add workout to HealthKit if available
        HealthKitHelper.sharedInstance.saveRunningWorkout(self.workoutActivityType, startDate: self.routineStartDate, endDate: self.routineEndDate, kiloCalories: nil, distance: nil, completion: { (success, error) -> Void in
            
            if success {
                
                print("Workout saved!")
                
            } else if error != nil {
                
                print("\(error)")
            }
            
            return
        })
    }
    
    func startWorkSession() {
        
        guard workoutSession == nil else { return }
        
        // Start HKWorkoutSession
        workoutSession = HKWorkoutSession(activityType: workoutActivityType, locationType: HKWorkoutSessionLocationType.Unknown)
        workoutSession.delegate = self
        
        guard workoutSession.state == .NotStarted else { return }
        HealthKitHelper.sharedInstance.healthKitStore.startWorkoutSession(workoutSession)
        
        print("Workout session started")
    }
    
    func endWorkoutSession() {
        
        guard workoutSession != nil else { return }
        guard workoutSession.state == .Running else { return }
        
        HealthKitHelper.sharedInstance.healthKitStore.endWorkoutSession(workoutSession)
        
        workoutSession.delegate = nil
        workoutSession = nil
        
        print("Workout session ended")
    }
    
    // Heart rate stuff
    
    func displayNotAllowed() {
        label.setText("Not allowed")
    }
    
    func workoutSession(workoutSession: HKWorkoutSession, didChangeToState toState: HKWorkoutSessionState, fromState: HKWorkoutSessionState, date: NSDate) {
        switch toState {
        case .Running:
            workoutDidStart(date)
        case .Ended:
            workoutDidEnd(date)
        default:
            print("Unexpected state \(toState)")
        }
    }
    
    func workoutSession(workoutSession: HKWorkoutSession, didFailWithError error: NSError) {
        
        print("workout session failed: \(error)")
    }
    
    func workoutDidStart(date : NSDate) {
        
        guard selectedRoutine.isKindOfClass(RoutineModel) else { return }
        
        if let query = createHeartRateStreamingQuery() {
             HealthKitHelper.sharedInstance.healthKitStore.executeQuery(query)
        } else {
            label.setText("Cannot start")
        }
    }
    
    func workoutDidEnd(date : NSDate) {
        
        guard selectedRoutine.isKindOfClass(RoutineModel) else { return }
        
        if let query = createHeartRateStreamingQuery() {
             HealthKitHelper.sharedInstance.healthKitStore.stopQuery(query)
            label.setText("---")
        } else {
            label.setText("Cannot stop")
        }
    }
    
    func createHeartRateStreamingQuery() -> HKQuery? {
        // adding predicate will not work
        // let predicate = HKQuery.predicateForSamplesWithStartDate(workoutStartDate, endDate: nil, options: HKQueryOptions.None)
        
        guard let quantityType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate) else { return nil }
        
        let heartRateQuery = HKAnchoredObjectQuery(type: quantityType, predicate: nil, anchor: anchor, limit: Int(HKObjectQueryNoLimit)) { (query, sampleObjects, deletedObjects, newAnchor, error) -> Void in
            guard let newAnchor = newAnchor else {return}
            self.anchor = newAnchor
            self.updateHeartRate(sampleObjects)
        }
        
        heartRateQuery.updateHandler = {(query, samples, deleteObjects, newAnchor, error) -> Void in
            self.anchor = newAnchor!
            self.updateHeartRate(samples)
        }
        return heartRateQuery
    }
    
    func updateHeartRate(samples: [HKSample]?) {
        guard let heartRateSamples = samples as? [HKQuantitySample] else {return}
        
        dispatch_async(dispatch_get_main_queue()) {
            guard let sample = heartRateSamples.first else{return}
            let value = sample.quantity.doubleValueForUnit( HealthKitHelper.sharedInstance.heartRateUnit)
            self.label.setText(String(UInt16(value)))
            
            // retrieve source from sample
            //let name = sample.sourceRevision.source.name
            self.animateHeart()
        }
    }
    
    func animateHeart() {
        
        self.animateWithDuration(0.5) {
            self.heart.setWidth(20)
            self.heart.setHeight(20)
        }
        
        let when = dispatch_time(DISPATCH_TIME_NOW, Int64(0.5 * double_t(NSEC_PER_SEC)))
        let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
        dispatch_after(when, queue) {
            dispatch_async(dispatch_get_main_queue(), {
                self.animateWithDuration(0.5, animations: {
                    self.heart.setWidth(15)
                    self.heart.setHeight(15)
                })
            })
        }
    }
    
    func hideHeartRateGroup() {
        
        heartRateGroup.setHidden(true)
        heartRateGroup.setHeight(0)
    }
}
