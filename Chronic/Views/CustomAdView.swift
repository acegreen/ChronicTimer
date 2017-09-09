//
//  CustomAdView.swift
//  Chronic
//
//  Created by Ace Green on 5/22/16.
//  Copyright © 2016 Ace Green. All rights reserved.
//

import UIKit
import PureLayout

class CustomAdView: UIView {
   
    override init(frame: CGRect) {
        super.init(frame: frame)
        customSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        customSetup()
    }

    func customSetup() {
        self.backgroundColor = UIColor(patternImage: UIImage(named: "backgroundPattern")!)
    }
}
