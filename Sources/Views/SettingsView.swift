import SwiftUI
import UserNotifications

struct SettingsView: View {
    @Binding var rules: [NotificationRule]
    var onChange: () -> Void

    @State private var pendingCount = 0

    var body: some View {
        Form {
            Section("Notifications système") {
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Label("Ouvrir les réglages iOS de l'app", systemImage: "gear")
                }
                Button {
                    NotificationScheduler.shared.resetBadge()
                } label: {
                    Label("Réinitialiser le badge de l'app", systemImage: "app.badge")
                }
            }

            Section {
                HStack {
                    Text("Notifications programmées")
                    Spacer()
                    Text("\(pendingCount) / 64")
                        .foregroundStyle(.secondary)
                }
            } footer: {
                Text("iOS limite chaque app à 64 notifications programmées en même temps. NotifCraft répartit automatiquement cet espace entre tes différentes notifications actives. Les rythmes 'chaque jour', 'chaque semaine', 'toutes les X minutes/heures' n'utilisent qu'un seul emplacement chacun, quel que soit le nombre de répétitions.")
            }

            Section {
                Button(role: .destructive) {
                    for rule in rules {
                        ImageStore.shared.delete(fileName: rule.imageFileName)
                    }
                    rules.removeAll()
                    onChange()
                } label: {
                    Label("Supprimer toutes les notifications", systemImage: "trash")
                }
            }

            Section("À propos") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0").foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Réglages")
        .tint(.brandGreen)
        .onAppear {
            NotificationScheduler.shared.pendingCount { pendingCount = $0 }
        }
    }
}
