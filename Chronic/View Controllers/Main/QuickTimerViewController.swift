//
//  QuickTimerViewController.swift
//  Chronic
//
//  Created by Ace Green on 2015-05-15.
//  Copyright (c) 2015 Ace Green. All rights reserved.
//

import UIKit

class QuickTimerViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    
    var picker:UIPickerView = UIPickerView()
    var pickerHours: Double!
    var pickerMinutes: Double!
    var pickerSeconds: Double!
    var pickerTotal: Double!
    
    @IBOutlet var StartButton: UIButton!
    
    @IBAction func StartButtonPressed(sender: AnyObject) {
        
        if Routines != nil {
            
            deselectSelectedRoutine()
        }
        
        let timerViewController = mainStoryboard.instantiateViewControllerWithIdentifier("TimerViewController") as! TimerViewController
        timerViewController.initializeQuickTimer()
        
        self.dismissViewControllerAnimated(true) { 
            appDel.window?.rootViewController?.presentViewController(timerViewController, animated: true, completion: nil)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        picker.delegate = self
        picker.dataSource = self
        
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            
            self.navigationItem.leftBarButtonItem = nil
        
        }
        
    }
    
    override func viewWillLayoutSubviews() {
        
        super.viewWillLayoutSubviews()
        
        configurePicker()
    }
    
    override func viewWillAppear(animated: Bool) {
        
        super.viewWillAppear(true)
        
        setPickerInitialValues()
        
        picker.selectRow(1, inComponent: 1, animated: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - UIPickerView Functions
    
    func configurePicker() {
        
        let hoursLabel: UILabel = UILabel(frame: CGRectMake(75, 95, 75, 30))
        hoursLabel.text = "hour"
        hoursLabel.textColor = UIColor.whiteColor()
        picker.addSubview(hoursLabel)
        
        let minutesLabel: UILabel = UILabel(frame: CGRectMake(75 + (picker.frame.size.width / 3), 95 , 75, 30))
        minutesLabel.text = "min"
        minutesLabel.textColor = UIColor.whiteColor()
        picker.addSubview(minutesLabel)
        
        let secondsLabel: UILabel = UILabel(frame: CGRectMake(75 + ((picker.frame.size.width / 3) * 2), 95, 75, 30))
        secondsLabel.text = "sec"
        secondsLabel.textColor = UIColor.whiteColor()
        picker.addSubview(secondsLabel)
        
        self.view.addSubview(picker)
        picker.autoCenterInSuperview()
        
    }
    
    // returns the number of 'columns' to display.
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
 
        return 3
        
    }
    
    // returns the # of rows in each component..
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        if component == 0 {
            
            return 24
            
        }
        
        return 60
    }
    
    func pickerView(pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        
        return NSAttributedString(string: String(row), attributes: [NSForegroundColorAttributeName:UIColor.whiteColor()])
        
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        if component == 0 {
            
            pickerHours = Double(row) * 3600
            
        } else if component == 1 {
            
            pickerMinutes = Double(row) * 60
            
        } else if component == 2 {
            
            pickerSeconds = Double(row)
        }
        
        pickerTotal = pickerHours + pickerMinutes + pickerSeconds
        
        QuickTimerTime = pickerTotal
    }
    
    func setPickerInitialValues() {
        
        pickerHours = 0.0
        pickerMinutes = 60.0
        pickerSeconds = 0.0
        
        pickerTotal = 60.0
        QuickTimerTime = pickerTotal
        
    }
    
}
