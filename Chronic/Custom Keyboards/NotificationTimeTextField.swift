//
//  CustomTextField.swift
//  Chronic
//
//  Created by Ace Green on 2015-07-29.
//  Copyright © 2015 Ace Green. All rights reserved.
//

import UIKit
import Foundation

class NotificationTimeTextField: UITextField, UIPickerViewDataSource, UIPickerViewDelegate {
    
    var picker:UIPickerView = UIPickerView()
    
    override func awakeFromNib() {
        super.awakeFromNib()
    
        picker.delegate = self
        picker.dataSource = self
    }
    
    override func layoutSubviews() {
        
        super.layoutSubviews()
        
        self.inputView = configurePicker()
        self.inputAccessoryView = configureAccessoryView()
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        
        // Prevent textfield from editing
        return false
    }
    
    func configurePicker() -> UIView {
        
        picker.selectRow(NotificationHelper.hour, inComponent: 0, animated: true)
        
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
        doneButton.action = #selector(NotificationTimeTextField.dismissPicker)
        
        inputAccessoryView.items = NSArray(array: [flex, doneButton]) as? [UIBarButtonItem]
        
        return inputAccessoryView
    }
    
    // Disallow selection or editing and remove caret
    
    override func caretRect(for position: UITextPosition) -> CGRect {
        return CGRect.zero
    }
    
    override func selectionRects(for range: UITextRange) -> [UITextSelectionRect] {
        return []
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        
        UIMenuController.shared.isMenuVisible = false
        
        if action == #selector(copy(_:)) || action == #selector(selectAll(_:)) || action == #selector(paste(_:)) {
            return false
        }
        
        return super.canPerformAction(action, withSender:sender)
    }

    @objc func dismissPicker () {
        self.resignFirstResponder()
    }
    
    //MARK: - UIPickerView Functions
    
    // returns the number of 'columns' to display.
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        
        return 1
    }
    
    // returns the # of rows in each component..
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        return 24
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        
        let title = String(row) + ":00"
        let attributedString = NSAttributedString(string: title, attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])
        
        pickerView.backgroundColor = UIColor.clear
        
        return attributedString
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        updateNotificationSetting("NOTIFICATION_REMINDER_TIME", value: row)
        
        self.text = String(row) + ":00"
        self.sizeToFit()
    }
    
    func updateNotificationSetting(_ key: String, value: Int) {
        Constants.userDefaults.set(value, forKey: key)
        NotificationHelper.updateNotificationPreferences(Constants.notificationReminderState)
    }
}
