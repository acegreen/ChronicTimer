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
        
        hoursLabel = UILabel(frame: CGRectMake(((self.frame.size.width / 3) / 2) + 25, (self.frame.size.height / 2) -  15, 50, 30))
        minutesLabel = UILabel(frame: CGRectMake((self.frame.size.width / 2) + 25, (self.frame.size.height / 2) -  15 , 50, 30))
        secondsLabel = UILabel(frame: CGRectMake(((self.frame.size.width ) * (5 / 6)) + 25, (self.frame.size.height / 2) -  15, 50, 30))

        hoursLabel.text = "hour"
        hoursLabel.textColor = UIColor.whiteColor()
        
        minutesLabel.text = "min"
        minutesLabel.textColor = UIColor.whiteColor()
    
        secondsLabel.text = "sec"
        secondsLabel.textColor = UIColor.whiteColor()
        
        self.addSubview(secondsLabel)
        self.addSubview(minutesLabel)
        self.addSubview(hoursLabel)
    }
    
    override func layoutSubviews() {
        
        super.layoutSubviews()
        
        hoursLabel.frame = CGRectMake(((self.frame.size.width / 3) / 2) + 25, (self.frame.size.height / 2) -  15, 50, 30)
        
        minutesLabel.frame = CGRectMake((self.frame.size.width / 2) + 25, (self.frame.size.height / 2) -  15 , 50, 30)
        
        secondsLabel.frame = CGRectMake(((self.frame.size.width ) * (5 / 6)) + 25, (self.frame.size.height / 2) -  15, 50, 30)
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
}