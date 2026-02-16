import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            if granted {
                print("✅ Notification permission granted")
            } else {
                print("❌ Notification permission denied")
            }
            return granted
        } catch {
            print("❌ Notification permission error: \(error.localizedDescription)")
            return false
        }
    }
    
    func scheduleNotifications(for subscriptions: [Subscription]) {
        // Clear existing requests to avoid duplicates/outdated info
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let fallbackFormatter = ISO8601DateFormatter()
        
        for sub in subscriptions {
            guard let nextdate = sub.nextdate else { continue }
            var date = dateFormatter.date(from: nextdate)
            if date == nil {
                date = fallbackFormatter.date(from: nextdate)
            }
            
            guard let validDate = date else { continue }
            
            // Schedule for 3 days, 2 days, and 1 day before due date
            for dayOffset in [3, 2, 1] {
                guard let triggerDate = Calendar.current.date(byAdding: .day, value: -dayOffset, to: validDate) else { continue }
                
                // Set time to 6 AM
                var triggerComponents = Calendar.current.dateComponents([.year, .month, .day], from: triggerDate)
                triggerComponents.hour = 6
                triggerComponents.minute = 0
                triggerComponents.second = 0
                
                guard let fireDate = Calendar.current.date(from: triggerComponents) else { continue }
                
                if fireDate < Date() {
                    continue
                }
                
                let content = UNMutableNotificationContent()
                content.title = "Subscription Expiring Soon"
                
                // Format date nicely
                let displayFormatter = DateFormatter()
                displayFormatter.dateStyle = .medium
                displayFormatter.timeStyle = .none
                let dateString = displayFormatter.string(from: validDate)
                
                content.body = "\(sub.name) is renewing on \(dateString) (in \(dayOffset) days)"
                content.sound = .default
                
                let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
                // Unique ID for each day notification: subID_3days, subID_2days...
                let request = UNNotificationRequest(identifier: "\(sub.id)_\(dayOffset)days", content: content, trigger: trigger)
                
                UNUserNotificationCenter.current().add(request)
            }
        }
    }
    
    // Check immediately (Step 6)
    func checkAndNotifyUpcoming(subscriptions: [Subscription]) {
        let upcoming = subscriptions.filter { sub in
             let dateFormatter = ISO8601DateFormatter()
             dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
             let fallbackFormatter = ISO8601DateFormatter()
            
              guard let nextdate = sub.nextdate else { return false }
              var date = dateFormatter.date(from: nextdate)
              if date == nil { date = fallbackFormatter.date(from: nextdate) }
             guard let validDate = date else { return false }
            
             let now = Date()
             // Check if within next 3 days
             let diff = validDate.timeIntervalSince(now)
             return diff > 0 && diff <= (3 * 24 * 3600)
        }
        
        print("📋 Found \(upcoming.count) upcoming subscriptions within 3 days")
        
        for (index, sub) in upcoming.enumerated() {
            let content = UNMutableNotificationContent()
            content.title = "Subscription Expiring Soon"
            
            // Format date nicely
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let fallbackFormatter = ISO8601DateFormatter()
            let date = dateFormatter.date(from: sub.nextdate ?? "") ?? fallbackFormatter.date(from: sub.nextdate ?? "")
            
            var dateString = String((sub.nextdate ?? "N/A").prefix(10))
            var daysString = ""
            
            if let validDate = date {
                let displayFormatter = DateFormatter()
                displayFormatter.dateStyle = .medium
                displayFormatter.timeStyle = .none
                dateString = displayFormatter.string(from: validDate)
                
                let diff = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: Date()), to: Calendar.current.startOfDay(for: validDate))
                if let days = diff.day {
                    daysString = days == 0 ? " (Today)" : " (in \(days) days)"
                }
            }
            
            content.body = "\(sub.name) is renewing on \(dateString)\(daysString)"
            content.sound = .default
            
            // Stagger notifications so they don't overwrite each other
            let delay = TimeInterval(1 + index * 2)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
            // Use a unique ID so we don't overwrite if multiple pop at once
            let request = UNNotificationRequest(identifier: "immediate_\(sub.id)", content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("❌ Error scheduling immediate notification: \(error.localizedDescription)")
                } else {
                    print("✅ Scheduled notification for: \(sub.name) in \(delay)s")
                }
            }
        }
    }
}
