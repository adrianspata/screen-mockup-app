import SwiftUI

struct CanvasOverlayLayer: View {
    let document: MockupDocument
    let canvasSize: CGSize
    var activeElementID: UUID? = nil
    var activeElementScale: CGFloat = 1.0
    var activeElementTranslation: CGSize = .zero
    let isEditor: Bool
    
    var body: some View {
        ZStack {
            // Sort elements by zIndex to ensure deterministic ordering.
            // Tie-break with stable UUID to guarantee deterministic layer order when zIndexes match.
            ForEach(document.sortedElements) { element in
                let isActive = element.id == activeElementID
                CanvasElementView(
                    element: element,
                    canvasSize: canvasSize,
                    isSelected: document.selectedElementID == element.id,
                    isEditor: isEditor,
                    document: document,
                    activeScale: isActive ? activeElementScale : 1.0,
                    activeTranslation: isActive ? activeElementTranslation : .zero
                )
            }
        }
        // Ensure the overlay layer itself matches canvas bounds
        .frame(width: canvasSize.width, height: canvasSize.height)
    }
}

struct CanvasElementView: View {
    let element: CanvasElement
    let canvasSize: CGSize
    let isSelected: Bool
    let isEditor: Bool
    let document: MockupDocument
    var activeScale: CGFloat = 1.0
    var activeTranslation: CGSize = .zero
    
    var body: some View {
        Group {
            switch element.content {
            case .image(let ref):
                if let uiImage = AssetManager.shared.getImage(for: ref.assetID) {
                    let w = canvasSize.width * element.scale * activeScale
                    // Base 400 points as reference for "1x" scale on screen
                    let scaledRadius = ref.cornerRadius * element.scale * activeScale * (canvasSize.width / 400)
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: w)
                        .clipShape(RoundedRectangle(cornerRadius: scaledRadius, style: .continuous))
                } else {
                    Color.clear
                        .frame(width: canvasSize.width * element.scale * activeScale)
                }
            case .text(let textData):
                let w = canvasSize.width * element.scale * activeScale
                let font = font(for: textData.fontName, size: w)
                
                if document.editingTextElementID == element.id {
                    let binding = Binding<String>(
                        get: {
                            if let idx = document.elements.firstIndex(where: { $0.id == element.id }),
                               case .text(let t) = document.elements[idx].content {
                                return t.string
                            }
                            return ""
                        },
                        set: { newValue in
                            if let idx = document.elements.firstIndex(where: { $0.id == element.id }),
                               case .text(var t) = document.elements[idx].content {
                                t.string = newValue
                                document.elements[idx].content = .text(t)
                            }
                        }
                    )
                    TextField("Text", text: binding)
                        .font(font)
                        .foregroundColor(textData.color)
                        .multilineTextAlignment(.center)
                        .frame(minWidth: 100) // allow it to grow
                        .fixedSize(horizontal: true, vertical: false) // natural width
                        // Optional: close editing on submit
                        .onSubmit {
                            document.editingTextElementID = nil
                        }
                } else {
                    Text(textData.string)
                        .font(font)
                        .foregroundColor(textData.color)
                        .multilineTextAlignment(.center)
                        // Make it tappable for double tap
                        .contentShape(Rectangle())
                        .onTapGesture(count: 2) {
                            if isEditor {
                                document.editingTextElementID = element.id
                            }
                        }
                }
            case .sfSymbol:
                // Phase 8.4 placeholder
                Image(systemName: "star.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.white)
            }
        }
        .position(
            x: (element.normalizedPosition.x * canvasSize.width) + activeTranslation.width,
            y: (element.normalizedPosition.y * canvasSize.height) + activeTranslation.height
        )
        // Selection visualization (Phase 8.2A)
        .overlay(
            Group {
                if isSelected && isEditor {
                    Rectangle()
                        .strokeBorder(Color.white.opacity(0.8), lineWidth: 1.5)
                        .shadow(color: .black.opacity(0.3), radius: 2)
                        // Make it tightly wrap the actual frame
                        .padding(-1)
                }
            }
            .position(
                x: (element.normalizedPosition.x * canvasSize.width) + activeTranslation.width,
                y: (element.normalizedPosition.y * canvasSize.height) + activeTranslation.height
            )
        )
        // Only allow hit testing on elements in editor mode
        .allowsHitTesting(isEditor)
    }
    
    private func font(for name: String, size: CGFloat) -> Font {
        switch name {
        case "System": return .system(size: size)
        case "System Serif": return .system(size: size, design: .serif)
        case "System Rounded": return .system(size: size, design: .rounded)
        case "System Mono": return .system(size: size, design: .monospaced)
        default: return .custom(name, size: size)
        }
    }
}
