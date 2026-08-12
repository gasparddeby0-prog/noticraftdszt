import Foundation

/// Les différents rythmes de répétition proposés à l'utilisateur.
enum FrequencyKind: String, Codable, CaseIterable, Identifiable {
    case once = "Une seule fois"
    case everySeconds = "Toutes les X secondes (rafale)"
    case everyMinutes = "Toutes les X minutes"
    case everyHours = "Toutes les X heures"
    case daily = "Chaque jour"
    case weekly = "Chaque semaine"

    var id: String { rawValue }

    var helpText: String {
        switch self {
        case .once:
            return "La notification part une seule fois, à la date et l'heure choisies."
        case .everySeconds:
            return "iOS interdit les répétitions de moins d'une minute. NotifCraft programme donc une rafale de notifications espacées de X secondes, jusqu'à la limite système. Rouvre l'app pour reprogrammer une nouvelle rafale."
        case .everyMinutes:
            return "Répétition toutes les X minutes (minimum imposé par iOS : 1 minute)."
        case .everyHours:
            return "Répétition toutes les X heures."
        case .daily:
            return "Une notification chaque jour, à l'heure choisie."
        case .weekly:
            return "Une notification chaque semaine, le jour et à l'heure choisis."
        }
    }
}

struct Frequency: Codable, Equatable {
    var kind: FrequencyKind = .once
    /// Utilisé par everySeconds / everyMinutes / everyHours
    var intervalValue: Int = 1
    /// Utilisé par once / daily / weekly (composante heure/minute)
    var timeOfDay: Date = Date()
    /// 1 = dimanche ... 7 = samedi (convention Calendar), utilisé par weekly
    var weekday: Int = 2

    static let weekdayNames: [Int: String] = [
        1: "Dimanche", 2: "Lundi", 3: "Mardi", 4: "Mercredi",
        5: "Jeudi", 6: "Vendredi", 7: "Samedi"
    ]
}
