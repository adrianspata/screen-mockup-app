import SwiftUI

struct MockupCompositionView: View {
    let document: MockupDocument
    let canvasSize: CGSize
    
    var activeScale: CGFloat = 1.0
    var activeTranslation: CGSize = .zero
    var activeElementID: UUID? = nil
    var activeElementScale: CGFloat = 1.0
    var activeElementTranslation: CGSize = .zero
    var isEditor: Bool = false
    
    var body: some View {
        ZStack {
            // Background Layer
            Group {
                switch document.background {
                case .none:
                    Color.clear
                case .solid(let color):
                    color
                case .gradient(let start, let end):
                    LinearGradient(colors: [start, end], startPoint: .topLeading, endPoint: .bottomTrailing)
                case .image(let uiImage):
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
            }
            .opacity(document.backgroundOpacity)
            
            // Mockup Content Layer
            if let media = document.media {
                DeviceMockupView(media: media, style: document.bezelStyle, showStatusBar: document.showStatusBar)
                    // Transform
                    .scaleEffect(document.scale * activeScale)
                    .offset(x: (document.normalizedOffset.width * canvasSize.width) + activeTranslation.width,
                            y: (document.normalizedOffset.height * canvasSize.height) + activeTranslation.height)
            }
            
            // Shared Overlay Layer (Phase 8.0)
            CanvasOverlayLayer(
                document: document,
                canvasSize: canvasSize,
                activeElementID: activeElementID,
                activeElementScale: activeElementScale,
                activeElementTranslation: activeElementTranslation,
                isEditor: isEditor
            )
        }
        .frame(width: canvasSize.width, height: canvasSize.height)
        .clipShape(RoundedRectangle(cornerRadius: max(canvasSize.width, canvasSize.height) * 0.02, style: .continuous))
        .clipped()
    }
}
