import SwiftUI

@main
struct UniGramApp: App {
    @StateObject private var colorScheme = ColorSchemeManager()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(colorScheme)
        }
    }
}

/*
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Initialize NotificationManager
        _ = NotificationManager.shared // This was causing the ambiguous 'shared' error
        return true
    }
}
*/
