//
//  CustomUIPickerView.swift
//  Chronic
//
//  Created by Ace Green on 2015-10-08.
//  Copyright © 2015 Ace Green. All rights reserved.
//

import Foundation


class CustomUIPickerView : UIPickerView {
    
    var hoursLabel: UILabel!
    var minutesLabel: UILabel!
    var secondsLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        hoursLabel = UILabel(frame: CGRect(x: ((self.frame.size.width / 3) / 2) + 25, y: (self.frame.size.height / 2) -  15, width: 50, height: 30))
        minutesLabel = UILabel(frame: CGRect(x: (self.frame.size.width / 2) + 25, y: (self.frame.size.height / 2) -  15 , width: 50, height: 30))
        secondsLabel = UILabel(frame: CGRect(x: ((self.frame.size.width ) * (5 / 6)) + 25, y: (self.frame.size.height / 2) -  15, width: 50, height: 30))

        hoursLabel.text = "hour"
        hoursLabel.textColor = UIColor.white()
        
        minutesLabel.text = "min"
        minutesLabel.textColor = UIColor.white()
    
        secondsLabel.text = "sec"
        secondsLabel.textColor = UIColor.white()
        
        self.addSubview(secondsLabel)
        self.addSubview(minutesLabel)
        self.addSubview(hoursLabel)
    }
    
    override func layoutSubviews() {
        
        super.layoutSubviews()
        
        hoursLabel.frame = CGRect(x: ((self.frame.size.width / 3) / 2) + 25, y: (self.frame.size.height / 2) -  15, width: 50, height: 30)
        
        minutesLabel.frame = CGRect(x: (self.frame.size.width / 2) + 25, y: (self.frame.size.height / 2) -  15 , width: 50, height: 30)
        
        secondsLabel.frame = CGRect(x: ((self.frame.size.width ) * (5 / 6)) + 25, y: (self.frame.size.height / 2) -  15, width: 50, height: 30)
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
}
