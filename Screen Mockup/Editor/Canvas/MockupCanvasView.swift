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
                            if magnifyTarget == .background {
                                let newZoom = globalEditorZoom * value.magnification
                                globalEditorZoom = max(newZoom, 0.01)
                            } else if case .element(let id) = magnifyTarget,
                                      let index = document.elements.firstIndex(where: { $0.id == id }) {
                                if !document.elements[index].isLocked {
                                    let newScale = document.elements[index].transform.scale * value.magnification
                                    document.elements[index].transform.scale = max(newScale, 0.01)
                                }
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
                                // Background panning doesn't snap. Just pan.
                                dragTranslation = value.translation // wait, this was handled differently before? 
                                // Actually background panning in v1 was snapping the MAIN DEVICE.
                                // Now we don't snap the background. We just update the global editor offset?
                                // Wait, v1 used background panning to move the device!
                                // In v2, if background is dragged, we PAN the EDITOR VIEWPORT. But wait, `globalEditorZoom` is there, but no global editor pan exists yet.
                                // Let's just accumulate `dragTranslation` and ignore snapping.
                            } else if case .element(let id) = target,
                                      let index = document.elements.firstIndex(where: { $0.id == id }) {
                                
                                let element = document.elements[index]
                                if !element.isLocked {
                                    let baseGeometry = ElementGeometryResolver.snapGeometry(for: element, in: canvasSize)
                                    
                                    var otherObjects: [UUID: SnapGeometry] = [:]
                                    let bgId = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
                                    // The canvas itself is [0...1] in normalized space
                                    otherObjects[bgId] = SnapGeometry(minX: 0, maxX: 1, minY: 0, maxY: 1) // Not perfectly accurate for background center snap, but SnapEngine handles canvas snap natively.
                                    
                                    for otherEl in document.elements where otherEl.id != id && !otherEl.isHidden {
                                        otherObjects[otherEl.id] = ElementGeometryResolver.snapGeometry(for: otherEl, in: canvasSize)
                                    }
                                    
                                    let originalOffset = CGSize(width: element.transform.normalizedPosition.x, height: element.transform.normalizedPosition.y)
                                    
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
                        }
                        .onEnded { value in
                            let target = dragTarget ?? .background
                            
                            if target == .background {
                                // Phase 8+ viewport panning would go here. For now do nothing.
                            } else if case .element(let id) = target,
                                      let index = document.elements.firstIndex(where: { $0.id == id }) {
                                if !document.elements[index].isLocked {
                                    document.elements[index].transform.normalizedPosition.x += dragTranslation.width / canvasSize.width
                                    document.elements[index].transform.normalizedPosition.y += dragTranslation.height / canvasSize.height
                                }
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
        
        for element in document.sortedElements.reversed() where !element.isHidden {
            // Inverse transform for rotation
            let cx = element.transform.normalizedPosition.x
            let cy = element.transform.normalizedPosition.y
            
            let rad = -element.transform.rotationDegrees * .pi / 180.0
            let cosA = cos(rad)
            let sinA = sin(rad)
            
            // Translate point to origin
            let tx = normLoc.x - cx
            let ty = normLoc.y - cy
            
            // Rotate point
            let rx = tx * cosA - ty * sinA
            let ry = tx * sinA + ty * cosA
            
            // Translate point back
            let nx = rx + cx
            let ny = ry + cy
            
            // Hit test against unrotated bounds
            let visual = ElementGeometryResolver.visualSize(for: element, in: canvasSize)
            let wNorm = visual.width / canvasSize.width
            let hNorm = visual.height / canvasSize.height
            
            let minX = cx - wNorm / 2
            let maxX = cx + wNorm / 2
            let minY = cy - hNorm / 2
            let maxY = cy + hNorm / 2
            
            if nx >= minX && nx <= maxX && ny >= minY && ny <= maxY {
                return element.id
            }
        }
        return nil
    }
    
    private func calculateCanvasSize(in availableSize: CGSize) -> CGSize {
        // Compute requested ratio or fallback
        let firstMedia = document.elements.compactMap { el -> MediaReference? in
            if case .device(let data) = el.content { return data.media }
            return nil
        }.first
        let ratio: CGFloat = document.canvasRatio.ratio(for: firstMedia, orientation: document.canvasOrientation) ?? (9.0 / 16.0)
        
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
