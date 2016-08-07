//
//  ExtensionDelegate.swift
//  Chronic WatchKit Extension
//
//  Created by Ace Green on 2015-07-18.
//  Copyright © 2015 Ace Green. All rights reserved.
//

import WatchKit
import CoreData
import WatchConnectivity

class ExtensionDelegate: NSObject, WKExtensionDelegate, WCSessionDelegate {

    func applicationDidFinishLaunching() {
        
        // setup user defaults
        //userDefaults.registerDefaults(defaultPrefs as! [String : AnyObject])
        
        Constants.keychainProVersionString = Constants.keychain[Constants.proVersionKey]
        
        // Request HealthKit Authorization
        HealthKitHelper.sharedInstance.authorizeHealthKit { (authorized,  error) -> Void in
            if authorized {
                
                print("HealthKit authorization received.")
                
            } else {
                
                if error != nil {
                    print("\(error)")
                }
            }
        }
        
        // Setup WCSession
        Constants.wcSession = WCSession.default()
        Constants.wcSession.delegate = self
        Constants.wcSession.activate()
    }

    func applicationDidBecomeActive() {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillResignActive() {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, etc.
    }
    
    // =========================================================================
    // MARK: - WCSessionDelegate
    
    @available(watchOSApplicationExtension 2.2, *)
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("session activationDidCompleteWith")
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : AnyObject]) {
        
        print("Context received")
        
        if applicationContext["contextType"] as! String == "RoutineAdded" {
            
            Functions.insertCoreDataObject(appContext: applicationContext)
            
        } else if applicationContext["contextType"] as! String == "RoutineModified" {
            
            Functions.modifyCoreDataObject(appContext: applicationContext)
            
        } else if applicationContext["contextType"] as! String == "RoutineDeleted" {
            
            Functions.deleteCoreDataObject(appContext: applicationContext)
            
        } else if applicationContext["contextType"] as! String == "PurchasedProVersion" {
            
            // Set KeyChain Value
            do {
                try Constants.keychain
                    .accessibility(accessibility: .Always)
                    .synchronizable(synchronizable: true)
                    .set(value: Constants.proVersionKeyValue, key: Constants.proVersionKey)
            } catch let error {
                print("error: \(error)")
            }
            
            Constants.keychainProVersionString = Constants.keychain[Constants.proVersionKey]
        }
        
    }
}
