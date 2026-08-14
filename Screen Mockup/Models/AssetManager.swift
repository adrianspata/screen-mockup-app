import UIKit
import Observation

@Observable
final class AssetManager {
    static let shared = AssetManager()
    
    private var images: [UUID: UIImage] = [:]
    
    private init() {}
    
    func store(image: UIImage) -> UUID {
        let id = UUID()
        images[id] = image
        return id
    }
    
    func getImage(for id: UUID) -> UIImage? {
        return images[id]
    }
    
    func removeImage(for id: UUID) {
        images.removeValue(forKey: id)
    }
}

struct ImageReference: Equatable {
    let assetID: UUID
    let intrinsicSize: CGSize
    var cornerRadius: CGFloat = 0
}
