import UIKit

class OBNotificationViewController: OnboardingViewController {

    @IBOutlet weak var notificationSwitch: UISwitch!
    @IBOutlet var notificationIntervalTextfield: NotificationIntervalTextField!
    @IBOutlet var notificationTimeTextfield: NotificationTimeTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func updateUI() {
        notificationSwitch.isOn = Constants.notificationReminderState
        notificationIntervalTextfield.text = NotificationHelper.interval
        notificationTimeTextfield.text = String(NotificationHelper.hour) + ":00"
    }

    @IBAction func notificationSwitchChanged(_ sender: UISwitch) {
        Constants.userDefaults.set(sender.isOn, forKey: "NOTIFICATION_REMINDER_ENABLED")
        
        Constants.notificationReminderState = Constants.userDefaults.bool(forKey: "NOTIFICATION_REMINDER_ENABLED") as Bool
        NotificationHelper.updateNotificationPreferences(Constants.notificationReminderState)
    }
    
    @IBAction func doneAction() {
        
        Constants.userDefaults.set(true, forKey: "ONBOARDING_SHOWN")
        Functions.loadMainInterface()
    }
    
    func updateNotificationPreferences(_ notificationReminderState: Bool) {
        if notificationReminderState {
            NotificationHelper.registerForPushNotifications()
        } else {
            NotificationHelper.unscheduleNotifications(notificationIdentifier: Constants.NotificationIdentifier.ReminderIdentifier.key())
        }
    }
}
