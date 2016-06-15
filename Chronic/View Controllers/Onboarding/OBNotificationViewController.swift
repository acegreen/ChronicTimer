import UIKit

class OBNotificationViewController: OnboardingViewController {

    @IBOutlet weak var notificationSwitch: UISwitch!
    @IBOutlet var notificationIntervalTextfield: NotificationIntervalTextField!
    @IBOutlet var notificationTimeTextfield: NotificationTimeTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func updateUI() {
        notificationSwitch.isOn = notificationReminderState
        notificationIntervalTextfield.text = NotificationHelper.interval
        notificationTimeTextfield.text = String(NotificationHelper.hour) + ":00"
    }

    @IBAction func notificationSwitchChanged(_ sender: UISwitch) {
        userDefaults.set(sender.isOn, forKey: "NOTIFICATION_REMINDER_ENABLED")
        userDefaults.synchronize()
        
        notificationReminderState = userDefaults.bool(forKey: "NOTIFICATION_REMINDER_ENABLED") as Bool
        NotificationHelper.updateNotificationPreferences(notificationReminderState)
    }
    
    @IBAction func doneAction() {
        
        userDefaults.set(true, forKey: "ONBOARDING_SHOWN")
        self.dismiss(animated: true, completion: nil)
    }
    
    func updateNotificationPreferences(_ notificationReminderState: Bool) {
        if notificationReminderState {
            NotificationHelper.unscheduleNotifications(NotificationCategory.ReminderCategory.key())
            NotificationHelper.registerForNotifications()
        } else {
            NotificationHelper.unscheduleNotifications(NotificationCategory.ReminderCategory.key())
        }
    }
}
