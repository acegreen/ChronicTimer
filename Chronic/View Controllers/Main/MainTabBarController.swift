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
    
    @IBAction func unwindToMainviewcontroller(_ segue: UIStoryboardSegue) {

    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !userDefaults.bool(forKey: "ONBOARDING_SHOWN") {
            // Present onboarding on first install
            self.performSegue(withIdentifier: "OBSegueIdentifier", sender: self)
        } else {
            // Present release notes on first update
            LaunchKit.sharedInstance().presentAppReleaseNotesIfNeeded(from: self, completion: { (didPresent) -> Void in
                if didPresent {
                    print("Woohoo, we showed the release notes card!")
                }
            })
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "FeedbackSegueIdentifier" {
            
            let controller = segue.destinationViewController
            controller.transitioningDelegate = self
            controller.modalPresentationStyle = .custom
        }
    }

}

// MARK: - UIViewControllerTransitioningDelegate
extension MainTabBarController: UIViewControllerTransitioningDelegate {
    
    func animationController(forPresentedController presented: UIViewController, presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transition.transitionMode = .present
        transition.startingPoint = self.view.center
        transition.bubbleColor = UIColor.goldColor()
        return transition
    }
    
    func animationController(forDismissedController dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transition.transitionMode = .dismiss
        transition.startingPoint = self.view.center
        transition.bubbleColor = chronicColor
        return transition
    }
}
