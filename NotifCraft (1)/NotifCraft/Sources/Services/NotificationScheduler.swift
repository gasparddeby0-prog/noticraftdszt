import UserNotifications
import UIKit

final class NotificationScheduler {
    static let shared = NotificationScheduler()
    private init() {}

    /// iOS plafonne à 64 notifications locales programmées par app.
    /// On garde une marge de sécurité.
    private let systemHardLimit = 64
    private let safeLimit = 58

    // MARK: - Autorisation

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async { completion(granted) }
        }
    }

    func authorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async { completion(settings.authorizationStatus) }
        }
    }

    // MARK: - Reprogrammation globale

    /// Annule tout puis reprogramme toutes les règles actives et valides.
    /// À appeler après chaque modification, et à chaque lancement / passage au premier plan.
    func rescheduleAll(_ rules: [NotificationRule]) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        let now = Date()
        let validRules = rules.filter { rule in
            rule.isActive && (rule.effectiveEndDate == nil || rule.effectiveEndDate! > now)
        }

        // Seules les règles en mode "rafale" (everySeconds) consomment plusieurs
        // emplacements. Les autres (once, daily, weekly, everyMinutes, everyHours)
        // n'utilisent qu'un seul déclencheur répétitif natif = 1 emplacement.
        let burstRules = validRules.filter { $0.frequency.kind == .everySeconds }
        let singleSlotRules = validRules.filter { $0.frequency.kind != .everySeconds }

        let reservedForSingleSlot = singleSlotRules.count
        let remainingForBursts = max(safeLimit - reservedForSingleSlot, burstRules.isEmpty ? 0 : burstRules.count)
        let perBurstBudget = burstRules.isEmpty ? 0 : max(1, remainingForBursts / burstRules.count)

        for rule in singleSlotRules {
            for request in buildRequests(for: rule, budget: 1) {
                center.add(request)
            }
        }
        for rule in burstRules {
            for request in buildRequests(for: rule, budget: perBurstBudget) {
                center.add(request)
            }
        }
    }

    // MARK: - Construction des requêtes

    private func buildRequests(for rule: NotificationRule, budget: Int) -> [UNNotificationRequest] {
        let content = makeContent(for: rule)
        let calendar = Calendar.current
        let now = Date()

        switch rule.frequency.kind {
        case .once:
            guard rule.startDate > now else { return [] }
            let comps = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: rule.startDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            return [UNNotificationRequest(identifier: rule.id.uuidString, content: content, trigger: trigger)]

        case .everySeconds:
            let interval = max(1, rule.frequency.intervalValue)
            var requests: [UNNotificationRequest] = []
            for i in 1...max(1, budget) {
                let fireInSeconds = TimeInterval(interval * i)
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: fireInSeconds, repeats: false)
                let identifier = "\(rule.id.uuidString)-\(i)"
                requests.append(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
            }
            return requests

        case .everyMinutes:
            let seconds = max(60, rule.frequency.intervalValue * 60)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(seconds), repeats: true)
            return [UNNotificationRequest(identifier: rule.id.uuidString, content: content, trigger: trigger)]

        case .everyHours:
            let seconds = max(60, rule.frequency.intervalValue * 3600)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(seconds), repeats: true)
            return [UNNotificationRequest(identifier: rule.id.uuidString, content: content, trigger: trigger)]

        case .daily:
            var comps = calendar.dateComponents([.hour, .minute], from: rule.frequency.timeOfDay)
            comps.second = 0
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
            return [UNNotificationRequest(identifier: rule.id.uuidString, content: content, trigger: trigger)]

        case .weekly:
            var comps = calendar.dateComponents([.hour, .minute], from: rule.frequency.timeOfDay)
            comps.weekday = rule.frequency.weekday
            comps.second = 0
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
            return [UNNotificationRequest(identifier: rule.id.uuidString, content: content, trigger: trigger)]
        }
    }

    private func makeContent(for rule: NotificationRule) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = rule.title.isEmpty ? "NotifCraft" : rule.title
        content.body = rule.body
        content.sound = rule.soundEnabled ? .default : nil
        content.userInfo = ["ruleId": rule.id.uuidString]

        if let fileName = rule.imageFileName {
            let imageURL = ImageStore.shared.url(for: fileName)
            if FileManager.default.fileExists(atPath: imageURL.path),
               let attachment = try? UNNotificationAttachment(identifier: fileName, url: imageURL) {
                content.attachments = [attachment]
            }
        }
        return content
    }

    // MARK: - Aperçu immédiat

    func sendPreview(for rule: NotificationRule) {
        let content = makeContent(for: rule)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(identifier: "preview-\(rule.id.uuidString)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - État

    func pendingCount(completion: @escaping (Int) -> Void) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            DispatchQueue.main.async { completion(requests.count) }
        }
    }

    func resetBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0)
    }
}
