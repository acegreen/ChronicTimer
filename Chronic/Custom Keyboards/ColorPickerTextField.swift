//
//  ColorPickerTextField.swift
//  Chronic
//
//  Created by Ace Green on 2015-07-29.
//  Copyright © 2015 Ace Green. All rights reserved.
//

import UIKit
import Foundation
import QuartzCore

class ColorPickerTextField: UITextField, SwiftColorPickerDelegate, SwiftColorPickerDataSource {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let square = self.bounds.width < self.bounds.height ? CGSize(width: self.bounds.width, height: self.bounds.width) : CGSize(width: self.bounds.height, height: self.bounds.height)
        self.layer.cornerRadius = square.width / 2
        self.layer.masksToBounds = true
        
        self.inputView = configureColorPicker()
        self.inputAccessoryView = configureAccessoryView()
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        
        // Prevent textfield from editing
        return false
        
    }
    
    func configureColorPicker() -> UIView {
        
        // configure picker
        let pickerViewFrame = CGRect(x: 0.0,y: 0.0, width: UIScreen.main().bounds.size.width, height: 216)
        
        //let pickerWidth = min(UIScreen.mainScreen().bounds.size.width,500)
        
        let colorPickerView = SwiftColorPickerView(frame: pickerViewFrame)
        colorPickerView.delegate = self
        colorPickerView.dataSource = self
        
        colorPickerView.numberColorsInXDirection = 4
        colorPickerView.numberColorsInYDirection = 4
        colorPickerView.coloredBorderWidth = 0
        
        return colorPickerView
        
    }
    
    func configureAccessoryView() -> UIView {
        
        let inputAccessoryView = UIToolbar(frame: CGRect(x: 0.0, y: 0.0, width: UIScreen.main().bounds.size.width, height: 44))
        inputAccessoryView.barStyle = UIBarStyle.blackTranslucent
        
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
    
        // Configure done button
        let doneButton = UIBarButtonItem()
        doneButton.title = "Done"
        doneButton.tintColor = UIColor.green()
        doneButton.action = #selector(ColorPickerTextField.dismissPicker)
        
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
        
        UIMenuController.shared().isMenuVisible = false
        
        if action == "copy:" || action == "selectAll:" || action == "paste:" {
            return false
        }
        
        return super.canPerformAction(action, withSender:sender)
    }

    func dismissPicker () {
        
        self.resignFirstResponder()
    }
    
    //MARK: - SwiftColorPickerDelegate Functions
    
    func colorSelectionChanged(selectedColor color: UIColor) {
        
        self.backgroundColor = color
        
    }
    
    func colorForPalletIndex(_ x: Int, y: Int, numXStripes: Int, numYStripes: Int) -> UIColor {
        
        if colorMatrix.count > x  {
            let colorArray = colorMatrix[x]
            if colorArray.count > y {
                return colorArray[y]
            } else {
                fillColorMatrix(numXStripes,numYStripes)
                return colorForPalletIndex(x, y:y, numXStripes: numXStripes, numYStripes: numYStripes)
            }
        } else {
            fillColorMatrix(numXStripes,numYStripes)
            return colorForPalletIndex(x, y:y, numXStripes: numXStripes, numYStripes: numYStripes)
        }
        
    }
    
    // MARK: - Color Matrix (only for test case)
    var colorMatrix = [ [UIColor.colorFromRGB(0x60E5BC), UIColor.colorFromRGB(0x1ABC9C), UIColor.colorFromRGB(0xF1C40F), UIColor.colorFromRGB(0xF39C12)],
                        [UIColor.colorFromRGB(0x4CD964), UIColor.colorFromRGB(0x27AE60), UIColor.orange(), UIColor.colorFromRGB(0xD35400)],
                        [UIColor.colorFromRGB(0x5AC8FA), UIColor.colorFromRGB(0x3498DB), UIColor.colorFromRGB(0xE74C3C), UIColor.red()],
                        [UIColor.colorFromRGB(0x9B59B6), UIColor.colorFromRGB(0x5856D6), UIColor.colorFromRGB(0x34495E), UIColor.black()]]
    
    private func fillColorMatrix(_ numX: Int, _ numY: Int) {
        colorMatrix.removeAll()
        if numX > 0 && numY > 0 {
            
            for _ in 0..<numX {
                var colInX = [UIColor]()
                for _ in 0..<numY {
                    colInX += [UIColor.randomColor()]
                }
                colorMatrix += [colInX]
            }
        }
    }
}
