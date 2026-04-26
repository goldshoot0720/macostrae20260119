import SwiftUI
import UserNotifications
import ServiceManagement

private enum LaunchMode {
    static let launchAtLoginArgument = "--launch-at-login"

    static var isLaunchAtLogin: Bool {
        ProcessInfo.processInfo.arguments.contains(launchAtLoginArgument)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().delegate = self
        Task { @MainActor in
            CrudeOilMonitor.shared.start()
        }
        Task {
            await NotificationManager.shared.refreshSubscriptionNotifications()
        }

        if LaunchMode.isLaunchAtLogin {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                NSApp.windows.forEach { window in
                    window.miniaturize(nil)
                    window.orderBack(nil)
                }
                NSApp.hide(nil)
            }
        }
    }
    
    // Show notification even when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("🔔 willPresent called for: \(notification.request.content.title) - \(notification.request.content.body)")
        completionHandler([.banner, .list, .sound])
    }
    
    // Keep app running after last window closed
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}

@main
struct macostrae20260119App: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var crudeOilMonitor = CrudeOilMonitor.shared
    @StateObject private var navigationState = AppNavigationState()
    
    var body: some Scene {
        WindowGroup {
            MainDashboardView()
                .environmentObject(navigationState)
                .environmentObject(crudeOilMonitor)
                .onAppear {
                    // Step 4: Auto-start on boot
                    // Note: This requires the app to be signed and possibly in /Applications to work reliably in production
                    // For development, it might fail or behave unexpectedly without proper signing.
                    if #available(macOS 13.0, *) {
                        do {
                            if SMAppService.mainApp.status == .notRegistered {
                                try SMAppService.mainApp.register()
                                print("Registered for login item")
                            }
                        } catch {
                            print("Failed to register login item: \(error)")
                        }
                    }
                }
        }
        .defaultSize(width: 1480, height: 920)

        Window("原油監控", id: "oil-monitor") {
            CrudeOilMonitorView()
                .environmentObject(crudeOilMonitor)
        }
        .defaultSize(width: 1180, height: 820)
        
        MenuBarExtra("Subscriptions", systemImage: "calendar.badge.clock") {
            SubscriptionsMenuBarView()
                .environmentObject(navigationState)
        }

        MenuBarExtra("原油監控", systemImage: "barrel.fill") {
            OilMonitorMenuBarView()
                .environmentObject(navigationState)
                .environmentObject(crudeOilMonitor)
        }
    }
}

private struct SubscriptionsMenuBarView: View {
    @EnvironmentObject private var navigationState: AppNavigationState

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(AppSection.allCases) { section in
                Button {
                    navigationState.show(section)
                } label: {
                    Label(section.title, systemImage: section.systemImage)
                }
            }

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(6)
        .frame(width: 240)
    }
}
