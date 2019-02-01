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
        
        self.inputView = configureColorPicker()
        self.inputAccessoryView = configureAccessoryView()
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        
        // Prevent textfield from editing
        return false
    }
    
    func configureColorPicker() -> UIView {
        
        // configure picker
        let pickerViewFrame = CGRect(x: 0.0,y: 0.0, width: UIScreen.main.bounds.size.width, height: 216)
        
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
        
        let inputAccessoryView = UIToolbar(frame: CGRect(x: 0.0, y: 0.0, width: UIScreen.main.bounds.size.width, height: 44))
        inputAccessoryView.barStyle = UIBarStyle.blackTranslucent
        
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
    
        // Configure done button
        let doneButton = UIBarButtonItem()
        doneButton.title = "Done"
        doneButton.tintColor = UIColor.green
        doneButton.action = #selector(ColorPickerTextField.dismissPicker)
        
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
    var colorMatrix = [[UIColor.colorFromRGB(0x60E5BC), UIColor.colorFromRGB(0x1ABC9C), UIColor.colorFromRGB(0xFFCD02), UIColor.colorFromRGB(0xFF9500)],
                       [UIColor.colorFromRGB(0x5AD427), UIColor.colorFromRGB(0x27AE60), UIColor.colorFromRGB(0xFF5E3A), UIColor.colorFromRGB(0xD35400)],
                       [UIColor.colorFromRGB(0x5AC8FA), UIColor.colorFromRGB(0x3498DB), UIColor.colorFromRGB(0xE74C3C), UIColor.colorFromRGB(0xFF3A2D)],
                       [UIColor.colorFromRGB(0x9B59B6), UIColor.colorFromRGB(0x1D62F0), UIColor.colorFromRGB(0x8E8E93), UIColor.colorFromRGB(0x4A4A4A)]]
    
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
