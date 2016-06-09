//
//  MainViewController.swift
//  Chronic
//
//  Created by Ahmed E on 08/02/15.
//  Copyright (c) 2015 Ace Green. All rights reserved.
//

import UIKit
import QuartzCore
import CoreFoundation
import CoreGraphics
import MapKit
import iAd
import HealthKit
import CNPPopupController
import Parse
import Fabric
import Crashlytics
import MoPub
import SDVersion
import AMPopTip
import LaunchKit
import Spring
import ChameleonFramework
import BubbleTransition
import PureLayout

class TimerViewController: UIViewController, UIPopoverControllerDelegate, UIPopoverPresentationControllerDelegate, CNPPopupControllerDelegate {
    
    enum WorkoutType {
        case Routine
        case Run
        case QuickTimer
    }

    enum WorkoutEventType {
        case PreRun
        case Active
        case Paused
        case Completed
    }
    
    enum ButtonState {
        case Play
        case Pause
        case Initial
        case Unlocked
        case Locked
    }

    var workoutType = WorkoutType.QuickTimer
    var workoutState = WorkoutEventType.PreRun
    var buttonState = ButtonState.Initial

    var workoutActivityType: HKWorkoutActivityType = HKWorkoutActivityType.CrossTraining
    
    var timer = NSTimer()
    var time: Int = 0
    var distance: Double = 0.0
    
    var timeRemaining: Int = 0
    var timeElapsed: Int = 0
    var preRoutineCountDownTime: Int = 3
    
//    var ProgressbarContainer: UIView = UIView()
//    var ProgressCircle = CAShapeLayer()
//    var WhiteCircle = CAShapeLayer()
//    var circleLineWidth: CGFloat = 20
    
    var routine: RoutineModel?
    var routineStages = [[String:AnyObject]]()
    var routineTotalTime = Int()
    var currentTimerDict = [String:AnyObject]()
    
    var routineIndex: Int = 0
    var routineStartDate: NSDate!
    var routineEndDate: NSDate!

    // var adView: MPAdView = MPAdView(adUnitId: "fbfd798cc29d4a3a819108bc7e735c5c", size: MOPUB_BANNER_SIZE)

    lazy var mapView: MKMapView = {
        
        var mapView = MKMapView()
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.mapType = MKMapType(rawValue: 0)!
        mapView.userTrackingMode = MKUserTrackingMode(rawValue: 2)!
        
        return mapView
    }()
    
    lazy var locations = [CLLocation]()
    
    lazy var locationManager: CLLocationManager = {
        var locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.activityType = .Fitness
        
        // Movement threshold for new events
        locationManager.distanceFilter = 5.0
        return locationManager
    }()
    
    var threeMinuteCounterLabel: UILabel!
    var threeMinuteCounterVisualEffectView: UIVisualEffectView!
    let transition = BubbleTransition()
    
    var adBannerView: CustomAdView!
    var mopubBanner: MPAdView!
    var mopubInterstitial: MPInterstitialAdController!
    
    @IBOutlet var mainStackViewTopConstraint: NSLayoutConstraint!
    
    @IBOutlet var topStackView: UIStackView!
    
    @IBOutlet var middleStackView: UIStackView!
    
    @IBOutlet var bottomStackView: UIStackView!
    
    @IBOutlet var ProgressView: UIView!
    
    @IBOutlet var RoutineStateLabel: UILabel!
    
    @IBOutlet var intervalLabel: UILabel!
    
    @IBOutlet var CountDownLabel: UILabel!
    
    // @IBOutlet var rewardsButton: SpringButton!
    
    @IBOutlet var leftSideLabel: UILabel!
    @IBOutlet var leftSideLabel2: UILabel!
    
    @IBOutlet var rightSideLabel: UILabel!
    @IBOutlet var rightSideLabel2: UILabel!
    
    @IBOutlet var stopButton: UIButton!
    @IBOutlet var previousButton: UIButton!
    @IBOutlet var playPauseButton: UIButton!
    @IBOutlet var forwardButton: UIButton!
    @IBOutlet var lockUnlockButton: UIButton!
    
    // MARK: - Button Actions
    
    @IBAction func previousButtonPressed(sender: UIButton) {
        
        guard (routineStages.get(routineIndex - 1) != nil) else { return }
        
        if timer.valid {
            self.pause()
        }
        
        routineIndex -= 1
        
        changeStage()
    }
    
    @IBAction func forwardButtonPressed(sender: UIButton) {
        
        guard (routineStages.get(routineIndex + 1) != nil) else { return }
        
        if timer.valid {
            self.pause()
        }
        
        routineIndex += 1
        
        changeStage()
    }
    
    //Button Action for playing routine button
    @IBAction func playPausebarButtonItemPressed(sender: UIButton) {
        
        print(workoutState)
        
        if workoutType != .Run && routineTotalTime == 0 {
            return
        } else {
            if workoutState == .PreRun || workoutState == .Paused {
                self.play()
            } else {
                self.pause()
            }
        }
    }
    
    @IBAction func lockUnlockButtonPressed(sender: UIButton) {

        if buttonState == .Locked {
            self.unlock()
        } else {
            self.lock()
        }
    }
    
    func lock() {
        buttonState = .Locked
        switchButtonState()
    }
    
    func unlock() {
        buttonState = .Unlocked
        switchButtonState()
    }
    
    func play() {
        
        if !isConnectedToNetwork() && !removeAdsUpgradePurchased() {
            
            SweetAlert().showAlert(NSLocalizedString("Alert: No Internet Connection Title Text", comment: ""), subTitle: NSLocalizedString("Alert: No Internet Connection Subtitle Text", comment: ""), style: AlertStyle.Warning)
            
        } else {
            
            if workoutState == .PreRun {
                startCountDown()
            } else {
                startWorkout()
            }
        }
    }
    
    func pause() {
        
        timer.invalidate()
    
        workoutState = .Paused
        buttonState = .Pause
        switchButtonState()
    }
    
    func stop() {
        
        timer.invalidate()
        
        // Set end time
        routineEndDate = NSDate()
        print("end time \(routineEndDate)")
        
        // Complete workout if .Run 
        if workoutType == .Run {
            workoutState = WorkoutEventType.Completed
        }
            
        // Set Alert if in background
        var message: String!
        
        if UIApplication.sharedApplication().applicationState == UIApplicationState.Background {
            
            if workoutType != .QuickTimer {
                
                if workoutType == .Routine {
                    
                    message = NSLocalizedString("Congratulation Text (Routine)", comment: "")
                    
                } else if workoutType == .Run {
                    
                    message = NSLocalizedString("Congratulation Text (Run)", comment: "")
                }
                
            } else {
                
                message = NSLocalizedString("Timer Ended Text", comment: "")
            }
            
            // Schedule workoutCompleteLocalNotification
            NotificationHelper.scheduleNotification(nil, repeatInterval: nil, alertTitle: appTitle, alertBody: message, sound: "Boxing.wav", category: NotificationCategory.WorkoutCategory.key())
        }
        
        // Save workout
        checkSaveWorkout { (complete) in
        }
        
        // Reset settings to initial state (Just for tidiness)
        switch workoutType {
        case .QuickTimer:
            self.initializeQuickTimer()
        case .Routine:
            self.initializeRoutine(with: routine)
        case .Run:
            self.initializeRunner()
        }
    }
    
    // MARK: - View Life Cycle
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Adjust font greater than 300 limitation from Storyboard
        self.CountDownLabel.font = CountDownLabel.font.fontWithSize(1000)
        
        // check if you should display ads
        self.displayBannerAds()
    }
    
    override func willRotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        guard let ad = mopubBanner where ad.isDescendantOfView(self.adBannerView) else { return }
        self.mopubBanner.rotateToOrientation(toInterfaceOrientation)
    }
    
    override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        centerMoPubBannerAd(mopubBanner, relativeToView: self.adBannerView)

    }

//    func LayoutProgressBarSubview() {
//        
//        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
//            
//            ProgressbarContainer.frame = CGRect(x: (self.view.center.x - (circleWidth / 2)), y: (self.view.center.y - (circleWidth / 2)), width: circleWidth, height: circleWidth)
//            self.view.addSubview(ProgressbarContainer)
//            
//            WhiteCircle.strokeColor = UIColor.whiteColor().CGColor
//            WhiteCircle.fillColor = UIColor.clearColor().CGColor
//            WhiteCircle.lineWidth = circleLineWidth
//            
//            ProgressCircle.fillColor = UIColor.clearColor().CGColor
//            ProgressCircle.lineWidth = circleLineWidth
//            
//            let CenterPoint = CGPoint (x: ProgressbarContainer.bounds.width / 2, y: ProgressbarContainer.bounds.height / 2)
//            let CircleRadius = (circleWidth / 2 -  WhiteCircle.lineWidth / 2)
//            let CirclePath = UIBezierPath(arcCenter: CenterPoint, radius: CircleRadius, startAngle: CGFloat(-0.5 * M_PI), endAngle: CGFloat(1.5 * M_PI), clockwise: true)
//            
//            WhiteCircle.path = CirclePath.CGPath
//            ProgressCircle.path = CirclePath.CGPath
//            
//            ProgressbarContainer.layoutIfNeeded()
//            
//            ProgressbarContainer.layer.addSublayer(WhiteCircle)
//            ProgressbarContainer.layer.addSublayer(ProgressCircle)
//            
//            // println("LayoutProgressBarSubview done")
//            
//        }
//    }
    
    func LayoutBurSubview() {
        
        threeMinuteCounterLabel = UILabel()
        threeMinuteCounterVisualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .ExtraLight)) as UIVisualEffectView
        
        self.view.addSubview(threeMinuteCounterVisualEffectView)
        threeMinuteCounterVisualEffectView.translatesAutoresizingMaskIntoConstraints = false
        threeMinuteCounterVisualEffectView.autoPinEdgesToSuperviewEdges()
        
        threeMinuteCounterLabel.frame = CGRect(x: (threeMinuteCounterVisualEffectView.frame.width / 2) - 100, y: (threeMinuteCounterVisualEffectView.frame.height / 2) - 100, width: 200, height: 200)
        threeMinuteCounterLabel.text = String(preRoutineCountDownTime)
        threeMinuteCounterLabel.textColor = UIColor.whiteColor()
        threeMinuteCounterLabel.font = UIFont(name: threeMinuteCounterLabel.font.fontName, size: 200)
        threeMinuteCounterLabel.textAlignment = NSTextAlignment.Center
        threeMinuteCounterVisualEffectView.addSubview(threeMinuteCounterLabel)
        threeMinuteCounterLabel.translatesAutoresizingMaskIntoConstraints = false
        threeMinuteCounterLabel.autoCenterInSuperview()
    }
    
    func LayoutMapView() {
        self.ProgressView.addSubview(mapView)
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.autoPinEdgesToSuperviewEdges()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //Function to start exercise time
    func startTimer(selector: String) {
        
        timer.invalidate()
        
        if !timer.valid {
            timer = NSTimer .scheduledTimerWithTimeInterval(1, target: self, selector: Selector(selector) , userInfo: nil, repeats: true)
        }
    }
    
    //Timer Function
    func counter() {
        
        if workoutType == .Routine || workoutType == .QuickTimer {
            
            time -= 1
            timeRemaining -= 1
            timeElapsed += 1
            
            changeLabels()
            
            if time < 4 && time > 0 {
                
                playSound("Tick")
                
            } else  if time <= 0 {
                
                // If timer == 0, stage is over
                
                if routineIndex == routineStages.count - 1 {
                    
                    // Play Sound
                    playSound("Routine End")
                    
                    // Mark routine as completed
                    workoutState = WorkoutEventType.Completed
                    
                    // Stop Timer
                    self.stop()
                    
                    // Ask for feedback or show ad
                    if SARate.sharedInstance().eventCount >= SARate.sharedInstance().eventsUntilPrompt && userDefaults.boolForKey("FEEDBACK_GIVEN") == false {
                        
                        self.performSegueWithIdentifier("FeedbackSegueIdentifier", sender: self)
                        
                    } else {

                        self.displayInterstitialAds()
                    }
                    
                } else {
                    
                    routineIndex += 1
                    
                    changeStage()
                    playSound(currentTimerDict["Name"] as! String!)
                    
                    startTimer("counter")
                    
                }
                
                return
            }
            
        } else if workoutType == .Run {
            
            timeElapsed += 1
            changeLabels()
        }
        
    }
    
    func countDown3Seconds() {
            
        playSound("Tick")
    
        preRoutineCountDownTime -= 1
        
        if preRoutineCountDownTime < 4 && preRoutineCountDownTime > 0 {
            
            threeMinuteCounterLabel.text = String(preRoutineCountDownTime)
            
        } else if preRoutineCountDownTime == 0 {
            
            timer.invalidate()
    
            if self.threeMinuteCounterVisualEffectView.isDescendantOfView(self.view) {
                
                threeMinuteCounterVisualEffectView.removeFromSuperview()
                
            }
            
            startWorkout()
            
            return
        }
    }
    
    func startLocationUpdates() {
        
        let status = CLLocationManager.authorizationStatus()
        
        if status == .AuthorizedAlways || status == .AuthorizedWhenInUse {
            
            locationManager.startUpdatingLocation()
            
        } else {
            
            SweetAlert().showAlert(NSLocalizedString("Alert: Location Authorization Title Text", comment: ""), subTitle: NSLocalizedString("Alert: Location Authorization Subtitle Text", comment: ""), style: AlertStyle.Warning)
        }
    }
    
    func initializeQuickTimer() {
        
        timer.invalidate()
        
        workoutType = WorkoutType.QuickTimer
        
        (routineStages, routineTotalTime) = makeRoutineArray(nil)
        
        switchAppState()
    }
    
    func initializeRoutine(with routine: RoutineModel?) {
    
        timer.invalidate()
        
        workoutType = WorkoutType.Routine
        
        (routineStages, routineTotalTime) = makeRoutineArray(routine)
        self.routine = routine
        
        switchAppState()
    }
    
    func initializeRunner() {
        
        timer.invalidate()
        
        workoutType = WorkoutType.Run
        routineStages = [[String:AnyObject]]()
        currentTimerDict = [String:AnyObject]()
        
        locationManager.requestWhenInUseAuthorization()
        
        switchAppState()
    }
    
    //Function to set the view to initial stage
    func setToInitialState() {
        
        routineIndex = 0
        timeRemaining = routineTotalTime ?? 0
        timeElapsed = 0
        distance = 0
        time = 0
        preRoutineCountDownTime = 3
        
//        ProgressCircle.strokeEnd = 0
        
        locations.removeAll(keepCapacity: false)
        
        if mapView.isDescendantOfView(self.view) {
            
            let pointsArray = mapView.overlays
            mapView.removeOverlays(pointsArray)
        }
    
        workoutState = WorkoutEventType.PreRun
        buttonState = ButtonState.Initial
    }

    //Function to change the state of routine, based on the currentTimerDict Value
    func changeStage() {
        
        if routineStages.get(routineIndex) != nil {
            
            currentTimerDict = routineStages[routineIndex]
            time = currentTimerDict["Time"] as! Int
            timeRemaining = calculateTimeRemaining()
        }
        
        changeLabels()
        changeProgressBarAndStageLabelColor()
        switchButtonState()
    }
    
    func changeLabels() {
        
        if workoutType == .Routine || workoutType == .QuickTimer {
            
            //RoutineButton.setTitle(routineName, forState: .Normal)
            
            RoutineStateLabel.text = currentTimerDict["Name"] as? String
            intervalLabel.text = currentTimerDict["Interval"] as? String
            CountDownLabel.text = timeStringFrom(time:Int(time), type: "Routine")
            rightSideLabel2.text = timeStringFrom(time:timeRemaining, type: "Routine")
            leftSideLabel2.text = timeStringFrom(time:timeElapsed, type: "Routine")
            
        } else if workoutType == .Run {
            
            //RoutineButton.setTitle(appTitle, forState: .Normal)
            leftSideLabel2.text = timeStringFrom(time: Int(timeElapsed), type: "Routine")
            
            let distanceFormatter = MKDistanceFormatter()
            distanceFormatter.units = MKDistanceFormatterUnits.Metric
            distanceFormatter.unitStyle = MKDistanceFormatterUnitStyle.Default
            
            rightSideLabel2.text = distanceFormatter.stringFromDistance(distance)
            
            //        let paceUnit = HKUnit.secondUnit().unitDividedByUnit(HKUnit.meterUnit())
            //        let paceQuantity = HKQuantity(unit: paceUnit, doubleValue: time / distance)
            //        paceLabel.text = "Pace: " + paceQuantity.description
        }
    }
    
    func changeProgressBarAndStageLabelColor() {
        
        var stageColor: UIColor!
        
        if let currentTimerDictColor = currentTimerDict["Color"] as? NSData {
            
            stageColor = (NSKeyedUnarchiver.unarchiveObjectWithData(currentTimerDictColor) as? UIColor)!
            self.ProgressView.backgroundColor = stageColor.flatten()
            RoutineStateLabel.textColor = stageColor
            print(stageColor)
        }
    }
    
    func switchAppState() {
    
        setToInitialState()
        
        switch workoutType {
            
        case .QuickTimer, .Routine:
        
            workoutActivityType = HKWorkoutActivityType.CrossTraining
            
            CountDownLabel.hidden = false
            
            if mapView.isDescendantOfView(self.ProgressView) {
                
                mapView.removeFromSuperview()
            }
            
//            ProgressBarView.hidden = false
//            ProgressbarContainer.hidden = false
            RoutineStateLabel.hidden = false
            intervalLabel.hidden = false
            
            leftSideLabel.text = NSLocalizedString("Left Side Label Text (Routine)", comment: "")
            rightSideLabel.text = NSLocalizedString("Right Side Label Text (Routine)", comment: "")
            
        case .Run:
        
            workoutActivityType = HKWorkoutActivityType.Running
            CountDownLabel.hidden = true
            
            if !mapView.isDescendantOfView(self.ProgressView) {
                
                self.LayoutMapView()
            }
            
//            ProgressBarView.hidden = true
//            ProgressbarContainer.hidden = true
            RoutineStateLabel.hidden = true
            intervalLabel.hidden = true
            
            leftSideLabel.text = NSLocalizedString("Left Side Label Text (Run)", comment: "")
            rightSideLabel.text = NSLocalizedString("Right Side Label Text (Run)", comment: "")
        }
        
        changeStage()
    }
    
    func switchButtonState() {
        
        switch buttonState {
            
        case .Initial:
            
            playPauseButton.setImage(UIImage(named:"play.png"),forState:UIControlState.Normal)
            lockUnlockButton.setImage(UIImage(named:"lock_unlocked.png"),forState:UIControlState.Normal)
            
            playPauseButton.enabled = true
            stopButton.enabled = true
            
            checkForwardBackButtonState()
            
        case .Play:
            
            playPauseButton.setImage(UIImage(named:"pause.png"),forState:UIControlState.Normal)

            checkForwardBackButtonState()

            
        case .Pause:
            
            playPauseButton.setImage(UIImage(named:"play.png"),forState:UIControlState.Normal)
            
            checkForwardBackButtonState()
            
        case .Unlocked:
            
            lockUnlockButton.setImage(UIImage(named:"lock_unlocked.png"),forState:UIControlState.Normal)
            
            playPauseButton.enabled = true
            stopButton.enabled = true
            
            checkForwardBackButtonState()
            
        case .Locked:
            
            lockUnlockButton.setImage(UIImage(named:"lock_locked.png"),forState:UIControlState.Normal)
            
            playPauseButton.enabled = false
            stopButton.enabled = false
            previousButton.enabled = false
            forwardButton.enabled = false
        }
    }
    
    func checkForwardBackButtonState() {
        
        switch workoutType {
            
        case .Routine:
            
            if (routineStages.get(routineIndex - 1) != nil) {
                previousButton.enabled = true
            } else {
                previousButton.enabled = false
            }
            
            if (routineStages.get(routineIndex + 1) != nil) {
                forwardButton.enabled = true
            } else {
                forwardButton.enabled = false
            }
            
        case .Run, .QuickTimer:
            previousButton.enabled = false
            forwardButton.enabled = false
        }
    }
    
    func calculateTimeRemaining() -> Int {
        
        var timeRemaining = 0
        
        for i in routineIndex...routineStages.count - 1 {
            
            let dictionary = routineStages[i]
            let interval = dictionary["Time"] as! Int
            
            timeRemaining += interval
        }
        
        return timeRemaining
    }
    
//    func animateStarButton() {
//        
//        self.view.bringSubviewToFront(starButton)
//        starButton.animation = "fadeIn"
//        starButton.animate()
//        starButton.animation = "swing"
//        starButton.repeatCount = 9999
//        starButton.animate()
//    }
    
//    func animateRewardsButton() {
//        
//        rewardsButton.animation = "slideDown"
//        rewardsButton.animate()
//        rewardsButton.animation = "shake"
//        rewardsButton.repeatCount = 9999
//        rewardsButton.animate()
//        
//        self.view.bringSubviewToFront(rewardsButton)
//        
////            self.allPopTips.append(showPopTipOnceForKey("REWARDS_HINT_SHOWN", userDefaults: userDefaults,
////                popTipText: NSLocalizedString("Tap To Redeem Your Reward", comment: ""),
////                inView: self.view,
////                fromFrame: self.rewardsButton.frame, direction: .Up, color: .lightGrayColor()))
//    }
    
//    func hideStarButton() {
//        
//        starButton.animation = "fadeOut"
//        starButton.animate()
//    }
    
//    func hideRewardsButton() {
//    
//        rewardsButton.animation = "fadeOut"
//        rewardsButton.animate()
//    }
    
    func playSound (type: String) {
        
        guard timerSound != "No Sound" else { return }
            
        var soundName: String = ""
        var ext: String!
        var currentStage: String!
        
        if workoutType == .Routine || workoutType == .QuickTimer {
            
            currentStage = currentTimerDict["Name"] as! String
        }
        
        switch type {
            
        case "Routine Begin":
            
            if timerSound == "Text-To-Speech" {
                
                if workoutType == .Routine || workoutType == .QuickTimer {
                    
                    textToSpeech("\(currentStage)")
                    
                } else if workoutType == .Run {
                    
                    textToSpeech(NSLocalizedString("Text-To-Speech Tracking Run Text", comment: ""))
                    
                }
                
            } else {
                
                soundName = timerSound
                ext = ".wav"
            }
            
        case "Routine End":
            
            if timerSound == "Text-To-Speech" {
                
                if workoutType == .QuickTimer {
                    
                    textToSpeech(NSLocalizedString("Text-To-Speech Timer Ended", comment: ""))
                    
                } else {
                    
                    if workoutType == .Routine {
                        
                        textToSpeech(NSLocalizedString("Text-To-Speech Workout Complete Text", comment: ""))
                        
                    } else if workoutType == .Run {
                        
                        textToSpeech(NSLocalizedString("Text-To-Speech Run Complete Text", comment: ""))
                    }
                }
                
            } else {
                
                soundName = timerSound
                ext = ".wav"
            }
            
        case "Tick":
            
            if timerSound == "Text-To-Speech" {
                
                if workoutState == .PreRun {
                    textToSpeech("\(preRoutineCountDownTime)")
                    
                } else {
                    textToSpeech("\(time)")
                }
                
            } else {
                
                soundName = "Tick-Deep"
                ext = ".mp3"
                
            }
            
        default:
            
            if timerSound == "Text-To-Speech" {
                
                textToSpeech("\(currentStage)")
                
            } else {
                
                soundName = timerSound
                ext = ".wav"
                
            }
        }
        
        if soundName != "" {
            
            loadPlayer(soundName, ext: ext)
            
        }
    }
    
    func startCountDown() {
        
        if workoutState == .PreRun {
            
            LayoutBurSubview()
            
            startTimer("countDown3Seconds")
        }
    }
    
    func startWorkout() {
        
        if workoutState == .PreRun {
            
            playSound("Routine Begin")
            
            // Set routine start time
            routineStartDate = NSDate()
            print("start time \(routineStartDate)")
            
            startTimer("counter")
            
            if workoutType == .Run {
                
                startLocationUpdates()
            }
        }
        
        if workoutState == .Paused {
            
            startTimer("counter")
            
            if workoutType == .Run {
                
                startLocationUpdates()
            }
        }
        
        workoutState = .Active
        buttonState = .Play
        switchButtonState()
    }
    
    func checkSaveWorkout(completion: (Bool) -> ()) {
        
        guard workoutState != .PreRun else { return completion(false) }
        
        guard HKHealthStore.isHealthDataAvailable() else { return completion(false) }
        
        if workoutType == .Routine || workoutType == .Run {
            
            if workoutState == .Completed {
                
                self.saveWorkout({ (success) in
                    
                    completion(true)
                })
                
            } else {
                promptToSaveWorkout({ (success) in
                    completion(true)
                })
            }
            
        } else {
            promptToSaveWorkout({ (success) in
                completion(true)
            })
        }
    }
    
    func promptToSaveWorkout(completion: (Bool) -> ()) {
        
        SweetAlert().showAlert(NSLocalizedString("Alert: Save Workout Question Title Text", comment: ""), subTitle: NSLocalizedString("Alert: Save Workout Question Subtitle Text", comment: ""), style: AlertStyle.Warning, dismissTime: nil, buttonTitle: NSLocalizedString("No", comment: ""), buttonColor:UIColor.colorFromRGB(0xD0D0D0) , otherButtonTitle: NSLocalizedString("Yes", comment: ""), otherButtonColor: UIColor.colorFromRGB(0xAEDEF4)) { (isOtherButton) -> Void in
            
            if !isOtherButton {
                self.saveWorkout({ (success) in
                    completion(true)
                })
            } else {
                completion(true)
            }
        }
    }
    
    func saveWorkout(completion: (Bool) -> ()) {
        
        let workoutAuthorizationStatus = HealthKitHelper.sharedInstance.healthKitStore.authorizationStatusForType(HealthKitHelper.sharedInstance.workoutType)
    
        guard workoutAuthorizationStatus != HKAuthorizationStatus.NotDetermined else {
            
            SweetAlert().showAlert(NSLocalizedString("Alert: Authorize Chronic Save Workout Title Text", comment: ""), subTitle: NSLocalizedString("Alert: Authorize Chronic Save Workout Subtitle Text 2", comment: ""), style: AlertStyle.Warning, dismissTime: nil, buttonTitle: NSLocalizedString("Cancel", comment: ""), buttonColor:UIColor.colorFromRGB(0xD0D0D0) , otherButtonTitle: NSLocalizedString("Prompt Me", comment: ""), otherButtonColor: UIColor.colorFromRGB(0xAEDEF4)) { (isOtherButton) -> Void in
                
                if !isOtherButton {
                    
                    // Request Authorization
                    HealthKitHelper.sharedInstance.authorizeHealthKit { (success,  error) -> Void in
                        
                        if success {
                            
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                
                                 self.saveWorkout({ (success) in
                                    
                                 })
                            })
                        }
                    }
                }
            }
            
            return
        }
        
        guard workoutAuthorizationStatus != HKAuthorizationStatus.SharingDenied else {
            
            SweetAlert().showAlert(NSLocalizedString("Alert: Authorize Chronic Save Workout Title Text", comment: ""), subTitle: NSLocalizedString("Alert: Authorize Chronic Save Workout Subtitle Text", comment: ""), style: AlertStyle.Warning, dismissTime: nil, buttonTitle: NSLocalizedString("Cancel", comment: ""), buttonColor:UIColor.colorFromRGB(0xD0D0D0) , otherButtonTitle: NSLocalizedString("Settings", comment: ""), otherButtonColor: UIColor.colorFromRGB(0xAEDEF4)) { (isOtherButton) -> Void in
                
                if !isOtherButton {
                    
                    UIApplication.sharedApplication().openURL(settingsURL!)
                }
            }
            
            return
        }
        
        guard self.routineStartDate != nil && self.routineEndDate != nil else { return }
        
        // Add workout to HealthKit
        HealthKitHelper.sharedInstance.saveRunningWorkout(self.workoutActivityType, startDate: self.routineStartDate, endDate: self.routineEndDate, kiloCalories: nil, distance: distance, completion: { (success, error) -> Void in

            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                
                if success {
                    
                    SweetAlert().showAlert("\(self.workoutType) Saved", subTitle: nil, style: .Success)
                    
                    completion(true)
                    
                } else if error != nil {
                    
                    SweetAlert().showAlert("Failed", subTitle: "We were unable to save your \(self.workoutType)", style: .Error)
                    
                    print("\(error)")
                    
                    completion(false)
                }
            })
        })
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "StopWorkoutSegueIdentifier" {
            
            self.stop()
            
        } else if segue.identifier == "FeedbackSegueIdentifier" {
            
            let controller = segue.destinationViewController
            controller.transitioningDelegate = self
            controller.modalPresentationStyle = .Custom
        }
    }
}

// MARK: - TimerViewController Location Extension
extension TimerViewController: CLLocationManagerDelegate, MKMapViewDelegate {
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        for location in locations {
            let howRecent = location.timestamp.timeIntervalSinceNow
            
            if abs(howRecent) < 10 && location.horizontalAccuracy < 20 {
                //update distance
                if self.locations.count > 0 {
                    distance += location.distanceFromLocation(self.locations.last!)
                    
                    var coords = [CLLocationCoordinate2D]()
                    coords.append(self.locations.last!.coordinate)
                    coords.append(location.coordinate)
                    
                    if workoutState == .Active {
                        
                        let region = MKCoordinateRegionMakeWithDistance(location.coordinate, 500, 500)
                        mapView.setRegion(region, animated: true)
                        
                        mapView.addOverlay(MKPolyline(coordinates: &coords, count: coords.count))
                        
                    }
                }
                
                //save location
                self.locations.append(location)
            }
        }
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        
        print(error)
    }

    // MARK: - MKMapViewDelegate
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        
        let polyline = overlay as! MKPolyline
        let renderer = MKPolylineRenderer(polyline: polyline)
        renderer.strokeColor = UIColor.greenColor()
        renderer.lineWidth = 10
        return renderer
    }
    
    func mapView(mapView: MKMapView, didUpdateUserLocation userLocation: MKUserLocation) {
        
        if workoutState == .PreRun {
            
            let region = MKCoordinateRegionMake(userLocation.coordinate, MKCoordinateSpanMake(0.01, 0.01))
            mapView.setRegion(region, animated: true)
        }
    }
}

// MARK: - TimerViewController Ads Extension
extension TimerViewController: MPAdViewDelegate, MPInterstitialAdControllerDelegate {
    
    // MARK: MoPud Functions
    func displayBannerAds() {
        
        var bannerID: String!
        var bannerSize: CGSize!
        
        if !removeAdsUpgradePurchased() {
            
            if UI_USER_INTERFACE_IDIOM() == .Phone {
                bannerID = "c023d0aea31c44d6a0698c8bb11cba4e"
                bannerSize = MOPUB_BANNER_SIZE
            }
            else {
                bannerID = "6c641c6d8e9b4f989cb81b950054c599"
                bannerSize = MOPUB_LEADERBOARD_SIZE
            }

            mopubBanner = MPAdView(adUnitId: bannerID, size: bannerSize)
            mopubBanner.delegate = self
            
            // Positions the ad at the top, with the correct size
            adBannerView = CustomAdView(forAutoLayout: ())
            self.view.addSubview(adBannerView)
            self.adBannerView.addSubview(mopubBanner)
            
            // Loads the ad over the network
            mopubBanner.loadAd()
            
        } else {
            
            mainStackViewTopConstraint.constant = 20

            guard let ad = mopubBanner where ad.isDescendantOfView(self.adBannerView) else { return }
            mopubBanner.removeFromSuperview()
            adBannerView.removeFromSuperview()
        }
    }
    
    func centerMoPubBannerAd(adView: MPAdView?, relativeToView: UIView?) {
        
        guard let adView = adView, let relativeToView = relativeToView else { return }
        
        let size: CGSize = adView.adContentViewSize()
        let centeredX: CGFloat = (relativeToView.bounds.size.width - size.width) / 2
        adView.frame = CGRectMake(centeredX, 0, size.width, size.height)
        mainStackViewTopConstraint.constant = size.height
    }
    
    func adViewDidLoadAd(view: MPAdView!) {
        adBannerView.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero, excludingEdge: .Bottom)
        adBannerView.autoSetDimension(.Height, toSize: view.adContentViewSize().height, relation: .Equal)
    
        centerMoPubBannerAd(view, relativeToView: self.view)
    }
    
    func adViewDidFailToLoadAd(view: MPAdView!) {
        mainStackViewTopConstraint.constant = 20
    }

    func viewControllerForPresentingModalView() -> UIViewController {
        return self
    }
    
    func displayInterstitialAds() {
        
        var interstitialID: String!
        
        if !removeAdsUpgradePurchased() {
            
            if UI_USER_INTERFACE_IDIOM() == .Phone {
                interstitialID = "ac4350a1be4046488d0cd0461469c8a9"
            }
            else {
                interstitialID = "c67dc2659e43438e97a28959f409d445"
            }
            
            mopubInterstitial = MPInterstitialAdController(forAdUnitId: interstitialID)
            mopubInterstitial.delegate = self
            
            // Loads the ad over the network
            mopubInterstitial.loadAd()
        }
    }
    
    func interstitialDidLoadAd(interstitial: MPInterstitialAdController) {
        if (interstitial.ready) {
            interstitial.showFromViewController(self)
        }
    }
}

// MARK: - UIViewControllerTransitioningDelegate
extension TimerViewController: UIViewControllerTransitioningDelegate {
    
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transition.transitionMode = .Present
        transition.startingPoint = self.view.center
        transition.bubbleColor = UIColor.goldColor()
        return transition
    }
    
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transition.transitionMode = .Dismiss
        transition.startingPoint = self.view.center
        transition.bubbleColor = chronicColor
        return transition
    }
}

//// MARK: - TimerViewController AdColony Extension
//extension TimerViewController: AppodealBannerDelegate {
//
//    // MARK: AppodealFunctions
//
//    func canDisplayAds() {
//
//        if !removeAdsUpgradePurchased() {
//
//            // optional: set delegate
//            Appodeal.setBannerDelegate(self)
//            Appodeal.showAd(AppodealShowStyle.BannerTop, rootViewController: self)
//
//            //            var size: CGSize = kAppodealUnitSize_320x50
//            //
//            //            if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
//            //                size = kAppodealUnitSize_728x90
//            //            } else {
//            //                size = kAppodealUnitSize_320x50
//            //            }
//            //
//            //            // required: init ad banner
//            //            bannerView = AppodealBannerView(size: size, rootViewController: self)
//            //
//            //            // required: add banner to superview and call -loadAd to start banner loading
//            //            self.view.addSubview(bannerView)
//            //            bannerView.loadAd()
//
//        } else {
//            Appodeal.hideBanner()
//            mainStackViewTopConstraint.constant = 20
//        }
//    }
//
//    func bannerDidLoadAd() {
//        print("bannerDidLoadAd")
//
//        mainStackViewTopConstraint.constant = Appodeal.banner().frame.height
//    }
//
//    func bannerDidFailToLoadAd() {
//        print("bannerDidFailToLoadAd")
//    }
//
//    func bannerDidClick() {
//        print("bannerDidClick")
//    }
//}