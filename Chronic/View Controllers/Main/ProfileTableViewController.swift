//
//  ProfileViewController.swift
//  HKTutorial
//
//  Created by ernesto on 18/10/14.
//  Copyright (c) 2014 raywenderlich. All rights reserved.
//

import UIKit
import HealthKit

class ProfileTableViewController: UITableViewController {
    
    let UpdateProfileInfoSection = 2
    let SaveBMISection = 3
    let kUnknownString   = "Unknown"
    
    @IBOutlet var ageLabel:UILabel!
    @IBOutlet var bloodTypeLabel:UILabel!
    @IBOutlet var biologicalSexLabel:UILabel!
    @IBOutlet var weightLabel:UILabel!
    @IBOutlet var heightLabel:UILabel!
    @IBOutlet var bmiLabel:UILabel!
    
    var bmi:Double?
    var height, weight:HKQuantitySample?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        if let view = view as? UITableViewHeaderFooterView {
            
            view.textLabel!.textColor = UIColor.white()
            
        }
        
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        cell.backgroundColor = UIColor.clear()
    }
    
    func updateHealthInfo() {
        
        updateProfileInfo()
        updateWeight()
        updateHeight()
        
        print("updateHealthInfo called")
        
    }
    
    func updateProfileInfo() {
        
        let profile = HealthKitHelper.sharedInstance.readProfile()
        
        ageLabel.text = profile.age == nil ? kUnknownString : String(profile.age!)
        biologicalSexLabel.text = biologicalSexLiteral(profile.biologicalsex?.biologicalSex)
        bloodTypeLabel.text = bloodTypeLiteral(profile.bloodtype?.bloodType)
    
    }
    
    func updateHeight() {
        
        // 1. Construct an HKSampleType for Height
        let sampleType = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.height)
        
        // 2. Call the method to read the most recent Height sample
        HealthKitHelper.sharedInstance.readMostRecentSample(sampleType!, completion: { (mostRecentHeight, error) -> Void in
            
            if error != nil {
                
                print("Error reading height from HealthKit Store: \(error.localizedDescription)")
                return;
            }
            
            var heightLocalizedString = self.kUnknownString;
            self.height = mostRecentHeight as? HKQuantitySample;
            
            // 3. Format the height to display it on the screen
            if let meters = self.height?.quantity.doubleValue(for: HKUnit.meter()) {
                let heightFormatter = LengthFormatter()
                heightFormatter.isForPersonHeightUse = true;
                heightLocalizedString = heightFormatter.string(fromMeters: meters);
            }
            
            // 4. Update UI. HealthKit use an internal queue. We make sure that we interact with the UI in the main thread
            DispatchQueue.main.async(execute: { () -> Void in
                self.heightLabel.text = heightLocalizedString
                self.updateBMI()
            });
        })
        
    }
    
    func updateWeight() {
        
        // 1. Construct an HKSampleType for weight
        let sampleType = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMass)
        
        // 2. Call the method to read the most recent weight sample
        HealthKitHelper.sharedInstance.readMostRecentSample(sampleType!, completion: { (mostRecentWeight, error) -> Void in
            
            if( error != nil )
            {
                print("Error reading weight from HealthKit Store: \(error.localizedDescription)")
                return;
            }
            
            var weightLocalizedString = self.kUnknownString;
            // 3. Format the weight to display it on the screen
            self.weight = mostRecentWeight as? HKQuantitySample;
            if let kilograms = self.weight?.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo)) {
                let weightFormatter = MassFormatter()
                weightFormatter.isForPersonMassUse = true;
                weightLocalizedString = weightFormatter.string(fromKilograms: kilograms)
            }
            
            // 4. Update UI in the main thread
            DispatchQueue.main.async(execute: { () -> Void in
                self.weightLabel.text = weightLocalizedString
                self.updateBMI()
                
            });
        });
    }
    
    func updateBMI() {
        
        if weight != nil && height != nil {
            // 1. Get the weight and height values from the samples read from HealthKit
            let weightInKilograms = weight!.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
            let heightInMeters = height!.quantity.doubleValue(for: HKUnit.meter())
            // 2. Call the method to calculate the BMI
            bmi  = calculateBMIWithWeightInKilograms(weightInKilograms, heightInMeters: heightInMeters)
        }
        
        // 3. Show the calculated BMI
        //var bmiString = kUnknownString
        if bmi != nil {
            bmiLabel.text =  String(format: "%.02f", bmi!)
        }
        
    }
    
    func saveBMI() {
        
        // Save BMI value with current BMI value
        if bmi != nil {
            
            HealthKitHelper.sharedInstance.saveBMISample(bmi!, date: Date())
        }
        else {
            print("There is no BMI data to save")
        }
        
    }
    
    // MARK: - utility methods
    
    func calculateBMIWithWeightInKilograms(_ weightInKilograms:Double, heightInMeters:Double) -> Double? {
        
        if heightInMeters == 0 {
            return nil;
        }
        return (weightInKilograms/(heightInMeters*heightInMeters));
    }
    
    
    func biologicalSexLiteral(_ biologicalSex:HKBiologicalSex?)->String {
        
        var biologicalSexText = kUnknownString;
        
        if  biologicalSex != nil {
            
            switch( biologicalSex! )
            {
            case .female:
                biologicalSexText = "Female"
            case .male:
                biologicalSexText = "Male"
            default:
                break;
            }
            
        }
        
        return biologicalSexText;
    }
    
    func bloodTypeLiteral(_ bloodType:HKBloodType?)->String {
        
        var bloodTypeText = kUnknownString;
        
        if bloodType != nil {
            
            switch( bloodType! ) {
            case .aPositive:
                bloodTypeText = "A+"
            case .aNegative:
                bloodTypeText = "A-"
            case .bPositive:
                bloodTypeText = "B+"
            case .bNegative:
                bloodTypeText = "B-"
            case .abPositive:
                bloodTypeText = "AB+"
            case .abNegative:
                bloodTypeText = "AB-"
            case .oPositive:
                bloodTypeText = "O+"
            case .oNegative:
                bloodTypeText = "O-"
            default:
                break;
            }
            
        }
        return bloodTypeText;
    }
    
//    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
//        tableView.deselectRowAtIndexPath(indexPath , animated: true)
//        
//        switch (indexPath.section, indexPath.row)
//        {
//        case (UpdateProfileInfoSection,0):
//            updateHealthInfo()
//        case (SaveBMISection,0):
//            saveBMI()
//        default:
//            break;
//        }
//        
//        
//    }
    
}
