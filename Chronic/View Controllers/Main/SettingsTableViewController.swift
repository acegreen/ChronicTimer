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
    
    @IBAction func unwindToSettingsViewController(_ segue: UIStoryboardSegue) {
        
    }
    
    @IBOutlet var timerSoundDetailTextField: UITextField!
    @IBOutlet var timerVolumeSlider: UISlider!
    @IBOutlet var enableDeviceSleepSwitch: UISwitch!
    @IBOutlet var runInBackgroundSwitch: UISwitch!
    @IBOutlet var notificationSwitch: UISwitch!
    @IBOutlet var notificationIntervalTextfield: NotificationIntervalTextField!
    @IBOutlet var notificationTimeTextfield: NotificationTimeTextField!
    
    @IBOutlet var appVersionLabel: UILabel!
    
    @IBAction func timerVolumeSlider(_ sender: UISlider) {
        
        Constants.timerVolume = timerVolumeSlider.value
        
        Constants.userDefaults.set(timerVolumeSlider.value, forKey: "TIMER_VOLUME")

    }
    
    @IBAction func enableDeviceSleepSwitchChanged(_ sender: UISwitch) {
        
        if !sender.isOn {
            
            Constants.userDefaults.set(false, forKey: "ENABLE_DEVICE_SLEEP")
            
        } else if sender.isOn {
                
            Constants.userDefaults.set(true, forKey: "ENABLE_DEVICE_SLEEP")
        }
                
        Constants.enableDeviceSleepState = Constants.userDefaults.bool(forKey: "ENABLE_DEVICE_SLEEP") as Bool
        
        UIApplication.shared.isIdleTimerDisabled = !Constants.enableDeviceSleepState
        
    }
    
    @IBAction func runInBackgroundSwitchChanged(_ sender: UISwitch) {
        
        if !sender.isOn {
            
            Constants.userDefaults.set(false, forKey: "RUN_IN_BACKGROUND")
            
        } else if sender.isOn {
            
            Constants.userDefaults.set(true, forKey: "RUN_IN_BACKGROUND")
        }
        
        Constants.runInBackgroundState = Constants.userDefaults.bool(forKey: "RUN_IN_BACKGROUND") as Bool
        
    }
    
    @IBAction func notificationSwitchChanged(_ sender: UISwitch) {
        Constants.userDefaults.set(sender.isOn, forKey: "NOTIFICATION_REMINDER_ENABLED")
        
        Constants.notificationReminderState = Constants.userDefaults.bool(forKey: "NOTIFICATION_REMINDER_ENABLED") as Bool
        NotificationHelper.updateNotificationPreferences(Constants.notificationReminderState)
    
        self.tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        // Add Observers
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: "setProFeaturesDefaultSettings",name:"SetProFeatureDefaultSettings", object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(true)
        
        timerSoundDetailTextField.text = Constants.timerSound
        timerVolumeSlider.value = Constants.timerVolume
        enableDeviceSleepSwitch.isOn = Constants.enableDeviceSleepState
        runInBackgroundSwitch.isOn = Constants.runInBackgroundState
        notificationSwitch.isOn = Constants.notificationReminderState
        notificationIntervalTextfield.text = NotificationHelper.interval
        notificationTimeTextfield.text = String(NotificationHelper.hour) + ":00"
        appVersionLabel.text = Constants.payloadShort

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setProFeaturesDefaultSettings() {
        
        DispatchQueue.main.async(execute: { () -> Void in
        
            self.runInBackgroundSwitch.isOn = true
            self.runInBackgroundSwitchChanged(self.runInBackgroundSwitch)
            self.enableDeviceSleepSwitch.isOn = false
            self.enableDeviceSleepSwitchChanged(self.enableDeviceSleepSwitch)
            
        })
    }
    
    // MARK: - TableView Functions
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        cell.backgroundColor = UIColor.clear
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        if let view = view as? UITableViewHeaderFooterView {
            
            view.textLabel!.textColor = UIColor.white
            
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (section == 0) {
            return 4
        } else if (section == 1) {
            return 4
        } else if (section == 2) {
            if Constants.notificationReminderState == true {
                return 3
            } else {
                return 1
            }
        } else {
            return 3
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard let reuseIdentifier = tableView.cellForRow(at: indexPath)?.reuseIdentifier else { return }
        
        switch reuseIdentifier {
            
        case "TimerSoundCell":
            
            timerSoundDetailTextField.becomeFirstResponder()
            
        case "WriteAReviewCell":
            
            if Functions.isConnectedToNetwork() {
                
                iRate.sharedInstance().openRatingsPageInAppStore()
                
            } else {
                
                SweetAlert().showAlert(NSLocalizedString("Alert: No Internet Connection Title Text", comment: ""), subTitle: NSLocalizedString("Alert: No Internet Connection Subtitle Text", comment: ""), style: AlertStyle.warning)
            }
            
        case "EmailUsCell":
            
            if MFMailComposeViewController.canSendMail() {
                
                let mc: MFMailComposeViewController = MFMailComposeViewController()
                
                mc.mailComposeDelegate = self
                
                emailTitle = "Chronic Feedback/Bug"
                messageBody = "Hello Chronic Team, </br> </br> </br> </br> </br> - - - - - - - - - - - - - - - - - - - - - </br>" + Constants.emailDiagnosticInfo
                toReceipients = [Constants.appEmail]
                
                mc.setSubject(emailTitle)
                mc.setMessageBody(messageBody, isHTML: true)
                mc.setToRecipients(toReceipients)
                
                self.present(mc, animated: true, completion: nil)
                
            } else {
                
                SweetAlert().showAlert(NSLocalizedString("Alert: No Email Account Title Text", comment: ""), subTitle: NSLocalizedString("Alert: No Email Account Subtitle Text", comment: ""), style: AlertStyle.warning, dismissTime: nil, buttonTitle: NSLocalizedString("Ok", comment: ""), buttonColor:UIColor.colorFromRGB(0xD0D0D0) , otherButtonTitle: nil, otherButtonColor: nil) { (isOtherButton) -> Void in
                    
                }
            }
            
        case "UltimatePackageCell":
            
            IAPHelper.sharedInstance.selectProduct(Constants.iapUltimatePackageKey)
            
        case "ProVersionCell":
            
            IAPHelper.sharedInstance.selectProduct(Constants.proVersionKey)
            
        case "RemoveAdsCell":
            
            IAPHelper.sharedInstance.selectProduct(Constants.removeAdsKey)
            
        case "DonateCell":
            
            IAPHelper.sharedInstance.selectProduct(Constants.donate99Key)
            
        case "RestoreUpgradesCell":
            
            IAPHelper.sharedInstance.restorePurchases()
            
        case "NotificationIntervalCell":
            
            notificationIntervalTextfield.becomeFirstResponder()
            
        case "NotificationTimeCell":
            
            notificationTimeTextfield.becomeFirstResponder()
            
        case "FAQCell":
            
            if Functions.isConnectedToNetwork() {
                
                self.performSegue(withIdentifier: "FAQSegueIdentifier", sender: self)
                
            } else {
                
                SweetAlert().showAlert(NSLocalizedString("Alert: No Internet Connection Title Text", comment: ""), subTitle: NSLocalizedString("Alert: No Internet Connection Subtitle Text", comment: ""), style: AlertStyle.warning)
            }
            
        default:
            break
        }
    }
}

// MARK: - Email Delegate
extension SettingsTableViewController: MFMailComposeViewControllerDelegate {
    
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: NSError?) {
        
        switch result.rawValue {
            
        case MFMailComposeResult.cancelled.rawValue:
            
            print("Mail Cancelled")
            
        case MFMailComposeResult.saved.rawValue:
            
            print("Mail Saved")
            
        case MFMailComposeResult.sent.rawValue:
            
            print("Mail Sent")
            
        case MFMailComposeResult.failed.rawValue:
            
            print("Mail Failed")
            
        default:
            
            return
            
        }
        
        self.dismiss(animated: true, completion: nil)
        
    }
    
}
