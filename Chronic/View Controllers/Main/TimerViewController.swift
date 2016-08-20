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
import BubbleTransition
import PureLayout

class TimerViewController: UIViewController, UIPopoverControllerDelegate, UIPopoverPresentationControllerDelegate, CNPPopupControllerDelegate {

    enum ButtonState {
        case play
        case pause
        case initial
        case unlocked
        case locked
    }

    var workoutType = Constants.WorkoutType.quickTimer
    var workoutState = Constants.WorkoutEventType.preRun
    var buttonState = ButtonState.initial

    var workoutActivityType: HKWorkoutActivityType = HKWorkoutActivityType.crossTraining
    
    var timer = Timer()
    
    var time: Int = 0
    var timeRemaining: Int = 0
    var timeElapsed: Int = 0
    var preRoutineCountDownTime: Int = 3

    var distance: Double = 0.0
    var pace: Double = 0.0
    
//    var ProgressbarContainer: UIView = UIView()
//    var ProgressCircle = CAShapeLayer()
//    var WhiteCircle = CAShapeLayer()
//    var circleLineWidth: CGFloat = 20
    
    var routine: RoutineModel?
    var routineStages = [[String:Any]]()
    var routineTotalTime = Int()
    var currentTimerDict = [String:Any]()
    
    var routineIndex: Int = 0
    var routineStartDate: Date!
    var routineEndDate: Date!
    
    var distanceFormatter: MKDistanceFormatter = {
        let distanceFormatter = MKDistanceFormatter()
        //distanceFormatter.units = MKDistanceFormatterUnits.metric
        distanceFormatter.unitStyle = .abbreviated
        return distanceFormatter
    }()

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
        locationManager.activityType = .fitness
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
    
    @IBOutlet var progressView: UIView!
    
    @IBOutlet var countDownLabel: UILabel!
    
    @IBOutlet var leftTopLabel: UILabel!
    @IBOutlet var leftBottomLabel: UILabel!
    @IBOutlet var middleTopLabel: UILabel!
    @IBOutlet var middleBottomLabel: UILabel!
    @IBOutlet var rightTopLabel: UILabel!
    @IBOutlet var rightBottomLabel: UILabel!
    
    @IBOutlet var stopButton: UIButton!
    @IBOutlet var previousButton: UIButton!
    @IBOutlet var playPauseButton: UIButton!
    @IBOutlet var forwardButton: UIButton!
    @IBOutlet var lockUnlockButton: UIButton!
    
    // MARK: - Button Actions
    
    @IBAction func previousButtonPressed(_ sender: UIButton) {
        
        guard (routineStages.get(routineIndex - 1) != nil) else { return }
        
        if timer.isValid {
            self.pause()
        }
        
        routineIndex -= 1
        
        changeStage()
    }
    
    @IBAction func forwardButtonPressed(_ sender: UIButton) {
        
        guard (routineStages.get(routineIndex + 1) != nil) else { return }
        
        if timer.isValid {
            self.pause()
        }
        
        routineIndex += 1
        
        changeStage()
    }
    
    //Button Action for playing routine button
    @IBAction func playPausebarButtonItemPressed(_ sender: UIButton) {
        
        print(workoutState)
        
        if workoutType != .run && routineTotalTime == 0 {
            return
        } else {
            if workoutState == .preRun || workoutState == .paused {
                self.play()
            } else {
                self.pause()
            }
        }
    }
    
    @IBAction func lockUnlockButtonPressed(_ sender: UIButton) {

        if buttonState == .locked {
            self.unlock()
        } else {
            self.lock()
        }
    }
    
    func lock() {
        buttonState = .locked
        switchButtonState()
    }
    
    func unlock() {
        buttonState = .unlocked
        switchButtonState()
    }
    
    func play() {
        
        if !Functions.isConnectedToNetwork() && !Functions.isRemoveAdsUpgradePurchased() {
            
            SweetAlert().showAlert(NSLocalizedString("Alert: No Internet Connection Title Text", comment: ""), subTitle: NSLocalizedString("Alert: No Internet Connection Subtitle Text", comment: ""), style: AlertStyle.warning)
            
        } else {
            
            if workoutState == .preRun {
                startCountDown()
            } else {
                startWorkout()
            }
        }
    }
    
    func pause() {
        
        timer.invalidate()
    
        workoutState = .paused
        buttonState = .pause
        switchButtonState()
    }
    
    func stop() {
        
        timer.invalidate()
        
        // Set end time
        routineEndDate = Date()
        print("end time \(routineEndDate)")
        
        // Complete workout if .Run 
        if workoutType == .run {
            workoutState = Constants.WorkoutEventType.completed
        }
            
        // Set Alert if in background
        var message: String!
        
        if UIApplication.shared.applicationState == UIApplicationState.background {
            
            var alertTitle: String!
            var alertBody: String!
            
            switch workoutType {
            case .quickTimer:
                alertTitle = NSLocalizedString("Notification Timer Text", comment: "")
                alertBody = NSLocalizedString("Notification Timer subText", comment: "")
            case .routine, .run:
                alertTitle = NSLocalizedString("Notification Workout Text", comment: "")
                alertBody = NSLocalizedString("Notifcation Workout subText", comment: "")
            }
            
            // Schedule workoutCompleteLocalNotification
            NotificationHelper.scheduleNotification(nil, repeatInterval: nil, alertTitle: alertTitle, alertBody: alertBody, sound: "Boxing.wav", identifier: Constants.NotificationIdentifier.WorkoutIdentifier.key())
        }
        
        // Save workout
        checkSaveWorkout { (complete) in
        }
        
        // Reset settings to initial state (Just for tidiness)
        switch workoutType {
        case .quickTimer:
            self.initializeQuickTimer()
        case .routine:
            self.initializeRoutine(with: routine)
        case .run:
            self.initializeRunner()
        }
    }
    
    // MARK: - View Life Cycle
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Adjust font greater than 300 limitation from Storyboard
        self.countDownLabel.font = countDownLabel.font.withSize(1000)
        
        // check if you should display ads
        self.displayBannerAds()
    }
    
    override func willRotate(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        guard let ad = mopubBanner, ad.isDescendant(of: self.adBannerView) else { return }
        self.mopubBanner.rotate(to: toInterfaceOrientation)
    }
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
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
        threeMinuteCounterVisualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .extraLight)) as UIVisualEffectView
        
        self.view.addSubview(threeMinuteCounterVisualEffectView)
        threeMinuteCounterVisualEffectView.translatesAutoresizingMaskIntoConstraints = false
        threeMinuteCounterVisualEffectView.autoPinEdgesToSuperviewEdges()
        
        threeMinuteCounterLabel.frame = CGRect(x: (threeMinuteCounterVisualEffectView.frame.width / 2) - 100, y: (threeMinuteCounterVisualEffectView.frame.height / 2) - 100, width: 200, height: 200)
        threeMinuteCounterLabel.text = String(preRoutineCountDownTime)
        threeMinuteCounterLabel.textColor = UIColor.white
        threeMinuteCounterLabel.font = UIFont(name: threeMinuteCounterLabel.font.fontName, size: 200)
        threeMinuteCounterLabel.textAlignment = NSTextAlignment.center
        threeMinuteCounterVisualEffectView.addSubview(threeMinuteCounterLabel)
        threeMinuteCounterLabel.translatesAutoresizingMaskIntoConstraints = false
        threeMinuteCounterLabel.autoCenterInSuperview()
    }
    
    func LayoutMapView() {
        self.progressView.addSubview(mapView)
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.autoPinEdgesToSuperviewEdges()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //Function to start exercise time
    func startTimer(_ selector: String) {
        
        timer.invalidate()
        
        if !timer.isValid {
            timer = Timer .scheduledTimer(timeInterval: 1, target: self, selector: Selector(selector) , userInfo: nil, repeats: true)
        }
    }
    
    //Timer Function
    func counter() {
        
        switch workoutType {
        case .routine, .quickTimer:
            
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
                    workoutState = Constants.WorkoutEventType.completed
                    
                    // Stop Timer
                    self.stop()
                    
                    // Ask for feedback or show ad
                    if SARate.sharedInstance().eventCount >= SARate.sharedInstance().eventsUntilPrompt && Constants.userDefaults.bool(forKey: "FEEDBACK_GIVEN") == false {
                        
                        self.performSegue(withIdentifier: "FeedbackSegueIdentifier", sender: self)
                        
                    } else {
                        
                        self.displayInterstitialAds()
                    }
                    
                } else {
                    
                    routineIndex += 1
                    
                    changeStage()
                    
                    // Play exercise name and interval stage
                    playSound("Stage Change")
                    
                    startTimer("counter")
                    
                }
                
                return
            }
            
        case .run:
            
            timeElapsed += 1
            
            if timeElapsed % 60 == 0 || pace == 0 {
                pace = calculatePace(timeElapsed, distance: distance)
            }
            
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
    
            if self.threeMinuteCounterVisualEffectView.isDescendant(of: self.view) {
                
                threeMinuteCounterVisualEffectView.removeFromSuperview()
                
            }
            
            startWorkout()
            
            return
        }
    }
    
    func startLocationUpdates() {
        
        let status = CLLocationManager.authorizationStatus()
        
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            
            locationManager.startUpdatingLocation()
            
        } else {
            
            SweetAlert().showAlert(NSLocalizedString("Alert: Location Authorization Title Text", comment: ""), subTitle: NSLocalizedString("Alert: Location Authorization Subtitle Text", comment: ""), style: AlertStyle.warning)
        }
    }
    
    func initializeQuickTimer() {
        
        timer.invalidate()
        
        workoutType = Constants.WorkoutType.quickTimer
        
        (routineStages, routineTotalTime) = Functions.makeRoutineArray(nil)
        
        switchAppState()
    }
    
    func initializeRoutine(with routine: RoutineModel?) {
    
        timer.invalidate()
        
        workoutType = Constants.WorkoutType.routine
        
        (routineStages, routineTotalTime) = Functions.makeRoutineArray(routine)
        self.routine = routine
        
        switchAppState()
    }
    
    func initializeRunner() {
        
        timer.invalidate()
        
        workoutType = Constants.WorkoutType.run
        routineStages = [[String:AnyObject]]()
        currentTimerDict = [String:AnyObject]()
        
        locationManager.requestWhenInUseAuthorization()
        
        switchAppState()
    }
    
    //Function to set the view to initial stage
    func setToInitialState() {
        
        routineIndex = 0
        timeRemaining = routineTotalTime 
        timeElapsed = 0
        distance = 0
        time = 0
        preRoutineCountDownTime = 3
        
//        ProgressCircle.strokeEnd = 0
        
        locations.removeAll(keepingCapacity: false)
        
        if mapView.isDescendant(of: self.view) {
            
            let pointsArray = mapView.overlays
            mapView.removeOverlays(pointsArray)
        }
    
        workoutState = Constants.WorkoutEventType.preRun
        buttonState = ButtonState.initial
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
        
        if workoutType == .routine || workoutType == .quickTimer {
            
            //RoutineButton.setTitle(routineName, forState: .Normal)
            countDownLabel.text = Functions.timeStringFrom(time: time, type: "Routine")
            leftBottomLabel.text = Functions.timeStringFrom(time:timeElapsed, type: "Routine")
            middleTopLabel.text = currentTimerDict["Name"] as? String
            middleBottomLabel.text = currentTimerDict["Interval"] as? String
            rightBottomLabel.text = Functions.timeStringFrom(time:timeRemaining, type: "Routine")
            
        } else if workoutType == .run {
            
            leftBottomLabel.text = Functions.timeStringFrom(time: timeElapsed, type: "Routine")
            middleBottomLabel.text = Functions.timeStringFrom(time: Int(pace * 3600), type: "Routine")
            rightBottomLabel.text = distanceFormatter.string(fromDistance: distance)
        }
    }
    
    func changeProgressBarAndStageLabelColor() {
        
        var stageColor: UIColor!
        
        if let currentTimerDictColor = currentTimerDict["Color"] as? Data {
            
            stageColor = (NSKeyedUnarchiver.unarchiveObject(with: currentTimerDictColor) as? UIColor)!
            self.progressView.backgroundColor = stageColor
            middleTopLabel.textColor = stageColor
            print(stageColor)
        }
    }
    
    func switchAppState() {
    
        setToInitialState()
        
        switch workoutType {
            
        case .quickTimer, .routine:
        
            workoutActivityType = HKWorkoutActivityType.crossTraining
            
            countDownLabel.isHidden = false
            
            if mapView.isDescendant(of: self.progressView) {
                
                mapView.removeFromSuperview()
            }
            
//            ProgressBarView.hidden = false
//            ProgressbarContainer.hidden = false
//            middleTopLabel.isHidden = false
//            middleBottomLabel.isHidden = false
            
            leftTopLabel.text = NSLocalizedString("Left Side Label Text (Routine)", comment: "")
            rightTopLabel.text = NSLocalizedString("Right Side Label Text (Routine)", comment: "")
            
        case .run:
        
            workoutActivityType = HKWorkoutActivityType.running
            countDownLabel.isHidden = true
            
            if !mapView.isDescendant(of: self.progressView) {
                self.LayoutMapView()
            }
            
//            ProgressBarView.hidden = true
//            ProgressbarContainer.hidden = true
//            middleTopLabel.isHidden = true
//            middleBottomLabel.isHidden = true
            
            leftTopLabel.text = NSLocalizedString("Left Side Label Text (Run)", comment: "")
            middleTopLabel.text = NSLocalizedString("Middle Label Text (Run)", comment: "")
            rightTopLabel.text = NSLocalizedString("Right Side Label Text (Run)", comment: "")
        }
        
        changeStage()
    }
    
    func switchButtonState() {
        
        switch buttonState {
            
        case .initial:
            
            playPauseButton.setImage(UIImage(named:"play.png"),for:UIControlState())
            lockUnlockButton.setImage(UIImage(named:"lock_unlocked.png"),for:UIControlState())
            
            playPauseButton.isEnabled = true
            stopButton.isEnabled = true
            
            checkForwardBackButtonState()
            
        case .play:
            
            playPauseButton.setImage(UIImage(named:"pause.png"),for:UIControlState())

            checkForwardBackButtonState()

            
        case .pause:
            
            playPauseButton.setImage(UIImage(named:"play.png"),for:UIControlState())
            
            checkForwardBackButtonState()
            
        case .unlocked:
            
            lockUnlockButton.setImage(UIImage(named:"lock_unlocked.png"),for:UIControlState())
            
            playPauseButton.isEnabled = true
            stopButton.isEnabled = true
            
            checkForwardBackButtonState()
            
        case .locked:
            
            lockUnlockButton.setImage(UIImage(named:"lock_locked.png"),for:UIControlState())
            
            playPauseButton.isEnabled = false
            stopButton.isEnabled = false
            previousButton.isEnabled = false
            forwardButton.isEnabled = false
        }
    }
    
    func checkForwardBackButtonState() {
        
        switch workoutType {
            
        case .routine:
            
            if (routineStages.get(routineIndex - 1) != nil) {
                previousButton.isEnabled = true
            } else {
                previousButton.isEnabled = false
            }
            
            if (routineStages.get(routineIndex + 1) != nil) {
                forwardButton.isEnabled = true
            } else {
                forwardButton.isEnabled = false
            }
            
        case .run, .quickTimer:
            previousButton.isEnabled = false
            forwardButton.isEnabled = false
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
    
    func calculatePace (_ timeElapsed: Int, distance: Double) -> Double {
        
        guard timeElapsed != 0 && distance != 0 else { return 0 }
        
        return Double(timeElapsed) / distance
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
    
    func playSound (_ type: String) {
        
        guard Constants.timerSound != "No Sound" else { return }
            
        var soundName: String = ""
        var ext: String!
        var currentStage: String!
        
        if workoutType == .routine || workoutType == .quickTimer {
            
            switch (currentTimerDict["Name"] as? String, currentTimerDict["Interval"] as? String) {
            case (let exerciseName?, let exerciseInterval?):
                currentStage = exerciseName + " " + exerciseInterval
            case (let exerciseName?, _):
                currentStage = exerciseName
            default:
                break
            }
        }
        
        switch type {
            
        case "Routine Begin":
            
            if Constants.timerSound == "Text-To-Speech" {
                
                if workoutType == .routine || workoutType == .quickTimer {
                    
                    Functions.textToSpeech(currentStage)
                    
                } else if workoutType == .run {
                    
                    Functions.textToSpeech(NSLocalizedString("Text-To-Speech Tracking Run Text", comment: ""))
                    
                }
                
            } else {
                
                soundName = Constants.timerSound
                ext = ".wav"
            }
            
        case "Routine End":
            
            if Constants.timerSound == "Text-To-Speech" {
                
                if workoutType == .quickTimer {
                    
                    Functions.textToSpeech(NSLocalizedString("Text-To-Speech Timer Ended", comment: ""))
                    
                } else {
                    
                    if workoutType == .routine {
                        
                        Functions.textToSpeech(NSLocalizedString("Text-To-Speech Workout Complete Text", comment: ""))
                        
                    } else if workoutType == .run {
                        
                        Functions.textToSpeech(NSLocalizedString("Text-To-Speech Run Complete Text", comment: ""))
                    }
                }
                
            } else {
                
                soundName = Constants.timerSound
                ext = ".wav"
            }
            
        case "Tick":
            
            if Constants.timerSound == "Text-To-Speech" {
                
                if workoutState == .preRun {
                    Functions.textToSpeech("\(preRoutineCountDownTime)")
                    
                } else {
                    Functions.textToSpeech("\(time)")
                }
                
            } else {
                
                soundName = "Tick-Deep"
                ext = ".mp3"
                
            }
            
        default:
            
            if Constants.timerSound == "Text-To-Speech" {
                
                Functions.textToSpeech(currentStage)
                
            } else {
                
                soundName = Constants.timerSound
                ext = ".wav"
                
            }
        }
        
        if soundName != "" {
            
            Functions.loadPlayer(soundName, ext: ext)
            
        }
    }
    
    func startCountDown() {
        
        if workoutState == .preRun {
            
            LayoutBurSubview()
            
            startTimer("countDown3Seconds")
        }
    }
    
    func startWorkout() {
        
        if workoutState == .preRun {
            
            playSound("Routine Begin")
            
            // Set routine start time
            routineStartDate = Date()
            print("start time \(routineStartDate)")
            
            startTimer("counter")
            
            if workoutType == .run {
                
                startLocationUpdates()
            }
        }
        
        if workoutState == .paused {
            
            startTimer("counter")
            
            if workoutType == .run {
                
                startLocationUpdates()
            }
        }
        
        workoutState = .active
        buttonState = .play
        switchButtonState()
        
        // Handle connection loss when workout running
        
    }
    
    func checkSaveWorkout(_ completion: @escaping (Bool) -> ()) {
        
        guard workoutState != .preRun else { return completion(false) }
        
        guard HKHealthStore.isHealthDataAvailable() else { return completion(false) }
        
        if workoutType == .routine || workoutType == .run {
            
            if workoutState == .completed {
                
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
    
    func promptToSaveWorkout(_ completion: @escaping (Bool) -> ()) {
        
        SweetAlert().showAlert(NSLocalizedString("Alert: Save Workout Question Title Text", comment: ""), subTitle: NSLocalizedString("Alert: Save Workout Question Subtitle Text", comment: ""), style: AlertStyle.warning, dismissTime: nil, buttonTitle: NSLocalizedString("No", comment: ""), buttonColor:UIColor.colorFromRGB(0xD0D0D0) , otherButtonTitle: NSLocalizedString("Yes", comment: ""), otherButtonColor: UIColor.colorFromRGB(0xAEDEF4)) { (isOtherButton) -> Void in
            
            if !isOtherButton {
                self.saveWorkout({ (success) in
                    completion(true)
                })
            } else {
                completion(true)
            }
        }
    }
    
    func saveWorkout(_ completion: @escaping (Bool) -> ()) {
        
        let workoutAuthorizationStatus = HealthKitHelper.sharedInstance.healthKitStore.authorizationStatus(for: HealthKitHelper.sharedInstance.workoutType)
    
        guard workoutAuthorizationStatus != HKAuthorizationStatus.notDetermined else {
            
            SweetAlert().showAlert(NSLocalizedString("Alert: Authorize Chronic Save Workout Title Text", comment: ""), subTitle: NSLocalizedString("Alert: Authorize Chronic Save Workout Subtitle Text 2", comment: ""), style: AlertStyle.warning, dismissTime: nil, buttonTitle: NSLocalizedString("Cancel", comment: ""), buttonColor:UIColor.colorFromRGB(0xD0D0D0) , otherButtonTitle: NSLocalizedString("Prompt Me", comment: ""), otherButtonColor: UIColor.colorFromRGB(0xAEDEF4)) { (isOtherButton) -> Void in
                
                if !isOtherButton {
                    
                    // Request Authorization
                    HealthKitHelper.sharedInstance.authorizeHealthKit { (success,  error) -> Void in
                        
                        if success {
                            
                            DispatchQueue.main.async(execute: { () -> Void in
                                
                                 self.saveWorkout({ (success) in
                                    
                                 })
                            })
                        }
                    }
                }
            }
            
            return
        }
        
        guard workoutAuthorizationStatus != HKAuthorizationStatus.sharingDenied else {
            
            SweetAlert().showAlert(NSLocalizedString("Alert: Authorize Chronic Save Workout Title Text", comment: ""), subTitle: NSLocalizedString("Alert: Authorize Chronic Save Workout Subtitle Text", comment: ""), style: AlertStyle.warning, dismissTime: nil, buttonTitle: NSLocalizedString("Cancel", comment: ""), buttonColor:UIColor.colorFromRGB(0xD0D0D0) , otherButtonTitle: NSLocalizedString("Settings", comment: ""), otherButtonColor: UIColor.colorFromRGB(0xAEDEF4)) { (isOtherButton) -> Void in
                
                if !isOtherButton {
                    
                    UIApplication.shared.open(Constants.settingsURL!, options: [:], completionHandler: { (success) in
                        
                    })
                }
            }
            
            return
        }
        
        guard self.routineStartDate != nil && self.routineEndDate != nil else { return }
        
        // Add workout to HealthKit
        HealthKitHelper.sharedInstance.saveRunningWorkout(workoutActivityType: self.workoutActivityType, startDate: self.routineStartDate, endDate: self.routineEndDate, kiloCalories: nil, distance: distance, completion: { (success, error) -> Void in

            DispatchQueue.main.async(execute: { () -> Void in
                
                if success {
                    
                    SweetAlert().showAlert("\(self.workoutType) Saved", subTitle: nil, style: .success)
                    
                    completion(true)
                    
                } else if error != nil {
                    
                    SweetAlert().showAlert("Failed", subTitle: "We were unable to save your \(self.workoutType)", style: .error)
                    
                    print("\(error)")
                    
                    completion(false)
                }
            })
        })
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "StopWorkoutSegueIdentifier" {
            
            self.stop()
            
        } else if segue.identifier == "FeedbackSegueIdentifier" {
            
            let controller = segue.destination
            controller.transitioningDelegate = self
            controller.modalPresentationStyle = .custom
        }
    }
}

// MARK: - TimerViewController Location Extension
extension TimerViewController: CLLocationManagerDelegate, MKMapViewDelegate {
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        for location in locations {
            
            let howRecent = location.timestamp.timeIntervalSinceNow
            
            if abs(howRecent) < 10 && location.horizontalAccuracy < 20 && workoutState == .active {
                
                //update distance
                if self.locations.count > 0 {
                    distance += location.distance(from: self.locations.last!)
                    
                    var coords = [CLLocationCoordinate2D]()
                    coords.append(self.locations.last!.coordinate)
                    coords.append(location.coordinate)
                        
                    let region = MKCoordinateRegionMakeWithDistance(location.coordinate, 500, 500)
                    mapView.setRegion(region, animated: true)
                    
                    mapView.add(MKPolyline(coordinates: &coords, count: coords.count))
                }
            }
            
            //save location
            self.locations.append(location)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        
        print(error)
    }

    // MARK: - MKMapViewDelegate
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        let polyline = overlay as! MKPolyline
        let renderer = MKPolylineRenderer(polyline: polyline)
        renderer.strokeColor = Constants.chronicGreen
        renderer.lineWidth = 6
        return renderer
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        
        if workoutState == .preRun {
            
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
        
        // && (LaunchKit.sharedInstance().currentUser?.isSuper() == false)
        if !Functions.isRemoveAdsUpgradePurchased() {
            
            if UI_USER_INTERFACE_IDIOM() == .phone {
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

            guard let ad = mopubBanner, ad.isDescendant(of: self.adBannerView) else { return }
            mopubBanner.removeFromSuperview()
            adBannerView.removeFromSuperview()
        }
    }
    
    func centerMoPubBannerAd(_ adView: MPAdView?, relativeToView: UIView?) {
        
        guard let adView = adView, let relativeToView = relativeToView else { return }
        
        let size: CGSize = adView.adContentViewSize()
        let centeredX: CGFloat = (relativeToView.bounds.size.width - size.width) / 2
        adView.frame = CGRect(x: centeredX, y: 0, width: size.width, height: size.height)
        mainStackViewTopConstraint.constant = size.height
    }
    
    func adViewDidLoadAd(_ view: MPAdView!) {
        adBannerView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets.zero, excludingEdge: .bottom)
        adBannerView.autoSetDimension(.height, toSize: view.adContentViewSize().height, relation: .equal)
    
        centerMoPubBannerAd(view, relativeToView: self.view)
    }
    
    func adViewDidFail(toLoadAd view: MPAdView!) {
        mainStackViewTopConstraint.constant = 20
    }

    func viewControllerForPresentingModalView() -> UIViewController {
        return self
    }
    
    func displayInterstitialAds() {
        
        var interstitialID: String!
        
        if !Functions.isRemoveAdsUpgradePurchased() {
            
            if UI_USER_INTERFACE_IDIOM() == .phone {
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
    
    func interstitialDidLoadAd(_ interstitial: MPInterstitialAdController) {
        if (interstitial.ready) {
            interstitial.show(from: self)
        }
    }
}

// MARK: - UIViewControllerTransitioningDelegate
extension TimerViewController: UIViewControllerTransitioningDelegate {
    
    func animationController(forPresentedController presented: UIViewController, presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transition.transitionMode = .present
        transition.startingPoint = self.view.center
        transition.bubbleColor = UIColor.goldColor()
        return transition
    }
    
    func animationController(forDismissedController dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transition.transitionMode = .dismiss
        transition.startingPoint = self.view.center
        transition.bubbleColor = Constants.chronicColor
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
