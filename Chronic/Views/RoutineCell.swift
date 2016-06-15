//
//  ExpandingCell.swift
//  ExpandingStackCells
//
//  Created by József Vesza on 27/06/15.
//  Copyright © 2015 Jozsef Vesza. All rights reserved.
//

import UIKit
//import Charts

class RoutineCell: UITableViewCell {
    
    var barPoints: [String]!
    var barValues: [Double]!
    var barColors: [UIColor]!
    
    var name: String? {
        didSet {
            routineName.text = name
        }
    }
    
    var time: String? {
        didSet {
            routineTotalTime.text = time
        }
    }
    
    @IBOutlet private weak var routineName: UILabel!
    @IBOutlet private weak var routineTotalTime: UILabel!
    //@IBOutlet private weak var routineChartView: PieChartView!
    
    func configure(with routine: RoutineModel) {
        
        self.name = routine.name
        self.time = timeStringFrom(time:Int(routine.totalRoutineTime!), type: "Routine")
        
        barPoints = [String]()
        barValues = [Double]()
        barColors = [UIColor]()
        
        let (routineStages, _) = makeRoutineArray(routine)
        
        for stage in routineStages {

            let currentTimerDict = stage
                
            barPoints.append(currentTimerDict["Name"] as! String)
            barValues.append(currentTimerDict["Time"] as! Double)
            barColors.append((NSKeyedUnarchiver.unarchiveObject(with: currentTimerDict["Color"] as! Data) as! UIColor).flatten())
        }
        
        //self.setPieChart(self.barPoints, values: barValues)
    }
    
    
    // MARK: Routine Chart Stuff
    
//    func setPieChart(_ dataPoints: [String], values: [Double]) {
//        
//        var dataEntries: [ChartDataEntry] = []
//        
//        for i in 0..<dataPoints.count {
//            let dataEntry = ChartDataEntry(value: values[i], xIndex: i)
//            dataEntries.append(dataEntry)
//        }
//        
//        let pieChartDataSet = PieChartDataSet(yVals: dataEntries, label: "Routine Data")
//        pieChartDataSet.colors = barColors
//        pieChartDataSet.drawValuesEnabled = false
//        let pieChartData = PieChartData(xVals: dataPoints, dataSet: pieChartDataSet)
//        
//        routineChartView.data = pieChartData
//        routineChartView.isUserInteractionEnabled = false
//        routineChartView.drawSliceTextEnabled = false
//        routineChartView.legend.enabled = false
//        routineChartView.holeColor = nil
//        routineChartView.descriptionText = ""
//    }
    
//    func setBarChart(dataPoints: [String], values: [Double]) {
//        
//        var dataEntries = [BarChartDataEntry]()
//        
//        for i in 0..<dataPoints.count {
//            let dataEntry = BarChartDataEntry(value: values[i], xIndex: i)
//            dataEntries.append(dataEntry)
//        }
//        
//        let chartDataSet = BarChartDataSet(yVals: dataEntries, label: "Routine Data")
//        chartDataSet.drawValuesEnabled = false
//        chartDataSet.colors = barColors
//        chartDataSet.valueFont = UIFont(name: "HelveticaNeue", size: 15.0)!
//        chartDataSet.valueTextColor = chronicColor
//        chartDataSet.barSpace = 0
//        
//        let numberFormatter = NSNumberFormatter()
//        numberFormatter.numberStyle = .NoStyle
//        chartDataSet.valueFormatter = numberFormatter
//        
//        //        routineChartView.noDataText = "Loading Analysts Data"
//        //        routineChartView.infoFont = UIFont(name: "HelveticaNeue", size: 20.0)!
//        //        routineChartView.infoTextColor = Constants.stockSwipeFontColor
//        routineChartView.descriptionText = ""
//        //routineChartView.backgroundColor = UIColor.flatGrayColor()
//        routineChartView.xAxis.labelPosition = .Bottom
//        routineChartView.xAxis.drawLabelsEnabled = false
//        routineChartView.xAxis.drawGridLinesEnabled = false
//        routineChartView.xAxis.labelFont = UIFont(name: "HelveticaNeue", size: 11.0)!
//        routineChartView.xAxis.labelTextColor = chronicColor
//        routineChartView.leftAxis.enabled = false
//        routineChartView.leftAxis.drawGridLinesEnabled = false
//        routineChartView.leftAxis.customAxisMin = 0.0
//        routineChartView.rightAxis.enabled = false
//        routineChartView.rightAxis.drawGridLinesEnabled = false
//        routineChartView.drawBordersEnabled = false
//        routineChartView.drawGridBackgroundEnabled = false
//        routineChartView.legend.enabled = false
//        routineChartView.userInteractionEnabled = false
//        
//        let chartData = BarChartData(xVals: barPoints, dataSet: chartDataSet)
//        routineChartView.data = chartData
//        
//        routineChartView.animate(xAxisDuration: 0.5, yAxisDuration: 0.5)
//    }
}
