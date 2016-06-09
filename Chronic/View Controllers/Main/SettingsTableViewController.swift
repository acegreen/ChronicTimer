//
//  SettingsTableViewController.swift
//  Chronic
//
//  Created by Ace Green on 2015-04-28.
//  Copyright (c) 2015 Ace Green. All rights reserved.
//

import UIKit
import MessageUI
import HealthKit
import LaunchKit

class SettingsTableViewController: UITableViewController {
    
    var emailTitle: String!
    var messageBody: String!
    var toReceipients: [String]!
    
    @IBOutlet var timerSoundDetailTextField: UITextField!
    @IBOutlet var timerVolumeSlider: UISlider!
    @IBOutlet var enableDeviceSleepSwitch: UISwitch!
    @IBOutlet var runInBackgroundSwitch: UISwitch!
    @IBOutlet var notificationSwitch: UISwitch!
    @IBOutlet var notificationIntervalTextfield: NotificationIntervalTextField!
    @IBOutlet var notificationTimeTextfield: NotificationTimeTextField!
    
    @IBOutlet var appVersionLabel: UILabel!
    
    @IBAction func timerVolumeSlider(sender: UISlider) {
        
        timerVolume = timerVolumeSlider.value
        
        userDefaults.setFloat(timerVolumeSlider.value, forKey: "TIMER_VOLUME")
        
        userDefaults.synchronize()
    }
    
    @IBAction func enableDeviceSleepSwitchChanged(sender: UISwitch) {
        
        if !sender.on {
            
        userDefaults.setBool(false, forKey: "ENABLE_DEVICE_SLEEP")
            
        } else if sender.on {
                
            userDefaults.setBool(true, forKey: "ENABLE_DEVICE_SLEEP")
        }
        
        userDefaults.synchronize()
        
        enableDeviceSleepState = userDefaults.boolForKey("ENABLE_DEVICE_SLEEP") as Bool
        
        UIApplication.sharedApplication().idleTimerDisabled = !enableDeviceSleepState
        
    }
    
    @IBAction func runInBackgroundSwitchChanged(sender: UISwitch) {
        
        if !sender.on {
            
            userDefaults.setBool(false, forKey: "RUN_IN_BACKGROUND")
            
        } else if sender.on {
            
            userDefaults.setBool(true, forKey: "RUN_IN_BACKGROUND")
        }
        
        userDefaults.synchronize()
        runInBackgroundState = userDefaults.boolForKey("RUN_IN_BACKGROUND") as Bool
        
    }
    
    @IBAction func notificationSwitchChanged(sender: UISwitch) {
        userDefaults.setBool(sender.on, forKey: "NOTIFICATION_REMINDER_ENABLED")
        userDefaults.synchronize()
        self.tableView.reloadData()
        
        notificationReminderState = userDefaults.boolForKey("NOTIFICATION_REMINDER_ENABLED") as Bool
        NotificationHelper.updateNotificationPreferences(notificationReminderState)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        // Add Observers
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: "setProFeaturesDefaultSettings",name:"SetProFeatureDefaultSettings", object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        
        super.viewWillAppear(true)
        
        timerSoundDetailTextField.text = timerSound
        timerVolumeSlider.value = timerVolume
        enableDeviceSleepSwitch.on = enableDeviceSleepState
        runInBackgroundSwitch.on = runInBackgroundState
        notificationSwitch.on = notificationReminderState
        notificationIntervalTextfield.text = NotificationHelper.interval
        notificationTimeTextfield.text = String(NotificationHelper.hour) + ":00"
        appVersionLabel.text = payloadShort

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setProFeaturesDefaultSettings() {
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
        
            self.runInBackgroundSwitch.on = true
            self.runInBackgroundSwitchChanged(self.runInBackgroundSwitch)
            self.enableDeviceSleepSwitch.on = false
            self.enableDeviceSleepSwitchChanged(self.enableDeviceSleepSwitch)
            
        })
    }
    
    // MARK: - TableView Functions
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        
        cell.backgroundColor = UIColor.clearColor()
    }
    
    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        if let view = view as? UITableViewHeaderFooterView {
            
            view.textLabel!.textColor = UIColor.whiteColor()
            
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (section == 0) {
            return 4
        } else if (section == 1) {
            return 4
        } else if (section == 2) {
            if userDefaults.boolForKey("NOTIFICATION_REMINDER_ENABLED") {
                return 3
            } else {
                return 1
            }
        } else {
            return 3
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        guard let reuseIdentifier = tableView.cellForRowAtIndexPath(indexPath)?.reuseIdentifier else { return }
        
        switch reuseIdentifier {
            
        case "TimerSoundCell":
            
            timerSoundDetailTextField.becomeFirstResponder()
            
        case "WriteAReviewCell":
            
            if isConnectedToNetwork() {
                
                appDel.window?.rootViewController?.performSegueWithIdentifier("FeedbackSegueIdentifier", sender: self)
                
            } else {
                
                SweetAlert().showAlert(NSLocalizedString("Alert: No Internet Connection Title Text", comment: ""), subTitle: NSLocalizedString("Alert: No Internet Connection Subtitle Text", comment: ""), style: AlertStyle.Warning)
            }
            
        case "EmailUsCell":
            
            if MFMailComposeViewController.canSendMail() {
                
                let mc: MFMailComposeViewController = MFMailComposeViewController()
                
                mc.mailComposeDelegate = self
                
                emailTitle = "Chronic Feedback/Bug"
                messageBody = "Hello Chronic Team, </br> </br> </br> </br> </br> - - - - - - - - - - - - - - - - - - - - - </br>" + emailDiagnosticInfo
                toReceipients = [appEmail]
                
                mc.setSubject(emailTitle)
                mc.setMessageBody(messageBody, isHTML: true)
                mc.setToRecipients(toReceipients)
                
                self.presentViewController(mc, animated: true, completion: nil)
                
            } else {
                
                SweetAlert().showAlert(NSLocalizedString("Alert: No Email Account Title Text", comment: ""), subTitle: NSLocalizedString("Alert: No Email Account Subtitle Text", comment: ""), style: AlertStyle.Warning, dismissTime: nil, buttonTitle: NSLocalizedString("Ok", comment: ""), buttonColor:UIColor.colorFromRGB(0xD0D0D0) , otherButtonTitle: nil, otherButtonColor: nil) { (isOtherButton) -> Void in
                    
                }
            }
            
        case "UltimatePackageCell":
            
            IAPHelper.sharedInstance.selectProduct(iapUltimatePackageKey)
            
        case "ProVersionCell":
            
            IAPHelper.sharedInstance.selectProduct(proVersionKey)
            
        case "RemoveAdsCell":
            
            IAPHelper.sharedInstance.selectProduct(removeAdsKey)
            
        case "DonateCell":
            
            IAPHelper.sharedInstance.selectProduct(donate99Key)
            
        case "RestoreUpgradesCell":
            
            IAPHelper.sharedInstance.restorePurchases()
            
        case "NotificationIntervalCell":
            
            notificationIntervalTextfield.becomeFirstResponder()
            
        case "NotificationTimeCell":
            
            notificationTimeTextfield.becomeFirstResponder()
            
        case "FAQCell":
            
            if isConnectedToNetwork() {
                
                self.performSegueWithIdentifier("FAQSegueIdentifier", sender: self)
                
            } else {
                
                SweetAlert().showAlert(NSLocalizedString("Alert: No Internet Connection Title Text", comment: ""), subTitle: NSLocalizedString("Alert: No Internet Connection Subtitle Text", comment: ""), style: AlertStyle.Warning)
            }
            
        default:
            break
        }
    }
}

// MARK: - Email Delegate
extension SettingsTableViewController: MFMailComposeViewControllerDelegate {
    
    
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        
        switch result.rawValue {
            
        case MFMailComposeResultCancelled.rawValue:
            
            print("Mail Cancelled")
            
        case MFMailComposeResultSaved.rawValue:
            
            print("Mail Saved")
            
        case MFMailComposeResultSent.rawValue:
            
            print("Mail Sent")
            
        case MFMailComposeResultFailed.rawValue:
            
            print("Mail Failed")
            
        default:
            
            return
            
        }
        
        self.dismissViewControllerAnimated(true, completion: nil)
        
    }
    
}
