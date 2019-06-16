//
//  MainNavigationController.swift
//  Chronic
//
//  Created by Ace Green on 3/27/16.
//  Copyright © 2016 Ace Green. All rights reserved.
//

import UIKit
import BubbleTransition

class MainTabBarController: UITabBarController {
    
    let transition = BubbleTransition()
    
    @IBAction func unwindToMainviewcontroller(_ segue: UIStoryboardSegue) {

    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Navigation
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        
//        if segue.identifier == "FeedbackSegueIdentifier" {
//            
//            let controller = segue.destination
//            controller.transitioningDelegate = self
//            controller.modalPresentationStyle = .custom
//        }
//    }
}

// MARK: - UIViewControllerTransitioningDelegate
//extension MainTabBarController: UIViewControllerTransitioningDelegate {
//    
//    func animationController(forPresentedController presented: UIViewController, presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
//        transition.transitionMode = .present
//        transition.startingPoint = self.view.center
//        transition.bubbleColor = UIColor.goldColor()
//        return transition
//    }
//    
//    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
//        transition.transitionMode = .dismiss
//        transition.startingPoint = self.view.center
//        transition.bubbleColor = Constants.chronicColor
//        return transition
//    }
//}
