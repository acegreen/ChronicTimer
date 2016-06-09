import UIKit

class OBNotificationViewController: OnboardingViewController {

    @IBOutlet weak var notificationSwitch: UISwitch!
    @IBOutlet var notificationIntervalTextfield: NotificationIntervalTextField!
    @IBOutlet var notificationTimeTextfield: NotificationTimeTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func updateUI() {
        notificationSwitch.on = notificationReminderState
        notificationIntervalTextfield.text = NotificationHelper.interval
        notificationTimeTextfield.text = String(NotificationHelper.hour) + ":00"
    }

    @IBAction func notificationSwitchChanged(sender: UISwitch) {
        userDefaults.setBool(sender.on, forKey: "NOTIFICATION_REMINDER_ENABLED")
        userDefaults.synchronize()
        
        notificationReminderState = userDefaults.boolForKey("NOTIFICATION_REMINDER_ENABLED") as Bool
        NotificationHelper.updateNotificationPreferences(notificationReminderState)
    }
    
    @IBAction func doneAction() {
        
        userDefaults.setBool(true, forKey: "ONBOARDING_SHOWN")

        if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
            appDelegate.loadMainInterface()
        }
    }
    
    func updateNotificationPreferences(notificationReminderState: Bool) {
        if notificationReminderState {
            NotificationHelper.unscheduleNotifications(NotificationCategory.ReminderCategory.key())
            NotificationHelper.registerForNotifications()
        } else {
            NotificationHelper.unscheduleNotifications(NotificationCategory.ReminderCategory.key())
        }
    }
}
