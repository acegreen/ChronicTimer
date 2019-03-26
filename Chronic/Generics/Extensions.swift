//
//  Extensions.swift
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
    
    func reduceWithIndex<T>(_ initial: T, combine: (T, Int, Array.Iterator.Element) throws -> T) rethrows -> T {
        var result = initial
        for (index, element) in self.enumerated() {
            result = try combine(result, index, element)
        }
        return result
    }
}

extension Array where Element: Equatable {
    
    mutating func removeObject(_ object: Element) {
        if let index = self.firstIndex(of: object) {
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
        imageView.contentMode = UIView.ContentMode.scaleAspectFill
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

extension SKProduct {
    
    func localizedPrice() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = self.priceLocale
        return formatter.string(from: self.price)!
    }
}

extension UIView {
    
    @IBInspectable var cornerRadius: CGFloat {
        get {
            return self.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
        }
    }
    
    @IBInspectable var borderWidth: CGFloat {
        get {
            return self.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }
    
    @IBInspectable var borderColor: UIColor?  {
        get {
            return self.borderColor
        }
        set {
            layer.borderColor = newValue?.cgColor
        }
    }
    
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
    
    func takeScreenshot() -> UIImage? {
        
        // Begin context
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, UIScreen.main.scale)
        
        // Draw view in that context
        drawHierarchy(in: self.bounds, afterScreenUpdates: true)
        
        // And finally, get image
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
}

extension UIControl.State {
    public static var normal: UIControl.State { return [] }
}

extension Dimmable where Self: UIViewController {
    
    func dim(direction: Constants.SegueDirection, color: UIColor = UIColor.black, alpha: CGFloat = 0.0, speed: Double = 0.0) {
        
        var dimView: UIView!
        
        switch direction {
        case .In:
            
            // Create and add a dim view
            dimView = UIView(frame: view.window!.frame)
            dimView.backgroundColor = color
            dimView.alpha = 0.0
            self.parent?.view.addSubview(dimView)
            
            // Deal with Auto Layout
            dimView.translatesAutoresizingMaskIntoConstraints = false
            dimView.autoPinEdgesToSuperviewEdges()
            
            // Animate alpha (the actual "dimming" effect)
            UIView.animate(withDuration: speed) { () -> Void in
                dimView.alpha = alpha
            }
            
        case .Out:
            
            UIView.animate(withDuration: speed, animations: { () -> Void in
                dimView.alpha = alpha
                }, completion: { (complete) -> Void in
                    dimView.removeFromSuperview()
            })
        }
    }
}

extension UIViewController {
    
    func fixIOS9PopOverAnchor(_ segue:UIStoryboardSegue?) {
        
        guard #available(iOS 9.0, *) else { return }
        if let popOver = segue?.destination.popoverPresentationController,
            let anchor  = popOver.sourceView
            , popOver.sourceRect == CGRect()
                && segue!.source === self
        { popOver.sourceRect = anchor.bounds }
    }
}

extension UIApplication {
    
    class func topViewController(_ base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return topViewController(nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            if let selected = tab.selectedViewController {
                return topViewController(selected)
            }
        }
        if let presented = base?.presentedViewController {
            return topViewController(presented)
        }
        return base
    }
}

extension Dismissible where Self: UIViewController {
    
}
