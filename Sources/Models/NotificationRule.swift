import Foundation

struct NotificationRule: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String = ""
    var body: String = ""
    /// Nom du fichier image, relatif au dossier Documents/Images. Nil = pas d'image.
    var imageFileName: String?
    var frequency: Frequency = Frequency()
    var startDate: Date = Date()
    var hasEndDate: Bool = false
    var endDate: Date = Date().addingTimeInterval(7 * 24 * 3600)
    var soundEnabled: Bool = true
    var isActive: Bool = true
    var createdAt: Date = Date()

    var effectiveEndDate: Date? { hasEndDate ? endDate : nil }
}
