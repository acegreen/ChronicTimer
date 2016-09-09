//
//  InAppPurchaseViewController.swift
//  Chronic
//
//  Created by Ace Green on 9/2/16.
//  Copyright © 2016 Ace Green. All rights reserved.
//

import UIKit
import StoreKit
import MZFormSheetPresentationController

class InAppPurchaseViewController: UIViewController, MZFormSheetPresentationContentSizing {
    
    enum ProductProperty: Int {
        case ultimatePackage = 0
        case appleWatch = 1
        case removeAds = 2
        case donate = 3
        
        func color() -> UIColor {
            switch self {
            case .ultimatePackage: return UIColor.colorFromRGB(0xF5C018)
            case .appleWatch: return UIColor.colorFromRGB(0x5AD427)
            case .removeAds: return UIColor.colorFromRGB(0xFF3A2D)
            case .donate: return UIColor.colorFromRGB(0x8E8E93)
            }
        }
        
        func image() -> UIImage {
            switch self {
            case .ultimatePackage: return UIImage(named: "ultimate_package")!
            case .appleWatch: return UIImage(named: "apple_watch")!
            case .removeAds: return UIImage(named: "ads_free")!
            case .donate: return UIImage(named: "donate")!
            }
        }
    }
    
    var inAppProducts = [SKProduct]()
    var carouselIndex: Int = 0
    
    var tapBackGroundGesture: UITapGestureRecognizer!
    
    @IBOutlet var carouselView: iCarousel!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        // Move to correct card
        carouselView.currentItemIndex = carouselIndex
    }
    
    public func shouldUseContentViewFrame(for presentationController: MZFormSheetPresentationController!) -> Bool {
        return true
    }
    
    func contentViewFrame(for presentationController: MZFormSheetPresentationController!, currentFrame: CGRect) -> CGRect {
        
        var currentFrame = currentFrame
        currentFrame.size.width = Constants.application.keyWindow!.bounds.size.width
        return currentFrame
    }
    
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(true)
//        
//        self.view.backgroundColor = UIColor.clear
//        
//        // Add dismiss feature
//        tapBackGroundGesture = UITapGestureRecognizer(target: self, action: #selector(InAppPurchaseViewController.settingsBGTapped))
//        tapBackGroundGesture.delegate = self
//        tapBackGroundGesture.numberOfTapsRequired = 1
//        tapBackGroundGesture.cancelsTouchesInView = false
//        self.view.window?.addGestureRecognizer(tapBackGroundGesture)
//    }
//    
//    func settingsBGTapped(sender: UITapGestureRecognizer) {
//        if sender.state == UIGestureRecognizerState.ended {
//            
//            let location = sender.location(in: nil)
//            
//            if !self.view.point(inside: self.view.convert(location, from: self.view.window), with: nil) {
//                // Remove the recognizer first so it's view.window is valid.
//                self.view.window?.removeGestureRecognizer(sender)
//                self.dismiss(animated: true, completion: { () -> Void in
//                })
//            }
//        }
//    }
//    
//    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
//        return true
//    }
//    
//    override func viewWillDisappear(_ animated: Bool) {
//        self.view.window?.removeGestureRecognizer(tapBackGroundGesture)
//    }
    
    
}

extension InAppPurchaseViewController: iCarouselDataSource, iCarouselDelegate {
    
    func numberOfItems(in carousel: iCarousel) -> Int {
        return self.inAppProducts.count
    }
    
    func carousel(_ carousel: iCarousel, viewForItemAt index: Int, reusing view: UIView?) -> UIView {
        
        var itemView: InAppPurchaseReusableView!
        
        //create new view if no view is available for recycling
        if view == nil {
            itemView = InAppPurchaseReusableView(frame: CGRect(x: 0, y: 0, width: 340, height: 450))
        } else {
            itemView = view as! InAppPurchaseReusableView
        }
        
        let productProperty = ProductProperty(rawValue: index)
        
        itemView.view.backgroundColor = productProperty?.color()
        itemView.productIconImageView.image = productProperty?.image()
        
        if productProperty == .ultimatePackage {
            itemView.bestValueImageView.isHidden = false
        }
        
        guard let productAtIndex = self.inAppProducts.get(index) else { return itemView }
        itemView.productTitleLabel.text = productAtIndex.localizedTitle
        itemView.productDescriptionTextView.text = productAtIndex.localizedDescription
        itemView.productPriceLabel.text = productAtIndex.localizedPrice()
        
        return itemView
    }
    
    func carousel(_ carousel: iCarousel, didSelectItemAt index: Int) {
        
        self.dismiss(animated: true) {
            IAPHelper.sharedInstance.buyProduct(product: self.inAppProducts[index])
        }
    }
    
    func carousel(_ carousel: iCarousel, valueFor option: iCarouselOption, withDefault value: CGFloat) -> CGFloat {
        
        if option == .spacing {
            
            return value * 1.05
            
        } else if option == .wrap {
            
            return 1.0
        }
        
        return value
    }
}
