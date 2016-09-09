import UIKit

class OBHealthViewController: OnboardingViewController {
    
    @IBAction func healthAccessButtonPressed(_ sender: AnyObject) {
        
        // Request HealthKit Authorization
        HealthKitHelper.sharedInstance.authorizeHealthKit { (success,  error) -> Void in
            
            DispatchQueue.main.async(execute: { () -> Void in
                
                if success {
                    
                    if Constants.userDefaults.bool(forKey: "HEALTHACCESS_PROMPTED") {
                        
                        SweetAlert().showAlert(NSLocalizedString("Alert: Health Prompted Title Text", comment: ""), subTitle: NSLocalizedString("Alert: Health Prompted Subtitle Text", comment: ""), style: AlertStyle.success)
                        
                        print("HealthKit authorization received.")
                        
                    } else {
                        
                        Constants.userDefaults.set(true, forKey: "HEALTHACCESS_PROMPTED")
                    }
                    
                } else if error != nil {
                    SweetAlert().showAlert(NSLocalizedString("Failed", comment: ""), subTitle: error?.localizedDescription, style: AlertStyle.warning)
                    print("\(error)")
                }
            })
        }
    }
}
