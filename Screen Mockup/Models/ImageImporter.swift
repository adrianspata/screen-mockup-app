import UIKit
import PhotosUI
import SwiftUI

final class ImageImporter {
    static func importImage(_ uiImage: UIImage, into session: ProjectSession) async {
        guard let data = uiImage.jpegData(compressionQuality: 0.9) else { return }
        
        do {
            let ref = try await session.assetStore.importImage(from: data, utType: "public.jpeg", fileExtension: "jpg")
            
            // Sensible default scale: 30% of canvas width
            let initialScale: CGFloat = 0.3
            
            let element = CanvasElement(
                content: .image(ref),
                transform: ElementTransform(normalizedPosition: CGPoint(x: 0.5, y: 0.5), scale: initialScale, rotationDegrees: 0.0, opacity: 1.0),
                zIndex: (session.document.elements.map { $0.zIndex }.max() ?? 0) + 1
            )
            
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.2)) {
                    session.document.elements.append(element)
                    session.document.selectedElementID = element.id
                }
            }
        } catch {
            print("Failed to import image: \(error)")
        }
    }
}
