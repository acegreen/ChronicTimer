//
//  FeedbackMainViewController.swift
//  Chronic
//
//  Created by Ace Green on 9/9/17.
//  Copyright © 2017 Ace Green. All rights reserved.
//

import UIKit
import StoreKit

class FeedbackMainViewController: UIViewController {
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    @IBAction func reviewAction() {
        self.dismiss(animated: true) {
            SKStoreReviewController.requestReview()
        }
    }
}
