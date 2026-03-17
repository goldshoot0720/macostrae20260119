import SwiftUI
import UserNotifications

struct ContentView: View {
    @StateObject private var viewModel = SubscriptionViewModel()
    @State private var showUpcomingAlert = false
    @State private var upcomingAlertMessage = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if viewModel.isLoading {
                    ProgressView("Loading subscriptions...")
                        .padding()
                } else if let error = viewModel.errorMessage {
                    ContentUnavailableView("Error", systemImage: "exclamationmark.triangle", description: Text(error))
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.subscriptions) { sub in
                            SubscriptionCard(subscription: sub)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Subscriptions")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        Task { await viewModel.loadSubscriptions() }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .alert("⚠️ 訂閱即將到期", isPresented: $showUpcomingAlert) {
            Button("OK") { }
        } message: {
            Text(upcomingAlertMessage)
        }
        .onAppear {
            Task {
                // First, request permission and wait for it
                let granted = await NotificationManager.shared.requestAuthorization()
                
                // Load subscriptions
                await viewModel.loadSubscriptions()
                
                // Get upcoming subscriptions within 3 days
                let upcoming = viewModel.getUpcomingExpirations()
                
                // Show in-app alert for upcoming subscriptions
                if !upcoming.isEmpty {
                    let lines = upcoming.map { sub -> String in
                        let dateStr = formatDate(sub.nextdate)
                        let daysLeft = daysUntil(sub.nextdate)
                        return "• \(sub.name) — \(dateStr) (\(daysLeft))"
                    }
                    upcomingAlertMessage = lines.joined(separator: "\n")
                    showUpcomingAlert = true
                }
                
                // Also schedule system notifications if permission was granted
                if granted {
                    NotificationManager.shared.checkAndNotifyUpcoming(subscriptions: viewModel.subscriptions)
                    NotificationManager.shared.scheduleNotifications(for: viewModel.subscriptions)
                }
            }
        }
    }
    
    private func formatDate(_ dateStr: String?) -> String {
        guard let dateStr = dateStr else { return "N/A" }
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let fallbackFormatter = ISO8601DateFormatter()
        if let date = isoFormatter.date(from: dateStr) ?? fallbackFormatter.date(from: dateStr) {
            let df = DateFormatter()
            df.dateStyle = .medium
            return df.string(from: date)
        }
        return dateStr
    }
    
    private func daysUntil(_ dateStr: String?) -> String {
        guard let dateStr = dateStr else { return "" }
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let fallbackFormatter = ISO8601DateFormatter()
        if let date = isoFormatter.date(from: dateStr) ?? fallbackFormatter.date(from: dateStr) {
            let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: Date()), to: Calendar.current.startOfDay(for: date)).day ?? 0
            if days == 0 { return "今天" }
            if days == 1 { return "明天" }
            return "\(days) 天後"
        }
        return ""
    }
}

struct SubscriptionCard: View {
    let subscription: Subscription
    
    var formattedDate: String {
        guard let nextdate = subscription.nextdate else { return "N/A" }
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let fallbackFormatter = ISO8601DateFormatter()
        
        let date = isoFormatter.date(from: nextdate) ?? fallbackFormatter.date(from: nextdate)
        
        if let date = date {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            return displayFormatter.string(from: date)
        }
        return nextdate
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(subscription.name)
                    .font(.headline)
                
                if let account = subscription.account, !account.isEmpty {
                    Text(account)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Text("Next Bill: \(formattedDate)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("\(subscription.currency ?? "USD") \(subscription.price)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.blue)
                
                if let site = subscription.site, let url = URL(string: site) {
                    Link("Visit", destination: url)
                        .font(.caption)
                        .buttonStyle(.bordered)
                }
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
