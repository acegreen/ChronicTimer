import UIKit
import HealthKit
import AMWaveTransition

class OnboardingViewController: AMWaveViewController {

    @IBOutlet var viewArray: [UIView]!

    override func viewDidLoad() {
        super.viewDidLoad()

        updateUI()
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }

    override func visibleCells() -> [AnyObject]! {
        return self.viewArray
    }

    func updateUI() {

    }
    
    @IBAction func forwardButtonAction(_ sender: AnyObject) {
        
        if HKHealthStore.isHealthDataAvailable() {
            self.performSegueWithIdentifier("OBSegue_HealthController", sender: self)
        } else {
            self.performSegueWithIdentifier("OBSegue_NotificationController", sender: self)
        }
    }

    @IBAction func backAction() {
        self.navigationController?.popViewControllerAnimated(true)
    }
}
