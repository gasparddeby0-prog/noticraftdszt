import SwiftUI

struct RuleListView: View {
    @State private var rules: [NotificationRule] = PersistenceStore.shared.load()
    @State private var showingNewRule = false
    @State private var pendingCount: Int = 0
    @State private var authStatus: String = ""

    var body: some View {
        NavigationStack {
            List {
                if !authStatus.isEmpty {
                    Section {
                        Text(authStatus)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                if rules.isEmpty {
                    ContentUnavailableView(
                        "Aucune notification",
                        systemImage: "bell.badge",
                        description: Text("Touche + pour créer ta première notification personnalisée.")
                    )
                } else {
                    Section {
                        ForEach(rules) { rule in
                            NavigationLink(value: rule.id) {
                                RuleRow(rule: rule)
                            }
                        }
                        .onDelete(perform: deleteRules)
                    } footer: {
                        Text("\(pendingCount) notification(s) actuellement programmée(s) sur ce téléphone (limite iOS : 64).")
                    }
                }
            }
            .navigationTitle("Mes notifications")
            .navigationDestination(for: UUID.self) { id in
                if let index = rules.firstIndex(where: { $0.id == id }) {
                    RuleEditView(rule: $rules[index], onSave: persistAndReschedule)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView(rules: $rules, onChange: persistAndReschedule)) {
                        Image(systemName: "gearshape")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        var newRule = NotificationRule()
                        newRule.title = "Nouvelle notification"
                        rules.insert(newRule, at: 0)
                        showingNewRule = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .navigationDestination(isPresented: $showingNewRule) {
                if let first = rules.first {
                    RuleEditView(rule: $rules[0], onSave: persistAndReschedule)
                }
            }
            .tint(.brandGreen)
            .onAppear {
                refreshPendingCount()
                NotificationScheduler.shared.authorizationStatus { status in
                    switch status {
                    case .denied:
                        authStatus = "⚠️ Les notifications sont désactivées pour NotifCraft dans les réglages iOS."
                    case .notDetermined:
                        authStatus = ""
                        NotificationScheduler.shared.requestAuthorization { _ in refreshPendingCount() }
                    default:
                        authStatus = ""
                    }
                }
            }
        }
    }

    private func deleteRules(at offsets: IndexSet) {
        for index in offsets {
            ImageStore.shared.delete(fileName: rules[index].imageFileName)
        }
        rules.remove(atOffsets: offsets)
        persistAndReschedule()
    }

    private func persistAndReschedule() {
        PersistenceStore.shared.save(rules)
        NotificationScheduler.shared.rescheduleAll(rules)
        refreshPendingCount()
    }

    private func refreshPendingCount() {
        NotificationScheduler.shared.pendingCount { pendingCount = $0 }
    }
}

private struct RuleRow: View {
    let rule: NotificationRule

    var body: some View {
        HStack(spacing: 12) {
            thumbnail
            VStack(alignment: .leading, spacing: 4) {
                Text(rule.title.isEmpty ? "Sans titre" : rule.title)
                    .font(.headline)
                Text(rule.frequency.kind.rawValue)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Circle()
                .fill(rule.isActive ? Color.brandGreen : Color.gray.opacity(0.4))
                .frame(width: 10, height: 10)
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let image = ImageStore.shared.loadImage(fileName: rule.imageFileName) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.brandGreen.opacity(0.15))
                .frame(width: 44, height: 44)
                .overlay(Image(systemName: "bell.fill").foregroundStyle(.brandGreen))
        }
    }
}
