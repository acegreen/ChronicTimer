//
//  SettingsTableViewController.swift
//  Chronic
//
//  Created by Ace Green on 2015-04-28.
//  Copyright (c) 2015 Ace Green. All rights reserved.
//

import UIKit
import StoreKit
import MessageUI
import HealthKit
import LaunchKit
import Crashlytics
import MZFormSheetPresentationController

class SettingsTableViewController: UITableViewController, Dimmable {
    
    var emailTitle: String!
    var messageBody: String!
    var toReceipients: [String]!
    
    @IBAction func unwindToSettingsViewController(_ segue: UIStoryboardSegue) {
        
    }
    
    @IBOutlet var timerSoundDetailTextField: UITextField!
    @IBOutlet var timerVolumeSlider: UISlider!
    @IBOutlet var enableDeviceSleepSwitch: UISwitch!
    @IBOutlet var runInBackgroundSwitch: UISwitch!
    @IBOutlet var timeRemainingFeedbackSwitch: UISwitch!
    @IBOutlet var countdownTimeTextfield: NumberPickerTextField!
    @IBOutlet var notificationSwitch: UISwitch!
    @IBOutlet var notificationIntervalTextfield: NotificationIntervalTextField!
    @IBOutlet var notificationTimeTextfield: NotificationTimeTextField!
    
    @IBOutlet var appVersionLabel: UILabel!
    
    @IBAction func timerVolumeSlider(_ sender: UISlider) {
        
        Constants.timerVolume = timerVolumeSlider.value
        
        Constants.userDefaults.set(timerVolumeSlider.value, forKey: "TIMER_VOLUME")

    }
    
    @IBAction func enableDeviceSleepSwitchChanged(_ sender: UISwitch) {
        
        guard Functions.isRemoveAdsUpgradePurchased() else {
            
            SweetAlert().showAlert(NSLocalizedString("Alert: Purchase Remove Ads Title Text", comment: ""), subTitle: NSLocalizedString("Alert: Purchase Remove Ads Subtitle Text", comment: ""), style: AlertStyle.warning)
            
            sender.isOn = false
            
            return
        }
        
        Constants.userDefaults.set(sender.isOn, forKey: "ENABLE_DEVICE_SLEEP")
                
        Constants.enableDeviceSleepState = Constants.userDefaults.bool(forKey: "ENABLE_DEVICE_SLEEP") as Bool
        
        UIApplication.shared.isIdleTimerDisabled = !Constants.enableDeviceSleepState
        
    }
    
    @IBAction func runInBackgroundSwitchChanged(_ sender: UISwitch) {
        
        guard Functions.isRemoveAdsUpgradePurchased() else {
            
            SweetAlert().showAlert(NSLocalizedString("Alert: Purchase Remove Ads Title Text", comment: ""), subTitle: NSLocalizedString("Alert: Purchase Remove Ads Subtitle Text", comment: ""), style: AlertStyle.warning)
            
            sender.isOn = false
            
            return
        }
        
        Constants.userDefaults.set(sender.isOn, forKey: "RUN_IN_BACKGROUND")
        Constants.runInBackgroundState = Constants.userDefaults.bool(forKey: "RUN_IN_BACKGROUND") as Bool
        
    }
    
    @IBAction func timeRemainingFeedbackSwitchChanged(_ sender: UISwitch) {
        
        Constants.userDefaults.set(sender.isOn, forKey: "TIME_REMAINING_FEEDBACK")
        Constants.timeRemainingFeedbackState = Constants.userDefaults.bool(forKey: "TIME_REMAINING_FEEDBACK") as Bool
    }

    @IBAction func countdownTimeTextfieldChanged(_ sender: UITextField) {
        
        Constants.userDefaults.set(Int(sender.text!), forKey: "COUNTDOWN_TIME")
        Constants.countdownTime = Constants.userDefaults.integer(forKey: "COUNTDOWN_TIME") as Int
    }
    
    @IBAction func notificationSwitchChanged(_ sender: UISwitch) {
        Constants.userDefaults.set(sender.isOn, forKey: "NOTIFICATION_REMINDER_ENABLED")
        
        Constants.notificationReminderState = Constants.userDefaults.bool(forKey: "NOTIFICATION_REMINDER_ENABLED") as Bool
        NotificationHelper.updateNotificationPreferences(Constants.notificationReminderState)
    
        self.tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        IAPHelper.sharedInstance.delegate = self
        
//        // Add Observers
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: "setProFeaturesDefaultSettings",name:"SetProFeatureDefaultSettings", object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(true)
        
        timerSoundDetailTextField.text = Constants.timerSound
        timerVolumeSlider.value = Constants.timerVolume
        enableDeviceSleepSwitch.isOn = Constants.enableDeviceSleepState
        runInBackgroundSwitch.isOn = Constants.runInBackgroundState
        timeRemainingFeedbackSwitch.isOn = Constants.timeRemainingFeedbackState
        countdownTimeTextfield.text = String(Constants.countdownTime)
        notificationSwitch.isOn = Constants.notificationReminderState
        notificationIntervalTextfield.text = NotificationHelper.interval
        notificationTimeTextfield.text = String(NotificationHelper.hour) + ":00"
        appVersionLabel.text = Constants.payloadShort

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setRemoveAdsDefaultSettings() {
        
        DispatchQueue.main.async(execute: { () -> Void in
        
            self.enableDeviceSleepSwitch.isOn = false
            self.enableDeviceSleepSwitchChanged(self.enableDeviceSleepSwitch)
            
            self.runInBackgroundSwitch.isOn = true
            self.runInBackgroundSwitchChanged(self.runInBackgroundSwitch)
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
            return 6
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
            
        case "CountdownTimeCell":
            
            countdownTimeTextfield.becomeFirstResponder()
            
        case "FacebookLikeCell":
            
            Constants.SocialNetwork.Facebook.openPage()
            
        case "TwitterFollowCell":
            
            Constants.SocialNetwork.Twitter.openPage()
            
        case "ShareWithFriendsCell":
            
            guard Functions.isConnectedToNetwork() else {
                SweetAlert().showAlert(NSLocalizedString("Alert: No Internet Connection Title Text", comment: ""), subTitle: NSLocalizedString("Alert: No Internet Connection Subtitle Text", comment: ""), style: AlertStyle.warning)
                return
            }
            
            let textToShare: String = "Check out @ChronicTimer, the simplest workout timer app! For Interval, HIIT, Tabata, Yoga, Boxing, Running #ChronicTimer"
            
            let objectsToShare: NSArray = [textToShare, Constants.appURL!]
            
            let excludedActivityTypesArray: [UIActivity.ActivityType] = [
                UIActivity.ActivityType.postToWeibo,
                UIActivity.ActivityType.addToReadingList,
                UIActivity.ActivityType.assignToContact,
                UIActivity.ActivityType.print,
                UIActivity.ActivityType.saveToCameraRoll,
                UIActivity.ActivityType.assignToContact,
                UIActivity.ActivityType.airDrop,
                ]
            
            let activityVC = UIActivityViewController(activityItems: objectsToShare as [AnyObject], applicationActivities: nil)
            activityVC.excludedActivityTypes = excludedActivityTypesArray
            
            activityVC.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.unknown
            
            activityVC.popoverPresentationController?.sourceView = self.view
            activityVC.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.width / 2, y: self.view.bounds.height / 2, width: 0, height: 0)
            
            self.present(activityVC, animated: true, completion: nil)
            
            activityVC.completionWithItemsHandler = { (activity, success, items, error) in
                print("Activity: \(activity) Success: \(success) Items: \(items) Error: \(error)")
                
                if success {
                    
                    SweetAlert().showAlert("Success!", subTitle: nil, style: AlertStyle.success)
                    
                    // log shared successfully
                    Answers.logShare(withMethod: "\(activity!)",
                                               contentName: "Chronic Shared",
                                               contentType: "Share",
                                               contentId: nil,
                                               customAttributes: ["App Version": Constants.AppVersion])
                    
                } else if error != nil {
                    SweetAlert().showAlert("Error!", subTitle: "That didn't go through", style: AlertStyle.error)
                }
            }
            
        case "WriteAReviewCell":
            
            iRate.sharedInstance().openRatingsPageInAppStore()
            
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
            
        case "UltimatePackageCell", "ProVersionCell", "RemoveAdsCell", "DonateCell":
            
            if !IAPHelper.sharedInstance.list.isEmpty {
                self.performSegue(withIdentifier: "InAppPurchaseSegueIdentifier", sender: tableView.cellForRow(at: indexPath))
            } else {
                IAPHelper.sharedInstance.requestProducts(displayAlert: true, { (success) in
                    if !IAPHelper.sharedInstance.list.isEmpty {
                        self.performSegue(withIdentifier: "InAppPurchaseSegueIdentifier", sender: tableView.cellForRow(at: indexPath))
                    }
                })
            }
            
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "InAppPurchaseSegueIdentifier" {
            let presentationSegue = segue as! MZFormSheetPresentationViewControllerSegue
            presentationSegue.formSheetPresentationController.contentViewControllerTransitionStyle = .slideAndBounceFromLeft
            presentationSegue.formSheetPresentationController.presentationController?.shouldCenterVertically = true
            presentationSegue.formSheetPresentationController.presentationController?.shouldUseMotionEffect = true
            presentationSegue.formSheetPresentationController.presentationController?.shouldDismissOnBackgroundViewTap = true
            presentationSegue.formSheetPresentationController.presentationController?.contentViewSize = CGSize(width: self.view.bounds.size.width, height: 450)
            
            let navigationController = presentationSegue.formSheetPresentationController.contentViewController as! UINavigationController
            let presentedViewController = navigationController.viewControllers.first as! InAppPurchaseViewController
            
            //presentedViewController.preferredContentSize = CGSize(width: self.view.bounds.size.width, height: 450)
            presentedViewController.inAppProducts = IAPHelper.sharedInstance.list
            
            guard let cell = sender as? UITableViewCell else { return }
            presentedViewController.carouselIndex = self.tableView.indexPath(for: cell)?.row ?? 0
        }
    }
}

// MARK: - IAP Delegate

extension SettingsTableViewController: IAPDelegate {
    
    func didPurchaseProFeaturesUpgrade() {
        print("didPurchaseProFeaturesUpgrade called in settings")
    }
    
    func didPurchaseRemoveAdsUpgrade() {
        
        print("didPurchaseRemoveAdsUpgrade called in settings")
        
        self.setRemoveAdsDefaultSettings()
    }
}

// MARK: - Email Delegate

extension SettingsTableViewController: MFMailComposeViewControllerDelegate {
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        
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
