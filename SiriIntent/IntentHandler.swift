//
//  IntentHandler.swift
//  SiriIntent
//
//  Created by Ace Green on 9/4/16.
//  Copyright © 2016 Ace Green. All rights reserved.
//

import Intents

class IntentHandler: INExtension, INStartWorkoutIntentHandling, INPauseWorkoutIntentHandling, INResumeWorkoutIntentHandling, INCancelWorkoutIntentHandling, INEndWorkoutIntentHandling {

    override func handler(for intent: INIntent) -> Any {
        // This is the default implementation.  If you want different objects to handle different intents,
        // you can override this and return the handler you want for that particular intent.
        
        return self
    }
    
    // MARK: - INStartWorkoutIntentHandling
    public func resolveWorkoutName(forStartWorkout intent: INStartWorkoutIntent, with completion: @escaping (INSpeakableStringResolutionResult) -> Void) {
        
        print("resolveWorkoutName")
        
        let speakableStringRoutine = INSpeakableString(identifier: "identifier", spokenPhrase: "Test", pronunciationHint: nil)
        let speakableStringQuickTimer = INSpeakableString(identifier: "identifier", spokenPhrase: "Quick Timer", pronunciationHint: "Quick")
        let speakableStringRun = INSpeakableString(identifier: "identifier", spokenPhrase: "Run", pronunciationHint: nil)
        
        if let workoutName = intent.workoutName, let spokenPhrase = workoutName.spokenPhrase, (spokenPhrase == speakableStringRoutine.spokenPhrase || spokenPhrase == speakableStringQuickTimer.spokenPhrase || spokenPhrase == speakableStringRun.spokenPhrase) {
            
            print("workoutName resolved")
            
            completion(INSpeakableStringResolutionResult.success(with: workoutName))
            
        } else {
            
            completion(INSpeakableStringResolutionResult.disambiguation(with: [speakableStringRoutine, speakableStringQuickTimer, speakableStringRun]))
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
    
    public func handle(startWorkout intent: INStartWorkoutIntent, completion: @escaping (INStartWorkoutIntentResponse) -> Void) {
        
        // Implement app logic to start a workout
        if let workoutName = intent.workoutName, let workoutNameSpokenPhrase = workoutName.spokenPhrase {
            let userActivity = NSUserActivity(activityType: NSStringFromClass(INStartWorkoutIntent.self))
            userActivity.userInfo = ["workoutName": workoutNameSpokenPhrase]
            let response = INStartWorkoutIntentResponse(code: .continueInApp, userActivity: userActivity)
            completion(response)
        }
    }
    
    // MARK: - INPauseWorkoutIntentHandling
    public func handle(pauseWorkout intent: INPauseWorkoutIntent, completion: @escaping (INPauseWorkoutIntentResponse) -> Void) {
        
    }
    
    // MARK: - INResumeWorkoutIntentHandling
    public func handle(resumeWorkout intent: INResumeWorkoutIntent, completion: @escaping (INResumeWorkoutIntentResponse) -> Void) {
        
        
    }
    
    // MARK: - INCancelWorkoutIntentHandling
    public func handle(cancelWorkout intent: INCancelWorkoutIntent, completion: @escaping (INCancelWorkoutIntentResponse) -> Void) {
        
        
    }

    // MARK: - INEndWorkoutIntentHandling
    public func handle(endWorkout intent: INEndWorkoutIntent, completion: @escaping (INEndWorkoutIntentResponse) -> Void) {
        
        
    }
}

