import Foundation

let path = "/Users/adrianspata/Screen Mockup/Screen Mockup/Editor/Canvas/MockupCanvasView.swift"
var content = try String(contentsOfFile: path)

// 1. Add globalEditorZoom and currentGlobalZoom
let zoomStateReplacement = """
    @State private var dragTarget: InteractionTarget? = nil
    @State private var magnifyTarget: InteractionTarget? = nil
    
    @State private var globalEditorZoom: CGFloat = 1.0
    
    var currentGlobalZoom: CGFloat {
        let activeScale = (magnifyTarget == .background) ? gestureScale : 1.0
        return globalEditorZoom * activeScale
    }
    
    private func unscaledLocation(_ location: CGPoint, in geometry: GeometryProxy, canvasSize: CGSize) -> CGPoint {
        let zoom = currentGlobalZoom
        let unscaledX = (location.x - geometry.size.width / 2) / zoom + canvasSize.width / 2
        let unscaledY = (location.y - geometry.size.height / 2) / zoom + canvasSize.height / 2
        return CGPoint(x: unscaledX, y: unscaledY)
    }
"""
content = content.replacingOccurrences(of: "    @State private var dragTarget: InteractionTarget? = nil\n    @State private var magnifyTarget: InteractionTarget? = nil", with: zoomStateReplacement)

// 2. MockupCompositionView activeScale and ZStack scaleEffect
let compositionReplacement = """
            ZStack {
                MockupCompositionView(
                    document: document,
                    canvasSize: canvasSize,
                    activeScale: 1.0,
                    activeTranslation: dragTarget == .background ? dragTranslation : .zero,
"""
content = content.replacingOccurrences(of: """
            ZStack {
                MockupCompositionView(
                    document: document,
                    canvasSize: canvasSize,
                    activeScale: magnifyTarget == .background ? gestureScale : 1.0,
                    activeTranslation: dragTarget == .background ? dragTranslation : .zero,
""", with: compositionReplacement)

let scaleEffectReplacement = """
            }
            .frame(width: canvasSize.width, height: canvasSize.height)
            .scaleEffect(currentGlobalZoom)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
"""
content = content.replacingOccurrences(of: """
            }
            .frame(width: canvasSize.width, height: canvasSize.height)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
""", with: scaleEffectReplacement)


// 3. onTapGesture
let tapReplacement = """
            .onTapGesture { location in
                let unscaled = unscaledLocation(location, in: geometry, canvasSize: canvasSize)
                let hit = hitTest(location: unscaled, canvasSize: canvasSize)
"""
content = content.replacingOccurrences(of: """
            .onTapGesture { location in
                let hit = hitTest(location: location, canvasSize: canvasSize)
""", with: tapReplacement)

// 4. MagnifyGesture
let magnifyReplacement = """
                        .onChanged { value in
                            if magnifyTarget == nil {
                                let unscaled = unscaledLocation(value.startLocation, in: geometry, canvasSize: canvasSize)
                                if let hitID = hitTest(location: unscaled, canvasSize: canvasSize) {
                                    magnifyTarget = .element(hitID)
                                    if document.selectedElementID != hitID {
                                        document.selectedElementID = hitID
                                    }
                                } else {
                                    magnifyTarget = .background
                                }
                            }
"""
content = content.replacingOccurrences(of: """
                        .onChanged { value in
                            if magnifyTarget == nil {
                                // Default to selected element if there is one, otherwise background
                                if let selected = document.selectedElementID {
                                    magnifyTarget = .element(selected)
                                } else {
                                    magnifyTarget = .background
                                }
                            }
""", with: magnifyReplacement)

let magnifyEndedReplacement = """
                        .onEnded { value in
                            let target = magnifyTarget ?? .background
                            
                            if target == .background {
                                let newZoom = globalEditorZoom * value.magnification
                                globalEditorZoom = max(newZoom, 0.01)
                            } else if case .element(let id) = target,
                                      let index = document.elements.firstIndex(where: { $0.id == id }) {
                                let newScale = document.elements[index].scale * value.magnification
                                document.elements[index].scale = max(newScale, 0.01)
                            }
                            
                            magnifyTarget = nil
                        }
"""
content = content.replacingOccurrences(of: """
                        .onEnded { value in
                            let target = magnifyTarget ?? .background
                            
                            if target == .background {
                                let newScale = document.scale * value.magnification
                                document.scale = min(max(newScale, 0.25), 2.0)
                            } else if case .element(let id) = target,
                                      let index = document.elements.firstIndex(where: { $0.id == id }) {
                                let newScale = document.elements[index].scale * value.magnification
                                document.elements[index].scale = min(max(newScale, 0.1), 5.0)
                            }
                            
                            magnifyTarget = nil
                        }
""", with: magnifyEndedReplacement)

// 5. DragGesture
let dragReplacement = """
                    DragGesture()
                        .onChanged { value in
                            if dragTarget == nil {
                                let unscaledStart = unscaledLocation(value.startLocation, in: geometry, canvasSize: canvasSize)
                                if let hitID = hitTest(location: unscaledStart, canvasSize: canvasSize) {
"""
content = content.replacingOccurrences(of: """
                    DragGesture()
                        .onChanged { value in
                            if dragTarget == nil {
                                if let hitID = hitTest(location: value.startLocation, canvasSize: canvasSize) {
""", with: dragReplacement)

let dragTranslationReplacement = """
                            let target = dragTarget!
                            let zoom = currentGlobalZoom
                            
                            let proposedTranslation = CGSize(
                                width: (value.translation.width / zoom) / canvasSize.width,
                                height: (value.translation.height / zoom) / canvasSize.height
                            )
"""
content = content.replacingOccurrences(of: """
                            let target = dragTarget!
                            
                            let proposedTranslation = CGSize(
                                width: value.translation.width / canvasSize.width,
                                height: value.translation.height / canvasSize.height
                            )
""", with: dragTranslationReplacement)

// 6. elementGeometry
let geomReplacement = """
        case .image(let ref):
            let pixelW = canvasSize.width * element.scale * extraScale
            let aspect = ref.intrinsicSize.width / max(1, ref.intrinsicSize.height)
            let pixelH = pixelW / aspect
            
            w = pixelW / canvasSize.width
            h = pixelH / canvasSize.height
"""
content = content.replacingOccurrences(of: """
        case .image(let ref):
            w = (ref.intrinsicSize.width * element.scale * extraScale) / canvasSize.width
            h = (ref.intrinsicSize.height * element.scale * extraScale) / canvasSize.height
""", with: geomReplacement)

try content.write(toFile: path, atomically: true, encoding: .utf8)
print("Updated MockupCanvasView.swift successfully")
