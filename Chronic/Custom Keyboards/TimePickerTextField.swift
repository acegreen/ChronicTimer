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
        
        (pickerHours,pickerMinutes,pickerSeconds) = Functions.timeComponentsFrom(string: self.text!)
        
        self.inputView = configurePicker()
        self.inputAccessoryView = configureAccessoryView()
        
        
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        
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
        
        let inputAccessoryView = UIToolbar(frame: CGRect(x: 0.0, y: 0.0, width: UIScreen.main.bounds.size.width, height: 44))
        inputAccessoryView.barStyle = UIBarStyle.blackTranslucent
        
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
    
        // Configure done button
        let doneButton = UIBarButtonItem()
        doneButton.title = "Done"
        doneButton.tintColor = UIColor.green
        doneButton.action = #selector(TimePickerTextField.dismissPicker)
        
        inputAccessoryView.items = NSArray(array: [flex, doneButton]) as? [UIBarButtonItem]
        
        return inputAccessoryView
    }
    
    // Disallow selection or editing and remove caret
    
    override func caretRect(for position: UITextPosition) -> CGRect {
        return CGRect.zero
    }
    
    override func selectionRects(for range: UITextRange) -> [AnyObject] {
        return []
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: AnyObject?) -> Bool {
        
        UIMenuController.shared.isMenuVisible = false
        
        if action == #selector(copy(_:)) || action == #selector(selectAll(_:)) || action == #selector(paste(_:)) {
            return false
        }
        
        return super.canPerformAction(action, withSender:sender)
    }

    func dismissPicker () {
        
        self.resignFirstResponder()
    }
    
    //MARK: - UIPickerView Functions
    
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
        
        let title = String(row)
        let attributedString = NSAttributedString(string: title, attributes: [NSForegroundColorAttributeName: UIColor.white])
        
        pickerView.backgroundColor = UIColor.clear
        
        return attributedString
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        if component == 0 {
            
            pickerHours = row
            
        } else if component == 1 {
            
            pickerMinutes = row
            
        } else if component == 2 {
            
            pickerSeconds = row
        }
        
        pickerTotal = Functions.timeFromTimeComponents(hoursComponent: pickerHours, minutesComponent: pickerMinutes, secondsComponent: pickerSeconds)
        
        UpdateLabel()
        
    }
    
    func UpdateLabel() {
        
        self.text = Functions.timeStringFrom(time: pickerTotal, type: "Routine")
        self.sizeToFit()

    }
}
