//
//  MainNavigationController.swift
//  Chronic
//
//  Created by Ace Green on 3/27/16.
//  Copyright © 2016 Ace Green. All rights reserved.
//

import UIKit
import LaunchKit
import BubbleTransition

class MainTabBarController: UITabBarController {
    
    let transition = BubbleTransition()
    
    @IBAction func unwindToMainviewcontroller(segue: UIStoryboardSegue) {

    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        
        if !userDefaults.boolForKey("ONBOARDING_SHOWN") {
            // Present onboarding on first install
            self.performSegueWithIdentifier("OBSegueIdentifier", sender: self)
        } else {
            // Present release notes on first update
            LaunchKit.sharedInstance().presentAppReleaseNotesIfNeededFromViewController(self, completion: { (didPresent) -> Void in
                if didPresent {
                    print("Woohoo, we showed the release notes card!")
                }
            })
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "FeedbackSegueIdentifier" {
            
            let controller = segue.destinationViewController
            controller.transitioningDelegate = self
            controller.modalPresentationStyle = .Custom
        }
    }

}

// MARK: - UIViewControllerTransitioningDelegate
extension MainTabBarController: UIViewControllerTransitioningDelegate {
    
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transition.transitionMode = .Present
        transition.startingPoint = self.view.center
        transition.bubbleColor = UIColor.goldColor()
        return transition
    }
    
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transition.transitionMode = .Dismiss
        transition.startingPoint = self.view.center
        transition.bubbleColor = chronicColor
        return transition
    }
}
