//
//  ShareViewController.swift
//  Chronic
//
//  Created by Ace Green on 6/8/19.
//  Copyright © 2019 StockSwipe. All rights reserved.
//

import UIKit
import Parse
import Firebase
import Branch
import UICountingLabel

class ShareViewController: UIViewController {
    
    @IBAction func dismissAction(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBOutlet weak var creditsLabel: UICountingLabel!
    @IBOutlet weak var creditsRemainingLabel: UICountingLabel!

    @IBAction func inviteFriendsAction(_ sender: UIButton) {
        self.presentShareSheet()
    }
    
    @IBOutlet weak var redeemStackView: UIStackView!
    @IBAction func redeemAction(_ sender: Any) {
        
        Branch.getInstance().redeemRewards(self.creditRequiredToRedeemFreeFeature, callback: {(success, error) in
            if success {
                IAPHelper.sharedInstance.proVersionPurchased()
                IAPHelper.sharedInstance.removeAdsPurchased()
                
                SweetAlert().showAlert(NSLocalizedString("Success", comment: ""), subTitle: NSLocalizedString("Alert: Redeem Success Subtitle Text", comment: ""), style: AlertStyle.success)
            }
            else {
                print("Failed to redeem credits: \(error)")
            }
        })
    }
    
    var creditRequiredToRedeemFreeFeature: Int = 100
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        creditsLabel.format = "%d"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.updateCreditBalance()
    }
    
    private func updateCreditBalance() {
        Branch.getInstance().loadRewards { (changed, error) in
            if (error == nil) {
                let credits = Branch.getInstance().getCredits()
                DispatchQueue.main.async {
                    self.creditsLabel.countFromZero(to: CGFloat(credits))
                }
                Functions.setupConfigParameter("CREDITREQUIREDTOREDEEMFREEFEATURE") { (parameterValue) -> Void in
                    self.creditRequiredToRedeemFreeFeature = parameterValue as? Int ?? 100
                    let creditsRemaining = self.creditRequiredToRedeemFreeFeature - credits
                    
                    DispatchQueue.main.async {
                        let creditsRemainingToDisplay = (creditsRemaining >= 0) ? "\(creditsRemaining)" : "0"
                        self.creditsRemainingLabel.text = creditsRemainingToDisplay
                        if credits == self.creditRequiredToRedeemFreeFeature {
                            self.redeemStackView.isHidden = false
                        } else {
                            self.redeemStackView.isHidden = true
                        }
                    }
                }
            }
        }
    }
    
    private func presentShareSheet() {
        
        guard Functions.isConnectedToNetwork() else { return }
        
        let textToShare: String = "Check out @ChronicTimer, the simplest workout timer app! For Interval, HIIT, Tabata, Yoga, Boxing, Running #ChronicTimer"
        let branchObject = BranchUniversalObject(title: "Chronic Timer")
        branchObject.contentDescription = "You concentrate on your workout, Chronic will take care of timing! Anyone who is serious about working out knows that the key is a routine."
        branchObject.imageUrl = "https://www.dropbox.com/s/gzuhakxg268flc5/chronic_512.png"
        branchObject.publiclyIndex = true
        branchObject.locallyIndex = true
        
        branchObject.showShareSheet(withShareText: textToShare) { (activityType, completed) in
            if completed {
                Functions.presentWhisper(with: "Success!")
            }
        }
    }
}
