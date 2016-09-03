//
//  iCarouselTickerView.swift
//  StockSwipe
//
//  Created by Ace Green on 2015-10-21.
//  Copyright © 2015 StockSwipe. All rights reserved.
//

import UIKit
import Foundation
import StoreKit

class InAppPurchaseReusableView: UIView {
    
    var product: SKProduct!
    
    @IBOutlet var productIconImageView: UIImageView!
    
    @IBOutlet var bestValueImageView: UIImageView!
        
    @IBOutlet var productTitleLabel: UILabel!
    
    @IBOutlet var productDescriptionTextView: UITextView!
    
    @IBOutlet var productPriceLabel: UILabel!
    
    var view: UIView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        customInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        customInit()
    }
    
    func customInit() {
        view = loadViewFromNib()
        view.frame = bounds
        addSubview(view)
    }
    
    func loadViewFromNib() -> UIView {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: "InAppPurchaseReusableView", bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
        return view
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)!
        // If the hitView is THIS view, return the view that you want to receive the touch instead:
        if hitView == productDescriptionTextView {
            return self
        }
        // Else return the hitView (as it could be one of this view's buttons):
        return hitView
    }
}
