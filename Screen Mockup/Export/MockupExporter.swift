import SwiftUI
import UniformTypeIdentifiers
import Combine
import Photos

@MainActor
final class MockupExporter: ObservableObject {
    @Published var isExporting: Bool = false
    @Published var exportProgress: Double = 0.0
    @Published var exportError: String? = nil
    @Published var sharedImage: UIImage? = nil
    @Published var sharedVideoURL: URL? = nil
    @Published var showSuccessMessage: Bool = false
    
    func saveToPhotos(document: MockupDocument) {
        isExporting = true
        exportError = nil
        showSuccessMessage = false
        exportProgress = 0.0
        
        Task {
            do {
                if case .video(let url) = document.media {
                    let canvasSize = calculateCanvasSize(document: document)
                    let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mp4")
                    try await VideoExporterCore.exportVideo(document: document, sourceURL: url, outputURL: outputURL, canvasSize: canvasSize) { p in
                        DispatchQueue.main.async { self.exportProgress = p }
                    }
                    try await saveVideoToPhotos(url: outputURL)
                } else {
                    let image = try await renderImage(document: document)
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
    
    func share(document: MockupDocument) {
        isExporting = true
        exportError = nil
        showSuccessMessage = false
        exportProgress = 0.0
        
        Task {
            do {
                if case .video(let url) = document.media {
                    let canvasSize = calculateCanvasSize(document: document)
                    let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mp4")
                    try await VideoExporterCore.exportVideo(document: document, sourceURL: url, outputURL: outputURL, canvasSize: canvasSize) { p in
                        DispatchQueue.main.async { self.exportProgress = p }
                    }
                    self.sharedVideoURL = outputURL
                } else {
                    let image = try await renderImage(document: document)
                    self.sharedImage = image
                }
                self.isExporting = false
            } catch {
                self.exportError = error.localizedDescription
                self.isExporting = false
            }
        }
    }
    
    private func saveImageToPhotos(image: UIImage) async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            throw NSError(domain: "MockupExporter", code: 3, userInfo: [NSLocalizedDescriptionKey: "Photos access is required to save."])
        }
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }
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
    
    private func calculateCanvasSize(document: MockupDocument) -> CGSize {
        let maxDim: CGFloat = 3000.0
        let ratio = document.canvasRatio.ratio(for: document.media, orientation: document.canvasOrientation) ?? (9.0 / 16.0)
        var targetWidth: CGFloat = 0
        var targetHeight: CGFloat = 0
        if ratio >= 1.0 {
            targetWidth = maxDim
            targetHeight = maxDim / ratio
        } else {
            targetHeight = maxDim
            targetWidth = maxDim * ratio
        }
        return CGSize(width: round(targetWidth), height: round(targetHeight))
    }
    
    private func renderImage(document: MockupDocument) async throws -> UIImage {
        let canvasSize = calculateCanvasSize(document: document)
        let rendererView = MockupCompositionView(document: document, canvasSize: canvasSize)
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
