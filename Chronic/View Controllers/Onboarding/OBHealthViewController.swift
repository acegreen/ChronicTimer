import UIKit

class OBHealthViewController: OnboardingViewController {
    
    @IBAction func healthAccessButtonPressed(sender: AnyObject) {
        
        // Request HealthKit Authorization
        HealthKitHelper.sharedInstance.authorizeHealthKit { (success,  error) -> Void in
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                
                if success {
                    
                    if userDefaults.boolForKey("HEALTHACCESS_PROMPTED") {
                        
                        SweetAlert().showAlert(NSLocalizedString("Alert: Health Prompted Title Text", comment: ""), subTitle: NSLocalizedString("Alert: Health Prompted Subtitle Text", comment: ""), style: AlertStyle.Success)
                        
                        print("HealthKit authorization received.")
                        
                    } else {
                        
                        userDefaults.setBool(true, forKey: "HEALTHACCESS_PROMPTED")
                    }
                    
                } else if error != nil {
                    SweetAlert().showAlert(NSLocalizedString("Failed", comment: ""), subTitle: error.localizedDescription, style: AlertStyle.Warning)
                    print("\(error)")
                }
            })
        }
    }
}
