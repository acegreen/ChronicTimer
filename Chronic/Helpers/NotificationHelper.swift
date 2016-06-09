import Foundation
import UIKit
import Parse

public class NotificationHelper {
    
    class var interval: String { return userDefaults.stringForKey("NOTIFICATION_REMINDER_INTERVAL")! }
    class var hour: Int { return userDefaults.integerForKey("NOTIFICATION_REMINDER_TIME") ?? 0 }

    class var reminderDate:NSDate { return currentCalendar.dateBySettingHour(hour, minute: 0, second: 0, ofDate: NSDate(), options: NSCalendarOptions())! }
    
    class func scheduleNotification(date: NSDate?, repeatInterval: NSCalendarUnit?, alertTitle: String?, alertBody: String?, sound: String?, category: String?) {
        
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
        
        UIApplication.sharedApplication().scheduleLocalNotification(localNotification)
        print(UIApplication.sharedApplication().scheduledLocalNotifications)
    }

    class func unscheduleNotifications(notificationCategory:String?) {
        
        if notificationCategory == nil {
            
            UIApplication.sharedApplication().cancelAllLocalNotifications()
            
        } else if let notificationScheduled = checkScheduledNotificationsForNotificationWith(notificationCategory!) {
                
            UIApplication.sharedApplication().cancelLocalNotification(notificationScheduled)
        }
    }
    
    class func checkScheduledNotificationsForNotificationWith(category:String) -> UILocalNotification? {
            
        guard let scheduledNotifications = UIApplication.sharedApplication().scheduledLocalNotifications else {
            
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
            let currentInstallation = PFInstallation.currentInstallation()
            currentInstallation.badge = 0
            currentInstallation.saveEventually()
        }
    }

    class func registerForNotifications() {
        if application.respondsToSelector(#selector(UIApplication.registerUserNotificationSettings(_:))) {
            let userNotificationTypes: UIUserNotificationType = [.Alert, .Badge, .Sound]
            let settings = UIUserNotificationSettings(forTypes: userNotificationTypes, categories: nil)
            application.registerUserNotificationSettings(settings)
            application.registerForRemoteNotifications()
            
        } else {
            application.registerForRemoteNotifications()
        }
    }

    class func updateNotificationPreferences(notificationReminderState: Bool) {
        if notificationReminderState {
            NotificationHelper.unscheduleNotifications(NotificationCategory.ReminderCategory.key())
            NotificationHelper.registerForNotifications()
        } else {
            NotificationHelper.unscheduleNotifications(NotificationCategory.ReminderCategory.key())
        }
    }
    
    class func getNSCalendarUnit(interval: String) -> NSCalendarUnit {
        
        switch interval {
            
            case NSLocalizedString("Week", comment: ""):
            
            return NSCalendarUnit.WeekOfYear
            
            case NSLocalizedString("Month", comment: ""):
            
            return NSCalendarUnit.Month
            
            default:
            
            return NSCalendarUnit.Day
            
        }
    }
}
