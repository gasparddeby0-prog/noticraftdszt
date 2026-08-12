import SwiftUI
import UserNotifications

@main
struct NotifCraftApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RuleListView()
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                // Recalcule les notifications programmées à chaque retour au premier plan
                // (utile notamment pour le mode "rafale" en secondes).
                let rules = PersistenceStore.shared.load()
                NotificationScheduler.shared.rescheduleAll(rules)
            }
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        NotificationScheduler.shared.requestAuthorization { _ in }
        return true
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge, .list])
    }
}
