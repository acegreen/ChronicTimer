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
    
    var workout: Workout!
    
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
    
    @IBOutlet var mapView: WKInterfaceMap!
    @IBOutlet var distanceLabel: WKInterfaceLabel!
    @IBOutlet var timeElapsedLabel: WKInterfaceLabel!
    
    @IBAction func PlayButtonPressed() {
        
        if !Constants.timer.isValid {
            
            if workout.workoutState == .preRun {
                
                playFeedback("Routine Begin")
                
                // Set routine start time
                workout.routineStartDate = Date()
                print("start time \(workout.routineStartDate)")
                
                // Start workout session
                Functions.startWorkSession(delegateInterfaceController: self, workoutActivityType: workout.workoutActivityType)
                
            } else {
                Functions.resumeWorkSession()
            }
            
            startLocationUpdates()
            
            startTimer()
            workout.workoutState = .active
        }
    }
    
    @IBAction func PauseButtonPressed() {
        
        Constants.timer.invalidate()
        
        workout.workoutState = .paused
        
        Functions.pauseWorkSession()
    }
    
    @IBAction func StopButtonPressed() {
        
        if workout.workoutState == .active || workout.workoutState == .paused {
            // Mark routine as completed
            workout.workoutState = .completed
        }
        
        // End workout session if running
        Functions.endWorkoutSession()
        
        if workout.workoutState == .completed {
            
            // Set end time
            workout.routineEndDate = Date()
            print("end time \(workout.routineEndDate)")
            
            // Save workout
            Functions.saveWorkout(interfaceController: self, workoutActivityType: workout.workoutActivityType, startDate: workout.routineStartDate, endDate: workout.routineEndDate, kiloCalories: nil, distance: workout.distance)
        }
        
        // Set to initial state
        setToInitialState()
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        self.workout = Workout(workoutActivityType: .running, workoutType: .run)
        
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
        workout.timeElapsed += 1
        changeLabels()
    }
    
    func changeLabels() {
        timeElapsedLabel.setText(Functions.timeStringFrom(time: workout.timeElapsed))
        distanceLabel.setText(distanceFormatter.string(fromDistance: workout.distance))
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
        
        workout.timeElapsed = 0
        workout.distance = 0.0
        locations.removeAll(keepingCapacity: false)
        
        workout.workoutState = .preRun
        
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
            
            if abs(howRecent) < 10 && location.horizontalAccuracy < 20 && workout.workoutState == .active {
                
                //update distance
                if self.locations.count > 0 {
                    workout.distance += location.distance(from: self.locations.last!)
                    self.distanceLabel.setText(distanceFormatter.string(fromDistance: workout.distance))
                    
                    
                    let region = MKCoordinateRegion(center: location.coordinate, span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1))
                    mapView.setRegion(region)
                }
            }
                
            //save location
            self.locations.append(location)
            print(workout.distance)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
}
