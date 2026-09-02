import UIKit

/// A thread-safe wrapper around NSCache for storing UIImages.
/// NSCache is inherently thread-safe in Foundation, allowing us to safely
/// mark this wrapper as @unchecked Sendable. It also listens to memory warnings
/// to automatically purge the cache.
final class AssetImageCache: @unchecked Sendable {
    nonisolated(unsafe) private let cache = NSCache<NSString, UIImage>()
    
    nonisolated init() {
        // Set a reasonable cost limit, e.g., 100 MB
        cache.totalCostLimit = 100 * 1024 * 1024
    }
    
    nonisolated func insert(_ image: UIImage, for key: String) {
        let cost = Int(image.size.width * image.size.height * 4) // Approx bytes
        cache.setObject(image, forKey: key as NSString, cost: cost)
    }
    
    nonisolated func image(for key: String) -> UIImage? {
        return cache.object(forKey: key as NSString)
    }
    
    nonisolated func clear() {
        cache.removeAllObjects()
    }
}
