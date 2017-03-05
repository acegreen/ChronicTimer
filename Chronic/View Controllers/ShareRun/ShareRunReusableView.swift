//
//  ShareCardView.swift
//  Chronic
//
//  Created by Ace Green on 2017-01-09.
//  Copyright © 2017 StockSwipe. All rights reserved.
//

import UIKit
import MapKit
import ChronicKit

class ShareRunReusableView: UIView {
    
    @IBOutlet weak var distanceValueLabel: UILabel!
    @IBOutlet weak var distanceUnitLabel: UILabel!
    @IBOutlet weak var distanceTitleLabel: UILabel!
    
    @IBOutlet weak var avgPaceValueLabel: UILabel!
    @IBOutlet weak var avgPaceUnitLabel: UILabel!
    @IBOutlet weak var avePaceTitleLabel: UILabel!
    
    @IBOutlet weak var totalTimeValueLabel: UILabel!
    @IBOutlet weak var totalTimeTitleLabel: UILabel!
    
    @IBOutlet var mapImage: UIImageView!
        
    @IBOutlet weak var topStackView: UIStackView!
    
    var distanceFormatter: MKDistanceFormatter = {
        let distanceFormatter = MKDistanceFormatter()
        //distanceFormatter.units = MKDistanceFormatterUnits.metric
        distanceFormatter.unitStyle = .abbreviated
        return distanceFormatter
    }()
    
    func configure(with workout: Workout) {
        
        self.distanceValueLabel.text = distanceFormatter.string(fromDistance: workout.distance)
        self.avgPaceValueLabel.text = Functions.timeStringFrom(time: Int(workout.pace * 3600))
        self.totalTimeValueLabel.text = Functions.timeStringFrom(time: workout.totalTime)
        
        self.mapImage.image = workout.mapImage
    }
    
    static func loadViewFromNib() -> UIView {
        let bundle = Bundle(for: ShareRunReusableView.self)
        let nib = UINib(nibName: "ShareRunReusableView", bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
        return view
    }
}
