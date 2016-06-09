//
//  FeedbackViewController.swift
//  Chronic
//
//  Created by Ace Green on 2015-05-15.
//  Copyright (c) 2015 Ace Green. All rights reserved.
//

import UIKit
import MessageUI

class FeedbackViewController: UIViewController, MFMailComposeViewControllerDelegate {

    @IBOutlet weak var negativeButton: UIButton!
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        SARate.sharedInstance().eventCount = 0
        negativeButton.layer.borderColor = UIColor.whiteColor().CGColor
    }
    
    @IBAction func reviewAction() {
        self.dismissViewControllerAnimated(true) {
            iRate.sharedInstance().openRatingsPageInAppStore()
        }
    }
    
    @IBAction func negativeAction() {
        self.dismissViewControllerAnimated(true) {}
    }

    @IBAction func contactAction() {

        if MFMailComposeViewController.canSendMail() {
            
            let mc: MFMailComposeViewController = MFMailComposeViewController()
            
            mc.mailComposeDelegate = self
            
            let emailTitle = "Chronic Feedback/Bug"
            let messageBody = "Hello Chronic Team, </br> </br> </br> </br> </br> - - - - - - - - - - - - - - - - - - - - - </br>" + emailDiagnosticInfo
            let toReceipients = [appEmail]
            
            mc.setSubject(emailTitle)
            mc.setMessageBody(messageBody, isHTML: true)
            mc.setToRecipients(toReceipients)
            
            self.presentViewController(mc, animated: true, completion: nil)
            
        } else {
            
            SweetAlert().showAlert(NSLocalizedString("Alert: No Email Account Title Text", comment: ""), subTitle: NSLocalizedString("Alert: No Email Account Subtitle Text", comment: ""), style: AlertStyle.Warning, dismissTime: nil, buttonTitle: NSLocalizedString("Ok", comment: ""), buttonColor:UIColor.colorFromRGB(0xD0D0D0) , otherButtonTitle: nil, otherButtonColor: nil) { (isOtherButton) -> Void in
                
            }
        }
    }
    
    // MARK: - Email Delegate
    
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        
        switch result.rawValue {
            
        case MFMailComposeResultCancelled.rawValue:
            
            print("Mail Cancelled")
            
        case MFMailComposeResultSaved.rawValue, MFMailComposeResultSent.rawValue:
            
            markFeedbackGiven()
            
        case MFMailComposeResultFailed.rawValue:
            
            print("Mail Failed")
            
        default:
            
            return
            
        }
        
        self.dismissViewControllerAnimated(true) { () -> Void in
            
            self.dismissViewControllerAnimated(true, completion: nil)
            
        }
    }
}
