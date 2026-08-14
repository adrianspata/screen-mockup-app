import SwiftUI

struct MockupPreset: Identifiable, Equatable {
    let id: String
    let name: String
    
    let background: BackgroundStyle
    var backgroundOpacity: Double = 1.0
    let canvasRatio: CanvasRatio
    var canvasOrientation: CanvasOrientation = .portrait
    let bezelStyle: BezelStyle
    var showStatusBar: Bool = false
    let scale: CGFloat
    let normalizedOffset: CGSize
    
    // Built-ins
    static let clean = MockupPreset(
        id: "clean", name: "Clean",
        background: .solid(Color(white: 0.95)),
        backgroundOpacity: 1.0,
        canvasRatio: .fourToFive,
        canvasOrientation: .portrait,
        bezelStyle: .iphone17White,
        showStatusBar: false,
        scale: 0.85,
        normalizedOffset: .zero
    )
    
    static let midnight = MockupPreset(
        id: "midnight", name: "Midnight",
        background: .solid(Color(white: 0.1)),
        backgroundOpacity: 1.0,
        canvasRatio: .fourToFive,
        canvasOrientation: .portrait,
        bezelStyle: .iphone17Black,
        showStatusBar: false,
        scale: 0.80,
        normalizedOffset: .zero
    )
    
    static let aurora = MockupPreset(
        id: "aurora", name: "Aurora",
        background: .gradient(Color.blue, Color.purple),
        backgroundOpacity: 1.0,
        canvasRatio: .fourToFive,
        canvasOrientation: .portrait,
        bezelStyle: .iphone17Black,
        showStatusBar: false,
        scale: 0.85,
        normalizedOffset: .zero
    )
    
    static let soft = MockupPreset(
        id: "soft", name: "Soft",
        background: .solid(Color(red: 0.96, green: 0.94, blue: 0.92)),
        backgroundOpacity: 1.0,
        canvasRatio: .fourToFive,
        canvasOrientation: .portrait,
        bezelStyle: .iphone17White,
        showStatusBar: false,
        scale: 0.85,
        normalizedOffset: .zero
    )
    
    static let story = MockupPreset(
        id: "story", name: "Story",
        background: .gradient(Color.orange, Color.pink),
        backgroundOpacity: 1.0,
        canvasRatio: .nineToSixteen,
        canvasOrientation: .portrait,
        bezelStyle: .iphone17Black,
        showStatusBar: false,
        scale: 0.85,
        normalizedOffset: .zero
    )
    
    static let wide = MockupPreset(
        id: "wide", name: "Wide",
        background: .solid(Color(white: 0.2)),
        backgroundOpacity: 1.0,
        canvasRatio: .nineToSixteen,
        canvasOrientation: .landscape,
        bezelStyle: .iphone17Black,
        showStatusBar: false,
        scale: 0.90,
        normalizedOffset: .zero
    )
    
    static let allBuiltIns: [MockupPreset] = [.clean, .midnight, .aurora, .soft, .story, .wide]
}
