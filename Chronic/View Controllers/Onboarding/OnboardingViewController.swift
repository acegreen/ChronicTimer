import UIKit
import HealthKit
import AMWaveTransition

class OnboardingViewController: AMWaveViewController {

    @IBOutlet var viewArray: [UIView]!

    override func viewDidLoad() {
        super.viewDidLoad()

        updateUI()
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override func visibleCells() -> [AnyObject]! {
        return self.viewArray
    }

    func updateUI() {

    }
    
    @IBAction func forwardButtonAction(_ sender: AnyObject) {
        
        if HKHealthStore.isHealthDataAvailable() {
            self.performSegue(withIdentifier: "OBSegue_HealthController", sender: self)
        } else {
            self.performSegue(withIdentifier: "OBSegue_NotificationController", sender: self)
        }
    }

    @IBAction func backAction() {
        self.navigationController?.popViewController(animated: true)
    }
}
