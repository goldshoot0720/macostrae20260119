import Foundation
import SwiftUI

@MainActor
class SubscriptionViewModel: ObservableObject {
    @Published var subscriptions: [Subscription] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func loadSubscriptions() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetched = try await AppwriteService.shared.fetchSubscriptions()
            // Sort by nextdate (near to far)
            self.subscriptions = fetched.sorted { sub1, sub2 in
                // Simple string comparison works for ISO8601, but let's be safe if format varies
                return sub1.nextdate < sub2.nextdate
            }
        } catch {
            self.errorMessage = "Failed to load: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // Helper to get items expiring in next 3 days
    func getUpcomingExpirations() -> [Subscription] {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let now = Date()
        let threeDaysLater = Calendar.current.date(byAdding: .day, value: 3, to: now)!
        
        return subscriptions.filter { sub in
            // Handle Appwrite date format which might vary slightly
            // Try standard ISO8601 first
            var date = dateFormatter.date(from: sub.nextdate)
            if date == nil {
                // Fallback for format without fractional seconds if needed
                let fallbackFormatter = ISO8601DateFormatter()
                date = fallbackFormatter.date(from: sub.nextdate)
            }
            
            guard let validDate = date else { return false }
            return validDate >= now && validDate <= threeDaysLater
        }
    }
}
