import Foundation
import SwiftUI
import Combine

@MainActor
final class SubscriptionViewModel: ObservableObject {
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
                let isoFormatter = ISO8601DateFormatter()
                isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                let fallbackFormatter = ISO8601DateFormatter()
                
                let date1 = isoFormatter.date(from: sub1.nextdate) ?? fallbackFormatter.date(from: sub1.nextdate) ?? Date.distantFuture
                let date2 = isoFormatter.date(from: sub2.nextdate) ?? fallbackFormatter.date(from: sub2.nextdate) ?? Date.distantFuture
                
                return date1 < date2
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
