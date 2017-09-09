//
//  FeedbackViewController.swift
//  Chronic
//
//  Created by Ace Green on 2015-05-15.
//  Copyright (c) 2015 Ace Green. All rights reserved.
//

import UIKit
import StoreKit
import MessageUI

class FeedbackViewController: UIViewController, MFMailComposeViewControllerDelegate {

    @IBOutlet weak var negativeButton: UIButton!
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        negativeButton.layer.borderColor = UIColor.white.cgColor
    }
    
    @IBAction func reviewAction() {
        self.dismiss(animated: true) {
            SKStoreReviewController.requestReview()
            Functions.markFeedbackGiven()
        }
    }
    
    @IBAction func negativeAction() {
        self.dismiss(animated: true) { }
    }

    @IBAction func contactAction() {

        if MFMailComposeViewController.canSendMail() {
            
            let mc: MFMailComposeViewController = MFMailComposeViewController()
            
            mc.mailComposeDelegate = self
            
            let emailTitle = "Chronic Feedback/Bug"
            let messageBody = "Hello Chronic Team, </br> </br> </br> </br> </br> - - - - - - - - - - - - - - - - - - - - - </br>" + Constants.emailDiagnosticInfo
            let toReceipients = [Constants.appEmail]
            
            mc.setSubject(emailTitle)
            mc.setMessageBody(messageBody, isHTML: true)
            mc.setToRecipients(toReceipients)
            
            self.present(mc, animated: true, completion: nil)
            
        } else {
            
            SweetAlert().showAlert(NSLocalizedString("Alert: No Email Account Title Text", comment: ""), subTitle: NSLocalizedString("Alert: No Email Account Subtitle Text", comment: ""), style: AlertStyle.warning, dismissTime: nil, buttonTitle: NSLocalizedString("Ok", comment: ""), buttonColor:UIColor.colorFromRGB(0xD0D0D0) , otherButtonTitle: nil, otherButtonColor: nil) { (isOtherButton) -> Void in
                
            }
        }
    }
    
    // MARK: - Email Delegate
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        
        switch result.rawValue {
            
        case MFMailComposeResult.cancelled.rawValue:
            
            print("Mail Cancelled")
            
        case MFMailComposeResult.saved.rawValue, MFMailComposeResult.sent.rawValue:
            
            Functions.markFeedbackGiven()
            
        case MFMailComposeResult.failed.rawValue:
            
            print("Mail Failed")
            
        default:
            return
        }
        
        self.dismiss(animated: true) { () -> Void in
            self.dismiss(animated: true, completion: nil)
        }
    }
}
