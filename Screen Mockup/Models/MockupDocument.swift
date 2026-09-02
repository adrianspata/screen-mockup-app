import SwiftUI
import Observation

@Observable
final class MockupDocument {
    var background: BackgroundStyle = .none
    var backgroundOpacity: Double = 1.0
    
    // Canvas Settings
    var canvasRatio: CanvasRatio = .original
    var canvasOrientation: CanvasOrientation = .portrait
    
    // Canvas Elements
    var elements: [CanvasElement] = []
    
    var sortedElements: [CanvasElement] {
        elements.sorted(by: {
            if $0.zIndex != $1.zIndex { return $0.zIndex < $1.zIndex }
            return $0.id.uuidString < $1.id.uuidString
        })
    }
    
    // MARK: - Element Management
    
    func normalizeZIndices() {
        let sorted = sortedElements
        for (i, el) in sorted.enumerated() {
            if let index = elements.firstIndex(where: { $0.id == el.id }) {
                elements[index].zIndex = i
            }
        }
    }
    
    func insertElement(_ element: CanvasElement, select: Bool = true) {
        var newElement = element
        newElement.zIndex = elements.count
        elements.append(newElement)
        normalizeZIndices()
        if select {
            selectedElementID = newElement.id
        }
    }
    
    func duplicateElement(id: UUID) {
        guard let original = elements.first(where: { $0.id == id }) else { return }
        var duplicate = original
        // Change ID but keep same content and offset slightly
        let newID = UUID()
        // Wait, content might need deep copy? All our properties are value types!
        duplicate = CanvasElement(
            id: newID,
            content: original.content,
            transform: original.transform,
            zIndex: original.zIndex, // will be resolved
            isLocked: original.isLocked,
            isHidden: original.isHidden
        )
        duplicate.transform.normalizedPosition.x += 0.05
        duplicate.transform.normalizedPosition.y += 0.05
        
        elements.append(duplicate)
        // Sort so the duplicate comes right after the original
        elements.sort(by: {
            if $0.zIndex != $1.zIndex { return $0.zIndex < $1.zIndex }
            // Original before duplicate
            if $0.id == id { return true }
            if $1.id == id { return false }
            return $0.id.uuidString < $1.id.uuidString
        })
        normalizeZIndices()
        selectedElementID = newID
    }
    
    func deleteElement(id: UUID) {
        elements.removeAll(where: { $0.id == id })
        normalizeZIndices()
        if selectedElementID == id {
            selectedElementID = nil
        }
    }
    
    func bringForward(id: UUID) {
        normalizeZIndices()
        guard let index = elements.firstIndex(where: { $0.id == id }) else { return }
        let currentZ = elements[index].zIndex
        if currentZ < elements.count - 1 {
            // Find element above it
            if let aboveIndex = elements.firstIndex(where: { $0.zIndex == currentZ + 1 }) {
                elements[index].zIndex = currentZ + 1
                elements[aboveIndex].zIndex = currentZ
            }
        }
        normalizeZIndices()
    }
    
    func sendBackward(id: UUID) {
        normalizeZIndices()
        guard let index = elements.firstIndex(where: { $0.id == id }) else { return }
        let currentZ = elements[index].zIndex
        if currentZ > 0 {
            // Find element below it
            if let belowIndex = elements.firstIndex(where: { $0.zIndex == currentZ - 1 }) {
                elements[index].zIndex = currentZ - 1
                elements[belowIndex].zIndex = currentZ
            }
        }
        normalizeZIndices()
    }
    
    // Selection
    var selectedElementID: UUID?
    var editingTextElementID: UUID?    
    // State preservation across mode switches
    var lastSolidColor: Color = .blue
    var lastGradientStart: Color = .purple
    var lastGradientEnd: Color = .orange
    var lastBackgroundImage: UIImage?
    
    func resetTransform() {
        if let id = selectedElementID, let index = elements.firstIndex(where: { $0.id == id }) {
            elements[index].transform.scale = 1.0
            elements[index].transform.normalizedPosition = CGPoint(x: 0.5, y: 0.5)
            elements[index].transform.rotationDegrees = 0.0
        }
    }
    
    // Preset Application
    func apply(preset: MockupPreset) {
        self.background = preset.background
        self.backgroundOpacity = preset.backgroundOpacity
        self.canvasRatio = preset.canvasRatio
        self.canvasOrientation = preset.canvasOrientation
        
        if let id = selectedElementID, let index = elements.firstIndex(where: { $0.id == id }), case .device(var data) = elements[index].content {
            data.bezelStyle = preset.bezelStyle
            data.showStatusBar = preset.showStatusBar
            elements[index].content = .device(data)
            elements[index].transform.scale = preset.scale
            elements[index].transform.normalizedPosition = CGPoint(x: 0.5 + preset.normalizedOffset.width, y: 0.5 + preset.normalizedOffset.height)
        }
    }
    
    // Check active preset
    func matches(preset: MockupPreset) -> Bool {
        guard self.background == preset.background,
              self.backgroundOpacity == preset.backgroundOpacity,
              self.canvasRatio == preset.canvasRatio,
              self.canvasOrientation == preset.canvasOrientation else {
            return false
        }
        
        if let id = selectedElementID, let element = elements.first(where: { $0.id == id }), case .device(let data) = element.content {
            return data.bezelStyle == preset.bezelStyle &&
                   data.showStatusBar == preset.showStatusBar &&
                   element.transform.scale == preset.scale &&
                   element.transform.normalizedPosition.x == 0.5 + preset.normalizedOffset.width &&
                   element.transform.normalizedPosition.y == 0.5 + preset.normalizedOffset.height
        }
        
        return false
    }
    
    // Create DTO Snapshot
    func persistenceSnapshot(projectID: UUID) -> ProjectManifest {
        // Map elements
        let manifestElements = elements.map { el -> ManifestElement in
            let content: ManifestElementContent
            switch el.content {
            case .device(let data):
                content = .device(ManifestDeviceElementData(
                    media: data.media,
                    bezelStyle: data.bezelStyle.rawValue,
                    showStatusBar: data.showStatusBar
                ))
            case .image(let ref):
                content = .image(ref)
            case .text(let textData):
                content = .text(ManifestTextData(string: textData.string, fontName: textData.fontName, color: textData.color.rgba))
            case .sfSymbol:
                content = .sfSymbol
            }
            return ManifestElement(
                id: el.id,
                content: content,
                transform: ManifestElementTransform(
                    normalizedPosition: [Double(el.transform.normalizedPosition.x), Double(el.transform.normalizedPosition.y)],
                    scale: Double(el.transform.scale),
                    rotationDegrees: Double(el.transform.rotationDegrees),
                    opacity: Double(el.transform.opacity)
                ),
                zIndex: el.zIndex,
                isLocked: el.isLocked,
                isHidden: el.isHidden
            )
        }
        
        let manifestBg: ManifestBackground
        switch background {
        case .none: manifestBg = .none
        case .solid(let c): manifestBg = .solid(c.rgba)
        case .gradient(let c1, let c2): manifestBg = .gradient(start: c1.rgba, end: c2.rgba)
        case .image(let ref): manifestBg = .image(ref)
        }
        
        return ProjectManifest(
            projectID: projectID,
            schemaVersion: 2,
            creationDate: Date(), // Usually want to keep original, but for now Date() since we don't store it in MockupDocument
            modifiedDate: Date(),
            background: manifestBg,
            backgroundOpacity: backgroundOpacity,
            canvasRatio: canvasRatio.rawValue,
            canvasOrientation: canvasOrientation.rawValue,
            elements: manifestElements,
            assets: [] // This is populated by SaveCoordinator / AssetStore
        )
    }
    
    func apply(manifest: ProjectManifest) {
        switch manifest.background {
        case .none: self.background = .none
        case .solid(let c): self.background = .solid(Color(rgba: c))
        case .gradient(let c1, let c2): self.background = .gradient(Color(rgba: c1), Color(rgba: c2))
        case .image(let ref): self.background = .image(ref)
        }
        self.backgroundOpacity = manifest.backgroundOpacity
        
        if let ratio = CanvasRatio(rawValue: manifest.canvasRatio) {
            self.canvasRatio = ratio
        }
        if let orientation = CanvasOrientation(rawValue: manifest.canvasOrientation) {
            self.canvasOrientation = orientation
        }
        
        self.elements = manifest.elements.map { dto -> CanvasElement in
            let content: CanvasElement.ElementContent
            switch dto.content {
            case .device(let data):
                content = .device(DeviceElementData(
                    media: data.media,
                    bezelStyle: BezelStyle(rawValue: data.bezelStyle) ?? .none,
                    showStatusBar: data.showStatusBar
                ))
            case .image(let ref):
                content = .image(ref)
            case .text(let t):
                content = .text(CanvasElement.TextData(string: t.string, fontName: t.fontName, color: Color(rgba: t.color)))
            case .sfSymbol:
                content = .sfSymbol
            }
            let pos = dto.transform.normalizedPosition.count == 2 ? CGPoint(x: dto.transform.normalizedPosition[0], y: dto.transform.normalizedPosition[1]) : CGPoint(x: 0.5, y: 0.5)
            let transform = ElementTransform(
                normalizedPosition: pos,
                scale: CGFloat(dto.transform.scale),
                rotationDegrees: dto.transform.rotationDegrees,
                opacity: dto.transform.opacity
            )
            return CanvasElement(
                id: dto.id,
                content: content,
                transform: transform,
                zIndex: dto.zIndex,
                isLocked: dto.isLocked,
                isHidden: dto.isHidden
            )
        }
    }
}
