import Foundation
import UIKit
import Parse

public class NotificationHelper {
    
    class var interval: String { return userDefaults.string(forKey: "NOTIFICATION_REMINDER_INTERVAL")! }
    class var hour: Int { return userDefaults.integer(forKey: "NOTIFICATION_REMINDER_TIME") ?? 0 }

    class var reminderDate:Date { return currentCalendar.date(bySettingHour: hour, minute: 0, second: 0, of: Date(), options: Calendar.Options())! }
    
    class func scheduleNotification(_ date: Date?, repeatInterval: Calendar.Unit?, alertTitle: String?, alertBody: String?, sound: String?, category: String?) {
        
        let localNotification = UILocalNotification()
        
        if date != nil {
            localNotification.fireDate = date!
        }
        
        if repeatInterval != nil {
            localNotification.repeatInterval = repeatInterval!
        }
        
        if #available(iOS 8.2, *) {
            localNotification.alertTitle = alertTitle
        }
        
        localNotification.alertBody = alertBody
        localNotification.soundName = sound
        localNotification.category = category
        
        UIApplication.shared().scheduleLocalNotification(localNotification)
        print(UIApplication.shared().scheduledLocalNotifications)
    }

    class func unscheduleNotifications(_ notificationCategory:String?) {
        
        if notificationCategory == nil {
            
            UIApplication.shared().cancelAllLocalNotifications()
            
        } else if let notificationScheduled = checkScheduledNotificationsForNotificationWith(notificationCategory!) {
                
            UIApplication.shared().cancelLocalNotification(notificationScheduled)
        }
    }
    
    class func checkScheduledNotificationsForNotificationWith(_ category:String) -> UILocalNotification? {
            
        guard let scheduledNotifications = UIApplication.shared().scheduledLocalNotifications else {
            
            print("notification found in scheduled")
            return nil
        }
        
        for notification in scheduledNotifications {
            
            if notification.category == category {
                
                print("notification found in scheduled for categoy \(category)")
                return notification
            }
        }
        
        print("No notification in scheduled for categoy \(category)")
        return nil
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
            NotificationHelper.unscheduleNotifications(NotificationCategory.ReminderCategory.key())
            NotificationHelper.registerForNotifications()
        } else {
            NotificationHelper.unscheduleNotifications(NotificationCategory.ReminderCategory.key())
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
