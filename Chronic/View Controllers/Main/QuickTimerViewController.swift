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
    var pickerHours: Int = 0
    var pickerMinutes: Int = 0
    var pickerSeconds: Int = 0
    var pickerTotal: Int = 0
    
    @IBOutlet var StartButton: UIButton!
    
    @IBAction func StartButtonPressed(_ sender: AnyObject) {
    
        Functions.deselectSelectedRoutine()
        
        let timerViewController = Constants.mainStoryboard.instantiateViewController(withIdentifier: "TimerViewController") as! TimerViewController
        timerViewController.initializeQuickTimer()
        
        self.dismiss(animated: true) { 
            Constants.appDel.window?.rootViewController?.present(timerViewController, animated: true, completion: nil)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        picker.delegate = self
        picker.dataSource = self
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            
            self.navigationItem.leftBarButtonItem = nil
        
        }
        
    }
    
    override func viewWillLayoutSubviews() {
        
        super.viewWillLayoutSubviews()
        
        configurePicker()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
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
        
        let hoursLabel: UILabel = UILabel(frame: CGRect(x: 75, y: 95, width: 75, height: 30))
        hoursLabel.text = "hour"
        hoursLabel.textColor = UIColor.white
        picker.addSubview(hoursLabel)
        
        let minutesLabel: UILabel = UILabel(frame: CGRect(x: 75 + (picker.frame.size.width / 3), y: 95 , width: 75, height: 30))
        minutesLabel.text = "min"
        minutesLabel.textColor = UIColor.white
        picker.addSubview(minutesLabel)
        
        let secondsLabel: UILabel = UILabel(frame: CGRect(x: 75 + ((picker.frame.size.width / 3) * 2), y: 95, width: 75, height: 30))
        secondsLabel.text = "sec"
        secondsLabel.textColor = UIColor.white
        picker.addSubview(secondsLabel)
        
        self.view.addSubview(picker)
        picker.autoCenterInSuperview()
        
    }
    
    // returns the number of 'columns' to display.
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
 
        return 3
        
    }
    
    // returns the # of rows in each component..
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        if component == 0 {
            
            return 24
            
        }
        
        return 60
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        
        return NSAttributedString(string: String(row), attributes: [NSForegroundColorAttributeName:UIColor.white])
        
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        if component == 0 {
            
            pickerHours = row * 3600
            
        } else if component == 1 {
            
            pickerMinutes = row * 60
            
        } else if component == 2 {
            
            pickerSeconds = row
        }
        
        pickerTotal = pickerHours + pickerMinutes + pickerSeconds
        
        Constants.QuickTimerTime = pickerTotal
    }
    
    func setPickerInitialValues() {
        
        pickerHours = 0
        pickerMinutes = 60
        pickerSeconds = 0
        
        pickerTotal = 60
        Constants.QuickTimerTime = pickerTotal
        
    }
    
}
