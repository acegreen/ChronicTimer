import Foundation
import UIKit
import Parse
import UserNotifications

public class NotificationHelper {
    
    static let center = UNUserNotificationCenter.current()
    
    class var interval: String { return userDefaults.string(forKey: "NOTIFICATION_REMINDER_INTERVAL")! }
    class var hour: Int { return userDefaults.integer(forKey: "NOTIFICATION_REMINDER_TIME") ?? 0 }

    class var reminderDateComponents:DateComponents { return DateComponents(calendar: currentCalendar, timeZone: nil, era: nil, year: nil, month: nil, day: nil, hour: hour, minute: nil, second: nil, nanosecond: nil, weekday: nil, weekdayOrdinal: nil, quarter: nil, weekOfMonth: nil, weekOfYear: nil, yearForWeekOfYear: nil) }
    
    class func scheduleNotification(_ dateComponents: DateComponents!, repeatInterval: Calendar.Unit?, alertTitle: String!, alertBody: String!, sound: String!, identifier: String!) {
        
        // Schedule workoutCompleteLocalNotification
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = alertTitle
        notificationContent.body = alertBody
        let notificaitonSound = UNNotificationSound(named: sound)
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
    
    class func checkScheduledNotificationsForNotificationWith(notificationIdentifier: String) -> Bool {
        
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
        if application.isRegisteredForRemoteNotifications() {
            let currentInstallation = PFInstallation.current()
            currentInstallation.badge = 0
            currentInstallation.saveEventually()
        }
    }

    class func registerForNotifications() {
        if application.responds(to: #selector(UIApplication.registerUserNotificationSettings(_:))) {
            let userNotificationTypes: UIUserNotificationType = [.alert, .badge, .sound]
            let settings = UIUserNotificationSettings(types: userNotificationTypes, categories: nil)
            application.registerUserNotificationSettings(settings)
            application.registerForRemoteNotifications()
            
        } else {
            application.registerForRemoteNotifications()
        }
    }

    class func updateNotificationPreferences(_ notificationReminderState: Bool) {
        if notificationReminderState {
            NotificationHelper.unscheduleNotifications(notificationIdentifier: NotificationIdentifier.ReminderIdentifier.key())
            NotificationHelper.registerForNotifications()
        } else {
            NotificationHelper.unscheduleNotifications(notificationIdentifier: NotificationIdentifier.ReminderIdentifier.key())
        }
    }
    
    class func getNSCalendarUnit(_ interval: String) -> Calendar.Unit {
        
        switch interval {
            
            case NSLocalizedString("Week", comment: ""):
            
            return Calendar.Unit.weekOfYear
            
            case NSLocalizedString("Month", comment: ""):
            
            return Calendar.Unit.month
            
            default:
            
            return Calendar.Unit.day
            
        }
    }
}
