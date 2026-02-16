import SwiftUI
import UserNotifications

struct ContentView: View {
    @StateObject private var viewModel = SubscriptionViewModel()
    
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
        .onAppear {
            NotificationManager.shared.requestAuthorization()
            Task {
                await viewModel.loadSubscriptions()
                // After loading, check for immediate notifications (Step 6)
                NotificationManager.shared.checkAndNotifyUpcoming(subscriptions: viewModel.subscriptions)
                // Schedule future notifications (Step 5)
                NotificationManager.shared.scheduleNotifications(for: viewModel.subscriptions)
            }
        }
    }
}

struct SubscriptionCard: View {
    let subscription: Subscription
    
    var formattedDate: String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let fallbackFormatter = ISO8601DateFormatter()
        
        let date = isoFormatter.date(from: subscription.nextdate) ?? fallbackFormatter.date(from: subscription.nextdate)
        
        if let date = date {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            return displayFormatter.string(from: date)
        }
        return subscription.nextdate
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

#Preview {
    ContentView()
}
