//
//  RunTrackerInterfaceController.swift
//  Chronic
//
//  Created by Ace Green on 2015-10-15.
//  Copyright © 2015 Ace Green. All rights reserved.
//

import WatchKit
import Foundation
import MapKit
import CoreLocation
import HealthKit

class RunTrackerInterfaceController: WKInterfaceController, CLLocationManagerDelegate, HKWorkoutSessionDelegate {
    
    var workoutType = Constants.WorkoutType.run
    var workoutState = Constants.WorkoutEventType.preRun
    
    let workoutActivityType: HKWorkoutActivityType = HKWorkoutActivityType.running
    
    var timeElapsed: Int = 0
    
    var routineStartDate: Date!
    var routineEndDate: Date!
    
    lazy var locationManager: CLLocationManager = {
        var locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        // Movement threshold for new events
        locationManager.distanceFilter = 5.0
        return locationManager
    }()
    
    lazy var locations = [CLLocation]()
    
    var distanceFormatter: MKDistanceFormatter = {
        let distanceFormatter = MKDistanceFormatter()
        //distanceFormatter.units = MKDistanceFormatterUnits.metric
        distanceFormatter.unitStyle = .abbreviated
        return distanceFormatter
    }()
    var distance = 0.0
    
    @IBOutlet var mapView: WKInterfaceMap!
    @IBOutlet var distanceLabel: WKInterfaceLabel!
    @IBOutlet var timeElapsedLabel: WKInterfaceLabel!
    
    @IBAction func PlayButtonPressed() {
        
        if !Constants.timer.isValid {
            
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
            
            startLocationUpdates()
            
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
        
        if workoutState == .active || workoutState == .pause {
            // Mark routine as completed
            workoutState = Constants.WorkoutEventType.complete
        }
        
        // End workout session if running
        Functions.endWorkoutSession()
        
        if workoutState == .complete {
            
            // Set end time
            routineEndDate = Date()
            print("end time \(routineEndDate)")
            
            // Save workout
            Functions.saveWorkout(interfaceController: self, workoutActivityType: workoutActivityType, startDate: self.routineStartDate, endDate: self.routineEndDate, kiloCalories: nil, distance: distance)
        }
        
        // Set to initial state
        setToInitialState()
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        setToInitialState()
        
        let status = CLLocationManager.authorizationStatus()
        if status == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else if status == .denied {
            let okAction = WKAlertAction(title: NSLocalizedString("Ok", comment: ""), style: WKAlertActionStyle.default, handler: { })
            
            self.presentAlert(withTitle: "Alert: Location Authorization Title Text", message: "Alert: Location Authorization Subtitle Text", preferredStyle: WKAlertControllerStyle.actionSheet, actions: [okAction])
        }
        
        locationManager.requestLocation()
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    //Function to start exercise timer
    func startTimer() {
        Constants.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(RunTrackerInterfaceController.countUp) , userInfo: nil, repeats: true)
    }
    
    func startLocationUpdates() {
        
        let status = CLLocationManager.authorizationStatus()
        
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            
            locationManager.startUpdatingLocation()
        }
    }
    
    //Timer Function
    func countUp() {
        timeElapsed += 1
        changeLabels()
    }
    
    func changeLabels() {
        timeElapsedLabel.setText(Functions.timeStringFrom(time: timeElapsed))
        distanceLabel.setText(distanceFormatter.string(fromDistance: distance))
    }
    
    func playFeedback (_ type: String) {
        
        var hapticType: WKHapticType!
        
        switch type {
            
        case "Routine Begin":
            
            hapticType = WKHapticType.start
            
        case "Routine End":
            
            hapticType = WKHapticType.success
            
        default:
            
            hapticType = WKHapticType.directionUp
            
        }
        
        WKInterfaceDevice.current().play(hapticType)
    }
    
    func setToInitialState() {
        
        // nil timer if exists
        Constants.timer.invalidate()
        
        // Stop location request if running
        locationManager.stopUpdatingLocation()
        
        timeElapsed = 0
        distance = 0.0
        locations.removeAll(keepingCapacity: false)
        
        workoutState = Constants.WorkoutEventType.preRun
        
        changeLabels()
    }
    
    // MARK: HKWorkoutSessionDelegate
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        switch toState {
        case .running:
            print("Workout didChangeTo running")
        case .ended:
            print("Workout didChangeTo ended")
        default:
            print("state \(toState.hashValue)")
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("workout session failed: \(error)")
    }
    
    // MARK: Location Manager delegates
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        for location in locations {
            
            let howRecent = location.timestamp.timeIntervalSinceNow
            
            if abs(howRecent) < 10 && location.horizontalAccuracy < 20 && workoutState == .active {
                
                //update distance
                if self.locations.count > 0 {
                    distance += location.distance(from: self.locations.last!)
                    self.distanceLabel.setText(distanceFormatter.string(fromDistance: distance))
                    
                    
                    let region = MKCoordinateRegion(center: location.coordinate, span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1))
                    mapView.setRegion(region)
                }
            }
                
            //save location
            self.locations.append(location)
            print(distance)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
}
