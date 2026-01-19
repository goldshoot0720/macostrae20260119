import SwiftUI
import UserNotifications
import ServiceManagement

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().delegate = self
    }
    
    // Show notification even when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
    
    // Keep app running after last window closed
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}

@main
struct macostrae20260119App: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
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
    }
}
