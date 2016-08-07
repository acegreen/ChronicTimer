//
//  InterfaceTableController.swift
//  Chronic
//
//  Created by Ace Green on 2015-05-09.
//  Copyright (c) 2015 Ace Green. All rights reserved.
//

import WatchKit
import Foundation

class QTInterfaceController: WKInterfaceController {
    
    var pickerHours: Double = 0.0
    var pickerMinutes: Double = 60.0
    var pickerSeconds: Double = 0.0
    
    var hourItemArray = [WKPickerItem]()
    var minuteItemArray = [WKPickerItem]()
    var secondItemArray = [WKPickerItem]()
    
    @IBOutlet var hourPicker: WKInterfacePicker!
    
    @IBOutlet var minutePicker: WKInterfacePicker!
    
    @IBOutlet var secondPicker: WKInterfacePicker!
    
    @IBAction func hourPicker(_ value: Int) {
        
        let hourValueInt: Int = Int(value)
        
        pickerHours = Double(hourValueInt) * 3600
    
    }
    
    @IBAction func minutePicker(_ value: Int) {
        
        let minutesValueInt: Int = Int(value)
        
        pickerMinutes = Double(minutesValueInt) * 60
    
    }
    
    @IBAction func secondPicker(_ value: Int) {
        
        let secondsValueInt: Int = Int(value)
        
        pickerSeconds = Double(secondsValueInt)
    
    }

    override func awake(withContext context: AnyObject?) {
        super.awake(withContext: context)
        
        for n in 0...23 {
            let item = WKPickerItem()
            item.title = String(n)
            item.caption = NSLocalizedString("Hours", comment: "")
            hourItemArray.append(item)
        }
        
        for n in 0...59 {
            let item = WKPickerItem()
            item.title = String(n)
            item.caption = NSLocalizedString("Minutes", comment: "")
            minuteItemArray.append(item)
        }
        
        for n in 0...59 {
            let item = WKPickerItem()
            item.title = String(n)
            item.caption = NSLocalizedString("Seconds", comment: "")
            secondItemArray.append(item)
        }
        
        hourPicker.setItems(hourItemArray)
        minutePicker.setItems(minuteItemArray)
        secondPicker.setItems(secondItemArray)
        
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        minutePicker.focus()
        hourPicker.setSelectedItemIndex(0)
        minutePicker.setSelectedItemIndex(1)
        secondPicker.setSelectedItemIndex(0)
        
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    

    override func contextForSegue(withIdentifier segueIdentifier: String) -> AnyObject? {
            
        Constants.QuickTimerTime = pickerHours + pickerMinutes + pickerSeconds
    
        return Constants.QuickTimerTime
    
    }
    
    override func contextsForSegue(withIdentifier segueIdentifier: String) -> [AnyObject]? {
        
        Constants.QuickTimerTime = pickerHours + pickerMinutes + pickerSeconds
        
        return [Constants.QuickTimerTime]
    }
    
}
