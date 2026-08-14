import SwiftUI
import Observation

@Observable
final class MockupDocument {
    var media: MediaItem?
    var background: BackgroundStyle = .none
    var backgroundOpacity: Double = 1.0
    var bezelStyle: BezelStyle = .none
    var showStatusBar: Bool = false
    
    // Canvas Settings
    var canvasRatio: CanvasRatio = .original
    var canvasOrientation: CanvasOrientation = .portrait
    
    // Transform State
    var scale: CGFloat = 1.0
    // Normalized offset relative to the canvas size. e.g., (0.1, 0) means 10% shifted to the right.
    var normalizedOffset: CGSize = .zero
    
    // Canvas Elements
    var elements: [CanvasElement] = []
    
    var sortedElements: [CanvasElement] {
        elements.sorted(by: {
            if $0.zIndex != $1.zIndex { return $0.zIndex < $1.zIndex }
            return $0.id.uuidString < $1.id.uuidString
        })
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
        scale = 1.0
        normalizedOffset = .zero
    }
    
    // Preset Application
    func apply(preset: MockupPreset) {
        self.background = preset.background
        self.backgroundOpacity = preset.backgroundOpacity
        self.canvasRatio = preset.canvasRatio
        self.canvasOrientation = preset.canvasOrientation
        self.bezelStyle = preset.bezelStyle
        self.showStatusBar = preset.showStatusBar
        self.scale = preset.scale
        self.normalizedOffset = preset.normalizedOffset
    }
    
    // Check active preset
    func matches(preset: MockupPreset) -> Bool {
        return self.background == preset.background &&
               self.backgroundOpacity == preset.backgroundOpacity &&
               self.canvasRatio == preset.canvasRatio &&
               self.canvasOrientation == preset.canvasOrientation &&
               self.bezelStyle == preset.bezelStyle &&
               self.showStatusBar == preset.showStatusBar &&
               self.scale == preset.scale &&
               self.normalizedOffset == preset.normalizedOffset
    }
}
