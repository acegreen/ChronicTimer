//
//  TextField.swift
//  Chronic
//
//  Created by Ace Green on 8/6/16.
//  Copyright © 2016 Ace Green. All rights reserved.
//

import Foundation

class TextField: UITextField {
    
    override func canPerformAction(_ action: Selector, withSender sender: AnyObject?) -> Bool {
        
        UIMenuController.shared.isMenuVisible = false
        
        print("performaction")
        if action == #selector(NSObject.paste(_:)) {
            print("no paste")
            return false
        }
        return super.canPerformAction(action, withSender:sender)
    }
}
