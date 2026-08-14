import UIKit
import PhotosUI
import SwiftUI

final class ImageImporter {
    static func importImage(_ uiImage: UIImage, into document: MockupDocument) {
        let assetID = AssetManager.shared.store(image: uiImage)
        let size = uiImage.size
        
        // Sensible default scale: 30% of canvas width
        let initialScale: CGFloat = 0.3
        
        let element = CanvasElement(
            content: .image(ImageReference(assetID: assetID, intrinsicSize: size)),
            normalizedPosition: CGPoint(x: 0.5, y: 0.5),
            scale: initialScale,
            zIndex: (document.elements.map { $0.zIndex }.max() ?? 0) + 1
        )
        
        withAnimation(.easeOut(duration: 0.2)) {
            document.elements.append(element)
            document.selectedElementID = element.id
        }
    }
}
