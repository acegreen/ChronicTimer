//
//  ProfileViewController.swift
//  Chronic
//
//  Created by Ace Green on 2015-10-24.
//  Copyright © 2015 Ace Green. All rights reserved.
//

import UIKit

class ProfileViewController: UIViewController, UIScrollViewDelegate {

    let offset_HeaderStop:CGFloat = 40.0 // At this offset the Header stops its transformations
    let offset_B_LabelHeader:CGFloat = 95.0 // At this offset the Black label reaches the Header
    let distance_W_LabelHeader:CGFloat = 35.0 // The distance between the bottom of the Header and the top of the White Label
    
    @IBOutlet var scrollView:UIScrollView!
    @IBOutlet var avatarImage:UIImageView!
    @IBOutlet var header:UIView!
    @IBOutlet var headerLabel:UILabel!
    //@IBOutlet var headerBlurImageView:UIImageView!
    var blurredHeaderImageView:UIImageView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
    
        // Header - Blurred Image
        
//        headerBlurImageView = UIImageView(frame: header.bounds)
//        headerBlurImageView?.image = UIImage(named: "header_bg")?.blurredImageWithRadius(10, iterations: 20, tintColor: UIColor.clearColor())
//        headerBlurImageView?.contentMode = UIViewContentMode.ScaleAspectFill
//        headerBlurImageView?.alpha = 0.0
//        header.insertSubview(headerBlurImageView, belowSubview: headerLabel)
        
        header.clipsToBounds = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        let offset = scrollView.contentOffset.y
        var avatarTransform = CATransform3DIdentity
        
        // PULL DOWN -----------------
        
        if offset < 0 {
            
            let avatarScaleFactor:CGFloat = -(offset) / header.bounds.height
            let avatarSizevariation = ((header.bounds.height * (1.0 + avatarScaleFactor)) - header.bounds.height)/2.0
            avatarTransform = CATransform3DTranslate(avatarTransform, 0, avatarSizevariation, 0)
            avatarTransform = CATransform3DScale(avatarTransform, 1.0 + avatarScaleFactor, 1.0 + avatarScaleFactor, 0)
            
            avatarImage.layer.transform = avatarTransform
        }
            
            // SCROLL UP/DOWN ------------
            
        else {
            
            //  ------------ Label
            
            let labelTransform = CATransform3DMakeTranslation(0, max(-distance_W_LabelHeader, offset_B_LabelHeader - offset), 0)
            headerLabel.layer.transform = labelTransform
            
            //  ------------ Blur
            
            // headerBlurImageView?.alpha = min (1.0, (offset - offset_B_LabelHeader)/distance_W_LabelHeader)
            
            if offset <= offset_HeaderStop {
                
                if avatarImage.layer.zPosition < header.layer.zPosition{
                    header.layer.zPosition = 0
                }
                
            }else {
                if avatarImage.layer.zPosition >= header.layer.zPosition{
                    header.layer.zPosition = 2
                }
            }
        }
    }
}
