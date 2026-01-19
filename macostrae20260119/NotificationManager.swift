import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }
    
    func scheduleNotifications(for subscriptions: [Subscription]) {
        // Clear existing requests to avoid duplicates/outdated info
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let fallbackFormatter = ISO8601DateFormatter()
        
        for sub in subscriptions {
            var date = dateFormatter.date(from: sub.nextdate)
            if date == nil {
                date = fallbackFormatter.date(from: sub.nextdate)
            }
            
            guard let validDate = date else { continue }
            
            // Calculate 3 days before
            guard let triggerDate = Calendar.current.date(byAdding: .day, value: -3, to: validDate) else { continue }
            
            // If the trigger date is in the past, don't schedule (or maybe check if it's TODAY and hasn't happened?)
            // The requirement says "Daily check... 6 AM... for items expiring in 3 days".
            // So on (Due Date - 3), at 6 AM, show notification.
            
            // Set time to 6 AM
            var triggerComponents = Calendar.current.dateComponents([.year, .month, .day], from: triggerDate)
            triggerComponents.hour = 6
            triggerComponents.minute = 0
            triggerComponents.second = 0
            
            guard let fireDate = Calendar.current.date(from: triggerComponents) else { continue }
            
            if fireDate < Date() {
                // If the 6AM notification time for this cycle has passed, maybe skip or show immediately if it's "today"?
                // Let's just skip past notifications to avoid spamming on launch
                continue
            }
            
            let content = UNMutableNotificationContent()
            content.title = "Subscription Expiring Soon"
            content.body = "\(sub.name) is renewing on \(sub.nextdate.prefix(10)) for $\(sub.price)"
            content.sound = .default
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
            let request = UNNotificationRequest(identifier: sub.id, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request)
        }
    }
    
    // Check immediately (Step 6)
    func checkAndNotifyUpcoming(subscriptions: [Subscription]) {
        let upcoming = subscriptions.filter { sub in
             let dateFormatter = ISO8601DateFormatter()
             dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
             let fallbackFormatter = ISO8601DateFormatter()
            
             var date = dateFormatter.date(from: sub.nextdate)
             if date == nil { date = fallbackFormatter.date(from: sub.nextdate) }
             guard let validDate = date else { return false }
            
             let now = Date()
             // Check if within next 3 days
             let diff = validDate.timeIntervalSince(now)
             return diff > 0 && diff <= (3 * 24 * 3600)
        }
        
        for sub in upcoming {
            let content = UNMutableNotificationContent()
            content.title = "Subscription Expiring Soon"
            content.body = "\(sub.name) is renewing on \(sub.nextdate.prefix(10))"
            content.sound = .default
            
            // Trigger immediately (after 1 sec)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            // Use a unique ID so we don't overwrite if multiple pop at once
            let request = UNNotificationRequest(identifier: "immediate_\(sub.id)", content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request)
        }
    }
}
