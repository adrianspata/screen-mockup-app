import SwiftUI

struct CanvasElementsLayer: View {
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
                if !element.isHidden {
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
        let baseSize = ElementGeometryResolver.baseSize(for: element.content, in: canvasSize)
        
        Group {
            switch element.content {
            case .device(let data):
                DeviceMockupView(media: data.media, style: data.bezelStyle, showStatusBar: data.showStatusBar)
                    .frame(width: baseSize.width, height: baseSize.height)
            case .image(let ref):
                AssetImageView(reference: ref)
                    .frame(width: baseSize.width, height: baseSize.height)
                    // We don't apply rounded corners here unless specified in the model
                    // For now, keep it simple
            case .text(let textData):
                let font = font(for: textData.fontName, size: baseSize.height) // Base height approximates font size
                
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
                        .frame(minWidth: baseSize.width) // allow it to grow
                        .fixedSize(horizontal: true, vertical: false) // natural width
                        .onSubmit {
                            document.editingTextElementID = nil
                        }
                } else {
                    Text(textData.string)
                        .font(font)
                        .foregroundColor(textData.color)
                        .multilineTextAlignment(.center)
                        .contentShape(Rectangle())
                        .onTapGesture(count: 2) {
                            if isEditor {
                                document.editingTextElementID = element.id
                            }
                        }
                }
            case .sfSymbol:
                Image(systemName: "star.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.white)
                    .frame(width: baseSize.width, height: baseSize.height)
            }
        }
        // 1. Scale
        .scaleEffect(element.transform.scale * activeScale)
        // 2. Rotate
        .rotationEffect(.degrees(element.transform.rotationDegrees))
        // 3. Opacity
        .opacity(element.transform.opacity)
        // 4. Translate (Position)
        .position(
            x: (element.transform.normalizedPosition.x * canvasSize.width) + activeTranslation.width,
            y: (element.transform.normalizedPosition.y * canvasSize.height) + activeTranslation.height
        )
        // Selection visualization
        .overlay(
            Group {
                if isSelected && isEditor {
                    Rectangle()
                        .strokeBorder(Color.white.opacity(0.8), lineWidth: 1.5)
                        .shadow(color: .black.opacity(0.3), radius: 2)
                        .padding(-1)
                        .frame(width: baseSize.width, height: baseSize.height)
                        .scaleEffect(element.transform.scale * activeScale)
                        .rotationEffect(.degrees(element.transform.rotationDegrees))
                        .position(
                            x: (element.transform.normalizedPosition.x * canvasSize.width) + activeTranslation.width,
                            y: (element.transform.normalizedPosition.y * canvasSize.height) + activeTranslation.height
                        )
                }
            }
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
