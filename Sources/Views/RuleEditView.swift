import SwiftUI
import PhotosUI

struct RuleEditView: View {
    @Binding var rule: NotificationRule
    var onSave: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var previewImage: UIImage?
    @State private var showPreviewSentAlert = false

    var body: some View {
        Form {
            Section("Contenu") {
                TextField("Titre de la notification", text: $rule.title)
                TextField("Message", text: $rule.body, axis: .vertical)
                    .lineLimit(3...6)
            }

            Section("Image") {
                HStack {
                    Spacer()
                    imagePreview
                    Spacer()
                }
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Label(rule.imageFileName == nil ? "Choisir une image" : "Changer l'image", systemImage: "photo")
                }
                if rule.imageFileName != nil {
                    Button(role: .destructive) {
                        ImageStore.shared.delete(fileName: rule.imageFileName)
                        rule.imageFileName = nil
                        previewImage = nil
                    } label: {
                        Label("Retirer l'image", systemImage: "trash")
                    }
                }
            }

            Section("Fréquence") {
                Picker("Répétition", selection: $rule.frequency.kind) {
                    ForEach(FrequencyKind.allCases) { kind in
                        Text(kind.rawValue).tag(kind)
                    }
                }
                Text(rule.frequency.kind.helpText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                frequencyDetailFields
            }

            Section("Période") {
                DatePicker(startLabel, selection: $rule.startDate, displayedComponents: startComponents)
                Toggle("Date de fin", isOn: $rule.hasEndDate)
                if rule.hasEndDate {
                    DatePicker("Se termine le", selection: $rule.endDate, displayedComponents: [.date, .hourAndMinute])
                }
            }

            Section("Options") {
                Toggle("Son activé", isOn: $rule.soundEnabled)
                Toggle("Notification active", isOn: $rule.isActive)
            }

            Section {
                Button {
                    NotificationScheduler.shared.sendPreview(for: rule)
                    showPreviewSentAlert = true
                } label: {
                    Label("Envoyer un aperçu maintenant", systemImage: "paperplane")
                }
            } footer: {
                Text("L'aperçu arrive dans les 2 secondes, avec l'image et le texte actuels.")
            }
        }
        .navigationTitle("Notification")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Enregistrer") {
                    onSave()
                    dismiss()
                }
                .fontWeight(.semibold)
            }
        }
        .tint(.brandGreen)
        .alert("Aperçu envoyé", isPresented: $showPreviewSentAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Regarde tes notifications dans quelques secondes.")
        }
        .onAppear {
            previewImage = ImageStore.shared.loadImage(fileName: rule.imageFileName)
        }
        .onChange(of: selectedPhoto) { newValue in
            guard let newValue else { return }
            Task {
                if let data = try? await newValue.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    let fileName = ImageStore.shared.save(uiImage, existingFileName: rule.imageFileName)
                    await MainActor.run {
                        rule.imageFileName = fileName
                        previewImage = uiImage
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var imagePreview: some View {
        if let previewImage {
            Image(uiImage: previewImage)
                .resizable()
                .scaledToFill()
                .frame(width: 140, height: 140)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        } else {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.brandGreen.opacity(0.12))
                .frame(width: 140, height: 140)
                .overlay(Image(systemName: "photo").font(.largeTitle).foregroundStyle(.brandGreen.opacity(0.6)))
        }
    }

    @ViewBuilder
    private var frequencyDetailFields: some View {
        switch rule.frequency.kind {
        case .once:
            EmptyView()

        case .everySeconds:
            Stepper("Toutes les \(rule.frequency.intervalValue) seconde(s)", value: $rule.frequency.intervalValue, in: 1...3600)

        case .everyMinutes:
            Stepper("Toutes les \(rule.frequency.intervalValue) minute(s)", value: $rule.frequency.intervalValue, in: 1...1440)

        case .everyHours:
            Stepper("Toutes les \(rule.frequency.intervalValue) heure(s)", value: $rule.frequency.intervalValue, in: 1...24)

        case .daily:
            DatePicker("Heure", selection: $rule.frequency.timeOfDay, displayedComponents: .hourAndMinute)

        case .weekly:
            Picker("Jour", selection: $rule.frequency.weekday) {
                ForEach(Frequency.weekdayNames.sorted(by: { $0.key < $1.key }), id: \.key) { key, name in
                    Text(name).tag(key)
                }
            }
            DatePicker("Heure", selection: $rule.frequency.timeOfDay, displayedComponents: .hourAndMinute)
        }
    }

    private var startLabel: String {
        rule.frequency.kind == .once ? "Date et heure d'envoi" : "Démarre à partir de"
    }

    private var startComponents: DatePicker.Components {
        rule.frequency.kind == .once ? [.date, .hourAndMinute] : [.date]
    }
}
