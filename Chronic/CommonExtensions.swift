//
//  CommonExtensions.swift
//  Chronic
//
//  Created by Ace Green on 2015-10-07.
//  Copyright © 2015 Ace Green. All rights reserved.
//

import Foundation
import UIKit
import StoreKit

extension Array {
    
    // Safely lookup an index that might be out of bounds,
    // returning nil if it does not exist
    func get(_ index: Int) -> Element? {
        if 0 <= index && index < count {
            return self[index]
        } else {
            return nil
        }
    }
    
    func reduceWithIndex<T>(_ initial: T, combine: @noescape(T, Int, Array.Iterator.Element) throws -> T) rethrows -> T {
        var result = initial
        for (index, element) in self.enumerated() {
            result = try combine(result, index, element)
        }
        return result
    }
}

extension Array where Element: Equatable {
    
    mutating func removeObject(_ object: Element) {
        if let index = self.index(of: object) {
            self.remove(at: index)
        }
    }
    
    mutating func removeObjectsInArray(_ array: [Element]) {
        for object in array {
            self.removeObject(object)
        }
    }
}

public extension UIColor {
    
    convenience init(red: Int, green: Int, blue: Int) {
        let newRed = CGFloat(red)/255
        let newGreen = CGFloat(green)/255
        let newBlue = CGFloat(blue)/255
        
        self.init(red: newRed, green: newGreen, blue: newBlue, alpha: 1.0)
    }
    
    class func goldColor() -> UIColor {
        
        return UIColor(red: 245, green: 192, blue: 24)
    }
    
    /// Random `UIColor`
    class func randomColor() -> UIColor {
        let r = CGFloat(arc4random_uniform(256))/CGFloat(255)
        let g = CGFloat(arc4random_uniform(256))/CGFloat(255)
        let b = CGFloat(arc4random_uniform(256))/CGFloat(255)
        let a = CGFloat(arc4random_uniform(256))/CGFloat(255)
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
    
    class func colorFromRGB(_ rgbValue: UInt) -> UIColor {
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
}

extension CALayer {
    var borderUIColor: UIColor {
        set {
            self.borderColor = newValue.cgColor
        }
        
        get {
            return UIColor(cgColor: self.borderColor!)
        }
    }
}

public extension UIImage {
    
    var rounded: UIImage {
        let imageView = UIImageView(image: self)
        imageView.layer.cornerRadius = size.height < size.width ? size.height/2 : size.width/2
        imageView.layer.masksToBounds = true
        UIGraphicsBeginImageContext(imageView.bounds.size)
        imageView.layer.render(in: UIGraphicsGetCurrentContext()!)
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result!
    }
    var circle: UIImage {
        let square = size.width < size.height ? CGSize(width: size.width, height: size.width) : CGSize(width: size.height, height: size.height)
        let imageView = UIImageView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: square))
        imageView.contentMode = UIViewContentMode.scaleAspectFill
        imageView.image = self
        imageView.layer.cornerRadius = square.width/2
        imageView.layer.masksToBounds = true
        UIGraphicsBeginImageContext(imageView.bounds.size)
        imageView.layer.render(in: UIGraphicsGetCurrentContext()!)
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result!
    }
}

public extension UIViewController {
    
    func fixIOS9PopOverAnchor(_ segue:UIStoryboardSegue?) {
        
        guard #available(iOS 9.0, *) else { return }
        if let popOver = segue?.destinationViewController.popoverPresentationController,
            let anchor  = popOver.sourceView
            where popOver.sourceRect == CGRect()
                && segue!.sourceViewController === self
        { popOver.sourceRect = anchor.bounds }
    }       
}

extension SKProduct {
    
    func localizedPrice() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = self.priceLocale
        return formatter.string(from: self.price)!
    }
}

extension UIView {
    
    func fitSubViewToSuperView(_ superView: UIView) {
        
        let top: NSLayoutConstraint = NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: superView, attribute: .top, multiplier: 1.0, constant: 0)
        let bottom: NSLayoutConstraint = NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: superView, attribute: .bottom, multiplier: 1.0, constant: 0)
        let leading: NSLayoutConstraint = NSLayoutConstraint(item: self, attribute: .leading, relatedBy: .equal, toItem: superView, attribute: .leading, multiplier: 1.0, constant: 0.0)
        let trailing: NSLayoutConstraint = NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: .equal, toItem: superView, attribute: .trailing, multiplier: 1.0, constant: 0.0)
        
        superView.addConstraint(top)
        superView.addConstraint(bottom)
        superView.addConstraint(leading)
        superView.addConstraint(trailing)
    }
}

extension UIControlState {
    public static var normal: UIControlState { return [] }
}
