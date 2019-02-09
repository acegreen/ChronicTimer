# CHANGE LOG

- [x] Create promotional video 
- [x] Promote app in various sites

## Version 1.0:
- [x] Add settings page

## Version 1.0.1:
- [x] Pause/Stop bug
- [x] Fix Label size on IPad when timer is in hours
- [x] Fix number of rounds issue
- [x] Enable sleep and pause in background settings added
- [x] Add remaining and elapsed time
- [x] Add buzzer sound at the end of stages
- [x] Make countdown show from the get-go 

## Version 2.0:
- [x] Remove start button and set timer label at routine start
- [x] Add Apple Watch integration
- [x] Pre routine warning 3 second timer
- [x] Create custom UIPickerView with seconds
- [x] Allow editing and moving of Routines
- [x] Quick timer feature
- [x] Different color progress bar
- [x] Upgrade UElements
- [x] Fix label truncation or limit routine name length
- [x] Auto size countdown label for maximum size 
- [x] LocalNotification for background with sound and alert body 
- [x] 3 seconds drawdown beeper at the end of each stage 
- [x] Remind user to review app 
- [x] Add iAds 
- [x] Quick Timer is selected by default when no routines are available
- [x] A new slider for quick timer when no routines are available (Apple Watch) 
- [x] Fix bug when pressing routine button on iPhone with no routines
- [x] Fix bug on apple watch when no routines is selected 

## Version 2.0.1:
- [x] Fix bug on apple watch where quick timer crashes at the end

## Version 2.1:
- [x] HealthKit Integration
- [x] Kiip Rewards Integration [REMOVED]
- [x] Add Google iOS app indexing [REMOVED]

## Version 2.2:
- [x] Add custom routines 
- [x] Add pickers for watch quick timer
- [x] Add haptic feedback for Apple Watch
- [x] Workout Sessions for Apple Watch
- [x] Use connectivity API to transfer routines to Apple Watch
- [x] Integrate with search API
- [x] Text-To-Speech feedback

## Version 2.2.1:
- [x] Fix routine type buttons location in portrait
- [x] HKWorkoutSession for AppleWatch

## Version 2.2.2:
- [x] Fix Apple Watch timer issue
- [x] Fixed keyboard going over UITableView 
- [x] Add in-app purchase (pro ## Version & remove ads)
- [x] Quick timer shouldn't count towards workout

## Version 2.3: 
- [x] Fix popup view issue
- [x] Add exercise  number of rounds and colours for custom routines

## Version 2.4 - 2.4.1:
- [x] Fix issues related to in app pro ## Version purchase
- [x] Fix exercise colours not displaying properly on Apple Watch

## Version 2.4.2:
- [x] Kiip reward after each workout [REMOVED]
- [x] Add push notification  
- [x] Fix crash on settings page related to in-app purchases 
- [x] Increase exercise number to 200 (thanks for the feedback Brick S)
- [x] Add donation button
- [x] Fix pause button on iOS 
- [x] Fix run tracker not resetting overlay 

## Version 2.4.3:
- [x] Receipt validation
- [x] Show in-app purchase prices before purchase (on alert popup)
- [x] Setting to remove Kiip rewards if you bought remove ads upgrade
- [x] Fix app badge not going away on app launch
- [x] Fix notification not showing for Quick Timer
- [x] Fix answers purchase flag

## Version 2.4.4:
- [x] No internet connect alert for “write a review” cell
- [x] Replace JBCBlurView with UIVisualEffectView
- [x] Make “Run in background” & “Enable Device Sleep” Pro Features.
- [x] Add installationID in Answers.Log event
- [x] Add Home Quick Actions
- [x] Add LaunchKit SDK + What’s New Popup
- [x] Add animation for feedback and Kiip rewards

## Version 2.5.0:
- [x] Add Ultimate Package bundle (Pro Features + Remove Ads)
- [x] Add reminder feature in settings
- [x] Add on boarding process
- [x] Fix re-save not adding routines on Watch
- [x] Fix workoutSession not ended when view is closed with a routine running
- [x] Fix end time when in background
- [x] Fix crashes caused when saving workout when routine paused
- [x] Replace Text-To-Speech special characters i.e “/“ should say “of” 
- [x] Replace Kiip rewards with AdColony
- [x] Add localization for (DE, IT, Chinese)
- [x] Add FAQ in settings

## Version 2.5.1:
- [x] Only allow review after 5 events
- [x] Make "run in background" & "device sleep" settings default options
- [x] Fix FAQ page
- [x] Improve guard and present statements to user when sending context to Watch 
- [x] Fix duplicated reminder notification 
- [x] Add SuperUser features

## Version 3.0:
- [x] Redesign UI
- [x] Add lock button/feature
- [x] Add forward/rewind to exercises
- [x] Add distance to HKWorkout
- [x] Fix custom routine save bug
- [x] Softer timer sounds

## Version 3.0.1:
- [x] Switch from Appodeal to MoPub
- [x] Fix nuisance watch app alert

## Version 3.1:
- [x] Add watch notification for when workout completes in background 
- [x] Upgrade to Swift 3
- [x] Update screenshots 
- [x] Super user view close button missing
- [x] Migrate Parse Database to server
- [x] Add interval stage in voice over
- [x] Add Pace to runs
- [x] Use Reachability framework instead of self-made solution
- [x] Create NSUserActivity during workouts
- [x] Make Core data model and NSManagedObjects a framework shared between targets
- [x] Migrate Core Data Store to shared group location
- [x] Adapt SiriKit (basic implementation)
- [x] Add social links to settings
- [x] Localize Apple Watch app
- [x] Check internet connection during workout to ensure you are connected
- [x] Rename Pro Features upgrade to Apple Watch (Update iTunes connect in-app purchase, localization info)
- [x] Upgrade in-app purchases UI - use carousel to present the products
- [x] Remove Pro Upgrade requirement on runner & custom routine features
- [x] Update notifications to iOS 10 (UNNotifications)
- [x] Adapt Constants & Functions classes for generic constants and functions
- [x] Raise in-app purchases back up ($2.99 x twice & $4.99) 
- [x] Move Onboarding to its own Storyboard
- [x] Move Feedback flow to its own Storyboard
- [x] Clean up project structure
- [x] Redesign interface especially remaining/elapsed section
- [x] Resolve crash caused by IAP bug when a purchase is left-over

## Version 3.1.1:
- [x] Re-enable Bitcode support (for main target)
- [x] Fix crash caused by countryCode during iRateDidOpenAppStore() call
- [x] Fix haptic feedback not working in background

## Version 3.1.2:
- [x] Update push certificates
- [x] Save prompt only if HealthKit permission is given
- [x] Fix Feedback animation
- [x] Background task only if routine is running
- [x] Fix backgroundTask ending
- [x] Disable Device sleep & run in background if remove ads isn’t purchased
- [x] Add sound at every minute in addition to the 3 second count down before a stage end
- [x] Add Workout logging to Answers
- [x] Setting for countdown time (in settings page - routine section)
- [x] Add a time remaining feature with settings option
- [x] Update Remove Ads IAP description to reflect new features

## Version 3.1.3:
- [x] Add Support for Facebook Audience Network ads
- [x] Update Charts library to 3.0.0
- [x] Support Rollout.io Swift ## Version
- [x] Add Support for AdColony ads (v2.6.2 for now)

## Version 3.1.4:
- [x] Fix crash -[NSLayoutConstraint _addToEngine:integralizationAdjustment:mutuallyExclusiveConstraints:] [MAYBE FIXED]
- [x] Add basic complication to watch app
- [x] Fix workout logging for “runs” counted even with workout in preRun mode
- [x] Integrate Chartboost
- [x] Integrate Flurry 
- [x] Integrate Vungle
- [x] Integrate LifeStreet

## Version 3.1.5:
- [x] Fix crash -[NSLayoutConstraint _addToEngine:integralizationAdjustment:mutuallyExclusiveConstraints:] [AGAIN]
- [x] Fix crash RoutinesTableViewController.swift line 0
specialized RoutinesTableViewController.tableView(UITableView, cellForRowAt : IndexPath) -> UITableViewCell
- [x] Flip “remaining” & “elapsed” time labels on watch app to match iOS app
- [x] Update Cocoapods

## Version 3.1.6:
- [x] Continue fixing crashes related to AdView presentation
- [x] Remove Rollout.io dependency
- [x] Increment event count only if workout > 60s
- [x] Update Parse server
- [x] Update Cocoapods

## Version 3.1.7:
- [x] Fixes minor UI glitch on TimerViewController
- [x] Supports Apples review framework 

## Version 3.1.8:
- [x] Update to Swift 4.2
- [x] Adds support for new iPhones

## Version 3.1.9:
- [x] Fixes a crash introduced in 3.1.8 during refactoring
