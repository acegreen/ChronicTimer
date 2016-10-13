//
//  CustomTextField.swift
//  Chronic
//
//  Created by Ace Green on 2015-07-29.
//  Copyright © 2015 Ace Green. All rights reserved.
//

import UIKit
import Foundation

class NumberPickerTextField: UITextField, UIPickerViewDataSource, UIPickerViewDelegate {
    
    var picker:UIPickerView = UIPickerView()
    
    var pickerNumber: Int = 0
    
    override func awakeFromNib() {
        super.awakeFromNib()
    
        picker.delegate = self
        picker.dataSource = self
    }
    
    override func layoutSubviews() {
        
        super.layoutSubviews()
        
        pickerNumber = Int(self.text!)!
        
        self.inputView = configurePicker()
        self.inputAccessoryView = configureAccessoryView()
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        
        // Prevent textfield from editing
        return false
    }
    
    func configurePicker() -> UIView {
        
        picker.selectRow(pickerNumber - 1, inComponent: 0, animated: true)
        
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
        doneButton.action = #selector(NumberPickerTextField.dismissPicker)
        
        inputAccessoryView.items = NSArray(array: [flex, doneButton]) as? [UIBarButtonItem]
        
        return inputAccessoryView
    }
    
    // Disallow selection or editing and remove caret
    
    override func caretRect(for position: UITextPosition) -> CGRect {
        return CGRect.zero
    }
    
    override func selectionRects(for range: UITextRange) -> [Any] {
        return []
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        
        UIMenuController.shared.isMenuVisible = false
        
        if action == #selector(copy(_:)) || action == #selector(select(_:)) || action == #selector(paste(_:)) {
            return false
        }
        
        return super.canPerformAction(action, withSender:sender)
    }

    func dismissPicker() {
        self.resignFirstResponder()
    }
    
    //MARK: - UIPickerView Functions
    
    // returns the number of 'columns' to display.
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        
        return 1
    }
    
    // returns the # of rows in each component..
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        return 500
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        
        let title = String(row + 1)
        let attributedString = NSAttributedString(string: title, attributes: [NSForegroundColorAttributeName: UIColor.white])
        
        pickerView.backgroundColor = UIColor.clear
        
        return attributedString
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        pickerNumber = row + 1
        
        UpdateLabel()
    }
    
    func UpdateLabel() {
        
        self.text = String(pickerNumber)
        self.sizeToFit()
    }
}
