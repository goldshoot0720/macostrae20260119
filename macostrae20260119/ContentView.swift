import SwiftUI
import UserNotifications

private enum DashboardPalette {
    static let canvasTop = Color(red: 0.05, green: 0.08, blue: 0.14)
    static let canvasBottom = Color(red: 0.02, green: 0.03, blue: 0.06)
    static let cyan = Color(red: 0.27, green: 0.84, blue: 0.98)
    static let blue = Color(red: 0.35, green: 0.51, blue: 1.0)
    static let mint = Color(red: 0.44, green: 0.94, blue: 0.76)
    static let cardFill = Color.white.opacity(0.08)
    static let cardBorder = Color.white.opacity(0.16)
    static let textPrimary = Color.white.opacity(0.96)
    static let textSecondary = Color.white.opacity(0.64)
}

struct ContentView: View {
    @StateObject private var viewModel = SubscriptionViewModel()
    @State private var showUpcomingAlert = false
    @State private var upcomingAlertMessage = ""

    var body: some View {
        ZStack {
            DashboardBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    DashboardHero(refreshAction: reloadSubscriptions)

                    contentSection
                }
                .padding(.horizontal, 28)
                .padding(.top, 28)
                .padding(.bottom, 34)
                .frame(maxWidth: 1180)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Subscriptions")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: reloadSubscriptions) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.plain)
                .help("Refresh")
            }
        }
        .alert("⚠️ 訂閱即將到期", isPresented: $showUpcomingAlert) {
            Button("OK") { }
        } message: {
            Text(upcomingAlertMessage)
        }
        .task {
            await loadInitialData()
        }
    }

    @ViewBuilder
    private var contentSection: some View {
        if viewModel.isLoading {
            LoadingPanel()
        } else if let error = viewModel.errorMessage {
            ErrorPanel(message: error, retryAction: reloadSubscriptions)
        } else {
            LazyVStack(spacing: 18) {
                ForEach(viewModel.subscriptions) { sub in
                    SubscriptionCard(subscription: sub)
                }
            }
        }
    }

    private func reloadSubscriptions() {
        Task {
            await viewModel.loadSubscriptions()
        }
    }

    private func loadInitialData() async {
        let granted = await NotificationManager.shared.requestAuthorization()

        await viewModel.loadSubscriptions()

        let upcoming = viewModel.getUpcomingExpirations()
        if !upcoming.isEmpty {
            let lines = upcoming.map { sub -> String in
                let dateStr = formattedDate(sub.nextdate)
                let daysLeft = relativeDayString(sub.nextdate)
                return "• \(sub.name) — \(dateStr) (\(daysLeft))"
            }
            upcomingAlertMessage = lines.joined(separator: "\n")
            showUpcomingAlert = true
        }

        if granted {
            NotificationManager.shared.checkAndNotifyUpcoming(subscriptions: viewModel.subscriptions)
            NotificationManager.shared.scheduleNotifications(for: viewModel.subscriptions)
        }
    }
}

private struct DashboardHero: View {
    let refreshAction: () -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.12),
                            DashboardPalette.blue.opacity(0.18),
                            DashboardPalette.cyan.opacity(0.14)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(alignment: .topTrailing) {
                    Circle()
                        .fill(DashboardPalette.cyan.opacity(0.18))
                        .frame(width: 220, height: 220)
                        .blur(radius: 12)
                        .offset(x: 32, y: -48)
                }
                .overlay(alignment: .bottomLeading) {
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.16), lineWidth: 1)
                }

            VStack(alignment: .leading, spacing: 20) {
                Text("Subscription Intelligence")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(DashboardPalette.mint)
                    .tracking(1.8)

                Text("Subscriptions")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(DashboardPalette.textPrimary)

                Text("Modernized desktop view with sharper hierarchy, glass surfaces, and a calmer futuristic control-room feel.")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(DashboardPalette.textSecondary)
                    .frame(maxWidth: 620, alignment: .leading)

                Button(action: refreshAction) {
                    Label("Refresh", systemImage: "arrow.clockwise")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                }
                .buttonStyle(HeroButtonStyle())
            }
            .padding(30)
        }
        .frame(minHeight: 220)
    }
}

struct SubscriptionCard: View {
    let subscription: Subscription

    private var dueDate: Date? {
        parseISODate(subscription.nextdate)
    }

    private var formattedPrice: String {
        "\(subscription.currency ?? "USD") \(subscription.price)"
    }

    private var dueLabel: String {
        formattedDate(subscription.nextdate)
    }

    private var relativeDueLabel: String {
        relativeDayString(subscription.nextdate)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 22) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center, spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [DashboardPalette.blue.opacity(0.86), DashboardPalette.cyan.opacity(0.76)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        Image(systemName: "sparkles.rectangle.stack.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.94))
                    }
                    .frame(width: 52, height: 52)

                    VStack(alignment: .leading, spacing: 5) {
                        Text(subscription.name)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(DashboardPalette.textPrimary)

                        if let account = subscription.account, !account.isEmpty {
                            Text(account)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(DashboardPalette.textSecondary)
                        }
                    }
                }

                HStack(spacing: 10) {
                    MetricChip(title: "Next Bill", value: dueLabel)
                    MetricChip(title: "Timeline", value: relativeDueLabel)
                }
            }

            Spacer(minLength: 20)

            VStack(alignment: .trailing, spacing: 16) {
                Text(formattedPrice)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [DashboardPalette.textPrimary, DashboardPalette.cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                if let site = subscription.site, let url = URL(string: site) {
                    Link(destination: url) {
                        Label("Visit", systemImage: "arrow.up.right")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                    }
                    .buttonStyle(CardLinkButtonStyle())
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(DashboardPalette.cardFill)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(DashboardPalette.cardBorder, lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.28), radius: 24, x: 0, y: 18)
    }
}

private struct MetricChip: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(1.1)
                .foregroundStyle(DashboardPalette.textSecondary)

            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(DashboardPalette.textPrimary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.06), in: Capsule())
        .overlay {
            Capsule()
                .strokeBorder(Color.white.opacity(0.09), lineWidth: 1)
        }
    }
}

private struct LoadingPanel: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
                .tint(DashboardPalette.cyan)

            Text("Loading subscriptions...")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(DashboardPalette.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 56)
        .background(panelBackground)
    }

    private var panelBackground: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(DashboardPalette.cardFill)
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(DashboardPalette.cardBorder, lineWidth: 1)
            }
    }
}

private struct ErrorPanel: View {
    let message: String
    let retryAction: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 28))
                .foregroundStyle(.yellow)

            Text("Error")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(DashboardPalette.textPrimary)

            Text(message)
                .multilineTextAlignment(.center)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(DashboardPalette.textSecondary)
                .frame(maxWidth: 540)

            Button("Try Again", action: retryAction)
                .buttonStyle(HeroButtonStyle())
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .padding(.vertical, 44)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(DashboardPalette.cardFill)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(DashboardPalette.cardBorder, lineWidth: 1)
        }
    }
}

private struct DashboardBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [DashboardPalette.canvasTop, DashboardPalette.canvasBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            GeometryReader { proxy in
                let size = proxy.size

                Circle()
                    .fill(DashboardPalette.blue.opacity(0.22))
                    .frame(width: 440, height: 440)
                    .blur(radius: 80)
                    .offset(x: size.width * 0.3, y: -120)

                Circle()
                    .fill(DashboardPalette.cyan.opacity(0.18))
                    .frame(width: 360, height: 360)
                    .blur(radius: 70)
                    .offset(x: -size.width * 0.28, y: size.height * 0.48)

                GridPattern()
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    .ignoresSafeArea()
            }
        }
    }
}

private struct GridPattern: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let step: CGFloat = 44

        stride(from: rect.minX, through: rect.maxX, by: step).forEach { x in
            path.move(to: CGPoint(x: x, y: rect.minY))
            path.addLine(to: CGPoint(x: x, y: rect.maxY))
        }

        stride(from: rect.minY, through: rect.maxY, by: step).forEach { y in
            path.move(to: CGPoint(x: rect.minX, y: y))
            path.addLine(to: CGPoint(x: rect.maxX, y: y))
        }

        return path
    }
}

private struct HeroButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Color.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 11)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                DashboardPalette.blue.opacity(configuration.isPressed ? 0.66 : 0.88),
                                DashboardPalette.cyan.opacity(configuration.isPressed ? 0.58 : 0.82)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .overlay {
                Capsule()
                    .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
            }
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.18), value: configuration.isPressed)
    }
}

private struct CardLinkButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(DashboardPalette.textPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(Color.white.opacity(configuration.isPressed ? 0.12 : 0.08), in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
            }
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

private func parseISODate(_ dateStr: String?) -> Date? {
    guard let dateStr else { return nil }

    let fractionalFormatter = ISO8601DateFormatter()
    fractionalFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

    let fallbackFormatter = ISO8601DateFormatter()
    return fractionalFormatter.date(from: dateStr) ?? fallbackFormatter.date(from: dateStr)
}

private func formattedDate(_ dateStr: String?) -> String {
    guard let date = parseISODate(dateStr) else { return dateStr ?? "N/A" }
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter.string(from: date)
}

private func relativeDayString(_ dateStr: String?) -> String {
    guard let date = parseISODate(dateStr) else { return "N/A" }

    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    let target = calendar.startOfDay(for: date)
    let days = calendar.dateComponents([.day], from: today, to: target).day ?? 0

    if days == 0 { return "今天" }
    if days == 1 { return "明天" }
    if days > 1 { return "\(days) 天後" }
    return "已過期 \(abs(days)) 天"
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
