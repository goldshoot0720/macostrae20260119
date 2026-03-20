import Combine
import SwiftUI

enum AppSection: String, CaseIterable, Identifiable {
    case subscriptions
    case oilMonitor

    var id: String { rawValue }

    var title: String {
        switch self {
        case .subscriptions:
            return "Subscriptions"
        case .oilMonitor:
            return "原油監控"
        }
    }

    var systemImage: String {
        switch self {
        case .subscriptions:
            return "rectangle.stack.badge.person.crop"
        case .oilMonitor:
            return "barrel.fill"
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
                }
            }
        }
    }
}
