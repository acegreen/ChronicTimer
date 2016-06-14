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

class RunTrackerInterfaceController: WKInterfaceController, CLLocationManagerDelegate {
    
    lazy var locationManager: CLLocationManager = {
        var locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        // Movement threshold for new events
        locationManager.distanceFilter = 5.0
        return locationManager
        }()
    
    lazy var locations = [CLLocation]()
    var distance = 0.0
    
    @IBOutlet var mapView: WKInterfaceMap!
    @IBOutlet var distanceLabel: WKInterfaceLabel!
    @IBOutlet var timeLabel: WKInterfaceLabel!

    override func awake(withContext context: AnyObject?) {
        super.awake(withContext: context)
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        let status = CLLocationManager.authorizationStatus()
        if status == .notDetermined || status == .denied {
            // present an alert indicating location authorization required
            // and offer to take the user to Settings for the app via
            // UIApplication -openUrl: and UIApplicationOpenSettingsURLString
            locationManager.requestWhenInUseAuthorization()
            
        } else if status == .authorizedWhenInUse || status == .authorizedAlways {
            
            
        }
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        for location in locations {
            //update distance
            if self.locations.count > 0 {
                distance += location.distance(from: self.locations.last!)
                
                let distanceFormatter = MKDistanceFormatter()
                distanceFormatter.units = MKDistanceFormatterUnits.metric
                distanceFormatter.unitStyle = MKDistanceFormatterUnitStyle.default
                self.distanceLabel.setText(distanceFormatter.string(fromDistance: distance))
                
                let region = MKCoordinateRegion(center: location.coordinate, span: MKCoordinateSpan(latitudeDelta: 100, longitudeDelta: 100))
                mapView.setRegion(region)
            }
            
            //save location
            self.locations.append(location)
            print(locations)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: NSError) {
        
        print(error)
        
    }
}
