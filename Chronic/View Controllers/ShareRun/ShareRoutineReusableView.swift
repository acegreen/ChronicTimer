//
//  ShareRoutineReusableView.swift
//  Chronic
//
//  Created by Ace Green on 2017-01-09.
//  Copyright © 2017 StockSwipe. All rights reserved.
//

import UIKit
import Charts
import ChronicKit

class ShareRoutineReusableView: UIView {
    
    @IBOutlet weak var totalTimeValueLabel: UILabel!
    @IBOutlet weak var totalTimeTitleLabel: UILabel!
    
    @IBOutlet weak var routineChartView: PieChartView!
        
    @IBOutlet weak var topStackView: UIStackView!
    
    var routine: RoutineModel!
    var barPoints = [String]()
    var barValues = [Double]()
    var barColors = [UIColor]()
    
    static func loadViewFromNib() -> UIView {
        let bundle = Bundle(for: ShareRoutineReusableView.self)
        let nib = UINib(nibName: "ShareRoutineReusableView", bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
        return view
    }
    
    func configure(with routine: RoutineModel) {
        
        self.routine = routine
        self.totalTimeValueLabel.text = Functions.timeStringFrom(time: Int(routine.totalRoutineTime))
        
        barPoints.removeAll()
        barValues.removeAll()
        barColors.removeAll()
        
        let (routineStages, _) = Functions.makeRoutineArray(routine: routine)
        
        for stage in routineStages {
            
            let currentTimerDict = stage
            
            barPoints.append(currentTimerDict["Name"] as! String)
            barValues.append(currentTimerDict["Time"] as! Double)
            barColors.append((NSKeyedUnarchiver.unarchiveObject(with: currentTimerDict["Color"] as! Data) as! UIColor))
        }
    
        setupPieChart(barPoints, values: barValues)
    }
    
    func setupPieChart(_ dataPoints: [String], values: [Double]) {
        
        var dataEntries: [ChartDataEntry] = []
        
        for i in 0..<dataPoints.count {
            let dataEntry = ChartDataEntry(x: Double(i), y: values[i])
            dataEntries.append(dataEntry)
        }
        
        let pieChartDataSet = PieChartDataSet(entries: dataEntries, label: "Routine Data")
        pieChartDataSet.colors = barColors
        pieChartDataSet.drawValuesEnabled = false
        let pieChartData = PieChartData(dataSet: pieChartDataSet)
        
        routineChartView.data = pieChartData
        routineChartView.isUserInteractionEnabled = false
        routineChartView.drawEntryLabelsEnabled = false
        routineChartView.holeColor = nil
        routineChartView.chartDescription = nil
        routineChartView.legend.enabled = false
        let stringAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: Constants.CTFonts.regular]
        routineChartView.centerAttributedText = NSAttributedString(string: routine.name, attributes: stringAttributes)
        routineChartView.animate(xAxisDuration: 2.0, yAxisDuration: 2.0, easingOption: ChartEasingOption.easeInOutBack)
    }
}
