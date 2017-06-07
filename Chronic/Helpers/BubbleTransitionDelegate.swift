//
//  BubbleTransitionDelegate.swift
//  Chronic
//
//  Created by Ace Green on 3/11/17.
//  Copyright © 2017 Ace Green. All rights reserved.
//

import UIKit
import BubbleTransition
import Foundation

class BubbleTransitionDelegate: NSObject, UIViewControllerTransitioningDelegate {
    
    let transition = BubbleTransition()
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transition.transitionMode = .present
        transition.startingPoint = presenting.view.center
        transition.bubbleColor = UIColor.goldColor()
        return transition
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transition.transitionMode = .dismiss
        transition.startingPoint = dismissed.view.center
        transition.bubbleColor = Constants.chronicColor
        return transition
    }
}
