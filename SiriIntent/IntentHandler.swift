//
//  IntentHandler.swift
//  SiriIntent
//
//  Created by Ace Green on 9/4/16.
//  Copyright © 2016 Ace Green. All rights reserved.
//

import Foundation
import Intents
import ChronicKit

class IntentHandler: INExtension, INWorkoutsDomainHandling {
    
    var routines = [RoutineModel]()

    override func handler(for intent: INIntent) -> Any {
        // This is the default implementation.  If you want different objects to handle different intents,
        // you can override this and return the handler you want for that particular intent.
        
        // Load routines
        routines = loadRoutines()
        
        return self
    }
    
    // MARK: - INStartWorkoutIntentHandling
    public func resolveWorkoutName(for intent: INStartWorkoutIntent, with completion: @escaping (INSpeakableStringResolutionResult) -> Void) {
        
        print("resolveWorkoutName", intent.workoutName?.spokenPhrase)
        
        if routines.count > 0 {
            
            if let workoutName = intent.workoutName, let routine = routines.filter({ $0.name.lowercased() == workoutName.spokenPhrase.lowercased() }).first {
                
                print("workoutName resolved", workoutName)
                
                let resolvingString = INSpeakableString(identifier: "routine", spokenPhrase: routine.name, pronunciationHint: nil)
                
                completion(INSpeakableStringResolutionResult.success(with: resolvingString))
                
            } else {
                
                let speakableStringRoutines: [INSpeakableString] = routines.map({ INSpeakableString(identifier: "routines", spokenPhrase: $0.name, pronunciationHint: nil) })
                
                completion(INSpeakableStringResolutionResult.disambiguation(with: speakableStringRoutines))
            }
            
        } else {
            // TODO: Handle no routines
        }
    }
    
//    public func confirm(startWorkout intent: INStartWorkoutIntent, completion: @escaping (INStartWorkoutIntentResponse) -> Void) {
//        
//        // Verify workout exists and ready to be started
//        print("confirm workout")
//        
//        let userActivity = NSUserActivity(activityType: NSStringFromClass(INStartWorkoutIntent.self))
//        let response = INStartWorkoutIntentResponse(code: .ready, userActivity: userActivity)
//        completion(response)
//    }
    
    public func handle(intent: INStartWorkoutIntent, completion: @escaping (INStartWorkoutIntentResponse) -> Void) {
        
        // Implement app logic to start a workout
        var response: INStartWorkoutIntentResponse!

        if let workoutName = intent.workoutName {
            let workoutSpokenphrase = workoutName.spokenPhrase
            let userActivity = NSUserActivity(activityType: NSStringFromClass(INStartWorkoutIntent.self))
            userActivity.userInfo = ["workoutName": workoutSpokenphrase]
            
            response = INStartWorkoutIntentResponse(code: .continueInApp, userActivity: userActivity)
            
        } else {
            response = INStartWorkoutIntentResponse(code: .failureRequiringAppLaunch, userActivity: nil)
        }
        
        completion(response)
    }
    
    
    func handle(intent: INPauseWorkoutIntent, completion: @escaping (INPauseWorkoutIntentResponse) -> Void) {
        print(intent.workoutName)
    }
    
    func handle(intent: INEndWorkoutIntent, completion: @escaping (INEndWorkoutIntentResponse) -> Void) {
        print(intent.workoutName)
    }
    
    func handle(intent: INCancelWorkoutIntent, completion: @escaping (INCancelWorkoutIntentResponse) -> Void) {
        print(intent.workoutName)
    }
    
    func handle(intent: INResumeWorkoutIntent, completion: @escaping (INResumeWorkoutIntentResponse) -> Void) {
        print(intent.workoutName)
    }
    
    func loadRoutines() -> [RoutineModel] {
        
        // Get Routines from database
        do {
            
            return try DataAccess.sharedInstance.fetchRoutines(with: nil)
            
        } catch {
            // TO-DO: HANDLE ERROR
            
            return []
        }
    }
}

