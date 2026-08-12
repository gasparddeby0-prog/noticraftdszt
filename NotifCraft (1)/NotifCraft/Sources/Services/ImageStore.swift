import UIKit

final class ImageStore {
    static let shared = ImageStore()
    private init() {
        try? FileManager.default.createDirectory(at: imagesFolder, withIntermediateDirectories: true)
    }

    private var imagesFolder: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent("Images", isDirectory: true)
    }

    func url(for fileName: String) -> URL {
        imagesFolder.appendingPathComponent(fileName)
    }

    /// Enregistre l'image sur disque et retourne le nom de fichier à stocker dans la règle.
    @discardableResult
    func save(_ image: UIImage, existingFileName: String? = nil) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.85) else { return nil }
        let fileName = existingFileName ?? "\(UUID().uuidString).jpg"
        let destination = url(for: fileName)
        do {
            try data.write(to: destination, options: .atomic)
            return fileName
        } catch {
            return nil
        }
    }

    func delete(fileName: String?) {
        guard let fileName else { return }
        try? FileManager.default.removeItem(at: url(for: fileName))
    }

    func loadImage(fileName: String?) -> UIImage? {
        guard let fileName else { return nil }
        return UIImage(contentsOfFile: url(for: fileName).path)
    }
}
