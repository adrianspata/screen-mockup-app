import Foundation
import UIKit
import AVFoundation

actor ProjectAssetStore {
    let projectID: UUID
    let directoryURL: URL
    
    private var committedDescriptors: [UUID: AssetDescriptor] = [:]
    private var pendingDescriptors: [UUID: AssetDescriptor] = [:]
    
    private let cache = AssetImageCache()
    private var loadingTasks: [UUID: Task<UIImage, Error>] = [:]
    
    init(projectID: UUID, directoryURL: URL) {
        self.projectID = projectID
        self.directoryURL = directoryURL
    }
    
    func setCommittedAssets(_ assets: [AssetDescriptor]) {
        committedDescriptors.removeAll()
        for asset in assets {
            committedDescriptors[asset.assetID] = asset
        }
    }
    
    func url(for assetID: UUID) throws -> URL {
        if let descriptor = committedDescriptors[assetID] ?? pendingDescriptors[assetID] {
            return directoryURL.appendingPathComponent(descriptor.relativePath)
        }
        throw LoadError.invalidNumericValue("Missing asset descriptor for ID: \(assetID)")
    }
    
    func validateDescriptors(_ descriptors: [AssetDescriptor]) throws {
        var seenPaths = Set<String>()
        var seenIDs = Set<UUID>()
        
        for descriptor in descriptors {
            if seenIDs.contains(descriptor.assetID) {
                throw LoadError.invalidNumericValue("Duplicate asset ID in manifest: \(descriptor.assetID)")
            }
            seenIDs.insert(descriptor.assetID)
            
            if seenPaths.contains(descriptor.relativePath) {
                throw LoadError.invalidNumericValue("Duplicate relative path in manifest: \(descriptor.relativePath)")
            }
            seenPaths.insert(descriptor.relativePath)
            
            if descriptor.relativePath.contains("../") || descriptor.relativePath.hasPrefix("/") {
                throw LoadError.invalidNumericValue("Invalid relative path: \(descriptor.relativePath)")
            }
        }
    }
    
    func importImage(from data: Data, utType: String, fileExtension: String) throws -> MediaReference {
        let assetID = UUID()
        let filename = "\(assetID.uuidString).\(fileExtension)"
        let fileURL = directoryURL.appendingPathComponent(filename)
        
        try data.write(to: fileURL)
        
        guard let image = UIImage(data: data) else {
            try? FileManager.default.removeItem(at: fileURL)
            throw LoadError.invalidNumericValue("Unreadable image data")
        }
        
        let descriptor = AssetDescriptor(
            assetID: assetID,
            relativePath: filename,
            contentType: utType,
            byteCount: Int64(data.count)
        )
        
        pendingDescriptors[assetID] = descriptor
        
        let cacheKey = "\(projectID)-\(assetID)"
        cache.insert(image, for: cacheKey)
        
        return MediaReference(
            assetID: assetID,
            kind: .image,
            pixelSize: image.size,
            duration: nil
        )
    }
    
    func importVideo(from sourceURL: URL, utType: String, fileExtension: String) async throws -> MediaReference {
        let assetID = UUID()
        let filename = "\(assetID.uuidString).\(fileExtension)"
        let destinationURL = directoryURL.appendingPathComponent(filename)
        
        try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
        
        let asset = AVURLAsset(url: destinationURL)
        let duration = try await asset.load(.duration).seconds
        
        let size: CGSize?
        if let track = try await asset.loadTracks(withMediaType: .video).first {
            let naturalSize = try await track.load(.naturalSize)
            let transform = try await track.load(.preferredTransform)
            let transformedSize = naturalSize.applying(transform)
            size = CGSize(width: abs(transformedSize.width), height: abs(transformedSize.height))
        } else {
            size = nil
        }
        
        let attr = try FileManager.default.attributesOfItem(atPath: destinationURL.path)
        let byteCount = attr[.size] as? Int64
        
        let descriptor = AssetDescriptor(
            assetID: assetID,
            relativePath: filename,
            contentType: utType,
            byteCount: byteCount
        )
        
        pendingDescriptors[assetID] = descriptor
        
        return MediaReference(
            assetID: assetID,
            kind: .video,
            pixelSize: size,
            duration: duration
        )
    }
    
    func cacheImage(_ image: UIImage, for assetID: UUID) {
        cache.insert(image, for: "\(projectID)-\(assetID)")
    }
    
    nonisolated func cachedImage(for assetID: UUID) -> UIImage? {
        let cacheKey = "\(projectID)-\(assetID)"
        return cache.image(for: cacheKey)
    }

    func loadImage(for assetID: UUID) async throws -> UIImage {
        let cacheKey = "\(projectID)-\(assetID)"
        if let cached = cache.image(for: cacheKey) {
            return cached
        }
        
        if let existingTask = loadingTasks[assetID] {
            return try await existingTask.value
        }
        
        let fileURL = try url(for: assetID)
        
        let task = Task<UIImage, Error> {
            let data = try Data(contentsOf: fileURL)
            guard let image = UIImage(data: data) else {
                throw LoadError.invalidNumericValue("Unreadable image on disk for asset: \(assetID)")
            }
            cache.insert(image, for: cacheKey)
            return image
        }
        
        loadingTasks[assetID] = task
        
        defer { loadingTasks[assetID] = nil }
        
        return try await task.value
    }
    
    func ensureImagesLoaded(for assetIDs: Set<UUID>) async throws {
        for id in assetIDs {
            // Video assets might be in the set if they are main media,
            // but we shouldn't fail if we try to load an image for a video and it fails?
            // Wait, we should only ensureImagesLoaded for image references.
            // Let's check kind first.
            let descriptor = committedDescriptors[id] ?? pendingDescriptors[id]
            guard descriptor != nil else {
                throw LoadError.invalidNumericValue("Missing descriptor for \(id)")
            }
            // Simple heuristic: if it's not a known video type, try to load as image.
            // For now, let's just attempt to load and if it's video, the caller shouldn't have passed it in `ensureImagesLoaded`.
            // The caller (MockupExporter) should filter by `kind == .image`.
            _ = try await loadImage(for: id)
        }
    }
    
    func markCommitted(assetIDs: Set<UUID>) {
        var newCommitted: [UUID: AssetDescriptor] = [:]
        for id in assetIDs {
            if let desc = committedDescriptors[id] ?? pendingDescriptors[id] {
                newCommitted[id] = desc
            }
        }
        committedDescriptors = newCommitted
        
        // Remove all pending, since unreferenced ones are discarded
        pendingDescriptors.removeAll()
    }
    
    func getUnusedFiles(in directory: URL) throws -> [URL] {
        let contents = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        var usedPaths = Set<String>()
        
        for desc in committedDescriptors.values {
            usedPaths.insert(desc.relativePath)
        }
        for desc in pendingDescriptors.values {
            usedPaths.insert(desc.relativePath)
        }
        
        return contents.filter { url in
            let filename = url.lastPathComponent
            return !usedPaths.contains(filename)
        }
    }
    
    func clearPending() {
        pendingDescriptors.removeAll()
    }
    
    func getDescriptor(for id: UUID) -> AssetDescriptor? {
        return committedDescriptors[id] ?? pendingDescriptors[id]
    }
}
