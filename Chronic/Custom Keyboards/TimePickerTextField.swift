//
//  CustomTextField.swift
//  Chronic
//
//  Created by Ace Green on 2015-07-29.
//  Copyright © 2015 Ace Green. All rights reserved.
//

import UIKit
import Foundation

class TimePickerTextField: UITextField, UIPickerViewDataSource, UIPickerViewDelegate {

    var picker:UIPickerView = CustomUIPickerView()

    var pickerHours: Int = 0
    var pickerMinutes: Int = 0
    var pickerSeconds: Int = 0
    var pickerTotal: Int = 0
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        picker.delegate = self
        picker.dataSource = self

    }
    
    override func layoutSubviews() {
        
        super.layoutSubviews()
        
        (pickerHours,pickerMinutes,pickerSeconds) = timeComponentsFrom(string: self.text!)
        
        self.inputView = configurePicker()
        self.inputAccessoryView = configureAccessoryView()
        
        
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        
        // Prevent textfield from editing
        return false
        
    }
    
    func configurePicker() -> UIView {
        
        picker.selectRow(pickerHours, inComponent: 0, animated: true)
        picker.selectRow(pickerMinutes, inComponent: 1, animated: true)
        picker.selectRow(pickerSeconds, inComponent: 2, animated: true)
        
        return picker
        
    }
    
    func configureAccessoryView() -> UIView {
        
        let inputAccessoryView = UIToolbar(frame: CGRectMake(0.0, 0.0, UIScreen.mainScreen().bounds.size.width, 44))
        inputAccessoryView.barStyle = UIBarStyle.BlackTranslucent
        
        let flex = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: self, action: nil)
    
        // Configure done button
        let doneButton = UIBarButtonItem()
        doneButton.title = "Done"
        doneButton.tintColor = UIColor.greenColor()
        doneButton.action = Selector("dismissPicker")
        
        inputAccessoryView.items = NSArray(array: [flex, doneButton]) as? [UIBarButtonItem]
        
        return inputAccessoryView
    }
    
    // Disallow selection or editing and remove caret
    
    override func caretRectForPosition(position: UITextPosition) -> CGRect {
        return CGRectZero
    }
    
    override func selectionRectsForRange(range: UITextRange) -> [AnyObject] {
        return []
    }
    
    override func canPerformAction(action: Selector, withSender sender: AnyObject?) -> Bool {
        
        UIMenuController.sharedMenuController().menuVisible = false
        
        if action == "copy:" || action == "selectAll:" || action == "paste:" {
            return false
        }
        
        return super.canPerformAction(action, withSender:sender)
    }

    func dismissPicker () {
        
        self.resignFirstResponder()
    }
    
    //MARK: - UIPickerView Functions
    
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
        
        let title = String(row)
        let attributedString = NSAttributedString(string: title, attributes: [NSForegroundColorAttributeName: UIColor.whiteColor()])
        
        pickerView.backgroundColor = UIColor.clearColor()
        
        return attributedString
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        if component == 0 {
            
            pickerHours = row
            
        } else if component == 1 {
            
            pickerMinutes = row
            
        } else if component == 2 {
            
            pickerSeconds = row
        }
        
        pickerTotal = timeFromTimeComponents(hoursComponent: pickerHours, minutesComponent: pickerMinutes, secondsComponent: pickerSeconds)
        
        UpdateLabel()
        
    }
    
    func UpdateLabel() {
        
        self.text = timeStringFrom(time: pickerTotal, type: "Routine")
        self.sizeToFit()

    }
}
