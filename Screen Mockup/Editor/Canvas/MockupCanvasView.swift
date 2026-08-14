import SwiftUI

enum InteractionTarget: Equatable {
    case background
    case element(UUID)
}

struct MockupCanvasView: View {
    let document: MockupDocument
    
    @GestureState private var gestureScale: CGFloat = 1.0
    
    // Snapping state
    @State private var dragTranslation: CGSize = .zero
    @State private var activeVerticalGuide: CGFloat? = nil
    @State private var activeHorizontalGuide: CGFloat? = nil
    @State private var activeSnapXType: SnapTargetType? = nil
    @State private var activeSnapYType: SnapTargetType? = nil
    
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
    
    var body: some View {
        GeometryReader { geometry in
            let canvasSize = calculateCanvasSize(in: geometry.size)
            
            ZStack {
                MockupCompositionView(
                    document: document,
                    canvasSize: canvasSize,
                    activeScale: 1.0,
                    activeTranslation: dragTarget == .background ? dragTranslation : .zero,
                    activeElementID: {
                        if case .element(let id) = dragTarget { return id }
                        if case .element(let id) = magnifyTarget { return id }
                        return nil
                    }(),
                    activeElementScale: {
                        if case .element = magnifyTarget { return gestureScale }
                        return 1.0
                    }(),
                    activeElementTranslation: {
                        if case .element = dragTarget { return dragTranslation }
                        return .zero
                    }(),
                    isEditor: true
                )
                
                // Snap Guides (Editor-only Chrome)
                if let vGuide = activeVerticalGuide {
                    Rectangle()
                        .fill(Color.screenyOrange)
                        .frame(width: 1, height: canvasSize.height)
                        .position(x: vGuide * canvasSize.width, y: canvasSize.height / 2)
                }
                
                if let hGuide = activeHorizontalGuide {
                    Rectangle()
                        .fill(Color.screenyOrange)
                        .frame(width: canvasSize.width, height: 1)
                        .position(x: canvasSize.width / 2, y: hGuide * canvasSize.height)
                }
            }
            .frame(width: canvasSize.width, height: canvasSize.height)
            .scaleEffect(currentGlobalZoom)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            .contentShape(Rectangle())
            .onTapGesture { location in
                let unscaled = unscaledLocation(location, in: geometry, canvasSize: canvasSize)
                let hit = hitTest(location: unscaled, canvasSize: canvasSize)
                withAnimation(.easeOut(duration: 0.15)) {
                    if let hitID = hit {
                        document.selectedElementID = hitID
                    } else {
                        document.selectedElementID = nil
                        document.editingTextElementID = nil
                    }
                }
            }
            .gesture(
                SimultaneousGesture(
                    MagnifyGesture()
                        .updating($gestureScale) { value, state, _ in
                            state = value.magnification
                        }
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
                            
                            if case .element(let id) = magnifyTarget,
                               let _ = document.elements.firstIndex(where: { $0.id == id }) {
                                // We don't want to live-update the element scale using gestureScale because gestureScale is a GestureState.
                                // But since we apply gestureScale to background in UI, for elements we can just temporarily scale it in the view?
                                // Actually, for elements, it's easier to just apply the delta.
                                // We will modify document directly in onEnded for elements, or update a local state.
                                // Actually, the user wants live preview. We can't do live preview if we don't have transient state for element scale.
                            }
                        }
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
                        },
                    DragGesture()
                        .onChanged { value in
                            if dragTarget == nil {
                                let unscaledStart = unscaledLocation(value.startLocation, in: geometry, canvasSize: canvasSize)
                                if let hitID = hitTest(location: unscaledStart, canvasSize: canvasSize) {
                                    dragTarget = .element(hitID)
                                    // Optionally select the dragged element automatically
                                    if document.selectedElementID != hitID {
                                        document.selectedElementID = hitID
                                    }
                                } else {
                                    dragTarget = .background
                                    document.selectedElementID = nil // deselect when dragging bg
                                }
                            }
                            
                            let target = dragTarget!
                            let zoom = currentGlobalZoom
                            
                            let proposedTranslation = CGSize(
                                width: (value.translation.width / zoom) / canvasSize.width,
                                height: (value.translation.height / zoom) / canvasSize.height
                            )
                            
                            let thresholdX = 5.0 / max(1, canvasSize.width)
                            let thresholdY = 5.0 / max(1, canvasSize.height)
                            let releaseThresholdX = 10.0 / max(1, canvasSize.width)
                            let releaseThresholdY = 10.0 / max(1, canvasSize.height)
                            
                            if target == .background {
                                let baseGeometry = screenshotGeometry(canvasSize: canvasSize, scale: document.scale * gestureScale)
                                
                                var otherObjects: [UUID: SnapGeometry] = [:]
                                for element in document.elements {
                                    otherObjects[element.id] = elementGeometry(element: element, canvasSize: canvasSize)
                                }
                                
                                let result = SnapEngine.evaluateSnap(
                                    proposedGeometry: baseGeometry,
                                    originalOffset: document.normalizedOffset,
                                    proposedTranslation: proposedTranslation,
                                    thresholdX: thresholdX,
                                    thresholdY: thresholdY,
                                    releaseThresholdX: releaseThresholdX,
                                    releaseThresholdY: releaseThresholdY,
                                    activeSnapX: activeSnapXType,
                                    activeSnapY: activeSnapYType,
                                    otherObjects: otherObjects
                                )
                                
                                updateSnapState(result: result, canvasSize: canvasSize, originalOffset: document.normalizedOffset)
                                
                            } else if case .element(let id) = target,
                                      let index = document.elements.firstIndex(where: { $0.id == id }) {
                                
                                let element = document.elements[index]
                                let baseGeometry = elementGeometry(element: element, canvasSize: canvasSize)
                                
                                var otherObjects: [UUID: SnapGeometry] = [:]
                                // Background as snap target
                                let bgId = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
                                otherObjects[bgId] = screenshotGeometry(canvasSize: canvasSize, scale: document.scale)
                                
                                // Other elements
                                for otherEl in document.elements where otherEl.id != id {
                                    otherObjects[otherEl.id] = elementGeometry(element: otherEl, canvasSize: canvasSize)
                                }
                                
                                // For element snapping, originalOffset is its normalizedPosition!
                                let originalOffset = CGSize(width: element.normalizedPosition.x, height: element.normalizedPosition.y)
                                
                                let result = SnapEngine.evaluateSnap(
                                    proposedGeometry: baseGeometry,
                                    originalOffset: originalOffset,
                                    proposedTranslation: proposedTranslation,
                                    thresholdX: thresholdX,
                                    thresholdY: thresholdY,
                                    releaseThresholdX: releaseThresholdX,
                                    releaseThresholdY: releaseThresholdY,
                                    activeSnapX: activeSnapXType,
                                    activeSnapY: activeSnapYType,
                                    otherObjects: otherObjects
                                )
                                
                                updateSnapState(result: result, canvasSize: canvasSize, originalOffset: originalOffset)
                            }
                        }
                        .onEnded { value in
                            let target = dragTarget ?? .background
                            
                            if target == .background {
                                document.normalizedOffset.width += dragTranslation.width / canvasSize.width
                                document.normalizedOffset.height += dragTranslation.height / canvasSize.height
                            } else if case .element(let id) = target,
                                      let index = document.elements.firstIndex(where: { $0.id == id }) {
                                document.elements[index].normalizedPosition.x += dragTranslation.width / canvasSize.width
                                document.elements[index].normalizedPosition.y += dragTranslation.height / canvasSize.height
                            }
                            
                            dragTranslation = .zero
                            activeVerticalGuide = nil
                            activeHorizontalGuide = nil
                            activeSnapXType = nil
                            activeSnapYType = nil
                            dragTarget = nil
                        }
                )
            )
        }
    }
    
    private func updateSnapState(result: SnapResult, canvasSize: CGSize, originalOffset: CGSize) {
        activeVerticalGuide = result.activeVerticalGuide
        activeHorizontalGuide = result.activeHorizontalGuide
        activeSnapXType = result.snappedXType
        activeSnapYType = result.snappedYType
        
        let deltaX = result.correctedOffset.width - originalOffset.width
        let deltaY = result.correctedOffset.height - originalOffset.height
        
        dragTranslation = CGSize(
            width: deltaX * canvasSize.width,
            height: deltaY * canvasSize.height
        )
    }
    
    private func hitTest(location: CGPoint, canvasSize: CGSize) -> UUID? {
        let normLoc = CGPoint(x: location.x / canvasSize.width, y: location.y / canvasSize.height)
        for element in document.sortedElements.reversed() { // Check front-most elements first
            let geom = elementGeometry(element: element, canvasSize: canvasSize)
            if normLoc.x >= geom.minX && normLoc.x <= geom.maxX &&
               normLoc.y >= geom.minY && normLoc.y <= geom.maxY {
                return element.id
            }
        }
        return nil
    }
    
    private func screenshotGeometry(canvasSize: CGSize, scale: CGFloat = 1.0) -> SnapGeometry {
        let screenshotAspect: CGFloat
        if document.bezelStyle == .none, let media = document.media {
            let size = media.size
            screenshotAspect = size.height > 0 ? (size.width / size.height) : 1.0
        } else if let spec = document.bezelStyle.spec {
            screenshotAspect = spec.imageAspect
        } else {
            screenshotAspect = 9.0 / 16.0
        }
        
        let canvasAspect = canvasSize.width / max(1, canvasSize.height)
        let unscaledW = screenshotAspect > canvasAspect ? canvasSize.width : canvasSize.height * screenshotAspect
        let unscaledH = screenshotAspect > canvasAspect ? canvasSize.width / screenshotAspect : canvasSize.height
        
        let w = (unscaledW * scale) / canvasSize.width
        let h = (unscaledH * scale) / canvasSize.height
        
        let baseCenter = CGPoint(
            x: 0.5 + document.normalizedOffset.width,
            y: 0.5 + document.normalizedOffset.height
        )
        
        return SnapGeometry(
            minX: baseCenter.x - w / 2,
            maxX: baseCenter.x + w / 2,
            minY: baseCenter.y - h / 2,
            maxY: baseCenter.y + h / 2
        )
    }
    
    private func elementGeometry(element: CanvasElement, canvasSize: CGSize, extraScale: CGFloat = 1.0) -> SnapGeometry {
        var w: CGFloat = 0
        var h: CGFloat = 0
        
        switch element.content {
        case .image(let ref):
            let pixelW = canvasSize.width * element.scale * extraScale
            let aspect = ref.intrinsicSize.width / max(1, ref.intrinsicSize.height)
            let pixelH = pixelW / aspect
            
            w = pixelW / canvasSize.width
            h = pixelH / canvasSize.height
        case .text(let textData):
            let fontSize = canvasSize.width * element.scale * extraScale
            let uiFont: UIFont
            switch textData.fontName {
            case "System": uiFont = .systemFont(ofSize: fontSize)
            case "System Serif": uiFont = .systemFont(ofSize: fontSize) // approximate
            case "System Rounded": uiFont = .systemFont(ofSize: fontSize)
            case "System Mono": uiFont = .monospacedSystemFont(ofSize: fontSize, weight: .regular)
            default: uiFont = UIFont(name: textData.fontName, size: fontSize) ?? .systemFont(ofSize: fontSize)
            }
            let nsString = textData.string as NSString
            let rect = nsString.boundingRect(with: CGSize(width: canvasSize.width, height: .greatestFiniteMagnitude),
                                             options: .usesLineFragmentOrigin,
                                             attributes: [.font: uiFont],
                                             context: nil)
            
            w = rect.size.width / canvasSize.width
            h = rect.size.height / canvasSize.height
        default:
            w = 0 // Phase 8.4
            h = 0
        }
        
        return SnapGeometry(
            minX: element.normalizedPosition.x - w / 2,
            maxX: element.normalizedPosition.x + w / 2,
            minY: element.normalizedPosition.y - h / 2,
            maxY: element.normalizedPosition.y + h / 2
        )
    }
    
    private func calculateCanvasSize(in availableSize: CGSize) -> CGSize {
        // Compute requested ratio or fallback
        let ratio: CGFloat = document.canvasRatio.ratio(for: document.media, orientation: document.canvasOrientation) ?? (9.0 / 16.0)
        
        // Ensure bounds are non-zero
        guard availableSize.width > 0, availableSize.height > 0 else { return .zero }
        let availableRatio = availableSize.width / availableSize.height
        
        // Calculate dimensions to fit exactly within available space (aspect fit)
        if ratio > availableRatio {
            return CGSize(width: availableSize.width, height: availableSize.width / ratio)
        } else {
            return CGSize(width: availableSize.height * ratio, height: availableSize.height)
        }
    }
}
