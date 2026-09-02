import SwiftUI
import UniformTypeIdentifiers
import Combine
import Photos

@MainActor
final class MockupExporter: ObservableObject {
    @Published var isExporting: Bool = false
    @Published var exportProgress: Double = 0.0
    @Published var exportError: String? = nil
    @Published var sharedImageURL: URL? = nil
    @Published var sharedVideoURL: URL? = nil
    @Published var showSuccessMessage: Bool = false
    
    func saveToPhotos(session: ProjectSession) {
        let document = session.document
        isExporting = true
        exportError = nil
        showSuccessMessage = false
        exportProgress = 0.0
        
        Task {
            do {
                try await preloadImages(for: session)
                
                let videoElements = document.elements.compactMap { el -> (UUID, DeviceElementData)? in
                    if case .device(let data) = el.content, data.media.kind == .video { return (el.id, data) }
                    return nil
                }
                
                if videoElements.count > 1 {
                    throw MockupExportError.unsupportedMultipleVideoElements(count: videoElements.count)
                } else if let videoTuple = videoElements.first {
                    let url = try await session.assetStore.url(for: videoTuple.1.media.assetID)
                    let canvasSize = calculateCanvasSize(document: document)
                    let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mp4")
                    try await VideoExporterCore.exportVideo(document: document, session: session, videoElementID: videoTuple.0, sourceURL: url, outputURL: outputURL, canvasSize: canvasSize) { p in
                        DispatchQueue.main.async { self.exportProgress = p }
                    }
                    try await saveVideoToPhotos(url: outputURL)
                } else {
                    let image = try await renderImage(document: document, session: session)
                    try await saveImageToPhotos(image: image)
                }
                self.showSuccessMessage = true
                self.isExporting = false
            } catch {
                self.exportError = error.localizedDescription
                self.isExporting = false
            }
        }
    }
    
    func share(session: ProjectSession) {
        let document = session.document
        isExporting = true
        exportError = nil
        showSuccessMessage = false
        exportProgress = 0.0
        
        Task {
            do {
                try await preloadImages(for: session)
                
                let videoElements = document.elements.compactMap { el -> (UUID, DeviceElementData)? in
                    if case .device(let data) = el.content, data.media.kind == .video { return (el.id, data) }
                    return nil
                }
                
                if videoElements.count > 1 {
                    throw MockupExportError.unsupportedMultipleVideoElements(count: videoElements.count)
                } else if let videoTuple = videoElements.first {
                    let url = try await session.assetStore.url(for: videoTuple.1.media.assetID)
                    let canvasSize = calculateCanvasSize(document: document)
                    let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mp4")
                    try await VideoExporterCore.exportVideo(document: document, session: session, videoElementID: videoTuple.0, sourceURL: url, outputURL: outputURL, canvasSize: canvasSize) { p in
                        DispatchQueue.main.async { self.exportProgress = p }
                    }
                    self.sharedVideoURL = outputURL
                } else {
                    let image = try await renderImage(document: document, session: session)
                    if let pngData = image.pngData() {
                        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("Mockup-\(UUID().uuidString).png")
                        try pngData.write(to: tempURL)
                        self.sharedImageURL = tempURL
                    } else {
                        throw NSError(domain: "MockupExporter", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to generate PNG data."])
                    }
                }
                self.isExporting = false
            } catch {
                self.exportError = error.localizedDescription
                self.isExporting = false
            }
        }
    }
    
    private func preloadImages(for session: ProjectSession) async throws {
        var imageIDs = Set<UUID>()
        if case .image(let ref) = session.document.background {
            imageIDs.insert(ref.assetID)
        }
        for element in session.document.elements {
            if case .image(let ref) = element.content {
                imageIDs.insert(ref.assetID)
            } else if case .device(let data) = element.content, data.media.kind == .image {
                imageIDs.insert(data.media.assetID)
            }
        }
        try await session.assetStore.ensureImagesLoaded(for: imageIDs)
    }
    
    private func saveImageToPhotos(image: UIImage) async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            throw NSError(domain: "MockupExporter", code: 3, userInfo: [NSLocalizedDescriptionKey: "Photos access is required to save."])
        }
        
        guard let pngData = image.pngData() else {
            throw NSError(domain: "MockupExporter", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to generate PNG data."])
        }
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".png")
        try pngData.write(to: tempURL)
        
        try await PHPhotoLibrary.shared().performChanges {
            let request = PHAssetCreationRequest.forAsset()
            request.addResource(with: .photo, fileURL: tempURL, options: nil)
        }
        
        try? FileManager.default.removeItem(at: tempURL)
    }
    
    private func saveVideoToPhotos(url: URL) async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            throw NSError(domain: "MockupExporter", code: 3, userInfo: [NSLocalizedDescriptionKey: "Photos access is required to save."])
        }
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
        }
    }
    
    // Extracted for testability. Called by the private instance method below.
    // Algorithm and rounding are identical to the original implementation.
    // @MainActor is inherited from the enclosing class; call from tests via @MainActor test methods.
    static func calculateCanvasSize(
        ratio: CanvasRatio,
        orientation: CanvasOrientation,
        media: MediaReference?
    ) -> CGSize {
        let maxDim: CGFloat = 3000.0
        let r = ratio.ratio(for: media, orientation: orientation) ?? (9.0 / 16.0)
        var targetWidth: CGFloat = 0
        var targetHeight: CGFloat = 0
        if r >= 1.0 {
            targetWidth = maxDim
            targetHeight = maxDim / r
        } else {
            targetHeight = maxDim
            targetWidth = maxDim * r
        }
        return CGSize(width: round(targetWidth), height: round(targetHeight))
    }

    private func calculateCanvasSize(document: MockupDocument) -> CGSize {
        let firstMedia = document.elements.compactMap { el -> MediaReference? in
            if case .device(let data) = el.content { return data.media }
            return nil
        }.first
        return MockupExporter.calculateCanvasSize(
            ratio: document.canvasRatio,
            orientation: document.canvasOrientation,
            media: firstMedia
        )
    }
    
    private func renderImage(document: MockupDocument, session: ProjectSession) async throws -> UIImage {
        let canvasSize = calculateCanvasSize(document: document)
        let rendererView = MockupCompositionView(document: document, canvasSize: canvasSize)
            .environment(\.projectAssetStore, session.assetStore)
            .frame(width: canvasSize.width, height: canvasSize.height)
        
        let renderer = ImageRenderer(content: rendererView)
        renderer.scale = 1.0
        renderer.proposedSize = .init(canvasSize)
        renderer.isOpaque = false
        
        guard let cgImage = renderer.cgImage else {
            throw NSError(domain: "MockupExporter", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to render high-resolution image."])
        }
        return UIImage(cgImage: cgImage)
    }
}

enum MockupExportError: LocalizedError {
    case unsupportedMultipleVideoElements(count: Int)
    
    var errorDescription: String? {
        switch self {
        case .unsupportedMultipleVideoElements(let count):
            return "Exporting multiple video elements (\(count)) is not supported yet."
        }
    }
}
