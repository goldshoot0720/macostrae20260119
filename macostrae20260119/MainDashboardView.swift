import Combine
import SwiftUI

enum AppSection: String, CaseIterable, Identifiable {
    case subscriptions
    case oilMonitor
    case batteryStatus
    case usDebt
    case fengTools
    case bankStats
    case foodManagement
    case fengNotes
    case lotteryReason
    case fengCommon

    var id: String { rawValue }

    var title: String {
        switch self {
        case .subscriptions:
            return "Subscriptions"
        case .oilMonitor:
            return "原油監控"
        case .batteryStatus:
            return "電池狀態"
        case .usDebt:
            return "美國國債"
        case .fengTools:
            return "鋒兄工具"
        case .bankStats:
            return "銀行統計"
        case .foodManagement:
            return "食物管理"
        case .fengNotes:
            return "鋒兄筆記"
        case .lotteryReason:
            return "抽籤理由"
        case .fengCommon:
            return "常用帳號"
        }
    }

    var systemImage: String {
        switch self {
        case .subscriptions:
            return "rectangle.stack.badge.person.crop"
        case .oilMonitor:
            return "barrel.fill"
        case .batteryStatus:
            return "battery.100percent"
        case .usDebt:
            return "chart.line.uptrend.xyaxis"
        case .fengTools:
            return "wrench.and.screwdriver.fill"
        case .bankStats:
            return "building.columns.fill"
        case .foodManagement:
            return "fork.knife"
        case .fengNotes:
            return "note.text"
        case .lotteryReason:
            return "number.square.fill"
        case .fengCommon:
            return "person.2.badge.key.fill"
        }
    }

    var subtitle: String {
        switch self {
        case .subscriptions:
            return "Appwrite subscription data and renewal timeline."
        case .oilMonitor:
            return "OQD daily marker price monitor."
        case .batteryStatus:
            return "Battery health and charging state from the Android dashboard."
        case .usDebt:
            return "US debt trend panel from the Android dashboard."
        case .fengTools:
            return "Price and phone comparison tools."
        case .bankStats:
            return "Bank account and deposit summary."
        case .foodManagement:
            return "Food inventory and expiry management."
        case .fengNotes:
            return "Personal notes and article list."
        case .lotteryReason:
            return "Lottery reason tracker."
        case .fengCommon:
            return "Common account vault overview."
        }
    }
}

@MainActor
final class AppNavigationState: ObservableObject {
    @Published var selectedSection: AppSection? = .subscriptions

    func show(_ section: AppSection) {
        selectedSection = section
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first {
            window.makeKeyAndOrderFront(nil)
        }
    }
}

struct MainDashboardView: View {
    @EnvironmentObject private var navigationState: AppNavigationState
    @EnvironmentObject private var crudeOilMonitor: CrudeOilMonitor

    var body: some View {
        NavigationSplitView {
            List(AppSection.allCases, selection: $navigationState.selectedSection) { section in
                Label(section.title, systemImage: section.systemImage)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .padding(.vertical, 4)
                    .tag(section)
            }
            .navigationTitle("Workspace")
            .frame(minWidth: 220)
        } detail: {
            Group {
                switch navigationState.selectedSection ?? .subscriptions {
                case .subscriptions:
                    ContentView()
                case .oilMonitor:
                    CrudeOilMonitorView()
                        .environmentObject(crudeOilMonitor)
                case .batteryStatus:
                    FeaturePlaceholderView(section: .batteryStatus)
                case .usDebt:
                    FeaturePlaceholderView(section: .usDebt)
                case .fengTools:
                    FeaturePlaceholderView(section: .fengTools)
                case .bankStats:
                    FeaturePlaceholderView(section: .bankStats)
                case .foodManagement:
                    FeaturePlaceholderView(section: .foodManagement)
                case .fengNotes:
                    FeaturePlaceholderView(section: .fengNotes)
                case .lotteryReason:
                    FeaturePlaceholderView(section: .lotteryReason)
                case .fengCommon:
                    FeaturePlaceholderView(section: .fengCommon)
                }
            }
        }
    }
}

struct FeaturePlaceholderView: View {
    let section: AppSection

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.07, blue: 0.10),
                    Color(red: 0.08, green: 0.13, blue: 0.16),
                    Color(red: 0.12, green: 0.09, blue: 0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 18) {
                Image(systemName: section.systemImage)
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(.cyan)

                Text(section.title)
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text(section.subtitle)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.72))
                    .fixedSize(horizontal: false, vertical: true)

                Text("This menu item is now available in the macOS sidebar. The Android feature screen can be ported here next.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.56))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 6)
            }
            .frame(maxWidth: 680, alignment: .leading)
            .padding(34)
            .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(.white.opacity(0.16), lineWidth: 1)
            )
            .padding(40)
        }
    }
}
