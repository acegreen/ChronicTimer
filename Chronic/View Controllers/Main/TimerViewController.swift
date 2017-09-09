//
//  MainViewController.swift
//  Chronic
//
//  Created by Ahmed E on 08/02/15.
//  Copyright (c) 2015 Ace Green. All rights reserved.
//

import UIKit
import ChronicKit
import MapKit
import HealthKit
import Fabric
import Crashlytics
import MoPub
import LaunchKit
import PureLayout
import Crashlytics

protocol TimerVCDelegate {
    func workoutDidBegin(timer: Timer)
    func workoutDidEnd(timer: Timer)
}

class TimerViewController: UIViewController, UIPopoverControllerDelegate, UIPopoverPresentationControllerDelegate {

    enum ButtonState {
        case play
        case pause
        case initial
        case unlocked
        case locked
    }
    
    var delegate: TimerVCDelegate!
    
    var buttonState = ButtonState.initial
    
    var time: Int = 0
    var preRoutineCountDownTime = Constants.countdownTime
    
    var workout: Workout!
    
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
        locationManager.distanceFilter = 10.0
        return locationManager
    }()
    
    var threeMinuteCounterLabel: UILabel!
    var threeMinuteCounterVisualEffectView: UIVisualEffectView!
    
    var mopubBanner: MPAdView?
    var mopubInterstitial: MPInterstitialAdController!
    
    @IBOutlet var adStackView: UIStackView!
    @IBOutlet var topStackView: UIStackView!
    @IBOutlet var middleStackView: UIStackView!
    @IBOutlet var bottomStackView: UIStackView!
    
    @IBOutlet var adBannerView: CustomAdView!
    @IBOutlet weak var adStackViewHeightConstraint: NSLayoutConstraint!
    
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
        
        guard (workout.routineStages.get(workout.routineIndex - 1) != nil) else { return }
        
        if Constants.timer.isValid {
            self.pause()
        }
        
        workout.routineIndex -= 1
        
        changeStage()
    }
    
    @IBAction func forwardButtonPressed(_ sender: UIButton) {
        
        guard (workout.routineStages.get(workout.routineIndex + 1) != nil) else { return }
        
        if Constants.timer.isValid {
            self.pause()
        }
        
        workout.routineIndex += 1
        
        changeStage()
    }
    
    //Button Action for playing routine button
    @IBAction func playPausebarButtonItemPressed(_ sender: UIButton) {
        
        if workout.workoutType != .run && workout.totalTime == 0 {
            return
        } else {
            if workout.workoutState == .preRun || workout.workoutState == .paused {
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
            
            SweetAlert().showAlert(NSLocalizedString("Alert: Purchase Remove Ads Title Text", comment: ""), subTitle: NSLocalizedString("Alert: Purchase Remove Ads Subtitle Text", comment: ""), style: AlertStyle.warning)
            
        } else {
            
            if workout.workoutState == .preRun {
                startCountDown()
            } else {
                startWorkout()
            }
        }
    }
    
    func pause() {
        
        Constants.timer.invalidate()
    
        workout.workoutState = .paused
        buttonState = .pause
        switchButtonState()
    }
    
    func stop() {
        
        // Stop timer
        Constants.timer.invalidate()
        
        // Set end time
        workout.routineEndDate = Date()
        print("end time \(workout.routineEndDate)")
        
        // Complete workout if .Run  and present share card
        if workout.workoutType == .run && workout.workoutState != .preRun {
            workout.workoutState = Workout.WorkoutState.completed
        }
        
        // Store lastWorkout
        Constants.lastWorkout = workout
        
        // End the workout session 
        workout.nsUserActivity?.invalidate()
        
        // take a screenshot of map if workout type is run - for share feature
        if workout.workoutType == .run {
            workout.mapImage = mapView.takeScreenshot()
        }
        
        // Save & log workout
        if workout.workoutState != .preRun {
            
            checkSaveWorkout { (complete) in
            }
            
            let applicationState: String = Constants.app.applicationState == .active ? "Active" : "Background"
            Answers.logCustomEvent(withName: "Workout", customAttributes: ["Workout Type": self.workout.workoutType.rawValue, "Workout Duration": Functions.timeStringFrom(time: self.workout.timeElapsed), "Workout Distance": self.distanceFormatter.string(fromDistance: self.workout.distance), "Application State": applicationState, "Remove Ads Upgrade Purchased": String(Functions.isRemoveAdsUpgradePurchased()), "App Version": Constants.AppVersion])
        }
        
        // Set Alert if in background
        if UIApplication.shared.applicationState == UIApplicationState.background {
            
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
            
            // Schedule workoutCompleteLocalNotification
            NotificationHelper.scheduleNotification(nil, repeatInterval: nil, alertTitle: alertTitle, alertBody: alertBody, sound: "Boxing.wav", identifier: Constants.NotificationIdentifier.WorkoutIdentifier.key())
        }
        
        // Send to delegate
        self.delegate.workoutDidEnd(timer: Constants.timer)
        
        // increment event count
        if workout.timeElapsed >= 60 {
            SARate.sharedInstance().eventCount += 1
            print("eventCount", SARate.sharedInstance().eventCount)
        }
        
        // Reset settings to initial state (Just for tidiness)
        switch workout.workoutType {
        case .quickTimer:
            self.initializeQuickTimer()
        case .routine:
            self.initializeRoutine(with: workout.routineModel!)
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
        
        // assign delegate to appDelegate
        self.delegate = Constants.appDel
        
        // Adjust font greater than 300 limitation from Storyboard
        self.countDownLabel.font = countDownLabel.font.withSize(1000)
        
        // check if you should display ads
        self.displayBannerAds()
    }
    
    override func willRotate(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        guard let mopubBanner = mopubBanner else { return }
        mopubBanner.rotate(to: toInterfaceOrientation)
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
    func startTimer(selector: String) {
        
        Constants.timer.invalidate()
        
        if !Constants.timer.isValid {
            Constants.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: Selector(selector) , userInfo: nil, repeats: true)
        }
    }
    
    //Timer Function
    func counterRoutine() {
        
        // Check for internet connection every 30 seconds, pause routine and display error if not connected and no upgrade purchased
        if workout.timeElapsed % 30 == 0 && !Functions.isConnectedToNetwork() && !Functions.isRemoveAdsUpgradePurchased() {
            
            SweetAlert().showAlert(NSLocalizedString("Alert: Purchase Remove Ads Title Text", comment: ""), subTitle: NSLocalizedString("Alert: Purchase Remove Ads Subtitle Text", comment: ""), style: AlertStyle.warning)

            self.pause()
            
            return
        }
        
        switch workout.workoutType {
        case .routine, .quickTimer:
            
            // Increment time
            time -= 1
            workout.timeRemaining -= 1
            workout.timeElapsed += 1
            
            // Update labels
            changeLabels()
            
            // handle time accordingly (Routine/QT)
            if (time < 4 && time > 0) || (time % 60 == 0 && time != 0) {
        
                playSound("Tick")
                
            } else  if time <= 0 {
                
                // If timer == 0, stage is over
                
                if workout.routineIndex == workout.routineStages.count - 1 {
                    
                    // Play Sound
                    playSound("Routine End")
                    
                    // Mark routine as completed
                    workout.workoutState = Workout.WorkoutState.completed
                    
                    // Stop Timer
                    self.stop()
                    
                } else {
                    
                    // Update index
                    workout.routineIndex += 1
                    
                    // Change stage
                    changeStage()
                    
                    // Start a new timer
                    startTimer(selector: "counterRoutine")
                    
                    // Play exercise name and interval stage
                    playSound("Stage Change")
                }
                
                return
            }
            
        case .run:
            
            // Increment time
            workout.timeElapsed += 1
            
            // Update labels
            changeLabels()
            
            // Calculate pace every minute
            if workout.timeElapsed % 60 == 0 || workout.pace == 0 {
                workout.pace = calculatePace(workout.timeElapsed, distance: workout.distance)
            }
        }
    }
    
    func counterPreRun() {
            
        playSound("Tick")
    
        preRoutineCountDownTime -= 1
        
        if preRoutineCountDownTime > 0 {
            
            threeMinuteCounterLabel.text = String(preRoutineCountDownTime)
            
        } else if preRoutineCountDownTime <= 0 {
            
            Constants.timer.invalidate()
    
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
        
        Constants.timer.invalidate()
        
        self.workout = Workout(workoutActivityType: .crossTraining, workoutType: .quickTimer)
        
        switchAppState()
    }
    
    func initializeRoutine(with routine: RoutineModel) {
    
        Constants.timer.invalidate()
        
        self.workout = Workout(workoutActivityType: .crossTraining, workoutType: .routine, routineModel: routine)
        
        switchAppState()
    }
    
    func initializeRunner() {
        
        Constants.timer.invalidate()
        
        self.workout = Workout(workoutActivityType: .running, workoutType: .run)
        
        locationManager.requestWhenInUseAuthorization()
        
        switchAppState()
    }
    
    //Function to set the view to initial stage
    func setToInitialState() {
        
        workout.routineIndex = 0
        workout.timeRemaining = workout.totalTime
        workout.timeElapsed = 0
        workout.distance = 0
        time = 0
        preRoutineCountDownTime = Constants.countdownTime
        
        locations.removeAll(keepingCapacity: false)
        
        if mapView.isDescendant(of: self.view) {
            
            let pointsArray = mapView.overlays
            mapView.removeOverlays(pointsArray)
        }
    
        workout.workoutState = Workout.WorkoutState.preRun
        buttonState = ButtonState.initial
    }

    //Function to change the state of routine, based on the currentTimerDict Value
    func changeStage() {
        
        if workout.routineStages.get(workout.routineIndex) != nil {
            
            workout.currentTimerDict = workout.routineStages[workout.routineIndex]
            time = workout.currentTimerDict["Time"] as! Int
            workout.timeRemaining = calculateTimeRemaining()
        }
        
        changeLabels()
        changeProgressBarAndStageLabelColor()
        switchButtonState()
    }
    
    func changeLabels() {
        
        if workout.workoutType == .routine || workout.workoutType == .quickTimer {
            
            countDownLabel.text = Functions.timeStringFrom(time: time)
            leftBottomLabel.text = Functions.timeStringFrom(time: workout.timeElapsed)
            middleTopLabel.text = workout.currentTimerDict["Name"] as? String
            middleBottomLabel.text = workout.currentTimerDict["Interval"] as? String
            rightBottomLabel.text = Functions.timeStringFrom(time: workout.timeRemaining)
            
        } else if workout.workoutType == .run {
            
            leftBottomLabel.text = Functions.timeStringFrom(time: workout.timeElapsed)
            middleBottomLabel.text = Functions.timeStringFrom(time: Int(workout.pace * 3600))
            rightBottomLabel.text = distanceFormatter.string(fromDistance: workout.distance)
        }
    }
    
    func changeProgressBarAndStageLabelColor() {
        
        var stageColor: UIColor!
        
        if let currentTimerDictColor = workout.currentTimerDict["Color"] as? Data {
            
            stageColor = (NSKeyedUnarchiver.unarchiveObject(with: currentTimerDictColor) as? UIColor)!
            self.progressView.backgroundColor = stageColor
            middleTopLabel.textColor = stageColor
            // print(stageColor)
        }
    }
    
    func switchAppState() {
    
        setToInitialState()
        
        switch workout.workoutType {
            
        case .quickTimer, .routine:
            
            countDownLabel.isHidden = false
            
            if mapView.isDescendant(of: self.progressView) {
                
                mapView.removeFromSuperview()
            }
            
            leftTopLabel.text = NSLocalizedString("Left Side Label Text (Routine)", comment: "")
            rightTopLabel.text = NSLocalizedString("Right Side Label Text (Routine)", comment: "")
            
        case .run:
            
            countDownLabel.isHidden = true
            
            if !mapView.isDescendant(of: self.progressView) {
                self.LayoutMapView()
            }
            
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
        
        switch workout.workoutType {
            
        case .routine:
            
            if (workout.routineStages.get(workout.routineIndex - 1) != nil) {
                previousButton.isEnabled = true
            } else {
                previousButton.isEnabled = false
            }
            
            if (workout.routineStages.get(workout.routineIndex + 1) != nil) {
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
        
        for i in workout.routineIndex...workout.routineStages.count - 1 {
            
            let dictionary = workout.routineStages[i]
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
        
        if workout.workoutType == .routine || workout.workoutType == .quickTimer {
            
            switch (workout.currentTimerDict["Name"] as? String, workout.currentTimerDict["Interval"] as? String) {
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
                
                if workout.workoutType == .routine || workout.workoutType == .quickTimer {
                    
                    Functions.textToSpeech(currentStage)
                    
                } else if workout.workoutType == .run {
                    
                    Functions.textToSpeech(NSLocalizedString("Text-To-Speech Tracking Run Text", comment: ""))
                }
                
            } else {
                
                soundName = Constants.timerSound
                ext = ".wav"
            }
            
        case "Routine End":
            
            if Constants.timerSound == "Text-To-Speech" {
                
                if workout.workoutType == .quickTimer {
                    
                    Functions.textToSpeech(NSLocalizedString("Text-To-Speech Timer Ended", comment: ""))
                    
                } else {
                    
                    if workout.workoutType == .routine {
                        
                        Functions.textToSpeech(NSLocalizedString("Text-To-Speech Workout Complete Text", comment: ""))
                        
                    } else if workout.workoutType == .run {
                        
                        Functions.textToSpeech(NSLocalizedString("Text-To-Speech Run Complete Text", comment: ""))
                    }
                }
                
            } else {
                
                soundName = Constants.timerSound
                ext = ".wav"
            }
            
        case "Tick":
            
            if Constants.timerSound == "Text-To-Speech" {
                
                if workout.workoutState == .preRun {
                    
                    Functions.textToSpeech("\(preRoutineCountDownTime)")
    
                } else {
                    
                    if time > 59 {
                        Functions.textToSpeech(Functions.timeRemainingString(from: time), volumeOn: Constants.timeRemainingFeedbackState)
                    } else {
                        Functions.textToSpeech("\(time)")
                    }
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
        
        if workout.workoutState == .preRun {
            
            LayoutBurSubview()
            
            startTimer(selector: "counterPreRun")
        }
        
        // Send to delegate
        self.delegate.workoutDidBegin(timer: Constants.timer)
    }
    
    func startWorkout() {
        
        if workout.workoutState == .preRun {
            
            playSound("Routine Begin")
            
            // Set routine start time
            workout.routineStartDate = Date()
            print("start time \(workout.routineStartDate)")
            
            startTimer(selector: "counterRoutine")
            
            if workout.workoutType == .run {
                startLocationUpdates()
            }
            
            // Create an NSUserActivity
            Functions.createNSUserActivity(workout: self.workout, domainIdentifier: Constants.DomainIdentifier.routineIdentifier.rawValue)
        }
        
        if workout.workoutState == .paused {
            
            startTimer(selector: "counterRoutine")
            
            if workout.workoutType == .run {
                
                startLocationUpdates()
            }
        }
        
        workout.workoutState = .active
        buttonState = .play
        switchButtonState()
        
        // Handle connection loss when workout running
        
    }
    
    func checkSaveWorkout(_ completion: @escaping (Bool) -> ()) {
        
        guard workout.workoutState != .preRun else { return completion(false) }
        
        guard HKHealthStore.isHealthDataAvailable() else { return completion(false) }
        
        guard HealthKitHelper.sharedInstance.workoutAuthorizationStatus != HKAuthorizationStatus.notDetermined else {
            
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
        
        guard HealthKitHelper.sharedInstance.workoutAuthorizationStatus != HKAuthorizationStatus.sharingDenied else {
            
            SweetAlert().showAlert(NSLocalizedString("Alert: Authorize Chronic Save Workout Title Text", comment: ""), subTitle: NSLocalizedString("Alert: Authorize Chronic Save Workout Subtitle Text", comment: ""), style: AlertStyle.warning, dismissTime: nil, buttonTitle: NSLocalizedString("Cancel", comment: ""), buttonColor:UIColor.colorFromRGB(0xD0D0D0) , otherButtonTitle: NSLocalizedString("Settings", comment: ""), otherButtonColor: UIColor.colorFromRGB(0xAEDEF4)) { (isOtherButton) -> Void in
                
                if !isOtherButton {
                    
                    UIApplication.shared.open(Constants.settingsURL!, options: [:], completionHandler: { (success) in
                    })
                }
            }
            
            return
        }
        
        if workout.workoutType == .routine || workout.workoutType == .run {
            
            if workout.workoutState == .completed {
                
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
        
        guard workout.routineStartDate != nil && workout.routineEndDate != nil else { return }
        
        // Add workout to HealthKit
        HealthKitHelper.sharedInstance.saveRunningWorkout(workoutActivityType: workout.workoutActivityType, startDate: workout.routineStartDate, endDate: workout.routineEndDate, kiloCalories: nil, distance: workout.distance, completion: { (success, error) -> Void in

            DispatchQueue.main.async(execute: { () -> Void in
                
                if success {
                    
                    Functions.presentWhisper(with: "\(self.workout.workoutType) Saved")
                    
                    completion(true)
                    
                } else if error != nil {
                    
                    Functions.presentWhisper(with: "We were unable to save your \(self.workout.workoutType)")
                    
                    print("\(error)")
                    
                    completion(false)
                }
            })
        })
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "StopWorkoutSegueIdentifier" {
            
            self.stop()
        }
    }
}

// MARK: - TimerViewController Location Extension
extension TimerViewController: CLLocationManagerDelegate, MKMapViewDelegate {
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        for location in locations {
            
            let howRecent = location.timestamp.timeIntervalSinceNow
            
            if abs(howRecent) < 10 && location.horizontalAccuracy < 20 && workout.workoutState == .active {
                
                //update distance
                if self.locations.count > 0 {
                    workout.distance += location.distance(from: self.locations.last!)
                    
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
        
        if workout.workoutState == .preRun {
            
            let region = MKCoordinateRegionMake(userLocation.coordinate, MKCoordinateSpanMake(0.01, 0.01))
            mapView.setRegion(region, animated: true)
        }
    }
}

// MARK: - TimerViewController Ads Extension
extension TimerViewController: MPAdViewDelegate, MPInterstitialAdControllerDelegate {
    
    // MARK: MoPud Functions
    func displayBannerAds() {
        
        // && (LaunchKit.sharedInstance().currentUser?.isSuper() == false)
        if !Functions.isRemoveAdsUpgradePurchased() {
            
            var bannerID: String!
            var bannerSize: CGSize!
            
            if UI_USER_INTERFACE_IDIOM() == .phone {
                bannerID = "c023d0aea31c44d6a0698c8bb11cba4e"
                bannerSize = MOPUB_BANNER_SIZE
            }
            else {
                bannerID = "6c641c6d8e9b4f989cb81b950054c599"
                bannerSize = MOPUB_LEADERBOARD_SIZE
            }

            mopubBanner = MPAdView(adUnitId: bannerID, size: bannerSize)
            mopubBanner?.delegate = self
            
            adStackView.isHidden = false
            
            // Add it to the view
            guard let mopubBanner = mopubBanner else { return }
            adBannerView.addSubview(mopubBanner)
            
            // Loads the ad over the network
            mopubBanner.loadAd()
            
        } else {
            guard let mopubBanner = mopubBanner else { return }
            mopubBanner.removeFromSuperview()
            adStackView.isHidden = true
        }
    }
    
    func centerMoPubBannerAd(_ adView: MPAdView?, relativeToView: UIView?) {
        
        guard let adView = adView, let relativeToView = relativeToView, adBannerView.isDescendant(of: self.view) else { return }
        
        let size: CGSize = adView.adContentViewSize()
        let centeredX: CGFloat = (relativeToView.bounds.size.width - size.width) / 2
        adView.frame = CGRect(x: centeredX, y: 0, width: size.width, height: size.height)
        
        adStackViewHeightConstraint.constant = size.height
    }
    
    func adViewDidLoadAd(_ view: MPAdView!) {
        adStackView.isHidden = false
        centerMoPubBannerAd(view, relativeToView: self.view)
    }
    
    func adViewDidFail(toLoadAd view: MPAdView!) {
        adStackView.isHidden = true
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
