import Foundation
import UIKit
import Parse
import UserNotifications

public class NotificationHelper {
    
    static let center = UNUserNotificationCenter.current()
    
    class var interval: String { return Constants.userDefaults.string(forKey: "NOTIFICATION_REMINDER_INTERVAL")! }
    class var hour: Int { return Constants.userDefaults.integer(forKey: "NOTIFICATION_REMINDER_TIME")}

    class var reminderDateComponents: DateComponents { return DateComponents(calendar: Constants.currentCalendar, timeZone: nil, era: nil, year: nil, month: nil, day: nil, hour: hour, minute: nil, second: nil, nanosecond: nil, weekday: nil, weekdayOrdinal: nil, quarter: nil, weekOfMonth: nil, weekOfYear: nil, yearForWeekOfYear: nil) }
    
    class func scheduleNotification(_ dateComponents: DateComponents!, repeatInterval: Calendar.Component?, alertTitle: String!, alertBody: String!, sound: String!, identifier: String!) {
        
        // Schedule workoutCompleteLocalNotification
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = alertTitle
        notificationContent.body = alertBody
        let notificaitonSound = UNNotificationSound(named: UNNotificationSoundName(rawValue: sound!))
        notificationContent.sound = notificaitonSound
        
        var trigger: UNNotificationTrigger!
        if dateComponents != nil {
            trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        }
        
        let request = UNNotificationRequest(identifier: identifier, content: notificationContent, trigger: trigger)
        
        // Schedule the notification.
        center.add(request) { (error) in
            print(error)
        }
        
        center.getPendingNotificationRequests(completionHandler: { (requests) in
            print(requests)
        })
    }

    class func unscheduleNotifications(notificationIdentifier :String?) {
        
        if notificationIdentifier == nil {
            
            center.removeAllPendingNotificationRequests()
            
        } else if let notificationCategory = notificationIdentifier {
                
            center.removePendingNotificationRequests(withIdentifiers: [notificationCategory])
            
            center.getPendingNotificationRequests(completionHandler: { (requests) in
                print(requests)
            })
        }
    }
    
    class func checkScheduledNotificationsForNotificationWith(_ notificationIdentifier: String) -> Bool {
        
        let deliveredNotification: [UNNotification] = {
            var deliveredNotification = [UNNotification]()
            center.getDeliveredNotifications { (notifications) in
                deliveredNotification = notifications
            }
            return deliveredNotification
        }()
        
        guard deliveredNotification.count != 0 else {
            
            print("notification not found")
            return false
        }
        
        for notification in deliveredNotification {
            
            if notification.request.identifier == notificationIdentifier {
                
                print("notification found in scheduled for categoy \(notificationIdentifier)")
                return true
            }
        }
        
        return false
    }
    
    class func resetAppBadgePush() {
        if Constants.application.isRegisteredForRemoteNotifications {
            guard let currentInstallation = PFInstallation.current() else { return }
            currentInstallation.badge = 0
            currentInstallation.saveEventually()
        }
    }

    class func registerForPushNotifications() {
        
        // Unschedule reminder notifications
        self.unscheduleNotifications(notificationIdentifier: Constants.NotificationIdentifier.ReminderIdentifier.key())
        
        if Constants.application.responds(to: #selector(UIApplication.registerUserNotificationSettings(_:))) {
            
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
                
                if granted == true {
                    
                    if Constants.userDefaults.bool(forKey: "NOTIFICATION_REMINDER_ENABLED") == true  {
                    
                        // Schedule reminder notifications if userdefault if true
                        self.scheduleNotification(NotificationHelper.reminderDateComponents, repeatInterval: NotificationHelper.getNSCalendarUnit(NotificationHelper.interval), alertTitle: NSLocalizedString("Notification Reminder Text", comment: ""), alertBody:  NSLocalizedString("Notification Reminder subText", comment: ""), sound: "Boxing.wav", identifier: Constants.NotificationIdentifier.ReminderIdentifier.key())
                    }
                    print("Granted")
                    
                } else if let error = error {
                    print(error)
                }
                
                DispatchQueue.main.async {
                    Constants.application.registerForRemoteNotifications()
                }
            }
            
        } else {
            Constants.application.registerForRemoteNotifications()
        }
    }

    class func updateNotificationPreferences(_ notificationReminderState: Bool) {
        if notificationReminderState {
            NotificationHelper.registerForPushNotifications()
        } else {
            NotificationHelper.unscheduleNotifications(notificationIdentifier: Constants.NotificationIdentifier.ReminderIdentifier.key())
        }
    }
    
    class func getNSCalendarUnit(_ interval: String) -> Calendar.Component {
        
        switch interval {
            
            case NSLocalizedString("Week", comment: ""):
            
            return Calendar.Component.weekOfYear
            
            case NSLocalizedString("Month", comment: ""):
            
            return Calendar.Component.month
            
            default:
            
            return Calendar.Component.day
        }
    }
    
//    // MARK: UNUserNotificationCenterDelegate functions
//    
//    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: (UNNotificationPresentationOptions) -> Void) {
//        
//        print("willPresent notification called")
//    }
//    
//    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: () -> Void) {
//        
//        // Handle received remote notification
//    }
}
